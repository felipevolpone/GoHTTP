//
//  GoHTTP.swift
//
//  Created by http://twitter.com/felipevolpone

import Foundation
import SwiftyJSON

public enum Method:String {
    case POST="POST"
    case GET="GET"
    case PUT="PUT"
}

public enum Encoding {
    case JSON
    case URLFORM
}

public enum RequestError: ErrorType {
    case SyncRequest
}

public class GoHTTP {
    
    var request: NSMutableURLRequest
    
    public func createStringFromDictionary(dict: Dictionary<String,AnyObject>) -> String {
        var params = String()
        for (key, value) in dict {
            params += "&\(key)=\(value)"
        }
        return params
    }
    
    public init(httpMethod: Method=Method.GET, url: String, encoding:Encoding?=Encoding.JSON) {
        
        request = NSMutableURLRequest()
        
        if let finalURL = NSURL(string: url) {
            self.request = NSMutableURLRequest(URL: finalURL)
        }
        else {
            print("GoHTTP warning: failed to create url")
        }
        
        self.request.HTTPMethod = httpMethod.rawValue
        
        if let encode = encoding {
            applyEncoding(encode)
        }
        else {
            print("GoHTTP warning: uncoded request")
        }
        
    }
    
    private func applyEncoding (encoding:Encoding) {
        
        switch encoding {
            
        case Encoding.JSON:
            self.request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
        case Encoding.URLFORM:
            self.request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }
        
    }
    
    public class func get(path:String) -> GoHTTP {
        return GoHTTP(httpMethod: Method.GET, url: path)
    }
    
    @available(iOS, deprecated =  9.0)
    public func getSync() throws -> JSON? {
        let response: AutoreleasingUnsafeMutablePointer<NSURLResponse?>=nil
        var responseData: NSData?
        
        do {
            responseData = try NSURLConnection.sendSynchronousRequest(self.request, returningResponse: response) as NSData?
            
            guard let data = responseData else {return nil}
            
            return JSON(data: data)
            
        } catch {
            throw RequestError.SyncRequest
        }
        
    }
    
    public class func post(path:String) -> GoHTTP {
        return GoHTTP(httpMethod: Method.POST, url: path)
    }
    
    public class func put(path:String) -> GoHTTP {
        return GoHTTP(httpMethod: Method.PUT, url: path)
    }
    
    public func bodyContent(dict: Dictionary<String, AnyObject>) -> GoHTTP {
        let data = self.createStringFromDictionary(dict).dataUsingEncoding(NSUTF8StringEncoding)
        self.request.HTTPBody = data
        
        return self
    }
    
    public func jsonContent(json: JSON) -> GoHTTP {
        let data = (json.description as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        self.request.HTTPBody = data
        
        return self
    }
    
    public func done(callback : (json: JSON?, error:NSError?) -> ()) {
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: nil
            , delegateQueue: NSOperationQueue.mainQueue())
        
        session.dataTaskWithRequest(self.request, completionHandler: { (dt:NSData?, urlResp: NSURLResponse?, err: NSError?) in
            
            if let data = dt {
                callback(json: JSON(data: data), error: err)
            }
            else {
                callback(json: nil, error: err)
            }
            
        }).resume()
    }
    
    public func doneWithBlock(completion: (json: JSON?, error:NSError?) -> ()) -> () {
        
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: nil, delegateQueue: NSOperationQueue.mainQueue())
        
        session.dataTaskWithRequest(self.request, completionHandler: { (dt:NSData?, urlResp: NSURLResponse?, err: NSError?) in
            
            if let data = dt {
                completion(json: JSON(data: data), error: err)
            }
            else {
                completion(json: nil, error: err)
            }
            
        }).resume()
        
    }
    
}