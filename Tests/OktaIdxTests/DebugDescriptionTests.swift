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

import XCTest
@testable import OktaIdx

class DebugDescriptionTests: XCTestCase {
    private class ReferenceMock {
    }
    
    private struct StackMock {
    }
    
    func testReferenceObjectAddress() {
        let object = ReferenceMock()
        let logger = DebugDescription(object)
        let address = logger.address().components(separatedBy: ": ")
        
        XCTAssertTrue(address.first!.hasPrefix("ReferenceMock"))
        XCTAssertTrue(address[1].matches(for: "(0x)?([0-9a-f])"))
    }
    
    func testStackObjectAddress() {
        let object = StackMock()
        let logger = DebugDescription(object)
        let address = logger.address().components(separatedBy: ": ")
        
        XCTAssertTrue(address.first!.hasPrefix("StackMock"))
        XCTAssertTrue(address[1].matches(for: "(0x)?([0-9a-f])"))
    }
    
    func testBracing() {
        let object = StackMock()
        let logger = DebugDescription(object)
        let bracingString = "StackObject;"
        
        XCTAssertEqual(logger.brace(bracingString), "<\(bracingString)>")
    }
    
    func testUnbracing() {
        let object = ReferenceMock()
        let logger = DebugDescription(object)
        let bracingString = "ReferenceObject;"
        let bracedString = logger.brace(bracingString)
        
        XCTAssertEqual(logger.unbrace(bracedString), bracingString)
    }
    
    func testListFormatting() {
        let object = ReferenceMock()
        let logger = DebugDescription(object)
        let list = (0...2).map { "Object\($0): Value\($0)" }
        let formattedList = logger.format(list, indent: 4)
        
        XCTAssertEqual(formattedList,
                       """
                           Object0: Value0;
                           Object1: Value1;
                           Object2: Value2
                       """
        )
    }
    
    func testStringsIndentation() {
        let strings = (0...2).map { "Object\($0): Value\($0)" }.joined(separator: "\n")
        
        XCTAssertEqual(strings.indentingNewlines(by: 0),
                       """
                       Object0: Value0
                       Object1: Value1
                       Object2: Value2
                       """
        )
        
        XCTAssertEqual(strings.indentingNewlines(by: 4),
                       """
                           Object0: Value0
                           Object1: Value1
                           Object2: Value2
                       """
        )
    }
}

fileprivate extension String {
    func matches(for pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return false
        }
        
        let range = NSRange(startIndex..., in: self)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}
