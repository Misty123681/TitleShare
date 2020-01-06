// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Alamofire
import Apollo
import Foundation

// Adapts alamofire for use by apollo, adding in extra functionality for our use-case
// Loosely based on https://github.com/graphql-community/ApolloAlamofire
public class AlamofireApolloTransport: NetworkTransport {
    private let _sessionManager: SessionManager
    private let _url: URL
    private let _loggingEnabled: Bool
    private let _unsupportedAppVersion = Watchable<Bool>.Source(value: false)
    private let _userAgent: String
    var authorization: String?

    public init(url: URL, userAgent: String, loggingEnabled: Bool = false) {
        _sessionManager = SessionManager.default
        _url = url
        _userAgent = userAgent
        _loggingEnabled = loggingEnabled
    }

    var unsupportedAppVersion: Watchable<Bool> {
        return _unsupportedAppVersion.watchable
    }

    public func send<Operation>(operation: Operation, completionHandler: @escaping (GraphQLResponse<Operation>?, Error?) -> Void) -> Cancellable where Operation: GraphQLOperation {
        let variables: JSONEncodable = operation.variables?.mapValues { $0?.jsonValue }
        let body: Parameters = [
            "query": operation.queryDocument,
            "variables": variables,
        ]
        var headers: HTTPHeaders = [
            "User-Agent": _userAgent,
        ]
        if let authorization = authorization {
            headers["Authorization"] = authorization
        }
        
        let encoding = PrecomputedJsonEncoding(with: body)
        if _requiresSignature(operation), let bodyBytes = encoding.bodyBytes {
            headers["X-Signature"] = RequestSigner.getRequestSignatureV1(forUrl: _url, method: "POST", headers: headers, body: bodyBytes)
        }
        
        let request = _sessionManager.request(_url, method: .post, parameters: body, encoding: encoding, headers: headers)
        
        if _loggingEnabled {
            debugPrint(request)
        }
        let unsupportedAppVersion = _unsupportedAppVersion
        return request
            .response { [loggingEnabled = _loggingEnabled] response in
                if loggingEnabled {
                    debugPrint(response)
                    if let data = response.data, let decodedData = String(data: data, encoding: .utf8) {
                        debugPrint(decodedData)
                    }
                }
                if let httpResponse = response.response, httpResponse.statusCode == 400, let data = response.data, let decodedData = String(data: data, encoding: .utf8), decodedData.contains("UNSUPPORTED_APP_VERSION") {
                    unsupportedAppVersion.value = true
                }
            }
            .validate(statusCode: [200])
            .responseJSON { response in
                let gqlResult = response.result
                    .flatMap { value -> GraphQLResponse<Operation> in
                        guard let value = value as? JSONObject else {
                            throw response.error!
                        }
                        return GraphQLResponse(operation: operation, body: value)
                    }
                completionHandler(gqlResult.value, gqlResult.error)
            }
            .task!
    }
    
    private func _requiresSignature<Operation>(_ operation: Operation) -> Bool where Operation: GraphQLOperation {
        if operation is SignUpWithCodeMutation || operation is JoinCodeMutation {
            return true
        }
        
        return false
    }
}

/// A JSON encoding which allows access to the encoded bytes before passing it to SessionManager.request
struct PrecomputedJsonEncoding: ParameterEncoding {
    let bodyBytes: Data?
    let error: Error?
    
    init(with parameters: Parameters) {
        do {
            self.bodyBytes = try JSONSerialization.data(withJSONObject: parameters)
            self.error = nil
        } catch {
            self.bodyBytes = nil
            self.error = AFError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
        }
    }
    
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()
        
        if let error = self.error {
            // Throw the error here instead of in the initalizer so it's handled the same as other ParameterEncoding implementations
            throw error
        }
        
        guard let data = self.bodyBytes else { return urlRequest }
        
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        urlRequest.httpBody = data
        return urlRequest
    }
}
