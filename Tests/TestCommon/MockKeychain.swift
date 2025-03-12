//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || os(visionOS)

import Foundation
@testable import AuthFoundation

final class MockKeychain: @unchecked Sendable, KeychainProtocol {
    private var results = [CFTypeRef?]()
    private var statuses = [OSStatus]()
    private(set) var operations = [Operation]()
    
    enum Action {
        case delete, add, update, copy
    }
    
    struct Operation: Equatable {
        let action: Action
        let query: NSDictionary
        let attributes: NSDictionary?
    }
    
    func expect(_ result: Dictionary<String,Any?>) {
        var data: [String:Any?] = [
            "tomb": 0,
            "svce": "Generic",
            "musr": nil,
            "class": "genp",
            "sync": 0,
            "cdat": Date(),
            "mdat": Date(),
            "pdmn": "ak",
            "agrp": "com.okta.sample.app",
            "sha": "someshadata".data(using: .utf8),
            "UUID": UUID().uuidString
        ]
        data.merge(result) { lhs, rhs in
            rhs
        }
        expect(noErr, result: data as CFDictionary)
    }
    
    func expect(_ status: OSStatus, result: CFTypeRef? = nil) {
        statuses.append(status)
        results.append(result)
    }
    
    func reset() {
        results.removeAll()
        statuses.removeAll()
        operations.removeAll()
    }
    
    private func nextStatus(_ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        let status = statuses.first ?? errSecUnimplemented
        if !statuses.isEmpty {
            statuses.remove(at: 0)
        }
        
        if !results.isEmpty {
            let resultResponse = results[0]

            results.remove(at: 0)
            
            if let result = result {
                result.initialize(to: resultResponse)
            }
        }

        return status
    }
    
    func deleteItem(_ query: CFDictionary) -> OSStatus {
        operations.append(Operation(action: .delete, query: query, attributes: nil))
        return nextStatus(nil)
    }
    
    func addItem(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        operations.append(Operation(action: .add, query: query, attributes: nil))
        return nextStatus(result)
    }
    
    func updateItem(_ query: CFDictionary, _ attributes: CFDictionary) -> OSStatus {
        operations.append(Operation(action: .update, query: query, attributes: attributes))
        return nextStatus(nil)
    }
    
    func copyItemMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        operations.append(Operation(action: .copy, query: query, attributes: nil))
        return nextStatus(result)
    }
}

#endif
