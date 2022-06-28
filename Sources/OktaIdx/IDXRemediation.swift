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

/// Describes choices the user can make to proceed through the authentication workflow.
public class Remediation: Equatable, Hashable {
    /// The type of this remediation, which is used for keyed subscripting from a `RemediationCollection`.
    public let type: RemediationType
    
    /// The string name for this type.
    public let name: String
    
    /// A description of the form values that this remediation option supports and expects.
    public let form: Form
    
    /// The set of authenticators associated with this remediation.
    public internal(set) var authenticators: Authenticator.Collection = .init(authenticators: nil)
    
    public let capabilities: [RemediationCapability]
    
    /// Returns the field within this remedation with the given name or key-path.
    ///
    /// To retrieve nested fields, keyPath "." notation can be used to select fields within child forms, for example:
    ///
    ///    response.remediations[.identifier]["credentials.passcode"]
    public subscript(name: String) -> Form.Field? {
        get { form[name] }
    }
    
    /// Collection of messages for all fields within this remedation.
    public lazy var messages: Response.Message.Collection = {
        Response.Message.Collection(messages: nil, nestedMessages: nestedMessages())
    }()
    
    private weak var flow: InteractionCodeFlowAPI?
    
    let method: String
    let href: URL
    let accepts: String?
    let refresh: TimeInterval?
    let relatesTo: [String]?
    
    internal required init?(flow: InteractionCodeFlowAPI,
                            name: String,
                            method: String,
                            href: URL,
                            accepts: String?,
                            form: Form,
                            refresh: TimeInterval? = nil,
                            relatesTo: [String]? = nil,
                            capabilities: [RemediationCapability])
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
        self.capabilities = capabilities
    }
    
    /// Executes the remediation option and proceeds through the workflow using the supplied form parameters.
    ///
    /// This method is used to proceed through the authentication flow, using the data assigned to the nested fields' `value` to make selections.
    /// - Important:
    /// If a completion handler is not provided, you should ensure that you implement the ``InteractionCodeFlowDelegate`` methods to process any response or error returned from this call.
    /// - Parameters:
    ///   - completion: Optional completion handler invoked when a response is received.
    public func proceed(completion: InteractionCodeFlow.ResponseResult? = nil) {
        guard let flow = flow else {
            completion?(.failure(.invalidFlow))
            return
        }
        
        let request: InteractionCodeFlow.RemediationRequest
        do {
            request = try InteractionCodeFlow.RemediationRequest(remediation: self)
        } catch let error as InteractionCodeFlowError {
            flow.send(error: error, completion: completion)
            return
        } catch let error as APIClientError {
            flow.send(error: .apiError(error), completion: completion)
            return
        } catch {
            flow.send(error: .internalError(error), completion: completion)
            return
        }

        request.send(to: flow.client) { result in
            switch result {
            case .failure(let error):
                flow.send(error: .apiError(error), completion: completion)
            case .success(let response):
                do {
                    flow.send(response: try Response(flow: flow,
                                                     ion: response.result),
                              completion: completion)
                } catch let error as APIClientError {
                    flow.send(error: .apiError(error), completion: completion)
                    return
                } catch {
                    flow.send(error: .internalError(error), completion: completion)
                    return
                }
            }
        }
    }
    
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

#if swift(>=5.5.1) && !os(Linux)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
extension Remediation {
    /// Executes the remediation option and proceeds through the workflow using the supplied form parameters.
    ///
    /// This method is used to proceed through the authentication flow, using the data assigned to the nested fields' `value` to make selections.
    public func proceed() async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            proceed() { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif
