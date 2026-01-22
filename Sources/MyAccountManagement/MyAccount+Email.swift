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
    @inlinable public var email: Email {
        get throws {
            try .init(client: client)
        }
    }

    public struct Email {
        @usableFromInline let client: Client
        @usableFromInline
        init(client: Client) {
            self.client = client
        }
        
        public typealias Role = Operations.CreateEmail.Input.Body.JsonPayload.RolePayload
        
        @inlinable
        public func create(
            _ email: String,
            sendEmail: Bool? = nil,
            state: String? = nil,
            role: Role? = nil
        ) async throws -> Components.Schemas.Email {
            try await client
                .createEmail(
                    body: .json(.init(profile: .init(email: email),
                                      sendEmail: sendEmail,
                                      state: state,
                                      role: role)))
                .created
                .body
                .applicationJsonOktaVersion_1_0_0
        }
        
        @inlinable
        public func list() async throws -> [Components.Schemas.Email] {
            try await client
                .listEmails()
                .ok
                .body
                .applicationJsonOktaVersion_1_0_0
        }
        
        @inlinable
        public func get(id: String) async throws -> Components.Schemas.Email {
            try await client
                .getEmail(path: .init(id: id))
                .ok
                .body
                .applicationJsonOktaVersion_1_0_0
        }
        
        @inlinable
        public func delete(id: String) async throws {
            _ = try await client
                .deleteEmail(path: .init(id: id))
                .noContent
        }
        
        @inlinable
        public func verify(id: String,
                           challengeId: String,
                           verificationCode: String) async throws {
            _ = try await client
                .verifyEmailOtp(path: .init(id: id, challengeId: challengeId),
                                body: .json(.init(verificationCode: verificationCode)))
                .ok
        }
        
        @inlinable
        public func sendChallenge(id: String, state: String? = nil) async throws -> Operations.SendEmailChallenge.Output.Created.Body.ApplicationJsonOktaVersion100Payload {
            let body: Operations.SendEmailChallenge.Input.Body?
            if let state {
                body = .json(.init(state: state))
            } else {
                body = nil
            }
            
            return try await client
                .sendEmailChallenge(path: .init(id: id),
                                    body: body)
                .created
                .body
                .applicationJsonOktaVersion_1_0_0
        }
        
//        TODO: Use the APIRequestPollingHandler utility
//        @inlinable
//        public func pollChallengeForMagicLink(id: String,
//                                              challengeId: String) async throws {
//            try await client
//                .pollChallengeForEmailMagicLink(path: .init(id: id, challengeId: challengeId))
//                .ok
//                .body
//                .applicationJsonOktaVersion_1_0_0
//        }
    }
}
