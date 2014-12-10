public class TEMPLATE_YOUSEI_DS_PREFIX_<ET:AnyObject> {
    public typealias NotificationHandler = (ET?, NSError?) -> Void

    private var observers = [(AnyObject, NotificationHandler)]()

    let factory: YOUSEI_API_GENERATOR_PREFIX_Factory

    public init(factory: YOUSEI_API_GENERATOR_PREFIX_Factory) {
        self.factory = factory
    }

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
}
