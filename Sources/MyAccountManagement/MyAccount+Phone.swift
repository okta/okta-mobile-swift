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
    @inlinable public var phone: Phone {
        get throws {
            try .init(client: client)
        }
    }

    public struct Phone {
        @usableFromInline let client: Client
        @usableFromInline
        init(client: Client) {
            self.client = client
        }
        
        public typealias CreateMethod = Operations.CreatePhone.Input.Body.JsonPayload.MethodPayload
        
        public typealias ChallengeMethod = Operations.SendPhoneChallenge.Input.Body.JsonPayload.MethodPayload
        
        @inlinable
        public func create(
            _ phoneNumber: String?,
            sendCode: Bool? = nil,
            method: CreateMethod? = nil
        ) async throws -> Components.Schemas.Phone {
            try await client
                .createPhone(
                    body: .json(.init(profile: .init(phoneNumber: phoneNumber),
                                      sendCode: sendCode,
                                      method: method)))
                .created
                .body
                .applicationJsonOktaVersion_1_0_0
        }
        
        @inlinable
        public func list() async throws -> [Components.Schemas.Phone] {
            try await client
                .listPhones()
                .ok
                .body
                .applicationJsonOktaVersion_1_0_0
        }
        
        @inlinable
        public func get(id: String) async throws -> Components.Schemas.Phone {
            try await client
                .getPhone(path: .init(id: id))
                .ok
                .body
                .applicationJsonOktaVersion_1_0_0
        }
        
        @inlinable
        public func delete(id: String) async throws {
            _ = try await client
                .deletePhone(path: .init(id: id))
                .noContent
        }
        
        @inlinable
        public func verify(id: String,
                           verificationCode: String) async throws {
            _ = try await client
                .verifyPhoneChallenge(path: .init(id: id),
                                      body: .json(.init(verificationCode: verificationCode)))
                .noContent
        }
        
        @inlinable
        public func sendChallenge(id: String, method: ChallengeMethod? = nil, retry: Bool? = nil) async throws {
            let body: Operations.SendPhoneChallenge.Input.Body?
            if let method {
                body = .json(.init(method: method,
                                   retry: retry))
            } else {
                body = nil
            }
            
            _ = try await client
                .sendPhoneChallenge(path: .init(id: id),
                                    body: body)
                .ok
                .body
                .applicationJsonOktaVersion_1_0_0
        }
    }
}

