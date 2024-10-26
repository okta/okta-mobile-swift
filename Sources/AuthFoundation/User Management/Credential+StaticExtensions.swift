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
import OktaConcurrency
import OktaClientMacros
import JWT

fileprivate let staticLock = Lock()
nonisolated(unsafe) fileprivate var _refreshGraceInterval: TimeInterval = 300

extension Credential {
    /// The default grace interval used when refreshing tokens using ``Credential/refreshIfNeeded(graceInterval:completion:)`` or ``Credential/refreshIfNeeded(graceInterval:)``.
    ///
    /// This value may still be overridden by supplying an explicit `graceInterval` argument to the above methods.
    @Synchronized(variable: _refreshGraceInterval, lock: staticLock)
    public static var refreshGraceInterval: TimeInterval
}
