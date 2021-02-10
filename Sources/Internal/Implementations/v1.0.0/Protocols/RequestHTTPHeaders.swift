/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation

protocol HasHTTPHeaders {
    var httpHeaders: [String:String] { get }
}

protocol HasOAuthHTTPHeaders: HasHTTPHeaders {}
protocol HasIDPHTTPHeaders: HasHTTPHeaders {}

extension HasOAuthHTTPHeaders {
    var httpHeaders: [String : String] {
        get {
            return [
                "Content-Type": "application/x-www-form-urlencoded",
                "Accept": "application/json"
            ]
        }
    }
}

extension HasIDPHTTPHeaders {
    var httpHeaders: [String : String] {
        get {
            return [
                "Content-Type": "application/ion+json; okta-version=1.0.0",
                "Accept": "application/ion+json; okta-version=1.0.0"
            ]
        }
    }
}
