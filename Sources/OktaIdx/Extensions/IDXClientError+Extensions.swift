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

// swiftlint:disable cyclomatic_complexity
extension InteractionCodeFlowError: Equatable {
    public static func == (lhs: InteractionCodeFlowError,
                           rhs: InteractionCodeFlowError) -> Bool
    {
        switch (lhs, rhs) {
        case (.invalidFlow, .invalidFlow): return true
        case (.authenticationIncomplete, .authenticationIncomplete): return true
        case (.invalidParameter(name: let lhsName), .invalidParameter(name: let rhsName)):
            return lhsName == rhsName
        case (.missingRequiredParameter(name: let lhsName), .missingRequiredParameter(name: let rhsName)):
            return lhsName == rhsName
        case (.missingRemediation(name: let lhsName), .missingRemediation(name: let rhsName)):
            return lhsName == rhsName
        case (.responseValidationFailed(let lhsMessage), .responseValidationFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

extension InteractionCodeFlowError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidFlow:
            return NSLocalizedString("invalid_flow",
                                     tableName: "OktaIdx",
                                     bundle: .oktaIdx,
                                     comment: "Invalid flow")

        case .authenticationIncomplete:
            return NSLocalizedString("authentication_incomplete",
                                     tableName: "OktaIdx",
                                     bundle: .oktaIdx,
                                     comment: "Invalid flow")

        case .invalidParameter(name: let name):
            return String.localizedStringWithFormat(
                NSLocalizedString("invalid_parameter",
                                  tableName: "OktaIdx",
                                  bundle: .oktaIdx,
                                  comment: ""),
                name)

        case .missingRequiredParameter(name: let name):
            return String.localizedStringWithFormat(
                NSLocalizedString("missing_required_parameter",
                                  tableName: "OktaIdx",
                                  bundle: .oktaIdx,
                                  comment: ""),
                name)

        case .missingRemediation(name: let name):
            return String.localizedStringWithFormat(
                NSLocalizedString("missing_remediation",
                                  tableName: "OktaIdx",
                                  bundle: .oktaIdx,
                                  comment: ""),
                name)

        case .responseValidationFailed(let message):
            return String.localizedStringWithFormat(
                NSLocalizedString("response_validation_failed",
                                  tableName: "OktaIdx",
                                  bundle: .oktaIdx,
                                  comment: ""),
                message)
        }
    }
}
// swiftlint:enable cyclomatic_complexity
