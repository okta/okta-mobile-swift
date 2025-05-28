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
import AuthFoundation

extension Authenticator {
    /// Container that represents a collection of authenticators, providing conveniences for quickly accessing relevant objects.
    public final class Collection: Sendable, Equatable, Hashable {
        /// The current authenticator, if one is actively being enrolled or authenticated.
        public var current: Authenticator? {
            allAuthenticators.first { $0.state == .authenticating || $0.state == .enrolling }
        }
        
        /// The array of currently-enrolled authenticators.
        public var enrolled: [Authenticator] {
            allAuthenticators.filter { $0.state == .enrolled }
        }
        
        /// Access authenticators based on their type.
        public subscript(type: Authenticator.Kind) -> Authenticator? {
            allAuthenticators.first(where: { $0.type == type })
        }

        @_documentation(visibility: internal)
        public static func == (lhs: Collection, rhs: Collection) -> Bool {
            lhs.authenticators == rhs.authenticators &&
            lhs.relatedAuthenticators == rhs.relatedAuthenticators
        }

        @_documentation(visibility: internal)
        public func hash(into hasher: inout Hasher) {
            hasher.combine(authenticators)
            hasher.combine(relatedAuthenticators)
        }

        var allAuthenticators: [Authenticator] {
            var result = authenticators
            if let relatedAuthenticators {
                result.append(contentsOf: relatedAuthenticators)
            }
            return result
        }

        let authenticators: [Authenticator]
        var relatedAuthenticators: [Authenticator]? {
            get {
                lock.withLock { _relatedAuthenticators?.compactMap(\.wrappedValue) }
            }
            set {
                lock.withLock {
                    _relatedAuthenticators = newValue?.compactMap(Weak.init)
                }
            }
        }

        nonisolated(unsafe) private var _relatedAuthenticators: [Weak<Authenticator>]?
        private let lock = Lock()
        init(_ authenticators: [Authenticator]? = nil, relatedAuthenticators: [Authenticator]? = nil) {
            self.authenticators = authenticators ?? []
            self._relatedAuthenticators = relatedAuthenticators?.compactMap(Weak.init)
        }
    }
}
