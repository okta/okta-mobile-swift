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

import Testing
@testable import AuthFoundation

@Suite("Percent Encoded Query Tests", .disabled("Debugging test deadlocks within CI"))
struct PercentEncodedQueryTests {
    @Test("API Request Query encoding")
    func apiRequestQuery() {
        var query = [String: (any APIRequestArgument)?]()
        #expect(query.percentQueryEncoded == "")
        
        query["firstName"] = "Jane"
        #expect(query.percentQueryEncoded == "firstName=Jane")
        
        query["phoneNumber"] = "+15551234567"
        #expect(query.percentQueryEncoded == "firstName=Jane&phoneNumber=%2B15551234567")
        
        query["adjustment"] = "50%"
        #expect(query.percentQueryEncoded == "adjustment=50%25&firstName=Jane&phoneNumber=%2B15551234567")
    }
    
    @Test("Percent Query encoding")
    func percentQueryEncoded() {
        var query = [String: String]()
        #expect(query.percentQueryEncoded == "")
        
        query["name"] = "Jane Doe"
        #expect(query.percentQueryEncoded == "name=Jane%20Doe")
        
        query["phoneNumber"] = "+15551234567"
        #expect(query.percentQueryEncoded == "name=Jane%20Doe&phoneNumber=%2B15551234567")
        
        query["adjustment"] = "50%"
        #expect(query.percentQueryEncoded == "adjustment=50%25&name=Jane%20Doe&phoneNumber=%2B15551234567")
    }
}
