//
//  String+trimPrefix.swift
//  StreamBaseKit
//
//  Created by IMacLi on 15/10/12.
//  Copyright © 2015年 liwuyang. All rights reserved.
//

import Foundation

extension String {
    
    mutating func trimPrefix(prefix: String) {
        if hasPrefix(prefix) {
            removeRange(startIndex..<prefix.endIndex)
        }
    }
    
    func prefixTrimmed(prefix: String) -> String {
        if hasPrefix(prefix) {
            var copy = self
            copy.removeRange(startIndex..<prefix.endIndex)
            return copy
        }
        return self
    }
    
}

