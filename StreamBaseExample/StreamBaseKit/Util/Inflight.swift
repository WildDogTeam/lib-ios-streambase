//
//  Inflight.swift
//  StreamBaseKit
//
//  Created by IMacLi on 15/10/12.
//  Copyright © 2015年 liwuyang. All rights reserved.
//

import UIKit

/**
    RAII interface for network activity indicator: simply keep an Inflight object
    in scope for the duration of the request.  As long as you're not leaking Inflight
    objects, the underlying counter will remain accurate.  There are a few ways to make
    sure this works with closures.  Example usage:

        var inflight : Inflight? = Inflight()
        doSomethingInBackground() {
          inflight = nil
        }
*/
public class Inflight {
    
    /**
        Indicates that some work is happening and network activity indicator should
        appear.
    */
    public init() {
        InflightManager.sharedManager.increment()
    }
    
    deinit {
        InflightManager.sharedManager.decrement()
    }
    
    func hold() { }
}

private class InflightManager {
    private static let sharedManager = InflightManager()
    
    var counter: UnsafeMutablePointer<Int32>
    init() {
        counter = UnsafeMutablePointer<Int32>.alloc(1)
        counter.initialize(0)
    }
    
    deinit {
        counter.dealloc(1)
    }
    
    func increment() {
        OSAtomicIncrement32(counter)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func decrement() {
        let newValue = OSAtomicDecrement32(counter)
        assert(newValue >= 0)
        if newValue == 0 {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
}