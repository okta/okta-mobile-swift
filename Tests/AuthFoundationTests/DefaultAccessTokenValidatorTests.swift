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

import XCTest
@testable import AuthFoundation
import TestCommon

final class DefaultAccessTokenValidatorTests: XCTestCase {
    let validator = DefaultAccessTokenValidator()

    let validToken = "eyJraWQiOiJGSkEwSEdOdHN1dWRhX1BsNDVKNDJrdlFxY3N1XzBDNEZnN3BiSkxYVEhZIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHViNDF6N21nek5xcnlNdjY5NiIsIm5hbWUiOiJUZXN0IFVzZXIiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJ2ZXIiOjEsImlzcyI6Imh0dHBzOi8vZXhhbXBsZS5va3RhLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6InVuaXRfdGVzdF9jbGllbnRfaWQiLCJpYXQiOjE2NDQzNDcwNjksImV4cCI6MTY0NDM1MDY2OSwianRpIjoiSUQuNTVjeEJ0ZFlsOGw2YXJLSVNQQndkMHlPVC05VUNUYVhhUVRYdDJsYVJMcyIsImFtciI6WyJwd2QiXSwiaWRwIjoiMDBvOGZvdTdzUmFHR3dkbjQ2OTYiLCJzaWQiOiJpZHhXeGtscF80a1N4dUNfblUxcFhELW5BIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidGVzdEBleGFtcGxlLmNvbSIsImF1dGhfdGltZSI6MTY0NDM0NzA2OCwiYXRfaGFzaCI6IktfVVNrUU94SnVRb0M3blNFc1BFYnciLCJkc19oYXNoIjoiREFlTE9GUnFpZnlzYmdzcmJPZ2JvZyJ9.OYNrJXGj0fdMQjuCJSE4aInN3pRqjU6pcd-8-4Oqe5R9I-z6B2-aK_inbwFHwzZl9SLe0mJDdPcTlRpuK1rPb2QwNTPBB0JRGXnu0KkZTE8bv2CgfyKdiH7y0LEjJraboqX2Nddz9kUsEUhZsrt9LSNMWR2nkoE2QuQe8a1mvATeUY9itY-wMJMf6yC2f0FTBQqjCHI7W0SlRsgTsNRUDZsGMhdLwzSjYgB2M6Luc7TmXDbrKHBkEAsEat_8nED2hQWnGnT1i6jrcVEEWVqR5-bMJ_ocf7cLZM6FTq5Xtem-5QFpiePx2qWKCZ6QFWubr52qaEEUP-kj4jG1GNvIqA"

    let validAccessToken = "VGhpc0lzQVJlYWxseUdyZWF0QWNjZXNzVG9rZW4sIERvbid0WW91VGhpbms_"
    
    #if !os(Linux)
    func testInvalidAccessToken() throws {
        let jwt = try XCTUnwrap(JWT(rawValue: validToken))
        XCTAssertThrowsError(try validator.validate(accessToken: "ThisIsn'tGoingToWork", idToken: jwt)) { error in
            XCTAssertEqual(error as! JWTError, JWTError.signatureInvalid)
        }
    }

    func testValidAccessToken() throws {
        let jwt = try XCTUnwrap(JWT(rawValue: validToken))
        XCTAssertNoThrow(try validator.validate(accessToken: validAccessToken, idToken: jwt))
    }
    #endif
}
