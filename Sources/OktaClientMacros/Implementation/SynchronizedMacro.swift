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
import SwiftDiagnostics

struct SynchronizedMacro: PeerMacro, AccessorMacro {
    static func expansion(of node: SwiftSyntax.AttributeSyntax,
                          providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                          in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.AccessorDeclSyntax]
    {
        guard let property = declaration.as(VariableDeclSyntax.self),
              let binding = property.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            throw SynchronizedMacroError.declarationNotAVariable
        }
        
        let name = identifier.identifier.text
        let variableName = node.stringValue(for: "variable") ?? "_\(name)"
        let lockName = node.stringValue(for: "lock") ?? "lock"

        var results: [AccessorDeclSyntax] = [
            """
            get {
                \(raw: lockName).withLock {
                    \(raw: variableName)
                }
            }
            """
        ]

        if node.argument(for: "isReadOnly") == nil {
            results.append(
                """
                set {
                    \(raw: lockName).withLock {
                        \(raw: variableName) = newValue
                    }
                }
                """)
        }
        return results
    }
    
    static func expansion(of node: SwiftSyntax.AttributeSyntax,
                          providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                          in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax]
    {
        guard let property = declaration.as(VariableDeclSyntax.self),
              let binding = property.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
              let type = binding.typeAnnotation?.type
        else {
            throw SynchronizedMacroError.declarationNotAVariable
        }
        
        guard node.argument(for: "variable") == nil
        else {
            return []
        }
        
        let name = identifier.identifier.text
        let variableName = "_\(name)"

        var newProperty: VariableDeclSyntax?
        let letvar = node.argument(for: "isReadOnly") == nil ? "var" : "let"

        if let args = node.arguments?.as(LabeledExprListSyntax.self),
           let attribute = args.first(where: { $0.label?.text == "value" })
        {
            newProperty = VariableDeclSyntax(try DeclSyntax(validating: "nonisolated(unsafe) private \(raw: letvar) \(raw: variableName): \(raw: type) = \(attribute.expression)"))
        } else {
            newProperty = VariableDeclSyntax(try DeclSyntax(validating: "nonisolated(unsafe) private \(raw: letvar) \(raw: variableName): \(raw: type)"))
        }
        
        let newPropertyIdentifier = newProperty?.children(matching: { node in
            guard let node = node.as(IdentifierPatternSyntax.self) else {
                return false
            }
            
            return node.identifier.text == variableName
        }).first?.as(IdentifierPatternSyntax.self)
        
        if let accessorBlock = binding.accessorBlock,
           var newBinding = newProperty?.bindings.first
        {
            // Find invalid accesses
            let matchingChildren = accessorBlock.children(matching: { node in
                guard let node = node.as(DeclReferenceExprSyntax.self) else {
                    return false
                }
                
                return node.baseName.identifier?.name == name
            })
            
            if let newPropertyIdentifier = newPropertyIdentifier,
               !matchingChildren.isEmpty
            {
                matchingChildren.forEach { node in
                    let message = MacroExpansionErrorMessage(
                        "You should not reference a synchronized property from within a locked context")
                    let diagnostic = Diagnostic(
                        node: node,
                        message: message,
                        fixIt: FixIt(
                            message: MacroExpansionFixItMessage("use '\(variableName)'"),
                            changes: [
                                FixIt.Change.replace(
                                    oldNode: Syntax(node),
                                    newNode: Syntax(newPropertyIdentifier)
                                )
                            ]))
                    print(diagnostic.debugDescription)
                    context.diagnose(diagnostic)
                }
            }
            
            newBinding.accessorBlock = accessorBlock
            newProperty?.bindings = PatternBindingListSyntax(arrayLiteral: newBinding)
        }
        
        guard let result = DeclSyntax(newProperty) else {
            throw SynchronizedMacroError.cannotSynthesizePrivateProperty
        }
        return [result]
    }
}
