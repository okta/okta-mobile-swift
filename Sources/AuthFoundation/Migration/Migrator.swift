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

/// Protocol describing a version migrator.
///
/// Version migrators are used to both determine a) if any migration operations need to be performed during app start-up, and b) perform migrations to upgrade user data.
public protocol SDKVersionMigrator: AnyObject {
    /// Used to indicate if an individual migrator needs to perform any migration operations.  It is recommended that this value be cached.
    var needsMigration: Bool { get }
    
    /// Performs the version migration work necessary for this migrator.
    func migrate() throws
}
