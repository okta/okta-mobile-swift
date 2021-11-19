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

extension Capability {
    public struct SocialIDP: RemediationCapability {
        public let id: String
        
        /// The URL an application should load or redirect to in order to continue authentication with the IDP service.
        public let redirectUrl: URL
        
        /// The service for this social authentication remediation.
        public let service: Service
        
        /// The developer-assigned IDP name within the Okta admin dashboard.
        public let idpName: String
        
        /// The list of services that are possible within a social authentication workflow.
        public enum Service {
            /// SAML 2.0
            case saml
            /// Google
            case google
            /// Facebook
            case facebook
            /// LinkedIn
            case linkedin
            /// Microsoft
            case microsoft
            /// OIDC
            case oidc
            /// Okta
            case okta
            /// IWA
            case iwa
            /// AgentlessDSSO
            case agentlessIwa
            /// Certificate based authentication
            case x509
            /// Apple
            case apple
            /// OIN Social IdP Placeholder
            case oinSocial
            /// Other, unknown IDP service
            case other
        }
        
        let idpType: String
        internal private(set) weak var client: IDXClientAPI?
        init(client: IDXClientAPI,
             redirectUrl: URL,
             id: String,
             idpName: String,
             idpType: String,
             service: Service)
        {
            self.client = client
            self.redirectUrl = redirectUrl
            self.id = id
            self.idpName = idpName
            self.idpType = idpType
            self.service = service
        }
    }
}
