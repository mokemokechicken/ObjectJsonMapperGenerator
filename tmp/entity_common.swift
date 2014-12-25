import Foundation
private func encode(obj: AnyObject?) -> AnyObject {
    switch obj {
    case nil:
        return NSNull()
        
    case let ojmObject as EntityBase:
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

private func JsonGenObjectFromJsonData(data: NSData!) -> AnyObject? {
    if data == nil {
        return nil
    }
    return NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.MutableContainers, error: nil)
}

public class EntityBase {
    public init() {
    }

    public func toJsonDictionary() -> NSDictionary {
        return NSDictionary()
    }

    public class func toJsonArray(entityList: [EntityBase]) -> NSArray {
        return entityList.map {x in encode(x)}
    }

    public class func toJsonData(entityList: [EntityBase], pretty: Bool = false) -> NSData {
        var obj = toJsonArray(entityList)
        return toJson(obj, pretty: pretty)
    }

    public func toJsonData(pretty: Bool = false) -> NSData {
        var obj = toJsonDictionary()
        return EntityBase.toJson(obj, pretty: pretty)
    }

    public class func toJsonString(entityList: [EntityBase], pretty: Bool = false) -> NSString {
        return NSString(data: toJsonData(entityList, pretty: pretty), encoding: NSUTF8StringEncoding)!
    }

    public func toJsonString(pretty: Bool = false) -> NSString {
        return NSString(data: toJsonData(pretty: pretty), encoding: NSUTF8StringEncoding)!
    }

    public class func fromData(data: NSData!) -> AnyObject? {
        var object:AnyObject? = JsonGenObjectFromJsonData(data)
        switch object {
        case let hash as NSDictionary:
            return fromJsonDictionary(hash)

        case let array as NSArray:
            return fromJsonArray(array)

        default:
            return object
        }
    }

    public class func fromJsonDictionary(hash: NSDictionary?) -> EntityBase? {
        return nil
    }

    public class func fromJsonArray(array: NSArray?) -> [EntityBase]? {
        if array == nil {
            return nil
        }
        var ret = [EntityBase]()
        if let xx = array as? [NSDictionary] {
            for x in xx {
                if let obj = fromJsonDictionary(x) {
                    ret.append(obj)
                } else {
                    return nil
                }
            }
        } else {
            return nil
        }
        return ret
    }

    private class func toJson(obj: NSObject, pretty: Bool = false) -> NSData {
        let options = pretty ? NSJSONWritingOptions.PrettyPrinted : NSJSONWritingOptions.allZeros
        return NSJSONSerialization.dataWithJSONObject(obj, options: options, error: nil)!
    }
}

