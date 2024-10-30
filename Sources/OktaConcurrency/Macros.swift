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

@attached(accessor)
@attached(peer, names: prefixed(_))
public macro Synchronized(value: Any? = nil, lock: Lock? = nil) = #externalMacro(module: "OktaClientMacros", type: "SynchronizedMacro")

@attached(accessor)
public macro Synchronized<T>(variable: T, lock: Lock) = #externalMacro(module: "OktaClientMacros", type: "SynchronizedMacro")

@attached(member, names: arbitrary)
public macro HasLock(named: String = "lock") = #externalMacro(module: "OktaClientMacros", type: "HasLockMacro")
