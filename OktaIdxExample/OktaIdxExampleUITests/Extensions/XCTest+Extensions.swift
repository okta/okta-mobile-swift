//
//  XCTestCase+Extensions.swift
//  OktaIdxExampleUITests
//
//  Created by Mike Nachbaur on 2021-01-20.
//

import XCTest

extension XCUIElement {
    var isFocused: Bool {
        let isFocused = (self.value(forKey: "hasKeyboardFocus") as? Bool) ?? false
        return isFocused
    }
}
