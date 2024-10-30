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

final class SynchronizedMacroTests: XCTestCase {
    func testSimpleSynchronized() throws {
        #if canImport(OktaClientMacros)
        assertMacroExpansion(
        """
        class TestClass {
            @Synchronized
            public var propertyName: Bool
        }
        """,
        expandedSource:
        """
        class TestClass {
            public var propertyName: Bool {
                get {
                    lock.withLock {
                        _propertyName
                    }
                }
                set {
                    lock.withLock {
                        _propertyName = newValue
                    }
                }
            }
        
            nonisolated(unsafe) private var _propertyName: Bool
        }
        """,
        macros: testMacros,
        indentationWidth: .spaces(4))
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDictionarySynchronized() throws {
        #if canImport(OktaClientMacros)
        assertMacroExpansion(
        """
        public final class TestClass {
            @Synchronized
            public var additionalHttpHeaders: [String: String]?
        }
        """,
        expandedSource:
        """
        public final class TestClass {
            public var additionalHttpHeaders: [String: String]? {
                get {
                    lock.withLock {
                        _additionalHttpHeaders
                    }
                }
                set {
                    lock.withLock {
                        _additionalHttpHeaders = newValue
                    }
                }
            }
        
            nonisolated(unsafe) private var _additionalHttpHeaders: [String: String]?
        }
        """,
        macros: testMacros,
        indentationWidth: .spaces(4))
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDefaultValueSynchronized() throws {
        #if canImport(OktaClientMacros)
        assertMacroExpansion(
        """
        class TestClass {
            @Synchronized(value: true)
            public var propertyName: Bool
        }
        """,
        expandedSource:
        """
        class TestClass {
            public var propertyName: Bool {
                get {
                    lock.withLock {
                        _propertyName
                    }
                }
                set {
                    lock.withLock {
                        _propertyName = newValue
                    }
                }
            }
        
            nonisolated(unsafe) private var _propertyName: Bool = true
        }
        """,
        macros: testMacros,
        indentationWidth: .spaces(4))
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testGetterOnlySynchronized() throws {
        #if canImport(OktaClientMacros)
        assertMacroExpansion(
        """
        class TestClass {
            @Synchronized(isReadOnly)
            public var propertyName: Bool
        }
        """,
        expandedSource:
        """
        class TestClass {
            public var propertyName: Bool {
                get {
                    lock.withLock {
                        _propertyName
                    }
                }
            }
        
            nonisolated(unsafe) private let _propertyName: Bool
        }
        """,
        macros: testMacros,
        indentationWidth: .spaces(4))
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDidSetSynchronized() throws {
        #if canImport(OktaClientMacros)
        assertMacroExpansion(
        """
        class TestClass {
            @Synchronized(value: false)
            public var propertyName: Bool {
                didSet {
                    print("Did set")
                }
            }
        }
        """,
        expandedSource:
        """
        class TestClass {
            public var propertyName: Bool {
                didSet {
                    print("Did set")
                }
                get {
                    lock.withLock {
                        _propertyName
                    }
                }

                set {
                    lock.withLock {
                        _propertyName = newValue
                    }
                }
            }

            nonisolated(unsafe) private var _propertyName: Bool  = false {
                    didSet {
                        print("Did set")
                    }
                }
        }
        """,
        macros: testMacros,
        indentationWidth: .spaces(4))
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDidSetWarningSynchronized() throws {
        #if canImport(OktaClientMacros)
        assertMacroExpansion(
        """
        class TestClass {
            @Synchronized(value: false)
            public var propertyName: Bool {
                didSet {
                    print("Did set \\(propertyName)")
                    let otherValue = !propertyName
                }
            }
        }
        """,
        expandedSource:
        """
        class TestClass {
            public var propertyName: Bool {
                didSet {
                    print("Did set \\(propertyName)")
                    let otherValue = !propertyName
                }
                get {
                    lock.withLock {
                        _propertyName
                    }
                }

                set {
                    lock.withLock {
                        _propertyName = newValue
                    }
                }
            }

            nonisolated(unsafe) private var _propertyName: Bool  = false {
                    didSet {
                        print("Did set \\(propertyName)")
                        let otherValue = !propertyName
                    }
                }
        }
        """,
        diagnostics: [
            DiagnosticSpec(message: "You should not reference a synchronized property from within a locked context",
                           line: 5,
                           column: 30,
                           fixIts: [
                            FixItSpec(message: "use '_propertyName'")
                           ]),
            DiagnosticSpec(message: "You should not reference a synchronized property from within a locked context",
                           line: 6,
                           column: 31,
                           fixIts: [
                            FixItSpec(message: "use '_propertyName'")
                           ]),
        ],
        macros: testMacros,
        indentationWidth: .spaces(4))
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testEnumSynchronized() throws {
        #if canImport(OktaClientMacros)
        assertMacroExpansion(
        """
        class TestClass {
            enum Thingie {
               case foo, bar
            }
        
            @Synchronized(value: .foo)
            var propertyName: Thingie
        }
        """,
        expandedSource:
        """
        class TestClass {
            enum Thingie {
               case foo, bar
            }
            var propertyName: Thingie {
                get {
                    lock.withLock {
                        _propertyName
                    }
                }
                set {
                    lock.withLock {
                        _propertyName = newValue
                    }
                }
            }

            nonisolated(unsafe) private var _propertyName: Thingie = .foo
        }
        """,
        macros: testMacros,
        indentationWidth: .spaces(4))
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testStaticSynchronized() throws {
        #if canImport(OktaClientMacros)
        assertMacroExpansion(
        """
        fileprivate let staticLock = Lock()
        nonisolated(unsafe) fileprivate var _sharedProperty: Bool = true
        
        class TestClass {
            @Synchronized(variable: _sharedProperty, lock: staticLock)
            public static var sharedProperty: Bool
        }
        """,
        expandedSource:
        """
        fileprivate let staticLock = Lock()
        nonisolated(unsafe) fileprivate var _sharedProperty: Bool = true
        
        class TestClass {
            public static var sharedProperty: Bool {
                get {
                    staticLock.withLock {
                        _sharedProperty
                    }
                }
                set {
                    staticLock.withLock {
                        _sharedProperty = newValue
                    }
                }
            }
        }
        """,
        macros: testMacros,
        indentationWidth: .spaces(4))
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
