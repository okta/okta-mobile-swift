//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
import ArgumentParser

extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(string: argument)
    }
}

extension JWTSignin {
    var fileHandle: FileHandle? {
        get throws {
            guard let file else { return nil }
            if file.path() == "-" {
                return .standardInput
            }
            
            return try FileHandle(forReadingFrom: file)
        }
    }

    func assertionString() throws -> String {
        if let file = try fileHandle,
           let data = try file.readToEnd(),
           let string = String(data: data, encoding: .utf8)
        {
            return string
        }
        
        throw ValidationError("Assertion input file is empty.")
    }
}

