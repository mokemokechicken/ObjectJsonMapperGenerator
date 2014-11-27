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

class Base {
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


class Book : Base {
    var authors: [Author] = [Author]()
    var title: String = ""
    var note: String?
    var option: Book_0 = Book_0()
    
    class Book_0 : Base {
        var hoge: String?
        var hara: Bool?
    }
    
    override func toJsonDictionary() -> NSDictionary {
        var hash = NSMutableDictionary()
        hash["authors"] = self.authors.map { x in encode(x) }
        hash["title"] = encode(self.title)
        hash["note"] = encode(self.note)
        hash["option"] = encode(self.option)
        return hash
    }
    
    override func fromJsonDictionary(hash: NSDictionary) {
        if let xx = hash["authors"] as? NSArray {
            for x in xx as [NSDictionary] {
                self.authors.append(Author(hash: x))
            }
        }
        self.title = hash["title"] as String
        self.note = decodeOptional(hash["note"]) as? String
        self.option.fromJsonDictionary(hash["option"] as NSDictionary)
    }
}



class Author : Base {
}
