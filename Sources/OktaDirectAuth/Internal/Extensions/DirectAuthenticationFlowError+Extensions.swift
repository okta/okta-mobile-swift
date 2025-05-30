//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension DirectAuthenticationFlowError {
    @usableFromInline
    init(_ error: any Error) {
        if let error = error as? DirectAuthenticationFlowError {
            self = error
        } else if let error = error as? OAuth2Error {
            self = DirectAuthenticationFlowError(error)
        } else if let error = error as? APIClientError {
            self = DirectAuthenticationFlowError(error)
        } else if let error = error as? OAuth2ServerError {
            self = .server(error: error)
        } else {
            self = .other(error: error)
        }
    }

    @usableFromInline
    init(_ error: APIClientError) {
        switch error {
        case .httpError(let error):
            self = DirectAuthenticationFlowError(error)
        default:
            self = .network(error: error)
        }
    }
    
    @usableFromInline
    init(_ error: OAuth2Error) {
        switch error {
        case .network(error: let error):
            self = DirectAuthenticationFlowError(error)
        case .error(let error):
            self = .other(error: error)
        default:
            self = .oauth2(error: error)
        }
    }
}
