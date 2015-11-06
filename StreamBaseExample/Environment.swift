//
//  Environment.swift
//  StreamBaseExample
//
//  Created by IMacLi on 15/11/2.
//  Copyright © 2015年 liwuyang. All rights reserved.
//

import Foundation

import Wilddog

class Environment {
    let resourceBase: ResourceBase
    
    static let sharedEnv: Environment = {
        let wilddog = Wilddog(url: "https://streamexample.wilddogio.com")
        
        let resourceBase = ResourceBase(wilddog: wilddog)
        let registry: ResourceRegistry = resourceBase
        
        registry.resource(Message.self, path: "/message/@")
        
        return Environment(resourceBase: resourceBase)
        }()
    
    init(resourceBase: ResourceBase) {
        self.resourceBase = resourceBase
    }
}
