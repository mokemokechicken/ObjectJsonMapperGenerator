// Playground - noun: a place where people can play

import UIKit

/*
Book:
authors: [Author]
title: String
note?: String
option:
  hoge?: String
  hara?: Bool
*/

private func encode(obj: AnyObject?) -> AnyObject {
    switch obj {
    case nil:
        return NSNull()
        
    case let ojmObject as Base:
        return ojmObject.toJsonDictionary()
        
    default:
        return obj!
    }
}

private func decodeOptional(obj: AnyObject?) -> AnyObject? {
    switch obj {
    case let x as NSNull:
        return nil
    
    default:
        return obj
    }
}

class JsonGenEntityBase {
    convenience init(hash: NSDictionary) {
        self.init()
        self.fromJsonDictionary(hash)
    }

    func toJsonDictionary() -> NSDictionary {
        return NSDictionary()
    }

    func fromJsonDictionary(hash: NSDictionary) {
    }
}

