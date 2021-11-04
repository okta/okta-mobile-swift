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

struct DebugDescription<T: Any> {
    
    private let openBraceChar = "<"
    private let closeBraceChar = ">"
    
    let object: T
    
    init(_ object: T) {
        self.object = object
    }
    
    func address() -> String where T: AnyObject {
        "\(type(of: object)): \(Unmanaged.passUnretained(object).toOpaque())"
    }
    
    func address() -> String {
        "\(type(of: object)): \(object)"
    }
    
    func unbrace(_ string: String) -> String {
        var result = string
        
        if string.first == Character(openBraceChar) {
            result = String(result.dropFirst())
        }
        
        if string.last == Character(closeBraceChar) {
            result = String(result.dropLast())
        }
        
        return result
    }
    
    func brace(_ string: String) -> String {
        openBraceChar + string + closeBraceChar
    }
    
    func format(_ list: Array<String>, indent spaceCount: Int) -> String {
        if list.isEmpty {
            return "-".indentingNewlines(by: spaceCount)
        }
        
        return list.map { $0.indentingNewlines(by: spaceCount) }.joined(separator: ";\n")
    }
}

extension String {
    func indentingNewlines(by spaceCount: Int) -> String {
        let spaces = String(repeating: " ", count: spaceCount)
        let items = components(separatedBy: "\n")

        return String(items.map { "\n" + spaces + $0 }.joined().dropFirst())
    }
}
