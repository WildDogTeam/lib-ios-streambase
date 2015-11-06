//
//  Message.swift
//  StreamBaseExample
//
//  Created by IMacLi on 15/11/2.
//  Copyright © 2015年 liwuyang. All rights reserved.
//

import Foundation

class Message : BaseItem {
    var text: String?
    var username: String?
    
    override func update(dict: [String : AnyObject]?) {
        super.update(dict)
        text = dict?["text"] as? String
        username = dict?["username"] as? String
    }
    
    override var dict: [String: AnyObject] {
        var d = super.dict
        d["text"] = text
        d["username"] = username
        return d
    }
}