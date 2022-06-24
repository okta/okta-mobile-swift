//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

/// Errors that may occur in the process of managing credentials.
public enum CredentialError: Error {
    /// Thrown when a credential no longer has a weak reference to the coordinator that was used to create it.
    case missingCoordinator
    
    /// Thrown when a Credential is initialized with a ``Token`` and ``OAuth2Client`` with mismatched client configuration.
    case incorrectClientConfiguration
    
    /// Thrown when the metadata associated with a token has become inconsistent.
    case metadataConsistency
}

extension CredentialError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingCoordinator:
            return NSLocalizedString("credential_missing_coordinator",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")
            
        case .incorrectClientConfiguration:
            return  NSLocalizedString("credential_incorrect_configuration",
                                      tableName: "AuthFoundation",
                                      bundle: .authFoundation,
                                      comment: "")
            
        case .metadataConsistency:
            return NSLocalizedString("credential_metadata_consistency",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")
        }
    }
}
