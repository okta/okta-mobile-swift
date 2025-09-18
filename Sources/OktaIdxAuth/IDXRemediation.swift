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

#if !COCOAPODS
import CommonSupport
#endif

/// Describes choices the user can make to proceed through the authentication workflow.
public final class Remediation: Sendable, Equatable, Hashable {
    /// The type of this remediation, which is used for keyed subscripting from a `RemediationCollection`.
    public let type: RemediationType
    
    /// The string name for this type.
    public let name: String
    
    /// A description of the form values that this remediation option supports and expects.
    public let form: Form
    
    /// The set of authenticators associated with this remediation.
    public let authenticators: Authenticator.Collection

    public let capabilities: [CapabilityType]
    
    /// Returns the field within this remedation with the given name or key-path.
    ///
    /// To retrieve nested fields, keyPath "." notation can be used to select fields within child forms, for example:
    ///
    ///    response.remediations[.identifier]["credentials.passcode"]
    public subscript(name: String) -> Form.Field? {
        get { form[name] }
    }
    
    /// Collection of messages for all fields within this remedation.
    public var messages: Response.Message.Collection {
        get {
            lock.withLock {
                if let result = _messages {
                    return result
                }

                let result = Response.Message.Collection(nestedMessages: nestedMessages())
                _messages = result
                return result
            }
        }
    }
    
    let method: APIRequestMethod
    let href: URL
    let accepts: APIContentType?
    let refresh: TimeInterval?
    let relatesTo: [String]?

    nonisolated(unsafe) internal private(set) weak var flow: (any InteractionCodeFlowAPI)?
    nonisolated(unsafe) private(set) var _messages: Response.Message.Collection?
    private let lock = Lock()
    internal required init?(flow: any InteractionCodeFlowAPI,
                            name: String,
                            method: APIRequestMethod,
                            href: URL,
                            accepts: APIContentType?,
                            form: Form,
                            refresh: TimeInterval? = nil,
                            relatesTo: [String]? = nil,
                            capabilities: [any Capability],
                            authenticators: [Authenticator] = [])
    {
        self.flow = flow
        self.name = name
        self.type = .init(string: name)
        self.method = method
        self.href = href
        self.accepts = accepts
        self.form = form
        self.refresh = refresh
        self.relatesTo = relatesTo
        self.capabilities = capabilities.compactMap { CapabilityType($0) }
        self.authenticators = Authenticator.Collection(authenticators)
    }
    
    /// Executes the remediation option and proceeds through the workflow using the supplied form parameters.
    ///
    /// This method is used to proceed through the authentication flow, using the data assigned to the nested fields' `value` to make selections.
    /// - Important:
    /// If a completion handler is not provided, you should ensure that you implement the ``InteractionCodeFlowDelegate`` methods to process any response or error returned from this call.
    public func proceed() async throws -> Response {
        guard let flow = flow else {
            throw InteractionCodeFlowError.invalidFlow
        }

        return try await flow.resume(with: self)
    }
    
    @_documentation(visibility: internal)
    public static func == (lhs: Remediation, rhs: Remediation) -> Bool {
        lhs.flow === rhs.flow &&
        lhs.type == rhs.type &&
        lhs.name == rhs.name &&
        lhs.form == rhs.form &&
        lhs.method == rhs.method &&
        lhs.href == rhs.href &&
        lhs.refresh == rhs.refresh &&
        lhs.relatesTo == rhs.relatesTo
    }
    
    @_documentation(visibility: internal)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(name)
        hasher.combine(method)
        hasher.combine(href)
        hasher.combine(accepts)
        hasher.combine(refresh)
        hasher.combine(relatesTo)
        hasher.combine(messages)
    }
}

extension Remediation {
    /// Executes the remediation option and proceeds through the workflow using the supplied form parameters.
    ///
    /// This method is used to proceed through the authentication flow, using the data assigned to the nested fields' `value` to make selections.
    /// - Parameter completion: Completion handler invoked when a ``Response`` is received.
    public func proceed(completion: @escaping @Sendable (Result<Response, any Error>) -> Void)
    {
        Task {
            do {
                completion(.success(try await proceed()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
