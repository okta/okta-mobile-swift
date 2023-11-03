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

extension Credential {
    func createAutomaticRefreshTimer() -> DispatchSourceTimer? {
        guard let expiresAt = token.expiresAt else {
            return nil
        }
        
        refreshIfNeeded { _ in }
        
        automaticRefreshTimer?.cancel()
        
        let graceInterval = Credential.refreshGraceInterval
        let timeOffset = max(0.0, expiresAt.timeIntervalSinceNow - Date.nowCoordinated.timeIntervalSinceNow - graceInterval)
        let repeating = token.expiresIn - graceInterval
        
        let timerSource = DispatchSource.makeTimerSource(flags: [], queue: oauth2.refreshQueue)
        timerSource.schedule(deadline: .now() + timeOffset,
                             repeating: repeating)
        timerSource.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.refreshIfNeeded { _ in }
        }
        
        return timerSource
    }
    
    func shouldRemove(for type: Token.RevokeType) -> Bool {
        type == .all ||
        (type == .refreshToken && token.refreshToken != nil) ||
        (type == .accessToken && token.refreshToken == nil)
    }
}
