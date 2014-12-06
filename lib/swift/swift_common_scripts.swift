import Foundation

private func encode(obj: AnyObject?) -> AnyObject {
    switch obj {
    case nil:
        return NSNull()
        
    case let ojmObject as JsonGenEntityBase:
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
    func toJsonDictionary() -> NSDictionary {
        return NSDictionary()
    }

    class func fromJsonDictionary(hash: NSDictionary?) -> JsonGenEntityBase? {
        return nil
    }
}
