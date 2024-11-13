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

import APIClient

extension APIClientError {
    init(_ error: any Error) {
        switch error {
        case let error as APIClientError:
            self = error
        case let error as OAuth2Error:
            self = APIClientError(error)
        default:
            self = .serverError(error)
        }
    }

    init(_ error: OAuth2Error) {
        switch error {
        case .invalidUrl:
            self = .invalidUrl
        case .oauth2Error(_, _, _):
            self = .serverError(error)
        case .network(let error):
            self = error
        case .cannotComposeUrl: fallthrough
        case .missingToken(_): fallthrough
        case .missingClientConfiguration: fallthrough
        case .signatureInvalid: fallthrough
        case .missingLocationHeader: fallthrough
        case .missingOAuth2ResponseKey(_): fallthrough
        case .missingOpenIdConfiguration(_): fallthrough
        case .missingRevokableToken(_):
            self = .validation(error: error)
        case .error(let error):
            switch error {
            case let error as APIClientError:
                self = error
            case let error as OAuth2Error:
                self = APIClientError(error)
            default:
                self = .serverError(error)
            }
        case .revoke(errors: let errors):
            if errors.count == 1,
               let error = errors.first?.value
            {
                self = APIClientError(error)
            } else {
                self = .serverError(error)
            }
        }
    }
}
