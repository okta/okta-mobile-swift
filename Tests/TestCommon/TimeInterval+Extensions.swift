//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

public extension TimeInterval {
    static let standard: Self = 3
    static let short: Self = 1
    static let long: Self = 5
    static let veryLong: Self = 10
}

public extension DispatchTime {
    static var standard: Self { .now() + .standard }
    static var short: Self { .now() + .short }
    static var long: Self { .now() + .long }
    static var veryLong: Self { .now() + .veryLong }
}
