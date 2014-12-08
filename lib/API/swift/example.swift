import Foundation

public class Factory {
    public let config: YOUSEI_API_GENERATOR_PREFIX_ConfigProtocol
    
    public init(config: YOUSEI_API_GENERATOR_PREFIX_ConfigProtocol) {
        self.config = config
    }
    
    // ADD Custom
    public func createGetItem() -> GetItem {
        return GetItem(config: config)
    }
}


public class GetItem : YOUSEI_API_GENERATOR_PREFIX_Base {
    public init(config: YOUSEI_API_GENERATOR_PREFIX_ConfigProtocol) {
        var meta = [String:String]()
        let apiInfo = YOUSEI_API_GENERATOR_PREFIX_Info(method: .GET, path: "items", meta: meta)
        super.init(config: config, info: apiInfo)
    }
    
    public class Params {
        public var page: Int?
        public var perPage: Int?
        public var userId: Int?
        
        public init(page: Int? = nil, perPage: Int? = nil, userId: Int? = nil) {
            self.page = page
            self.perPage = perPage
            self.userId = userId
        }
        
        public func toDictionary() -> [String:AnyObject] {
            var ret = [String:AnyObject]()
            if let x = page { ret["page"] = x }
            if let x = perPage { ret["per_page"] = x }
            if let x = userId { ret["user_id"] = x }
            return ret
        }
    }

    func call(params: Params, completionHandler: ((YOUSEI_API_GENERATOR_PREFIX_Response, [Item]?) -> Void)) {
        query = params.toDictionary()
        
        var path = apiRequest.info.path
        // Convert PATH
        if let x:AnyObject = query["user_id"] {
            path.stringByReplacingOccurrencesOfString("{user_id}", withString: URLUtil.escape("\(x)"))
            query.removeValueForKey("user_id")
        }
        apiRequest.request.URL = NSURL(string: path, relativeToURL: config.baseURL)
        
        // Do Request
        doRequest() { response in
            completionHandler(response, Item.fromData(response.data) as? [Item])
        }
    }
}

public class SomePost : YOUSEI_API_GENERATOR_PREFIX_Base {
    public init(config: YOUSEI_API_GENERATOR_PREFIX_ConfigProtocol) {
        var meta = [String:String]()
        let apiInfo = YOUSEI_API_GENERATOR_PREFIX_Info(method: .POST, path: "some_post", meta: meta)
        super.init(config: config, info: apiInfo)
    }
    
    public class Params {
        public var userId: Int
        
        public init(userId: Int) {
            self.userId = userId
        }
        
        public func toDictionary() -> [String:AnyObject] {
            var ret = [String:AnyObject]()
            ret["user_id"] = userId
            return ret
        }
    }
    
    func call(params: Params, object: User, completionHandler: ((YOUSEI_API_GENERATOR_PREFIX_Response, [Item]?) -> Void)) {
        query = params.toDictionary()
        
        var path = apiRequest.info.path
        // Convert PATH
        if let x:AnyObject = query["user_id"] {
            path.stringByReplacingOccurrencesOfString("{user_id}", withString: URLUtil.escape("\(x)"))
            query.removeValueForKey("user_id")
        }
        apiRequest.request.URL = NSURL(string: path, relativeToURL: config.baseURL)
        
        // Do Request
        doRequest(object) { response in
            completionHandler(response, Item.fromData(response.data) as? [Item])
        }
    }
}

