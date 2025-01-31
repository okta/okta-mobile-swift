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

extension DirectAuthenticationFlow.ContinuationType {
    var mfaContext: DirectAuthenticationFlow.MFAContext? {
        if case let .webAuthn(context) = self {
            return context.mfaContext
        } else if case let .transfer(context, code: _) = self {
            return context.mfaContext
        } else if case let .prompt(context) = self {
            return context.mfaContext
        } else {
            return nil
        }
    }
    
    var bindingContext: DirectAuthenticationFlow.ContinuationType.BindingContext? {
        switch self {
        case .transfer(let context, _):
            return context
        case .prompt(let context):
            return context
        default:
            return nil
        }
    }
    
    public static func == (lhs: DirectAuthenticationFlow.ContinuationType, rhs: DirectAuthenticationFlow.ContinuationType) -> Bool {
        switch (lhs, rhs) {
        case (.webAuthn(let lhs), .webAuthn(let rhs)):
            return lhs == rhs
        case (.transfer(let lhs_context, let lhs_code), .transfer(let rhs_context, let rhs_code)):
            return lhs_context == rhs_context && lhs_code == rhs_code
        case (.prompt(let lhs), .prompt(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension DirectAuthenticationFlow.Status {
    var continuationType: DirectAuthenticationFlow.ContinuationType? {
        if case let .continuation(type) = self {
            return type
        }
        
        return nil
    }
    
    var mfaContext: DirectAuthenticationFlow.MFAContext? {
        if case let .mfaRequired(context) = self {
            return context
        } else if let mfaContext = continuationType?.mfaContext {
            return mfaContext
        } else {
            return nil
        }
    }
}
