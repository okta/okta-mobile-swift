//
// Copyright (c) 2025-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

extension OAuth2Error {
    @_documentation(visibility: internal)
    public init(_ error: any Error) {
        if let error = error as? OAuth2Error {
            self = error
        } else if let error = error as? APIClientError {
            self.init(error)
        } else if let error = error as? OAuth2ServerError {
            self = .server(error: error)
        } else {
            self = .error(error)
        }
    }
    
    @_documentation(visibility: internal)
    public init(_ error: APIClientError) {
        switch error {
        case .httpError(let error):
            self.init(error)
        default:
            self = .network(error: error)
        }
    }
}
