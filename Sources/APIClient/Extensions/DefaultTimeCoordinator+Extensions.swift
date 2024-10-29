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

import Foundation
import OktaUtilities

#if os(Linux)
import FoundationNetworking
#endif

extension DefaultTimeCoordinator: APIClientDelegate {
    public func api(client: any APIClient, didSend request: URLRequest, received response: HTTPURLResponse) {
        guard request.cachePolicy == .reloadIgnoringLocalAndRemoteCacheData,
              let dateString = response.allHeaderFields["Date"] as? String,
              let date = DateFormatter.httpDateFormatter.date(from: dateString)
        else {
            return
        }
        
        offset = date.timeIntervalSinceNow
    }
}
