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
    public func deleteSessions() async throws {
        _ = try await client
            .deleteSessions()
            .noContent
    }
    
    @inlinable
    public var organization: Components.Schemas.Organization {
        get async throws {
            try await client
                .getOrganization()
                .ok
                .body
                .applicationJsonOktaVersion_1_0_0
        }
    }
    
    @inlinable
    public var profile: Components.Schemas.Profile {
        get async throws {
            try await client
                .getProfile()
                .ok
                .body
                .applicationJsonOktaVersion_1_0_0
        }
    }
    
    @inlinable
    public var profileSchema: Components.Schemas.Schema {
        get async throws {
            try await client
                .getProfileSchema()
                .ok
                .body
                .applicationJsonOktaVersion_1_0_0
        }
    }
}

