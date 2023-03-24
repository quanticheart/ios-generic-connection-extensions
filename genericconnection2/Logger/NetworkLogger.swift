//
//  NetworkLogger.swift
//  conection-generic
//
//  Created by Jonn Alves on 13/03/23.
//

import Foundation

class NetworkLogger {
    static func log(request: URLRequest) {
#if DEBUG
        print("\n - - - - - - - - - - Request - - - - - - - - - - \n")
        defer { print("\n - - - - - - - - - -  END - - - - - - - - - - \n") }
        let urlAsString = request.url?.absoluteString ?? ""
        let urlComponents = URLComponents(string: urlAsString)
        let method = request.httpMethod != nil ? "\(request.httpMethod ?? "")" : ""
        let path = "\(urlComponents?.path ?? "")"
        let query = "\(urlComponents?.query ?? "")"
        let host = "\(urlComponents?.host ?? "")"
        var output = """
       \(urlAsString) \n\n
       \(method) \(path)?\(query) HTTP/1.1 \n
       HOST: \(host)\n
       """
        output += "Headers: \n\n"
        for (key,value) in request.allHTTPHeaderFields ?? [:] {
            output += "\(key): \(value) \n"
        }
        if let body = request.httpBody {
            output += "\n \(String(data: body, encoding: .utf8) ?? "")"
        }
        print(output)
#endif
    }
    
    static func log(response: URLResponse?, data: Data?, error: Error?) {
#if DEBUG
        print("\n - - - - - - - - - - Response - - - - - - - - - - \n")
        defer { print("\n - - - - - - - - - -  END - - - - - - - - - - \n") }
        let urlString = response?.url?.absoluteString
        let components = NSURLComponents(string: urlString ?? "")
        let path = "\(components?.path ?? "")"
        let query = "\(components?.query ?? "")"
        var output = ""
        if let urlString = urlString {
            output += "\(urlString)"
            output += "\n\n"
        }
        
        if response is HTTPURLResponse {
            if let statusCode =  (response as? HTTPURLResponse)?.statusCode {
                output += "HTTP \(statusCode) \(path)?\(query)\n"
                for (key, value) in (response as? HTTPURLResponse)?.allHeaderFields ?? [:] {
                    output += "\(key): \(value)\n"
                }
            }
        }
        
        if let host = components?.host {
            output += "Host: \(host)\n"
        }
        
        if let body = data {
            output += "\n\(String(data: body, encoding: .utf8) ?? "")\n"
        }
        if error != nil {
            output += "\nError: \(error!.localizedDescription)\n"
        }
        print(output)
#endif
    }
}
