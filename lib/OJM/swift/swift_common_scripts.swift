private func _encodeObject(obj: [AnyObject?]) -> [AnyObject] {
    var ary = [AnyObject]()
    for o in obj {
        ary.append(_encodeObject(o))
    }
    return ary
}

private func _encodeObject(obj: AnyObject?) -> AnyObject {
    switch obj {
    case nil:
        return NSNull()

    case let ojmObject as YOUSEI_ENTITY_PREFIX_EntityBase:
        return ojmObject.toJsonDictionary()

    default:
        return obj!
    }
}

func YOUSEI_ENTITY_PREFIX_JsonGenObjectFromJsonData(data: NSData!) -> AnyObject? {
    if data == nil {
        return nil
    }
    return NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.MutableContainers, error: nil)
}


public class YOUSEI_ENTITY_PREFIX_EntityBase {
    public init() {
    }

    public func toJsonDictionary() -> NSDictionary {
        return NSDictionary()
    }

    public class func toJsonArray(entityList: [YOUSEI_ENTITY_PREFIX_EntityBase]) -> NSArray {
        return _encodeObject(entityList)
    }

    public class func toJsonData(entityList: [YOUSEI_ENTITY_PREFIX_EntityBase], pretty: Bool = false) -> NSData {
        var obj = toJsonArray(entityList)
        return toJson(obj, pretty: pretty)
    }

    public func toJsonData(pretty: Bool = false) -> NSData {
        var obj = toJsonDictionary()
        return YOUSEI_ENTITY_PREFIX_EntityBase.toJson(obj, pretty: pretty)
    }

    public class func toJsonString(entityList: [YOUSEI_ENTITY_PREFIX_EntityBase], pretty: Bool = false) -> NSString {
        return NSString(data: toJsonData(entityList, pretty: pretty), encoding: NSUTF8StringEncoding)!
    }

    public func toJsonString(pretty: Bool = false) -> NSString {
        return NSString(data: toJsonData(pretty: pretty), encoding: NSUTF8StringEncoding)!
    }

    public class func fromData(data: NSData!) -> AnyObject? {
        var object:AnyObject? = YOUSEI_ENTITY_PREFIX_JsonGenObjectFromJsonData(data)
        switch object {
        case let hash as NSDictionary:
            return fromJsonDictionary(hash)

        case let array as NSArray:
            return fromJsonArray(array)

        default:
            return object
        }
    }

    public class func fromJsonDictionary(hash: NSDictionary?) -> YOUSEI_ENTITY_PREFIX_EntityBase? {
        return nil
    }

    public class func fromJsonArray(array: NSArray?) -> [YOUSEI_ENTITY_PREFIX_EntityBase]? {
        if array == nil {
            return nil
        }
        var ret = [YOUSEI_ENTITY_PREFIX_EntityBase]()
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

    func encodeObject(obj: [AnyObject?]) -> [AnyObject] {
        return _encodeObject(obj)
    }

    func encodeObject(obj: AnyObject?) -> AnyObject {
        return _encodeObject(obj)
    }


    func decodeOptional(obj: AnyObject?) -> AnyObject? {
        switch obj {
        case let x as NSNull:
            return nil

        default:
            return obj
        }
    }

}
