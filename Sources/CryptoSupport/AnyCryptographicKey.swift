//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

public struct AnyCryptographicKey: Crypto.KeyConvertible {
    private let wrappedValue: any Crypto.KeyConvertible
    private let dataRepresentation: Data
    
    /// The raw byte representation of the wrapped key.
    public var rawValue: Data {
        dataRepresentation
    }

    /// Creates a wrapper around a concrete cryptographic key.
    public init(_ wrappedValue: any Crypto.KeyConvertible) throws {
        self.wrappedValue = wrappedValue
        self.dataRepresentation = try wrappedValue.convert(to: Data.self)
    }

    public func convert<T>(to type: T.Type) throws -> T {
        try wrappedValue.convert(to: type)
    }
    
    public init?(rawValue: Data) {
        guard let key = rawValue as? any Crypto.KeyConvertible
        else {
            return nil
        }
        
        self.wrappedValue = key
        self.dataRepresentation = rawValue
    }
}

extension AnyCryptographicKey: Hashable {
    public static func == (lhs: AnyCryptographicKey, rhs: AnyCryptographicKey) -> Bool {
        lhs.dataRepresentation == rhs.dataRepresentation
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(dataRepresentation)
    }
}

