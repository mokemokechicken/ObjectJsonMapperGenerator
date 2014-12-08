//
//  api.swift
//  APISample
//
//  Created by 森下 健 on 2014/12/07.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import Foundation

public class MyAPIItem : MyAPIBase {
    public init(config: MyAPIConfigProtocol) {
        var meta = [String:String]()
        let apiInfo = MyAPIInfo(method: .GET, path: "items", meta: meta)
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

    func call(params: Params, completionHandler: ((MyAPIResponse, [Item]?) -> Void)) {
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

public class MyAPISomePost : MyAPIBase {
    public init(config: MyAPIConfigProtocol) {
        var meta = [String:String]()
        let apiInfo = MyAPIInfo(method: .POST, path: "some_post", meta: meta)
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

    func call(params: Params, object: User, completionHandler: ((MyAPIResponse, [Item]?) -> Void)) {
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

