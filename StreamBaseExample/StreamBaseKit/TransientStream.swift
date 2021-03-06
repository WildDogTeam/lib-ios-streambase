//
//  TransientStream.swift
//  StreamBaseKit
//
//  Created by IMacLi on 15/10/12.
//  Copyright © 2015年 liwuyang. All rights reserved.
//

import Foundation

/**
    A stream this is not connected to any Wilddog storage.
*/
public class TransientStream : StreamBase {
    public override init() {
        super.init()
        batchDelay = nil
    }
    
    /**
        Update this stream to contain exactly these items.
        
        :param: items   The items to appear in the stream.
    */
    public func reset(items: [BaseItem]?) {
        batching { a in
            a.reset(items ?? [])
        }
    }

    /**
        Add one or more items to the transient stream.

        :param: items   The items to add.
    */
    public func add(items: BaseItem...) {
        batching { a in
            a.extend(items)
        }
    }

    /**
        Remove one or more items from the transient stream.

        :param: items   The items to remove.
    */
    public func remove(items: BaseItem...) {
        batching { a in
            for p in items {
                if let i = a.find(p.key!) {
                    a.removeAtIndex(i)
                }
            }
        }
    }
}
