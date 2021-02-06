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
    
    /// The upstream client to communicate critical events to
    var client: IDXClientAPI? { get set }
    
    var interactionHandle: String? { get set }
    var codeVerifier: String? { get set }
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

internal extension IDXClient.Remediation.Option {
    func formValues(using parameters: IDXClient.Remediation.Parameters) throws -> [String:Any] {
        return try form.reduce(into: [:]) { (result, formValue) in
            guard let nestedResult = try formValue.formValues(using: parameters, in: self) else {
                return
            }
            
            if let nestedObject = nestedResult as? [String:Any] {
                result.merge(nestedObject, uniquingKeysWith: { (old, new) in
                    return new
                })
            } else if let name = formValue.name {
                result[name] = nestedResult
            } else {
                throw IDXClientError.invalidRequestData
            }
        }
    }
}

internal extension IDXClient.Remediation.FormValue {
    func formValues(using parameters: IDXClient.Remediation.Parameters, in remediationOption: IDXClient.Remediation.Option) throws -> Any? {
        // Unnamed FormValues, which may contain nested options
        guard let name = name else {
            if let form = form {
                let result: [String:Any] = try form.reduce(into: [:]) { (result, formValue) in
                    let nestedObject = try formValue.formValues(using: parameters, in: remediationOption)
                    
                    if let name = formValue.name {
                        result[name] = nestedObject
                    } else if let nestedObject = nestedObject as? [String:Any] {
                        result.merge(nestedObject, uniquingKeysWith: { (old, new) in
                            return new
                        })
                    } else {
                        throw IDXClientError.invalidParameter(name: formValue.name ?? "")
                    }
                }
                return result
            } else {
                return nil
            }
        }
        
        if !mutable && parameters[self] != nil {
            throw IDXClientError.parameterImmutable(name: name)
        }
        
        var result: Any? = nil
        // Named FormValues with nested forms
        if let form = form {
            let childValues: [String:Any] = try form.reduce(into: [:]) { (result, formValue) in
                guard let nestedResult = try formValue.formValues(using: parameters,
                                                                  in: remediationOption) else
                {
                    return
                }
                
                if let name = formValue.name {
                    result[name] = nestedResult
                } else if let nestedObject = nestedResult as? [String:Any] {
                    result.merge(nestedObject, uniquingKeysWith: { (old, new) in
                        return new
                    })
                } else {
                    throw IDXClientError.invalidRequestData
                }
            }
            result = [name: childValues]
        }
        
        // Named form values that consist of multiple child options
        else if let _ = options,
                let selectedOption = parameters[self] as? IDXClient.Remediation.FormValue
        {
            let nestedResult = try selectedOption.formValues(using: parameters, in: remediationOption)
            result = [name: nestedResult]
        }
        
        // Other..
        else {
            // lots 'o stuff here
            result = parameters[self] ?? value
        }
        
        if required && result == nil {
            throw IDXClientError.missingRequiredParameter(name: name)
        }
        return result
    }
}
