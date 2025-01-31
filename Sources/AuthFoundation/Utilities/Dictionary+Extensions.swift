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

import Foundation

extension Dictionary where Key == String, Value == String {
    @_documentation(visibility: internal)
    @inlinable public var percentQueryEncoded: String {
        var cs = CharacterSet.urlQueryAllowed
        cs.remove("+")

        return compactMap { (key, value) in
            guard let key = key.addingPercentEncoding(withAllowedCharacters: cs),
                  let value = value.addingPercentEncoding(withAllowedCharacters: cs)
            else {
                return nil
            }
            
            return key + "=" + value
        }.sorted().joined(separator: "&")
    }
}

extension Collection {
    @_documentation(visibility: internal)
    @inlinable public var nilIfEmpty: Self? {
        isEmpty ? nil : self
    }
}

extension Sequence where Element: Equatable {
    @_documentation(visibility: internal)
    @inlinable
    public func omitting(_ values: Element...) -> [Element] {
        filter { !values.contains($0) }
    }
}

extension Dictionary {
    @_documentation(visibility: internal)
    @inlinable
    public func omitting(_ keys: Key...) -> Self {
        filter { !keys.contains($0.key) }
    }
}

extension Dictionary where Key: Hashable {
    @_documentation(visibility: internal)
    @inlinable
    public func map(by keyPath: KeyPath<Key, Key>) -> Self {
        var result: Self = [:]
        
        for (key, value) in self {
            result[key[keyPath: keyPath]] = value
        }
        
        return result
    }
    
    @_documentation(visibility: internal)
    @inlinable
    public func value(_ key: Key, or alternatives: Key...) -> Value? {
        if let value = self[key] {
            return value
        }
        
        if let first = alternatives.first(where: self.keys.contains) {
            return self[first]
        }
        
        return nil
    }
}

extension Dictionary where Key == String, Value == (any APIRequestArgument)? {
    @_documentation(visibility: internal)
    @inlinable public var percentQueryEncoded: String {
        compactMapValues { $0?.stringValue }.percentQueryEncoded
    }
}
