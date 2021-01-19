//
//  IDXClientAPIImpl.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-11.
//

import Foundation

/// Internal protocol used to implement the IDXClientAPI protocol.
internal protocol IDXClientAPIImpl: class, IDXClientAPI {
    /// The client version for this API implementation.
    static var version: IDXClient.Version { get }
    
    /// The client configuration used when constructing the API implementation.
    var configuration: IDXClient.Configuration { get }
    
    /// The delegate used to coordinate messages to the public-facing client API instance.
    var delegate: IDXClientAPIDelegate? { get set }
}

/// Delegate protocol used to receive messages and updates from IDXClientAPIImpl instances.
internal protocol IDXClientAPIDelegate: class {
    func clientAPIStateHandleChanged(stateHandle: String?)
}

/// Protocol used to represent IDX API requests, and their expected response types.
internal protocol IDXClientAPIRequest {
    associatedtype ResponseType
    /// Produces a URLRequest suitable for performing the request.
    /// - Parameter configuration: Client configuration.
    func urlRequest(using configuration:IDXClient.Configuration) -> URLRequest?
    
    /// Sends the request to the given URL session, returning the response asynchronously to the supplied completion block.
    /// - Parameters:
    ///   - session: URL session to send the network request on.
    ///   - configuration: Client configuration.
    ///   - completion: Completion handler to receive the response.
    func send(to session: URLSessionProtocol,
              using configuration: IDXClient.Configuration,
              completion: @escaping (ResponseType?, Error?) -> Void)
}

internal extension IDXClient {
    class func extractFormValues(from form: [IDXClient.Remediation.FormValue], with params: [String:Any]? = nil) throws -> [String:Any] {
        var result: [String:Any] = try form
            .filter { $0.value != nil && $0.name != nil }
            .reduce(into: [:]) { (result, formValue) in
                guard let name = formValue.name else { throw IDXClientError.invalidParameter(name: "") }
                result[name] = formValue.value
            }
        
        let allFormValues = form.reduce(into: [String:IDXClient.Remediation.FormValue]()) { (result, value) in
            result[value.name] = value
        }
        
        try params?.forEach { (key, value) in
            guard let formValue = allFormValues[key] else {
                throw IDXClientError.invalidParameter(name: key)
            }
            
            guard formValue.mutable == true else {
                throw IDXClientError.parameterImmutable(name: key)
            }
            

            if let nestedForm = value as? IDXClient.Remediation.FormValue {
                result[key] = try nestedForm.formValues()
            } else {
                result[key] = value
            }
        }
        
        try allFormValues.values.filter { $0.required }.forEach {
            /// TODO: Fix compound field support and relatesTo
            guard result[$0.name!] != nil else {
                throw IDXClientError.missingRequiredParameter(name: $0.name!)
            }
        }
        
        return result
    }

}
