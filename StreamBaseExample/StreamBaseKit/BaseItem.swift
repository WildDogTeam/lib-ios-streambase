//
//  BaseItem.swift
//  StreamBaseKit
//
//  Created by IMacLi on 15/10/12.
//  Copyright © 2015年 liwuyang. All rights reserved.
//

import Wilddog

/**
    Protocol describing behavior of BaseItem.  This is useful for creating other
    protocols that extend the behavior of BaseItem subclasses.
*/
public protocol BaseItemProtocol : KeyedObject {
    var key: String? { get set }
    var dict: [String: AnyObject] { get }
    init(key: String?)
    func update(dict: [String: AnyObject]?)
    func clone() -> BaseItemProtocol
}

/**
    A base class for objects persisted in Wilddog that make up the
    items in streams.
 */
public class BaseItem: Equatable, BaseItemProtocol {
    /**
        The final part of the wilddog path.
    */
    public var key: String?
    
    /**
        Used for persisting data to wilddog.  Subclasses should override,
        appending their fields to this dictionary.
    */
    public var dict: [String: AnyObject] {
        return [:]
    }
    
    /**
        Create an empty instance.  Typically used for constructing new instances
        where the key and ref are filled in later.
    */
    public convenience init() {
        self.init(key: nil)
    }
    
    /**
        Create an instance fully initialized with the key, ref and data.

        :param: key The last part of the wilddog path
        :param: ref The full wilddog reference (including key)
        :param: dict    The data with which to populate this object
    */
    public required init(key: String?) {
        self.key = key
    }
    
    /**
        Subclasses should override to initialize fields.  If the dict is nil, then
        the object has been deleted.
    
        :param: dict    The dictionary containing the values of the fields.
     */
    public func update(dict: [String: AnyObject]?) {
    }
    
    /**
        Produce a shallow copy of this object.
    */
    public func clone() -> BaseItemProtocol {
        let copy = self.dynamicType.init(key: key)
        copy.update(dict)
        return copy
    }
}

// NOTE: This would make more sense on KeyedObject, but Swift 1.2 doesn't support
// Equatable protocols.
public func ==(lhs: BaseItem, rhs: BaseItem) -> Bool {
    return lhs.key == rhs.key
}


