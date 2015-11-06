//  StreamBaseKit
//
//  QueryBuilder.swift
//
//  Created by IMacLi on 15/10/12.
//  Copyright © 2015年 liwuyang. All rights reserved.
//

import Foundation
import Wilddog

/**
    Helper for constructing queries.  

    NOTE: This is needed because StreamBase does a lot of client side processing, 
    and so needs to duplicate some functionality of the Wilddog query.
    Additionally, it's not possible to inspect FQuery, so instead we generate FQuery 
    objects based on specs provided here.
*/
public class QueryBuilder {
    var ref: Wilddog
    
    /**
        The maximum number of results to return.  If nil, the whole collection is
        fetched (or at least attempted to be...)
    */
    public var limit: Int?
    
    /**
        Whether to present the collection in ascending (default, Wilddog native)
        or descending order.  The latter is needed for messaging apps.
    */
    public var ascending = true
    
    /**
        The sort order.
    */
    public var ordering = StreamBase.Ordering.Key
    
    /**
        Where to start querying.  If ordering is key this is a key, otherwise it
        is a child value.
    */
    public var start: AnyObject?

    /**
        Where to end querying.  If ordering is key this is a key, otherwise it
        is a child value.
    */
    public var end: AnyObject?

    /**
        Construct a builder.

        :param: ref The Wilddog ref for the collection.
    */
    public init(ref: Wilddog) {
        self.ref = ref
    }

    func buildComparator() -> StreamBase.Comparator {
        let comp: StreamBase.Comparator
        switch ordering {
        case .Key:
            comp = { (a, b) in a.key < b.key }
        case .Child(let key):
        
            // TODO: Compare unlike types correctly.
            comp = { (a, b) in
                let av: AnyObject? = a.dict[key] ?? NSNull()
                let bv: AnyObject? = b.dict[key] ?? NSNull()
                switch (av, bv) {
                case ( _ as NSNull, _ as NSNull):
                    break
                case (_ as NSNull, _):
                    return true
                case (_, _ as NSNull):
                    return false
                case (let astr as String, let bstr as String):
                    if astr != bstr {
                        return astr < bstr
                    }
                case (let aflt as Float, let bflt as Float):  // NOTE: Includes Int
                    if aflt != bflt {
                        return aflt < bflt
                    }
                case (let abool as Bool, let bbool as Bool):
                    if abool != bbool {
                        return !abool
                    }
                default:
                    break
                }
                return a.key < b.key
            }
        }
        return (ascending) ? comp : { comp($1, $0) }
    }
    
    func buildQueryPager() -> StreamBase.QueryPager {
        var query: WQuery
        switch ordering {
        case .Key:
            query = ref.queryOrderedByKey()
        case .Child(let key):
            query = ref.queryOrderedByChild(key)
        }
        return { (start, end, limit) in
            if self.ascending {
                if let s: AnyObject = start {
                    query = query.queryStartingAtValue(s)
                }
                if let e: AnyObject = end {
                    query = query.queryEndingAtValue(e)
                }
                if let l = limit {
                    query = query.queryLimitedToFirst(UInt(l + 1))
                }
                return query
            } else {
                if let s: AnyObject = start {
                    query = query.queryEndingAtValue(s)
                }
                if let e: AnyObject = end {
                    query = query.queryStartingAtValue(e)
                }
                if let l = limit {
                    query = query.queryLimitedToLast(UInt(l + 1))
                }
                return query
            }
        }
    }
    
    func buildQuery() -> WQuery {
        return buildQueryPager()(start: start, end: end, limit: limit)
    }
}
