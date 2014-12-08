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

public class JsonGenEntityBase {
    public init() {
    }

    public func toJsonDictionary() -> NSDictionary {
        return NSDictionary()
    }

    public class func toJsonArray(entityList: [JsonGenEntityBase]) -> NSArray {
        return entityList.map {x in encode(x)}
    }

    public class func toJsonData(entityList: [JsonGenEntityBase], pritty: Bool = false) -> NSData {
        var obj = toJsonArray(entityList)
        return toJson(obj, pritty: pritty)
    }

    public func toJsonData(pritty: Bool = false) -> NSData {
        var obj = toJsonDictionary()
        return JsonGenEntityBase.toJson(obj, pritty: pritty)
    }

    public class func toJsonString(entityList: [JsonGenEntityBase], pritty: Bool = false) -> NSString {
        return NSString(data: toJsonData(entityList, pritty: pritty), encoding: NSUTF8StringEncoding)!
    }

    public func toJsonString(pritty: Bool = false) -> NSString {
        return NSString(data: toJsonData(pritty: pritty), encoding: NSUTF8StringEncoding)!
    }

    public class func fromData(data: NSData!) -> AnyObject? {
        if data == nil {
            return nil
        }

        var object = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.MutableContainers, error: nil) as? NSObject
        switch object {
        case let hash as NSDictionary:
            return fromJsonDictionary(hash)

        case let array as NSArray:
            return fromJsonArray(array)

        default:
            return nil
        }
    }

    public class func fromJsonDictionary(hash: NSDictionary?) -> JsonGenEntityBase? {
        return nil
    }

    public class func fromJsonArray(array: NSArray?) -> [JsonGenEntityBase]? {
        if array == nil {
            return nil
        }
        var ret = [JsonGenEntityBase]()
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

    private class func toJson(obj: NSObject, pritty: Bool = false) -> NSData {
        let options = pritty ? NSJSONWritingOptions.PrettyPrinted : NSJSONWritingOptions.allZeros
        return NSJSONSerialization.dataWithJSONObject(obj, options: options, error: nil)!
    }
}
