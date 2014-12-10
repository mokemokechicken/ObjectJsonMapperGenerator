public class TEMPLATE_YOUSEI_DS_PREFIX_<ET> {
    public typealias NotificationHandler = (ET?, TEMPLATE_YOUSEI_DS_PREFIX_Status?) -> Void
    public var requestedObjectConverter: ET? -> ET? = { $0 }

    let factory: YOUSEI_API_GENERATOR_PREFIX_Factory
    public init(factory: YOUSEI_API_GENERATOR_PREFIX_Factory) {
        self.factory = factory
    }

    private var observers = [(AnyObject, NotificationHandler)]()
    public func addObserver(object: AnyObject, handler: NotificationHandler) {
        factory.config.log("\(self) addObserver \(object)")
        observers.append((object, handler))
    }

    public func removeObserver(object: AnyObject) {
        factory.config.log("\(self) removeObserver \(object)")
        observers = observers.filter { $0.0 !== object}
    }

    private func notify(data: ET?, status: TEMPLATE_YOUSEI_DS_PREFIX_Status) {
        factory.config.log("\(self) notify")
        for observer in observers {
            observer.1(data, status)
        }
    }

    private var cache = [String:Any]()
    public var enableCache = true

    private func findInCache(key: String) -> Any? {
        return self.cache[key]
    }

    private func storeInCache(key:String, object: Any?) {
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

public class TEMPLATE_YOUSEI_DS_PREFIX_Status {
    public let response: YOUSEI_API_GENERATOR_PREFIX_Response

    public init(response: YOUSEI_API_GENERATOR_PREFIX_Response) {
        self.response = response
    }
}

