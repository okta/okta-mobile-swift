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
    func nestedRelatableObjects() -> [IDXHasRelatedObjects]
}

/// Represents the root of a relatable object tree.
protocol IDXRelatedObjectRoot: IDXContainsRelatableObjects {
    /// Iterates through all nested relatable objects, and asks each one to find and assign their related objects.
    func loadRelatedObjects()
}

/// Indicates this relatable object is one that can directly reference other objects, through jsonPath keys.
protocol IDXHasRelatedObjects: IDXContainsRelatableObjects {
    /// Return the various json key paths that can uniquely represent this object.
    var jsonPaths: [String] { get }
    
    /// Asks this object to find, and assign, objects given the accumulated JSON keypath mapping
    /// - Parameter jsonMapping: JSON key path mapping table, relating JSON keys to their associated objects.
    func findRelatedObjects(using jsonMapping: [String: IDXHasRelatedObjects])
}

extension IDXRelatedObjectRoot {
    func loadRelatedObjects() {
        let nestedObjects = nestedRelatableObjects()
        let jsonMapping: [String: IDXHasRelatedObjects] = nestedObjects
            .reduce(into: [String:IDXHasRelatedObjects]()) { (result, object) in
                for path in object.jsonPaths {
                    result[path] = object
                }
            }
        
        nestedObjects.forEach { (object) in
            object.findRelatedObjects(using: jsonMapping)
        }
    }
}

extension IDXClient.Response: IDXRelatedObjectRoot {
    func nestedRelatableObjects() -> [IDXHasRelatedObjects] {
        return [remediations.nestedRelatableObjects(),
                authenticators.nestedRelatableObjects()].flatMap { $0 }
    }
}

extension IDXClient.AuthenticatorCollection: IDXContainsRelatableObjects {
    func nestedRelatableObjects() -> [IDXHasRelatedObjects] {
        return authenticators.flatMap { $0.nestedRelatableObjects() }
    }
}

extension IDXClient.RemediationCollection: IDXContainsRelatableObjects {
    func nestedRelatableObjects() -> [IDXHasRelatedObjects] {
        return remediations.flatMap { $0.nestedRelatableObjects() }
    }
}

extension IDXClient.Authenticator: IDXHasRelatedObjects {
    func findRelatedObjects(using jsonMapping: [String : IDXHasRelatedObjects]) {
        return
    }
    
    func nestedRelatableObjects() -> [IDXHasRelatedObjects] {
        return [self]
    }
}

extension IDXClient.Remediation: IDXHasRelatedObjects {
    func nestedRelatableObjects() -> [IDXHasRelatedObjects] {
        var result = form.flatMap { $0.nestedRelatableObjects() }
        result.append(self)
        return result
    }

    var jsonPaths: [String] { [] }
    
    func findRelatedObjects(using jsonMapping: [String: IDXHasRelatedObjects]) {
        var authenticatorObjects = relatesTo?.compactMap({ (jsonPath) -> IDXClient.Authenticator? in
            guard let authenticator = jsonMapping[jsonPath] as? IDXClient.Authenticator else { return nil }
            return authenticator
        }) ?? []
        
        // Work-around for 
        if let currentAuthenticator = jsonMapping["$.currentAuthenticator"] as? IDXClient.Authenticator,
           currentAuthenticator.type == .password,
           type == .identify
        {
            authenticatorObjects.append(currentAuthenticator)
        }
        
        guard !authenticatorObjects.isEmpty else { return }
        
        authenticators = IDXClient.WeakAuthenticatorCollection(authenticators: authenticatorObjects)
    }
}

extension IDXClient.Remediation.Form: IDXContainsRelatableObjects {
    func nestedRelatableObjects() -> [IDXHasRelatedObjects] {
        return fields.flatMap { $0.nestedRelatableObjects() }
    }
}

extension IDXClient.Remediation.Form.Field: IDXHasRelatedObjects {
    func nestedRelatableObjects() -> [IDXHasRelatedObjects] {
        var result: [IDXHasRelatedObjects] = [self]
        result.append(contentsOf: form?.nestedRelatableObjects() ?? [])
        result.append(contentsOf: options?.flatMap { $0.nestedRelatableObjects() } ?? [])
        return result
    }

    var jsonPaths: [String] { [] }
    
    func findRelatedObjects(using jsonMapping: [String: IDXHasRelatedObjects]) {
        guard let relatesTo = relatesTo else { return }
        authenticator = jsonMapping[relatesTo] as? IDXClient.Authenticator
    }
}
