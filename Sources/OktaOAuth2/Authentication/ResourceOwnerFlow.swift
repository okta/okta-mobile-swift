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

public protocol ResourceOwnerFlowDelegate: AuthenticationDelegate {
//    public typealias Flow = ResourceOwnerFlow.Configuration

}

public class ResourceOwnerFlow: AuthenticationFlow {
    public typealias AuthConfiguration = ResourceOwnerFlow.Configuration
    
    public struct Configuration: AuthenticationConfiguration {
        public let username: String
        public let password: String
        public let domain: String

        public var baseURL: URL { URL(string: "https://\(domain)")! }
    }
    
//    public struct Challenge {
//        public let deviceCode: String
//        public let userCode: String
//        public let expiresAt: Date
//        public let interval: TimeInterval
//        public let verificationUrl: URL
//    }
    
    public let configuration: Configuration
    public weak var delegate: ResourceOwnerFlowDelegate?
    private(set) public var isAuthenticating: Bool = false
    
//    private(set) public var challenge: Challenge?
    private(set) public var waitingForAuthorization: Bool = false
    
    public convenience init(username: String, password: String, domain: String) {
        self.init(.init(username: username, password: password, domain: domain))
    }
    
    public init(_ configuration: Configuration) {
        self.configuration = configuration
    }
    
    public func start(with: String) throws {
        
    }
    
    public func cancel() {}
    
    public func reset() {
        
    }

    // MARK: Private properties / methods
    private let delegates = DelegateCollection<ResourceOwnerFlowDelegate>()
}

extension ResourceOwnerFlow: UsesDelegateCollection {
    public typealias Delegate = ResourceOwnerFlowDelegate
    public func add(delegate: Delegate) { delegates += delegate }
    public func remove(delegate: Delegate) { delegates -= delegate }

    public var delegateCollection: DelegateCollection<Delegate> {
        delegates
    }
}
