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
    func toJsonDictionary() -> NSDictionary {
        return NSDictionary()
    }

    class func fromJsonDictionary(hash: NSDictionary) -> Base? {
    }
}


class Book : Base {
    var authors: [Author] = [Author]()
    var title: String = ""
    var note: String?
    var option: Book_0?
    
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
    
    override class func fromJsonDictionary(hash: NSDictionary) -> Book? {
        val this = Book()
        if let xx = hash["authors"] as? [NSDictionary] {
            for x in xx {
                if let obj = Author.fromJsonDictionary(hash: x) {
                    this.authors.append(obj)
                } else {
                    return nil
                }
            }
        } else {
            return nil
        }
        this.title = hash["title"] as String
        this.note = decodeOptional(hash["note"]) as? String
        this.option = Book_0.fromJsonDictionary(hash["option"] as NSDictionary)
        return this
    }
}



class Author : Base {
}
