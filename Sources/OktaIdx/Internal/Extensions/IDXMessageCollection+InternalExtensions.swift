//
// Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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

protocol ContainsNestedMessages {
    func nestedMessages() -> [IDXClient.Message]
}

extension IDXClient.RemediationCollection: ContainsNestedMessages {
    func nestedMessages() -> [IDXClient.Message] {
        remediations.reduce(into: [IDXClient.Message]()) { (result, remediation) in
            result.append(contentsOf: remediation.nestedMessages())
        }
    }
}

extension IDXClient.Remediation: ContainsNestedMessages {
    func nestedMessages() -> [IDXClient.Message] {
        form.nestedMessages()
    }
}

extension IDXClient.Remediation.Form: ContainsNestedMessages {
    func nestedMessages() -> [IDXClient.Message] {
        allFields.reduce(into: [IDXClient.Message]()) { (result, field) in
            result.append(contentsOf: field.nestedMessages())
        }
    }
}

extension IDXClient.Remediation.Form.Field: ContainsNestedMessages {
    func nestedMessages() -> [IDXClient.Message] {
        var result = messages.allMessages
        if let form = form {
            result.append(contentsOf: form.nestedMessages())
        }
        
        if let options = options {
            for option in options {
                result.append(contentsOf: option.nestedMessages())
            }
        }
        
        return result
    }
}
