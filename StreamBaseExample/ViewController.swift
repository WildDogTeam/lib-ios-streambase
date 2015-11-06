//
//  ViewController.swift
//  StreamBaseExample
//
//  Created by IMacLi on 15/11/2.
//  Copyright © 2015年 liwuyang. All rights reserved.
//

import UIKit

class ViewController: SLKTextViewController {
    
    var resourceContext: ResourceContext!
    var stream: StreamBase!
    var adapter: StreamTableViewAdapter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inverted = true
        
        tableView.separatorStyle = .None
        
        resourceContext = ResourceContext(base: Environment.sharedEnv.resourceBase, resources: nil)
        let ref = resourceContext.collectionRef(Message.self)
        stream = StreamBase(type: Message.self, ref: ref, limit: nil, ascending: !inverted)
        adapter = StreamTableViewAdapter(tableView: tableView)
        stream.delegate = adapter
    }
    
    override func didPressRightButton(sender: AnyObject!) {
        let message = Message()
        message.username = UIDevice.currentDevice().name
        message.text = textView.text
        resourceContext.create(message)
        textView.text = nil
    }
    
    // MARK: UITableViewDataSource
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stream.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: nil)
        let message = stream[indexPath.row] as! Message
        cell.textLabel?.text = message.text
        cell.detailTextLabel?.text = message.username
        cell.transform = tableView.transform  // Because inverted=true
        return cell
    }
    
    
}


