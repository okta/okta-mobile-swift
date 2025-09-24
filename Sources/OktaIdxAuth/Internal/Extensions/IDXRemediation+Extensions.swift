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
import AuthFoundation
import JSON

extension Remediation {
    func apiRequest() throws -> InteractionCodeFlow.RemediationRequest {
        // Inform any capabilities associated with this remediation that it will proceed.
        authenticators
            .allAuthenticators
            .compactMap { $0.capabilities }
            .flatMap { $0 }
            .forEach { $0.willProceed(to: self) }

        return try InteractionCodeFlow.RemediationRequest(remediation: self)
    }
}

extension Remediation.Form {
    func formValues() throws -> [String: JSON] {
        return try allFields.reduce(into: [:]) { (result, field) in
            let nestedResult = try field.formValues()
            guard nestedResult.json != .null else {
                return
            }

            if case let .object(nestedObject) = nestedResult.json {
                result.merge(nestedObject, uniquingKeysWith: { (old, new) in
                    return new
                })
            } else if let name = field.name {
                result[name] = nestedResult.json
            } else {
                throw APIClientError.invalidRequestData
            }
        }
    }
}

extension Remediation.Form.Field {
    // swiftlint:disable cyclomatic_complexity
    func formValues() throws -> any JSONRepresentable {
        // Unnamed FormValues, which may contain nested options
        guard let name = name else {
            if let form = self.form,
               !form.allFields.isEmpty
            {
                let result: [String: any JSONRepresentable] = try form.allFields.reduce(into: [:]) { (result, formValue) in
                    let nestedObject = try formValue.formValues()

                    if let name = formValue.name {
                        result[name] = nestedObject
                    } else if case let .object(nestedObject) = nestedObject.json {
                        result.merge(nestedObject, uniquingKeysWith: { (old, new) in
                            return new
                        })
                    } else {
                        throw InteractionCodeFlowError.invalidParameter(name: formValue.name ?? "")
                    }
                }
                return try JSON(result)
            } else {
                return value ?? JSON.null
            }
        }

        var result: any JSONRepresentable = JSON.null
        // Named FormValues with nested forms
        if let form = self.form,
           !form.allFields.isEmpty
        {
            let childValues: [String: any JSONRepresentable] = try form.allFields.reduce(into: [:]) { (result, formValue) in
                let nestedResult = try formValue.formValues()
                guard nestedResult.json != .null else {
                    return
                }

                if let name = formValue.name {
                    result[name] = nestedResult
                } else if let nestedObject = nestedResult as? [String: any JSONRepresentable] {
                    result.merge(nestedObject, uniquingKeysWith: { (old, new) in
                        return new
                    })
                } else {
                    throw APIClientError.invalidRequestData
                }
            }
            result = try JSON([name: childValues])
        }

        // Named form values that consist of multiple child options
        else if let selectedOption = selectedOption {
            if type == "object" {
                let nestedResult = try selectedOption.formValues()
                result = try JSON([name: nestedResult])
            } else {
                result = selectedOption.value ?? JSON.null
            }
        }

        // Other..
        else {
            // lots 'o stuff here
            result = value ?? JSON.null
        }

        if isRequired && result.json == .null {
            throw InteractionCodeFlowError.missingRequiredParameter(name: name)
        }
        
        return result
    }
    // swiftlint:enable cyclomatic_complexity
}
