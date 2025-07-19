/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation
import AuthFoundation

struct ClientConfiguration {
    let recoveryToken: String?
    
    init?(recoveryToken: String?) {
        guard recoveryToken?.isEmpty ?? false
        else {
            return nil
        }

        self.recoveryToken = recoveryToken
    }
    
    static var active: ClientConfiguration? = {
        launchConfiguration
    }()
    
    static var launchConfiguration: ClientConfiguration? {
        let arguments = [
            "--recoveryToken", "-t"
        ]
        
        var recoveryToken: String?
        var key: String?
        for argument in CommandLine.arguments {
            if arguments.contains(argument) {
                key = argument
                continue
            }
            
            switch key {
            case "--recoveryToken", "-t":
                recoveryToken = argument
                
            default: break
            }
            key = nil
        }
        
        return ClientConfiguration(recoveryToken: recoveryToken)
    }
}
