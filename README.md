# StreamBaseKit - UI 工具包 for Wilddog

StreamBaseKit是基于[Wilddog](https://www.wilddog.com)的Swift的UI工具包.  它表明Wilddog查询作为数据流进行实时同步, 递增地去提取, 并且可以被合并或分割成多个部分. 这些数据流可以很容易地插入到UI视图中, 比如UITableView.  

该套件还包括一个 [persistence layer](# 持久层), 可以很容易地在Wilddog中持久化对象.


## StreamBaseKit 入门:

如果你还没有Wilddog账号，注册一个 [野狗账号](https://www.wilddog.com/my-account/signup).

要使用streams, 你需要知道这些类:

类  |  描述
-------|-------------
StreamBase | 这是基于Wilddog查询的一个stream的主类.
StreamBaseItem | streams中的基类.
StreamBaseDelegate |通知stream的变化的代理.
StreamTableViewAdapter | 从streams到UITableViews的转接器.
PartitionedStream | 拆分一个stream为多个部分.
TransientStream |  Stream没有连接到Wilddog.
UnionStream |  Stream合并多个streams.
QueryBuilder | 组成Wilddog查询的帮手.

你需要继承StreamBaseItem和StreamBase建立类.  此外,StreamTableViewAdapter提供了一些方便的功能去连接streams和表.   下面是一些基本描述:

```swift

MyItem.swift

class MyItem : StreamBaseItem {
  var name: String?

  func update(dict: [String: AnyObject) {
    super.update(dict)
    name = dict["name"] as? String
  }

  var dict: [String: AnyObject] {
    var d = super.dict
    d["name"] = name
    return d
  }
}

MyViewController.swift

class MyViewController : UIViewController {
  var stream: StreamBase!
  var adapter: StreamTableViewAdapter!
  // etc...

  override func viewDidLoad() {
    // etc...
    
    //初始化 WDGApp
    let options = WDGOptions.init(syncURL: "https://<YOUR-WILDDOG-APP>.wilddogio.com")
    WDGApp.configureWithOptions(options)
    let wilddogeRef = WDGSync.sync().reference()
    stream = StreamBase(type: MyItem.self, ref: wilddogRef)
    adapter = StreamTableViewAdapter(tableView: tableView)
    stream.delegate = adapter
  }
}

extension MyViewController : UITableViewDataSource {
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return stream.count
  } 

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("MyCell", forIndexPath: indexPath)
    let item = stream[indexPath.row] as! MyItem
    cell.titleLabel?.text = item.name 
    return cell
  }
}
```

## 多组和 PartitionedStream

PartitionedStream允许定义分区函数来把一个stream分成多个部分.  这是有用的, eg, 把一些用户分为组织者和参与者.  前面例子的构建:

```swift

User.swift

class User : StreamBaseItem {
  var isOrganizer: Bool
  // etc...
}

MyViewController.swift

class MyViewController : UIViewController {
  var pstream: PartitionedStream!
  // etc...

  override func viewDidLoad() {
    // etc...
    pstream = PartitionedStream(stream: stream, sectionTitles: ["organizers", "participants"]) { ($0 as! User).isOrganizer ? 0 : 1 }
    pstream.delegate = adapter
  }
} 

extension MyViewController : UITableViewDataSource {
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return pstream[section].count
  } 

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("MyCell", forIndexPath: indexPath)
    let item = pstream[indexPath] as! User  // Index partitioned stream with whole NSIndexPath
    cell.titleLabel?.text = item.name 
    return cell
  }

  func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return pstream.sectionTitles[section]
  }
}

```

## 多组和多Streams

PartitionedStream容易使用,但如果基础数据有数百种以上的元素, 你需要提供每部分的限制. 可以通过构建多个组来这样做, 比如:

```swift

class MyViewController : UIViewController {
  var organizerStream: StreamBase!
  var participantStream: StreamBase!
  var organizerAdapter: StreamTableViewAdapter!
  var participantAdapter: StreamTableViewAdapter!
  // etc...

  override func viewDidLoad() {
    // etc...
    let organizerQuery = QueryBuilder(ref)
    organizerQuery.limit = 100
    organizerQuery.ordering = .Child("is_organizer")
    organizerQuery.start = true
    organizerStream = StreamBase(type: User.self, queryBuilder: organizerQuery)
    organizerAdapter = StreamTableViewAdapter(tableView: tableView, section: 0)

    let participantQuery = QueryBuilder(ref)
    participantQuery.limit = 100
    participantQuery.ordering = .Child("is_organizer")
    participantQuery.end = false
    participantStream = StreamBase(type: User.self, queryBuilder: participantQuery)
    participantAdapter = StreamTableViewAdapter(tableView: tableView, section: 1)
  }
}
  
extension MyViewController : UITableViewDataSource {
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return (section == 0) ? organizerStream.count : participantStream.count
  } 

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("MyCell", forIndexPath: indexPath)
    let user: User
    if indexPath.section == 0 {
      user = organizerStream[indexPath.row] as! User
    } else {
      user = participantStream[indexPath.row] as! User
    }
    // etc...
    return cell
  }
}
```

##  占位符和增量提取与TransientStream和UnionStream

聊天记录可能很长, 所以去逐步提取数据是很重要的.  要做到这一点, 我们需要能够插入临时占位符到表以便提供用户界面所需的数据的提取, 并实际执行额外的提取  更进一步的细节（如知道stream的实际大小！）, 这是如何做到这一点的工作草图:

```swift

class MyViewController : UIViewController {
  let maxToFetch = 100
  var stream: StreamBase!
  var unionStream: UnionStream!
  var transientStream: TransientStream!
  var fetchmore: FetchMoreItem?

  override func viewDidLoad() {
    // etc...
    stream = StreamBase(type: MyItem.self, ref: wilddogRef, ascending: false, limit: maxToFetch)
    transient = TransientStream()
    unionStream = UnionStream(sources: stream, transient)
    unionStream.delegate = self
  }

  func fetchMoreTapped(sender: UIButton) {
    stream.fetchMore(maxToFetch, start: stream[0].key!) {
      transient.remove(fetchmore)
      fetchmore = nil
    }
  }
}
```


这里我们扩展StreamBaseDelegate，而不是使用StreamTableViewAdapter，因为我们需要在控制器中操作状态。

```swift
extension MyViewController : StreamBaseDelegate {
  override func streamDidFinishInitialLoad(error: NSError?) {
    super.streamDidFinishInitialLoad(error)
    if stream.count > maxToFetch {
      fetchmore = FetchMoreItem(key: dropLast(stream[0].key))
      transient.add(fetchmore)
    }
  }
}

```

# 持久层


StreamBaseKit还包括一个使用声明方法的持久层：你声明存储了什么，并且该层负责处理其余的事情。例如

```swift
registry.resource(Group.self, "/group/@")
registry.resource(GroupMessage.self, "/group_message/$group/@")
```

这说明groups存储在“/group”,  messages在逻辑上是包含在"/group_message".  (这不是一个很好的做法将它们存储在 "/group", 在 "/group/$group/message/@",因为group提取所有的信息.)  

"@" 的意思是一个自动ID生成用于创建操作, 并且该对象的密钥用于更新和毁坏.  "$" 表示该值必须使用ResourceContext ... 更多介绍在下面.

要使用persitence层, 你会想知道这些类:

类  |  描述
-------|-------------
ResourceBase | 核心持久层.
ResourceContext | 帮助在持久层管理上下文.
ResourceRegistry | 注册资源的协议.


## 注册资源与持久层

用ResourceBase的ResourceRegistry协议注册资源.   一种ResourceBase制成单例的方法.  例如:

```swift

Environment.swift

class Environment {
  var resourceBase: ResourceBase!

  static let sharedEnv: Environment = {
    let env = Environment()
    //初始化 WDGApp
    let options = WDGOptions.init(syncURL: "https://<YOUR-WILDDOG-APP>.wilddogio.com")
    WDGApp.configureWithOptions(options)
    let wilddog = WDGSync.sync().reference()
    env.resourceBase = ResourceBase(wilddog: wilddog)

    let registry: ResourceRegistry = env.resourceBase
    registry.resource(Group.self, "/group/@")
    registry.resource(GroupMessage.self, "/group_message/$group/@")
    // ...

    return env
  }()
}

```

## 使用ResourceContext堆栈

在最初的视图控制器中, 使用环境单例创建根资源方面:

```swift

InitialViewController.swift

class InitialViewController : UIViewController {
  var rootResourceContext: ResourceContext!
  // ...
  
  override func viewDidLoad() {
    super.viewDidLoad()
    rootResourceContext = ResourceContext(base: Environment.sharedEnv.resourceBase, resources: nil)
    // ...
```

使用该Resource Context，在这个视图控制器现在可以创建, 更新和删除 Groups .  例如:


```swift
let group = Group()
group.name = "group name"
rootResourceContext.create(group)
```

“group”在“/group_message/$group/@“表示context密钥必须以坚持一个GroupMessage填写. 该ResourceContext负责做这个.  假设你有一个GroupViewControlle, 它允许用户把信息分组.  在最初的视图控制器, 推动组视图控制器到你的导航控制器之前，你会做这样的事情:

```swift
override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
  switch(segue.destinationViewController) {
  case let groupVC as GroupViewController:
    groupVC.resourceContext = resourceContext.push(["group": sender as! Group])
    // ...
```

现在，当你在GroupViewController调用 ```resourceContext.create(GroupMessage())```, ,它会知道如何解决的关键“$group”.同样，如果你想要更加深入,  可以“like”信息在groups, 你可以做到这一点通过短暂地推动ResourceContext入堆栈.  这可能是这样的:

```swift
func messageLikeTouched(sender: MessageLikeControl) {
  resourceContext.push(["message": sender.message]).create(MessageLike())
}
```

## 计数器

你可能去制定计数器去获取增加的和销毁的对象数量.   假设你想跟踪有多少信息是在你的 group.  你注册一个计数器, 比如:

```swift
registry.counter(Group.self, "message_count", GroupMessage.self)
```

当messages被创建和销毁时, 该ResourceBase将递增和递减"message_count".  由于groups被注册在“/groups/ @”下, 该计数器会出现在这里：“/groups/ $ group_key / MESSAGE_COUNT”.  

注意，这个计数器被保持在客户端, 因此可以随着时间的推移不一致.  例如, Wilddog 在 app 重启后 transactions 不是持续的, 因此，如果用户在脱机状态下更改，然后关闭该应用程序，计数器可能不会更新.

##  扩展ResourceBase

ResourceBase具有许多hooks，当使用时可以子类化.  有hooks用于创建，更新和销毁之前被调用，之后提交到本地存储，之后提交到 远程存储.  还有一个hook用于登录状态，这样一台服务器可以处理.

# 构建实例

一个简单的例子项目. 去构建它:

```
$ git clone https://github.com/movem3nt/StreamBaseKit.git
$ pod install
$ open StreamBaseExample.xcworkspace
```

Set the active scheme to StreamBaseExample, and then hit command-R.

#  与demo-ios-wildchat比较

要考虑的另外一个库是 [demo-ios-wildchat](https://github.com/WildDogTeam/demo-ios-wildchat). 这是Wilddog的官方客户端库。 这是用Objective-C写的，而不是Swift，它更简单.

StreamBaseKit脱胎于创建Movem3nt，它是一个复杂的社会应用，并解决各种这样做时遇到的问题。 例如，如果内容被插在上面，那么iOS的表视图将自动滚动，但Wilddog把新的数据添加到末尾。 为了使这些很好地协同工作去创建消息类型的应用程序，需要联合Wilddog和表视图.
StreamBaseKit也可以很容易地添加更多高级功能，例如拆分集合到表的多个部分，并插入瞬时内容到表像“获取更多的”控制增量提取.
资源层使得它更要保持你的数据库持久性逻辑和UI视图控制器逻辑分离。 它还提供了便捷的计数器功能.

## 支持
如果在使用过程中有任何问题，请提 [issue](https://github.com/WildDogTeam/lib-ios-streambase/issues) ，我会在 Github 上给予帮助。

## 相关文档

* [Wilddog 概览](https://docs.wilddog.com/overview/index.html)
* [IOS SDK快速入门](https://docs.wilddog.com/overview/index.html)
* [IOS SDK API](https://docs.wilddog.com/api/sync/ios/WDGOptions.html)
* [下载页面](https://docs.wilddog.com/quickstart/sync/ios.html)
* [Wilddog FAQ](https://docs.wilddog.com/overview/index.html)


## License

[MIT](http://wilddog.mit-license.org/)

## 感谢 Thanks

lib-ios-streambase is built on and with the aid of several projects. We would like to thank the following projects for helping us achieve our goals:

Open Source:

* [StreamBaseKit](https://github.com/burtherman/StreamBaseKit) Firebase StreamBaseKit powered by Firebase
