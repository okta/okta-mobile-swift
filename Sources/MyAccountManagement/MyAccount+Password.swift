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
    @inlinable public var password: Password {
        get throws {
            try .init(client: client)
        }
    }

    public struct Password {
        @usableFromInline let client: Client
        @usableFromInline
        init(client: Client) {
            self.client = client
        }

        @inlinable
        public func getStatus() async throws -> Components.Schemas.PasswordResponse {
            try await client
                .getPassword()
                .ok
                .body
                .applicationJsonOktaVersion_1_0_0
        }
        
        @inlinable
        public func create(_ password: String) async throws -> Components.Schemas.PasswordResponse {
            try await client
                .createPassword(body: .json(.init(profile: .init(password: password))))
                .created
                .body
                .applicationJsonOktaVersion_1_0_0
        }
        
        @inlinable
        public func delete() async throws {
            _ = try await client
                .deletePassword()
                .noContent
        }

        @inlinable
        public func update(oldPassword: String, newPassword: String) async throws {
            _ = try await client
                .updatePassword(body: .json(.init(oldPassword: oldPassword, newPassword: newPassword)))
                .noContent
        }
        
        @inlinable
        public func replace(_ password: String) async throws -> Components.Schemas.PasswordResponse {
            try await client
                .replacePassword(body: .json(.init(profile: .init(password: password))))
                .created
                .body
                .applicationJsonOktaVersion_1_0_0
        }
        
        @inlinable
        public func getRequirements() async throws {
            try await client
                .getPasswordRequirements()
                .ok
                .body
                .applicationJsonOktaVersion_1_0_0
        }
    }
}

