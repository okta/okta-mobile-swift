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

class Command {
    let executable: URL
    let arguments: [String]

    private(set) var output: [String: String]?
    private(set) var expectations: [String: String] = [:]
    
    init(_ executable: URL, arguments: [String] = []) {
        self.executable = executable
        self.arguments = arguments
    }
    
    func expect(_ pattern: String, response: String) {
        expectations[pattern] = response
    }
    
    func run() throws {
        let stdin = Pipe()
        let stdout = Pipe()

        let process = Process()
        process.standardInput = stdin
        process.standardOutput = stdout
        process.executableURL = executable
        process.arguments = arguments
        
        let group = DispatchGroup()

        group.enter()
        
        process.terminationHandler = { _ in
            DispatchQueue.main.async {
                group.leave()
            }
        }

        try process.run()
        
        while !expectations.isEmpty {
            let data = stdout.fileHandleForReading.availableData
            if let string = String(data: data, encoding: .utf8) {
                for pattern in Array(expectations.keys) {
                    if !string.contains(pattern) {
                        continue
                    }
                    
                    defer { expectations.removeValue(forKey: pattern) }
                    
                    guard let response = expectations[pattern],
                          let output = response.appending("\n").data(using: .utf8)
                    else { continue }
                    
                    try stdin.fileHandleForWriting.write(contentsOf: output)
                }
            }
        }
       
        let data = stdout.fileHandleForReading.availableData
        if let string = String(data: data, encoding: .utf8) {
            output = string.components(separatedBy: "\n")
                .reduce(into: [String: String]()) { partialResult, line in
                    let values = line.components(separatedBy: ": ")
                    guard values.count == 2 else { return }
                    partialResult[values[0]] = values[1]
                }
        }
        
        process.terminate()
    }
}
