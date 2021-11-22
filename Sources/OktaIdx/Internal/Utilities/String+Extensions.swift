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

extension String {
    var base64ImageData: Data? {
        let mimeLookupUpperBound = 25
         
        guard hasPrefix("data:image/") else { return nil }
        
        let searchRange = startIndex ..< index(startIndex, offsetBy: mimeLookupUpperBound)
        let mimeRange = range(of: ";base64,", range: searchRange)
        let base64String = String(self[mimeRange!.upperBound ..< endIndex])
        return Data(base64Encoded: base64String, options: .ignoreUnknownCharacters)
    }
}
