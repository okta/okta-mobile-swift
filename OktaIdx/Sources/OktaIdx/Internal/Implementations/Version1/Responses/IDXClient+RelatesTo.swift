//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import Foundation

/// Indicates that an object can contain nested objects, some of which may be related to one another.
protocol IDXContainsRelatableObjects {
    /// Return the array of related objects at this level, and below. It is expected to recurse through its children.
    func nestedRelatableObjects() -> [any IDXHasRelatedObjects]
}

/// Represents the root of a relatable object tree.
protocol IDXRelatedObjectRoot: IDXContainsRelatableObjects {
    /// Iterates through all nested relatable objects, and asks each one to find and assign their related objects.
    func loadRelatedObjects() throws
}

/// Indicates this relatable object is one that can directly reference other objects, through jsonPath keys.
protocol IDXHasRelatedObjects: IDXContainsRelatableObjects {
    /// Return the various json key paths that can uniquely represent this object.
    var jsonPaths: [String] { get }
    
    /// Asks this object to find, and assign, objects given the accumulated JSON keypath mapping
    /// - Parameter jsonMapping: JSON key path mapping table, relating JSON keys to their associated objects.
    func findRelatedObjects(using jsonMapping: [String: any IDXHasRelatedObjects]) throws
}

extension IDXRelatedObjectRoot {
    func loadRelatedObjects() throws {
        let nestedObjects = nestedRelatableObjects()
        let jsonMapping: [String: any IDXHasRelatedObjects] = nestedObjects
            .reduce(into: [String: any IDXHasRelatedObjects]()) { (result, object) in
                for path in object.jsonPaths {
                    result[path] = object
                }
            }
        
        try nestedObjects.forEach { (object) in
            try object.findRelatedObjects(using: jsonMapping)
        }
    }
}

extension Response: IDXRelatedObjectRoot {
    func nestedRelatableObjects() -> [any IDXHasRelatedObjects] {
        return [remediations.nestedRelatableObjects(),
                authenticators.nestedRelatableObjects()].flatMap { $0 }
    }
}

extension Authenticator.Collection: IDXContainsRelatableObjects {
    func nestedRelatableObjects() -> [any IDXHasRelatedObjects] {
        return authenticators.flatMap { $0.nestedRelatableObjects() }
    }
}

extension Remediation.Collection: IDXContainsRelatableObjects {
    func nestedRelatableObjects() -> [any IDXHasRelatedObjects] {
        return remediations.flatMap { $0.nestedRelatableObjects() }
    }
}

extension Authenticator: IDXHasRelatedObjects {
    func findRelatedObjects(using jsonMapping: [String: any IDXHasRelatedObjects]) throws {
        return
    }
    
    func nestedRelatableObjects() -> [any IDXHasRelatedObjects] {
        return [self]
    }
}

extension Remediation: IDXHasRelatedObjects {
    func nestedRelatableObjects() -> [any IDXHasRelatedObjects] {
        var result = form.flatMap { $0.nestedRelatableObjects() }
        result.append(self)
        return result
    }

    var jsonPaths: [String] { [] }
    
    func findRelatedObjects(using jsonMapping: [String: any IDXHasRelatedObjects]) throws {
        // Work around defects where some remediations don't
        // properly relate to their corresponding authenticator.
        var calculatedRelatesTo = relatesTo
        switch type {
        case .enrollPoll:
            calculatedRelatesTo = ["$.currentAuthenticator"]
        default: break
        }
        
        var authenticatorObjects = calculatedRelatesTo?.compactMap({ (jsonPath) -> Authenticator? in
            guard let authenticator = jsonMapping[jsonPath] as? Authenticator else { return nil }
            return authenticator
        }) ?? []
        
        guard authenticatorObjects.count == calculatedRelatesTo?.count ?? 0 else {
            #if DEBUG_RELATES_TO
            throw InteractionCodeFlowError.missingRelatedObject
            #else
            return
            #endif
        }
        
        // Work-around for the password authenticator not being associated with the identify remediation.
        if let currentAuthenticator = jsonMapping["$.currentAuthenticator"] as? Authenticator,
           currentAuthenticator.type == .password,
           type == .identify
        {
            authenticatorObjects.append(currentAuthenticator)
        }
        
        guard !authenticatorObjects.isEmpty else { return }
        
        authenticators.relatedAuthenticators = authenticatorObjects
    }
}

extension Remediation.Form: IDXContainsRelatableObjects {
    func nestedRelatableObjects() -> [any IDXHasRelatedObjects] {
        return fields.flatMap { $0.nestedRelatableObjects() }
    }
}

extension Remediation.Form.Field: IDXHasRelatedObjects {
    func nestedRelatableObjects() -> [any IDXHasRelatedObjects] {
        var result: [any IDXHasRelatedObjects] = [self]
        result.append(contentsOf: form?.nestedRelatableObjects() ?? [])
        result.append(contentsOf: options?.flatMap { $0.nestedRelatableObjects() } ?? [])
        return result
    }

    var jsonPaths: [String] { [] }
    
    func findRelatedObjects(using jsonMapping: [String: any IDXHasRelatedObjects]) throws {
        guard let relatesTo = relatesTo else { return }
        guard let mappedAuthenticator = jsonMapping[relatesTo] as? Authenticator else {
            #if DEBUG_RELATES_TO
            throw InteractionCodeFlowError.missingRelatedObject
            #else
            return
            #endif
        }
        authenticator = mappedAuthenticator
    }
}
