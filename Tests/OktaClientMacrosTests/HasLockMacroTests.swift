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

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(OktaClientMacros)
import OktaClientMacros
#endif

final class HasLockMacroTests: XCTestCase {
    func testDefaultMacro() throws {
        #if canImport(OktaClientMacros)
        assertMacroExpansion(
        """
        @HasLock
        class TestClass {
        }
        """,
        expandedSource:
        """
        class TestClass {
        
          private let lock = Lock()
        
          internal func withLock<LockedResult>(_ body: () throws -> LockedResult) rethrows -> LockedResult {
            try lock.withLock(body)
          }
        
          internal func withLock(_ body: () throws -> Void) rethrows {
            try lock.withLock(body)
          }
        }
        """,
        macros: testMacros,
        indentationWidth: .spaces(2))
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testCustomNameMacro() throws {
        #if canImport(OktaClientMacros)
        assertMacroExpansion(
        """
        @HasLock(named: "myLock")
        class TestClass {
        }
        """,
        expandedSource:
        """
        class TestClass {
        
          private let myLock = Lock()
        
          internal func withLock<LockedResult>(_ body: () throws -> LockedResult) rethrows -> LockedResult {
            try myLock.withLock(body)
          }
        
          internal func withLock(_ body: () throws -> Void) rethrows {
            try myLock.withLock(body)
          }
        }
        """,
        macros: testMacros,
        indentationWidth: .spaces(2))
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
