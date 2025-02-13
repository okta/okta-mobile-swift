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

extension String {
    @_documentation(visibility: internal)
    public enum CaseStyle {
        case snakeCase
    }
    
    var base64URLDecoded: String {
        var result = replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        while result.count % 4 != 0 {
            result.append(contentsOf: "=")
        }

        return result
    }
    
    @_documentation(visibility: internal)
    public static func nonce(length: UInt = 16) -> String {
        [UInt8].random(count: Int(length)).base64URLEncodedString
    }

    @_documentation(visibility: internal)
    @inlinable
    public func convertedTo(style: CaseStyle, separator: Character = "_") -> String {
        switch style {
        case .snakeCase:
            return convertToSnakeCase(value: self, separator: separator)
        }
    }
    
    @_documentation(visibility: internal)
    @inlinable public var snakeCase: String {
        convertedTo(style: .snakeCase)
    }
}

@usableFromInline
enum SnakeWordBoundaryType {
    case uppercase
    case number
    
    @inlinable
    init?(_ character: Character?) {
        guard let character = character else {
            return nil
        }
        
        if character.isUppercase {
            self = .uppercase
        } else if character.isNumber {
            self = .number
        } else {
            return nil
        }
    }
}

@inlinable
func convertToSnakeCase(value: String, separator: Character = "_") -> String {
    var result = ""

    guard !value.isEmpty else {
        return result
    }

    var previousCharacterType: SnakeWordBoundaryType?

    for index in value.indices {
        let character = value[index]
        let characterType = SnakeWordBoundaryType(character)
        let nextIndex = value.index(after: index)
        let nextCharacter: Character? = {
            guard nextIndex < value.endIndex else { return nil }
            return value[nextIndex]
        }()
        let nextCharacterType = SnakeWordBoundaryType(nextCharacter)

        var showSeparator = false
        if let characterType = characterType {
            // Word boundary between lowercase and a boundary word {
            if previousCharacterType == nil {
                showSeparator = true
            }
            
            // Word boundary between different word types
            else if previousCharacterType != characterType {
                showSeparator = true
            }

            // Word boundary between an acronym and another word
            else if characterType == .uppercase &&
                        previousCharacterType == .uppercase &&
                        nextCharacterType == nil &&
                        nextIndex < value.endIndex
            {
                showSeparator = true
            }
        }

        if showSeparator && !result.isEmpty {
            result += "\(separator)"
        }

        result += character.lowercased()
        previousCharacterType = characterType
    }
    
    return result
}
