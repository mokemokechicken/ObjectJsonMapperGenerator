public class QiitaDataService<ET:AnyObject> {
    public typealias NotificationHandler = (ET?, NSError?) -> Void

    private var observers = [(AnyObject, NotificationHandler)]()
    private var cache = [String:ET]()
    public var enableCache = true

    let factory: QiitaAPIFactory
    
    public init(factory: QiitaAPIFactory) {
        self.factory = factory
    }

    public func addObserver(object: AnyObject, handler: NotificationHandler) {
        observers.append((object, handler))
    }
    
    public func removeObserver(object: AnyObject) {
        observers = observers.filter { $0.0 !== object}
    }
    
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
    
    public func notify(data: ET?, error: NSError?) {
        for observer in observers {
            observer.1(data, error)
        }
    }
}
