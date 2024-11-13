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

extension SyntaxProtocol {
    func children(viewMode: SyntaxTreeViewMode = .all,
                  matching block: (_ node: any SyntaxProtocol) -> Bool) -> [any SyntaxProtocol]
    {
        var results: [any SyntaxProtocol] = []
        if block(self) {
            results.append(self)
        }
        
        children(viewMode: viewMode).forEach { syntax in
            results.append(contentsOf: syntax.children(viewMode: viewMode, matching: block))
        }
        
        return results
    }
}

extension AttributeSyntax {
    func argument(for name: String) -> LabeledExprSyntax? {
        guard let args = arguments?.as(LabeledExprListSyntax.self)
        else {
            return nil
        }
        
        for argument in args {
            if argument.label?.text == name {
                return argument
            }
            
            if argument.expression.as(DeclReferenceExprSyntax.self)?.baseName.text == name {
                return argument
            }
        }
        
        return nil
    }
    
    func stringValue(for argumentName: String) -> String? {
        guard let expression = argument(for: argumentName)?.expression
        else {
            return nil
        }
        
        if let expression = expression.as(StringLiteralExprSyntax.self) {
            return expression.representedLiteralValue
        }
        
        if let expression = expression.as(DeclReferenceExprSyntax.self) {
            #if swift(<6)
            return expression.baseName.text
            #else
            return expression.baseName.identifier?.name
            #endif
        }
        
        return nil
    }
}
