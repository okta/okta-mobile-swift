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

extension MyAccount {
    @inlinable
    public var webAuthn: WebAuthn {
        get throws {
            try .init(client: client)
        }
    }

    public struct WebAuthn {
        @usableFromInline let client: Client
        @usableFromInline
        init(client: Client) {
            self.client = client
        }
        
        // TODO: The OpenAPI spec is incorrect for the list response
        // @inlinable
        // public func list() async throws -> [Components.Schemas.WebAuthn] {
        //     try await client
        //         .listWebAuthn()
        //         .ok
        //         .body
        //         .applicationJsonOktaVersion_1_0_0
        // }
        
        @inlinable
        public func get(enrollmentId: String) async throws -> Components.Schemas.WebAuthn {
            try await client
                .getWebAuthn(path: .init(id: enrollmentId))
                .ok
                .body
                .applicationJsonOktaVersion_1_0_0
        }
        
        @inlinable
        public func delete(enrollmentId: String) async throws {
            _ = try await client
                .deleteWebAuthn(path: .init(id: enrollmentId))
                .noContent
        }
        
        @inlinable
        public func startEnrollment() async throws -> Components.Schemas.WebAuthnRegistrationOptions {
            try await client
                .startWebAuthnEnrollment()
                .ok
                .body
                .applicationJsonOktaVersion_1_0_0
        }
        
        @inlinable
        public func createEnrollment(attestation: String,
                                     clientData: String,
                                     clientExtensions: String? = nil,
                                     transports: String? = nil) async throws -> Components.Schemas.WebAuthn {
            try await client
                .createWebAuthnEnrollment(.init(body: .json(.init(
                    attestation: attestation,
                    clientData: clientData,
                    clientExtensions: clientExtensions,
                    transports: transports))))
                .ok
                .body
                .applicationJsonOktaVersion_1_0_0
        }
    }
}

