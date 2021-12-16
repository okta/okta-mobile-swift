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

/// Defines the types of properties that can be assigned to an `Remediation.Form.Field` value.
public protocol IDXFormValue {
}

extension String : IDXFormValue {
}

extension Bool : IDXFormValue {
}

extension Double : IDXFormValue {
}

extension Int : IDXFormValue {
}

extension UInt : IDXFormValue {
}

extension Int8 : IDXFormValue {
}

extension UInt8 : IDXFormValue {
}

extension Int16 : IDXFormValue {
}

extension UInt16 : IDXFormValue {
}

extension Int32 : IDXFormValue {
}

extension UInt32 : IDXFormValue {
}

extension Int64 : IDXFormValue {
}

extension UInt64 : IDXFormValue {
}

extension Float : IDXFormValue {
}

extension Array : IDXFormValue where Element == IDXFormValue {
}

extension Dictionary : IDXFormValue {
}

@nonobjc extension NSString : IDXFormValue {
}

@nonobjc extension NSDate : IDXFormValue {
}

@nonobjc extension NSData : IDXFormValue {
}

@nonobjc extension NSNumber : IDXFormValue {
}

@nonobjc extension NSArray : IDXFormValue {
}

@nonobjc extension NSDictionary : IDXFormValue {
}
