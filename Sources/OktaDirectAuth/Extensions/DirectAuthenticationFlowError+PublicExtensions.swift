//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension DirectAuthenticationFlowError: Equatable {
    static func compare(lhs: NSError, rhs: NSError) -> Bool {
        (lhs.code == rhs.code &&
         lhs.domain == rhs.domain)
    }

    public static func == (lhs: DirectAuthenticationFlowError, rhs: DirectAuthenticationFlowError) -> Bool {
        switch (lhs, rhs) {
        case (.pollingTimeoutExceeded, .pollingTimeoutExceeded): return true
        case (.bindingCodeMissing, .bindingCodeMissing): return true
        case (.missingArguments(let lhsNames), .missingArguments(let rhsNames)):
            return lhsNames.sorted() == rhsNames.sorted()
        case (.network(error: let lhsError), .network(error: let rhsError)):
            return lhsError == rhsError
        case (.oauth2(error: let lhsError), .oauth2(error: let rhsError)):
            return lhsError == rhsError
        case (.server(error: let lhsError), .server(error: let rhsError)):
            return lhsError == rhsError
        case (.other(error: let lhsError), .other(error: let rhsError)):
            return compare(lhs: lhsError as NSError, rhs: rhsError as NSError)
        default:
            return false
        }
    }
}
