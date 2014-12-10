public class TEMPLATE_YOUSEI_DS_PREFIX_<ET:AnyObject> {
    public typealias NotificationHandler = (ET?, NSError?) -> Void

    let factory: YOUSEI_API_GENERATOR_PREFIX_Factory
    public init(factory: YOUSEI_API_GENERATOR_PREFIX_Factory) {
        self.factory = factory
    }

    private var observers = [(AnyObject, NotificationHandler)]()
    public func addObserver(object: AnyObject, handler: NotificationHandler) {
        observers.append((object, handler))
    }

    public func removeObserver(object: AnyObject) {
        observers = observers.filter { $0.0 !== object}
    }

    public func notify(data: ET?, error: NSError?) {
        for observer in observers {
            observer.1(data, error)
        }
    }

    private var cache = [String:ET]()
    public var enableCache = true

    private func findInCache(key: String) -> ET? {
        var ret: ET?
        ret = self.cache[key]
        return ret
    }

    private func storeInCache(key:String, object: ET?) {
        if let o = object {
            if enableCache {
                self.cache[key] = o
            }
        } else {
            self.cache.removeValueForKey(key)
        }
    }

    public func clearCache() {
        self.cache.removeAll(keepCapacity: false)
    }
}
