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

#if !COCOAPODS
import JSON
#endif

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
    var formValue: JSON {
        get throws {
            var json = JSON([:])
            for field in allFields {
                guard let value = try field.formValue
                else {
                    continue
                }
                
                json.value += value
            }
            return json
        }
    }
}

extension Remediation.Form.Field {
    // swiftlint:disable cyclomatic_complexity
    var formValue: JSON.Value? {
        get throws {
            // Unnamed FormValues, which may contain nested options
            guard let name = name
            else {
                if let form = self.form,
                   !form.allFields.isEmpty
                {
                    return try form.formValue.value
                } else {
                    return value?.jsonValue
                }
            }
            
            var json = JSON([:])
            
            // Named FormValues with nested forms
            if let form = self.form,
               !form.allFields.isEmpty
            {
                for field in form.allFields {
                    guard let nestedResult = try field.formValue else {
                        continue
                    }
                    json[name] = nestedResult
                }
            }
            
            // Named form values that consist of multiple child options
            else if let selectedOption = selectedOption {
                if type == "object" {
                    json[name] = try selectedOption.formValue
                } else {
                    json[name] = selectedOption.value?.jsonValue
                }
            }
            
            // Other..
            else {
                // lots 'o stuff here
                json[name] = value?.jsonValue
            }
            
            if isRequired && json[name] == nil {
                throw InteractionCodeFlowError.missingRequiredParameter(name: name)
            }
            
            return json.value
        }
    }
    // swiftlint:enable cyclomatic_complexity
}
