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
import OktaSdk

extension Scenario {
    func createUser(username: String,
                    password: String,
                    firstName: String,
                    lastName: String,
                    groupNames: [OktaGroup] = [],
                    phoneNumber: String? = nil,
                    enrollFactors: [FactorType] = [],
                    completion: @escaping (Swift.Error?) -> Void)
    {
        let passwordCredential = PasswordCredential(hash: nil,
                                                    hook: nil,
                                                    value: password)
        
        let userProfile = UserProfile(email: username,
                                      firstName: firstName,
                                      lastName: lastName,
                                      login: username)
        
        let credentials = UserCredentials(password: passwordCredential,
                                          provider: nil,
                                          recoveryQuestion: nil)
        
        let groupIds = self.groupIds(byGroupNames: groupNames)
        
        let userRequest = CreateUserRequest(credentials: credentials,
                                            groupIds: groupIds,
                                            profile: userProfile,
                                            type: nil)
        
        UserAPI.createUser(body: userRequest,
                           activate: true,
                           provider: nil,
                           nextLogin: nil) { (user, error) in
            guard let user = user,
                  let userId = user.id
            else {
                completion(error)
                return
            }
            
            let group = DispatchGroup()
            var asyncError: Swift.Error?
            
            if let phoneNumber = phoneNumber {
                if enrollFactors.contains(.sms) {
                    group.enter()
                    
                    var factor = SmsUserFactor()
                    factor.profile = SmsUserFactorProfile(phoneNumber: phoneNumber)
                    UserFactorAPI.enrollFactor(userId: userId, body: factor, activate: true) { (factor, error) in
                        if let error = error {
                            asyncError = error
                        }
                        
                        group.leave()
                    }
                }
                
                if enrollFactors.contains(.call) {
                    group.enter()
                    
                    var factor = CallUserFactor()
                    factor.profile = CallUserFactorProfile(phoneExtension: nil, phoneNumber: phoneNumber)
                    UserFactorAPI.enrollFactor(userId: userId, body: factor) { (factor, error) in
                        if let error = error {
                            asyncError = error
                        }
                        group.leave()
                    }
                }
            }
                        
            group.notify(queue: DispatchQueue.global()) {
                completion(error ?? asyncError)
            }
        }
    }
    
    private func groupIds(byGroupNames groupNames: [OktaGroup]) -> [String] {
        guard !groupNames.isEmpty else {
            return []
        }
        
        var groupIds: [String] = []
        let group = DispatchGroup()
        group.enter()
        
        GroupAPI.listGroups { (groups, error) in
            groupIds = groups?.filter { groupObject in
                guard let groupName = groupObject.profile?.name,
                      let oktaGroup = OktaGroup(rawValue: groupName)
                else
                {
                    return false
                }
                
                return groupNames.contains(oktaGroup)
            }.compactMap {
                $0.id
            } ?? []
            
            group.leave()
        }
        
        group.wait()
        
        return groupIds
    }
}
