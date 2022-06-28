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
extension IDXAuthenticationFlowError: Equatable {
    public static func == (lhs: IDXAuthenticationFlowError,
                           rhs: IDXAuthenticationFlowError) -> Bool
    {
        switch (lhs, rhs) {
        case (.invalidFlow, .invalidFlow): return true
        case (.cannotCreateRequest, .cannotCreateRequest): return true
        case (.invalidHTTPResponse, .invalidHTTPResponse): return true
        case (.invalidResponseData, .invalidResponseData): return true
        case (.invalidRequestData, .invalidRequestData): return true
        case (.serverError(message: let lhsMessage, localizationKey: let lhsLocalizationKey, type: let lhsType),
              .serverError(message: let rhsMessage, localizationKey: let rhsLocalizationKey, type: let rhsType)):
            return (lhsMessage == rhsMessage && lhsLocalizationKey == rhsLocalizationKey && lhsType == rhsType)
        case (.invalidParameter(name: let lhsName), .invalidParameter(name: let rhsName)):
            return lhsName == rhsName
        case (.invalidParameterValue(name: let lhsName), .invalidParameterValue(name: let rhsName)):
            return lhsName == rhsName
        case (.parameterImmutable(name: let lhsName), .parameterImmutable(name: let rhsName)):
            return lhsName == rhsName
        case (.missingRequiredParameter(name: let lhsName), .missingRequiredParameter(name: let rhsName)):
            return lhsName == rhsName
        case (.unknownRemediationOption(name: let lhsName), .unknownRemediationOption(name: let rhsName)):
            return lhsName == rhsName
        case (.successResponseMissing, .successResponseMissing): return true
        case (.missingRefreshToken, .missingRefreshToken): return true
        default:
            return false
        }
    }
}

extension IDXAuthenticationFlowError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidFlow:
            return NSLocalizedString("IDXAuthenticationFlow instance is invalid.",
                                     comment: "Error message thrown when an IDXAuthenticationFlow object is missing or becomes invalid.")
        case .cannotCreateRequest:
            return NSLocalizedString("Could not create a URL request for this action.",
                                     comment: "Error message thrown when an error occurs while creating a URL request.")
        case .invalidHTTPResponse:
            return NSLocalizedString("Response received from a URL request is invalid.",
                                     comment: "Error message thrown when a network response has an invalid type or status code.")
        case .invalidResponseData:
            return NSLocalizedString("Response data is invalid or could not be parsed.",
                                     comment: "Error message thrown when response data is invalid.")
        case .invalidRequestData:
            return NSLocalizedString("Request data is invalid or could not be parsed.",
                                     comment: "Error message thrown when request data is invalid.")
        case .serverError(message: let message, localizationKey: let localizationKey, type: _):
            let result = NSLocalizedString(localizationKey, comment: "Error message thrown from the server.")
            guard result != localizationKey else {
                return message
            }
            return result
        case .internalMessage(let message):
            return message
        case .internalError(let error):
            return error.localizedDescription
        case .invalidParameter(name: let name):
            return NSLocalizedString("Invalid parameter \"\(name)\" supplied to a remediation option.",
                                     comment: "Error message thrown when an invalid parameter is supplied.")
        case .invalidParameterValue(name: let name, type: let type):
            return NSLocalizedString("Parameter \"\(name)\" was supplied a \(type) value which is unsupported.",
                                     comment: "Error message thrown when an invalid parameter value is supplied.")
        case .parameterImmutable(name: let name):
            return NSLocalizedString("Cannot override immutable remediation parameter \"\(name)\".",
                                     comment: "Error message thrown when a value is passed to an immutable parameter.")
        case .missingRequiredParameter(name: let name):
            return NSLocalizedString("Required parameter \"\(name)\" missing.",
                                     comment: "Error message thrown when a required value is missing.")
        case .unknownRemediationOption(name: let name):
            return NSLocalizedString("Unknown remediation option \"\(name)\".",
                                     comment: "Error message thrown when a remediation option is invoked that doesn't exist.")
        case .successResponseMissing:
            return NSLocalizedString("Success response is missing or unavailable.",
                                     comment: "Error message thrown when a success response is not yet ready.")
        case .missingRefreshToken:
            return NSLocalizedString("Cannot perform a refresh when no refresh token is available.",
                                     comment: "Cannot perform a refresh when no refresh token is available.")
        case .missingRelatedObject:
            return NSLocalizedString("Could not find an object within the response related from another object.",
                                     comment: "Cannot find a related object in the response.")
        case .missingRemediationOption(name: let name):
            return NSLocalizedString("The remediation option \"\(name)\" was expected, but not found..",
                                     comment: "Cannot find a required remediation option.")
        case .oauthError(summary: let summary, code: let code, errorId: _):
            return NSLocalizedString("\(summary). Error code \(code ?? "unknown").",
                                     comment: "OAuth error reported from the server.")
        case .invalidContext:
            return NSLocalizedString("The Context for this flow is missing or is invalid.",
                                     comment: "Error message thrown when an IDXAuthenticationFlow does not contain a Context.")

        case .platformUnsupported:
            return NSLocalizedString("The current platform is not yet supported.",
                                     comment: "")

        case .invalidUrl:
            return NSLocalizedString("The supplied URL is invalid.",
                                     comment: "")

        case .apiError(let error):
            return error.localizedDescription
        }
    }
}
// swiftlint:enable cyclomatic_complexity
