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

extension Dictionary<String, APIRequestArgument> {
    @_documentation(visibility: internal)
    @inlinable
    public mutating func merge(_ additionalParameters: Self?) {
        guard let additionalParameters = additionalParameters
        else {
            return
        }
        
        merge(additionalParameters) { $1 }
    }
    
    @_documentation(visibility: internal)
    @inlinable public var maxAge: TimeInterval? {
        if let value = self["max_age"] as? String {
            return TimeInterval(value)
        }
        
        if let value = self["max_age"] as? Double {
            return TimeInterval(value)
        }
        
        return nil
    }
    
    @_documentation(visibility: internal)
    @inlinable
    public func spaceSeparatedValues(for key: String) -> [String]? {
        if let value = self[key] as? [String] {
            return value
        }
        
        if let value = self[key] as? String {
            return value.whitespaceSeparated
        }
        
        return nil
    }

    @_documentation(visibility: internal)
    @inlinable
    public mutating func removeSpaceSeparatedValues(forKey key: String) -> [String]? {
        if let value = spaceSeparatedValues(for: key) {
            removeValue(forKey: key)
            return value
        }
        
        return nil
    }
}
