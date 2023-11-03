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

/// Describes the collection of keys associated with an authorization server.
///
/// These can be used to verify tokens and other signed or encrypted content using the keys published by the server.
public struct JWKS: Codable, Equatable, Collection {
    public typealias Index = Int
    public typealias Element = JWK

    private let keys: [JWK]

    public subscript(_ keyId: String) -> JWK? {
        keys.first { $0.id == keyId }
    }
    
    public var startIndex: Index {
        keys.startIndex
    }
    
    public var endIndex: Index {
        keys.endIndex
    }

    public subscript(index: Index) -> Element {
        keys[index]
    }
    
    public func index(after index: Index) -> Index {
        keys.index(after: index)
    }

    public static func == (lhs: JWKS, rhs: JWKS) -> Bool {
        Set(lhs.keys) == Set(rhs.keys)
    }
}
