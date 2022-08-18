//
//  NetworkManager.swift
//  Swift Concurrency
//
//  Created by 吴丹 on 2022/8/17.
//

import Foundation
import Alamofire
import Combine

enum NetworkManagerError: LocalizedError {
    case unauthorized
    case noInternetConnection

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Access is denied. User is unauthorized."
        case .noInternetConnection:
            return "Please check your internet connection and try again later."
        }
    }
}

enum NetworkManagerStatusCode: Int {
    //1xx Informationals
    case `continue` = 100
    case switchingProtocols = 101
    //2xx Successfuls
    case ok = 200
    case created = 201
    case accepted = 202
    case nonAuthoritativeInformation = 203
    case noContent = 204
    case resetContent = 205
    case partialContent = 206
    //3xx Redirections
    case multipleChoices = 300
    case movedPermanently = 301
    case found = 302
    case seeOther = 303
    case notModified = 304
    case useProxy = 305
    case unused = 306
    case temporaryRedirect = 307
    //4xx Client Errors
    case badRequest = 400
    case unauthorized = 401
    case paymentRequired = 402
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case notAcceptable = 406
    case proxyAuthenticationRequired = 407
    case requestTimeout = 408
    case conflict = 409
    case gone = 410
    case lengthRequired = 411
    case preconditionFailed = 412
    case requestEntityTooLarge = 413
    case requestURITooLong = 414
    case unsupportedMediaType = 415
    case requestedRangeNotSatisfiable = 416
    case expectationFailed = 417
    //5xx Server Errors
    case internalServerError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    case httpVersionNotSupported = 505
    //10xx Internet Error
    case noInternetConnection = -1009
}


class NetworkManager: Publisher {
    
    static let manager = NetworkManager()
    
    /// It's private for subclassing
    private init() {}
    
    // MARK: Types
    
    /// The response of data type.
    public typealias Output = Data
    public typealias Failure = Error
    
    // MARK: - Properties
    
    /// `Session` creates and manages Alamofire's `Request` types during their lifetimes. It also provides common
    /// functionality for all `Request`s, including queuing, interception, trust management, redirect handling, and response
    /// cache handling.
    private(set) var sessionManager: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 1200.0
        return Alamofire.Session(configuration: configuration)
    }()
    
    /// `HTTPHeaders` value to be added to the `URLRequest`. Set `["Content-Type": "application/json"]` by default..
    private(set) var headers: HTTPHeaders = ["Content-Type": "application/json"]
        
    /// `URLConvertible` value to be used as the `URLRequest`'s `URL`.
    private(set) var url: String?
    
    /// `HTTPMethod` for the `URLRequest`. `.get` by default..
    private(set) var httpMethod: HTTPMethod = .get
    
    /// `Param` (a.k.a. `[String: Any]`) value to be encoded into the `URLRequest`. `nil` by default..
    private(set) var param: [String: Any]?
    
         
    // MARK: - Initializer
    
    /// Set param
    ///
    /// - Parameter sessionManager: `Session` creates and manages Alamofire's `Request` types during their lifetimes.
    /// - Returns: Self
    public func setSessionManager(_ sessionManager: Session) -> Self {
        self.sessionManager = sessionManager
        return self
    }
    
    /// Set param
    ///
    /// - Parameter headers: a dictionary of parameters to apply to a `HTTPHeaders`.
    /// - Returns: Self
    public func setHeaders(_ headers: [String: String]) -> Self {
        for param in headers {
            self.headers[param.key] = param.value
        }
        return self
    }
    
    /// Set url
    ///
    /// - Parameter apiUrl: URL to set for api request
    /// - Returns: Self
    public func setURL(_ url: String) -> Self {
        self.url = url
        return self
    }
    
    /// Set httpMethod
    ///
    /// - Parameter httpMethod: to change as get, post, put, delete etc..
    /// - Returns: Self
    public func setHttpMethod(_ httpMethod: HTTPMethod) -> Self {
        self.httpMethod = httpMethod
        return self
    }
    
    /// Set param
    ///
    /// - Parameter param: a dictionary of parameters to apply to a `URLRequest`.
    /// - Returns: Self
    public func setParameter(_ param: [String:Any]) -> Self {
        self.param = param
        return self
    }
    
    
    /// The parameter encoding. `URLEncoding.default` by default.
    private func encoding(_ httpMethod: HTTPMethod) -> ParameterEncoding {
        var encoding : ParameterEncoding = JSONEncoding.default
        if httpMethod == .get {
            encoding = URLEncoding.default
        }
        return encoding
    }
    
    /// Subscriber for `observer` that can be used to cancel production of sequence elements and free resources.
    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        
        let urlQuery = url!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        /// Creates a `DataRequest` from a `URLRequest`.
        /// Responsible for creating and managing `Request` objects, as well as their underlying `NSURLSession`.
        let request = sessionManager.request(urlQuery,
                                             method: httpMethod,
                                             parameters: param,
                                             encoding: self.encoding(httpMethod),
                                             headers: self.headers)
        subscriber.receive(subscription: Subscription(request: request, target: subscriber))
    }
}

extension NetworkManager {
    // MARK: - Subscription -
    private final class Subscription<Target: Subscriber>: Combine.Subscription where Target.Input == Output, Target.Failure == Failure {
        private var target: Target?
        private let request: DataRequest
        
        init(request: DataRequest, target: Target) {
            self.request = request
            self.target = target
        }
        
        func request(_ demand: Subscribers.Demand) {
            assert(demand > 0)

            guard let target = target else { return }
            
            self.target = nil
    
            request.responseJSON { response in
                if response.response?.statusCode == NetworkManagerStatusCode.unauthorized.rawValue {
                    target.receive(completion: .failure(NetworkManagerError.unauthorized))
                    return
                }
                switch response.result {
                case .success :
                    _ = target.receive(response.data ?? Data())
                    target.receive(completion: .finished)
                case .failure(let error):
                    if error.isSessionTaskError {
                        target.receive(completion: .failure(NetworkManagerError.noInternetConnection))
                    } else {
                        target.receive(completion: .failure(error))
                    }
                }
            }
            .resume()
        }
        
        func cancel() {
            request.cancel()
            target = nil
        }
    }
}
