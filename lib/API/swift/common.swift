import Foundation

private func try<T>(x: T?, handler: (T) -> Void) {
    if let xx = x {
        handler(xx)
    }
}

private func try<T>(x: T?, handler: (T) -> Any?) -> Any? {
    if let xx = x {
        return handler(xx)
    }
    return nil
}


public enum MyAPIBodyFormat {
    case JSON, FormURLEncoded
}

// APIの実行時の挙動を操作するためのもの
public protocol MyAPIConfigProtocol {
    var baseURL: NSURL { get }
    var bodyFormat: MyAPIBodyFormat { get }
    var userAgent: String? { get }
    var queue: dispatch_queue_t { get }

    func configureRequest(apiRequest: MyAPIRequest)
    func beforeRequest(apiRequest: MyAPIRequest)
    func afterResponse(apiResponse: MyAPIResponse)
    func log(str: String?)
}

public class MyAPIConfig : MyAPIConfigProtocol {
    public let baseURL: NSURL
    public let bodyFormat: MyAPIBodyFormat
    public let queue: dispatch_queue_t
    public var userAgent: String?

    public init(baseURL: NSURL, bodyFormat: MyAPIBodyFormat? = nil, queue: NSOperationQueue? = nil) {
        self.baseURL = baseURL
        self.bodyFormat = bodyFormat ?? .JSON
        self.queue = queue ?? dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    }

    public func log(str: String?) {
        NSLog("\(str)")
    }

    public func configureRequest(apiRequest: MyAPIRequest) {
        apiRequest.request.setValue("gzip;q=1.0,compress;q=0.5", forHTTPHeaderField: "Accept-Encoding")
        try(userAgent) { ua in apiRequest.request.setValue(ua, forHTTPHeaderField: "User-Agent") }
    }

    public func beforeRequest(apiRequest: MyAPIRequest) {
        let method = apiRequest.info.method
        if method == .POST || method == .PUT || method == .PATCH {
            switch bodyFormat {
            case .FormURLEncoded:
                apiRequest.request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            case .JSON:
                apiRequest.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
    }
    public func afterResponse(apiResponse: MyAPIResponse) {}
}

public class MyAPIFactory {
    public let config: MyAPIConfigProtocol

    public init(config: MyAPIConfigProtocol) {
        self.config = config
    }

    // ADD Custom
    public func createMyAPIItem() -> MyAPIItem {
        return MyAPIItem(config: config)
    }
}

public protocol MyAPIEntityProtocol {
    func toJsonDictionary() -> NSDictionary
    func toJsonData() -> NSData
    func toJsonString() -> NSString

    class func fromData(data: NSData!) -> MyAPIEntityProtocol?
    class func fromJsonDictionary(hash: NSDictionary?) -> MyAPIEntityProtocol?
}

// API定義から作られる静的な情報、を動的に参照するためのもの
public class MyAPIInfo {
    public enum HTTPMethod : String {
        case GET    = "GET"
        case POST   = "POST"
        case PUT    = "PUT"
        case PATCH  = "PATCH"
        case DELETE = "DELETE"
    }

    public let method: HTTPMethod
    public let path: String
    public let meta : [String:String]

    public init(method: HTTPMethod, path: String, meta: [String:String]) {
        self.method = method
        self.path = path
        self.meta = meta
    }
}

public class MyAPIRequest {
    public let request = NSMutableURLRequest()
    public let info : MyAPIInfo

    public init(info: MyAPIInfo) {
        self.info = info
    }
}

public class MyAPIResponse {
    public let response: NSHTTPURLResponse?
    public let error: NSError?
    public let request: MyAPIRequest
    public let data: NSData?

    public init(request: MyAPIRequest, response: NSHTTPURLResponse?, data: NSData?, error: NSError?) {
        self.request = request
        self.response = response
        self.data = data
        self.error = error
    }
}

public class MyAPIBase {
    public typealias CompletionHandler = (MyAPIResponse) -> Void

    public var config: MyAPIConfigProtocol
    public let apiRequest : MyAPIRequest
    public var handlerQueue: dispatch_queue_t?
    public var query = [String:AnyObject]()
    public var body: NSData?

    public init(config: MyAPIConfigProtocol, info: MyAPIInfo) {
        self.config = config
        self.apiRequest = MyAPIRequest(info: info)
    }

    func setBody(object: JsonGenEntityBase) {
        // set body if needed
        let method = apiRequest.info.method
        if method == .POST || method == .PUT || method == .PATCH {
            switch(config.bodyFormat) {
            case .FormURLEncoded:
                let str = URLUtil.makeQueryString(object.toJsonDictionary() as [String:AnyObject])
                self.body = str.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)

            case .JSON:
                self.body = object.toJsonData()
            }
            apiRequest.request.HTTPBody = body
        }
    }

    func doRequest(object: JsonGenEntityBase, completionHandler: CompletionHandler) {
        setBody(object)
        doRequest(completionHandler)
    }

    func doRequest(completionHandler: CompletionHandler) {
        config.configureRequest(apiRequest)

        // Add Encoded Query String
        let urlComponents = NSURLComponents(URL: apiRequest.request.URL!, resolvingAgainstBaseURL: true)!
        let qs = URLUtil.makeQueryString(query)
        if !qs.isEmpty {
            urlComponents.percentEncodedQuery = (urlComponents.percentEncodedQuery != nil ? urlComponents.percentEncodedQuery! + "&" : "") + qs
            apiRequest.request.URL = urlComponents.URL
        }

        config.log("Request URL: \(apiRequest.request.URL?.absoluteString)")

        dispatch_async(config.queue) {
            self.config.beforeRequest(self.apiRequest)
            var response: NSURLResponse?
            var error: NSError?
            var data = NSURLConnection.sendSynchronousRequest(self.apiRequest.request, returningResponse: &response, error: &error)
            var apiResponse = MyAPIResponse(request: self.apiRequest, response: response as? NSHTTPURLResponse, data: data, error: error)
            self.config.afterResponse(apiResponse)
            dispatch_async(self.handlerQueue ?? dispatch_get_main_queue()) { // Thread周りは微妙。どうするといいだろう。
                completionHandler(apiResponse)
            }
        }
    }
}

///////////////////// Begin https://github.com/Alamofire/Alamofire/blob/master/Source/Alamofire.swift
class URLUtil {
    class func makeQueryString(parameters: [String: AnyObject]) -> String {
        var components: [(String, String)] = []
        for key in sorted(Array(parameters.keys), <) {
            let value: AnyObject! = parameters[key]
            components += queryComponents(key, value)
        }

        return join("&", components.map{"\($0)=\($1)"} as [String])
    }

    class func queryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
        var components = [(String, String)]()
        if let dictionary = value as? [String: AnyObject] {
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value)
            }
        } else if let array = value as? [AnyObject] {
            for value in array {
                components += queryComponents("\(key)[]", value)
            }
        } else {
            components.extend([(escape(key), escape("\(value)"))])
        }

        return components
    }

    class func escape(string: String) -> String {
        let legalURLCharactersToBeEscaped: CFStringRef = ":/?&=;+!@#$()',*"
        return CFURLCreateStringByAddingPercentEscapes(nil, string, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue)
    }
}
