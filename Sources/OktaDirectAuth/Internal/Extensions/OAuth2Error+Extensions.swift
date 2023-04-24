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

extension OAuth2Error {
    init(_ error: Error) {
        if let error = error as? OAuth2Error {
            self = error
        } else if let error = error as? APIClientError {
            self = .network(error: error)
        } else if let error = error as? DirectAuthenticationFlowError {
            switch error {
            case .network(error: let error):
                self = OAuth2Error(error)
            case .oauth2(error: let error):
                self = error
            default:
                self = .error(error)
            }
        } else {
            self = .error(error)
        }
    }
}
