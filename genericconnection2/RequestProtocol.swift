//
//  RequestProtocol.swift
//  genericconnection2
//
//  Created by Jonn Alves on 22/03/23.
//

import Foundation
import Combine

enum NetworkError: Error {
    case invalidURL
    case invalidServerResponse
}

class APIConstants {
    static let host = "www.amiiboapi.com"
    static let timeout = 60.0
    static var cache: NSURLRequest.CachePolicy { .reloadIgnoringLocalCacheData }
}

protocol RequestProtocol {
    var path: String { get }
    var headers: [String: String] { get }
    var params: [String: Any] { get }
    var urlParams: [String: String?] { get }
    var addAuthorizationToken: Bool { get }
    var requestType: RequestType { get }
}

extension RequestProtocol {
    var host: String { APIConstants.host }
    var addAuthorizationToken: Bool { true }
    var params: [String: Any] { [:] }
    var urlParams: [String: String?] { [:] }
    var headers: [String: String] { [:] }
}

enum RequestType: String {
    case GET
    case POST
}

extension URLRequest {
    mutating func setAuth(token: String = "") {
        setValue(token, forHTTPHeaderField: "Authorization")
    }
    mutating func setDefaultHeaders() {
        setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
}

extension Dictionary where Key == String, Value == String {
    var urlQueryItems: [URLQueryItem] {
        map { URLQueryItem(name: $0, value: $1) }
    }
}
extension Dictionary where Key == String, Value == String? {
    var urlQueryItems: [URLQueryItem] {
        map { URLQueryItem(name: $0, value: $1) }
    }
}
extension Dictionary where Key == String, Value == Any {
    func jsonData() throws -> Data {
        try JSONSerialization.data(withJSONObject: self)
    }
}

extension URLRequest {
    static func standard(
        host: String = APIConstants.host,
        requestType: RequestType, // I can respect this
        path: String,
        authToken: String? = nil,
        params: [String: Any] = [:],
        urlParams: [String: String?] = [:],
        headers: [String: String] = [:]
    ) throws -> URLRequest {
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/\(path)"
        
        if !urlParams.isEmpty {
            if requestType == RequestType.GET {
                components.queryItems = urlParams.urlQueryItems
            }
        }
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = requestType.rawValue
        urlRequest.timeoutInterval = APIConstants.timeout
        urlRequest.cachePolicy = APIConstants.cache
        
        if let authToken = authToken {
            urlRequest.setAuth(token: authToken)
        }
        
        if !headers.isEmpty {
            urlRequest.allHTTPHeaderFields = headers
        }
        urlRequest.setDefaultHeaders()
        
        if !params.isEmpty {
            if requestType == RequestType.POST {
                urlRequest.httpBody = try params.jsonData()
            }
        }
        
        NetworkLogger.log(request: urlRequest)
        return urlRequest
    }
}

extension Data {
    func decodable<T: Decodable>() throws -> T {
        try JSONDecoder().decode(T.self , from: self )
    }
}

extension URLRequest {
    static var authToken: URLRequest {
        get throws {
            try .standard(
                requestType: .POST,
                path: "/v2/oauth2/token",
                params: [
                    "grant_type": "test1",
                    "client_id": "test2",
                    "client_secret": "test2",
                ]
            )
        }
    }
    
    static var amiiboList: URLRequest {
        get throws {
            try .standard(
                requestType: .GET,
                path: "api/amiibo/"
            )
        }
    }
}

extension URLSession {
    func perform(request: URLRequest) async throws -> Data {
        let (data, response) = try await data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidServerResponse
        }
        return data
    }
}

extension URLRequest {
    func perform(urlSession: URLSession = .shared) async throws -> Data {
        let (data, response) = try await urlSession.data(for: self)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidServerResponse
        }
        NetworkLogger.log(response: response, data: data, error: nil)
        return data
    }
}

func requestAccessToken() async throws -> String {
    let data = try await URLRequest.authToken.perform()
    let token: APIToken = try data.decodable()
    return token.bearerAccessToken
}

func requestAmiiboList() async throws -> AmiiboResponse {
    let data = try await URLRequest.amiiboList.perform()
    let token: AmiiboResponse = try data.decodable()
    return token
}

class APIToken: Decodable {
    let bearerAccessToken:String
}

extension AnyPublisher {
    
    init(builder: @escaping (AnySubscriber<Output, Failure>) -> Cancellable?) {
        self.init(
            Deferred<Publishers.HandleEvents<PassthroughSubject<Output, Failure>>> {
                let subject = PassthroughSubject<Output, Failure>()
                var cancellable: Cancellable?
                cancellable = builder(AnySubscriber(subject))
                return subject
                    .handleEvents(
                        receiveCancel: {
                            cancellable?.cancel()
                            cancellable = nil
                        }
                    )
            }
        )
    }
}
