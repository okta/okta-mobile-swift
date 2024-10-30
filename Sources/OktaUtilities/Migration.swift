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
import OktaConcurrency

extension SDKVersion {
    /// Determines whether or not some user data needs to be migrated.
    ///
    /// This may be if a user has upgraded to a newer version of the SDK.
    public static var isMigrationNeeded: Bool {
        Migration.shared.needsMigration
    }
    
    /// Migrates user data, if necessary.
    public static func migrateIfNeeded() throws {
        try sharedLock.withLock {
            guard isMigrationNeeded else {
                return
            }
            
            try Migration.shared.migrate()
        }
    }
    
    /// Registers an SDK version migrator for use within a migration process.
    ///
    /// Version migrators are utilized to migrate user data on an as-needed basis.
    /// - Parameter migrator: Migrator to register.
    public static func register(migrator: any SDKVersionMigrator) {
        sharedLock.withLock {
            Migration.registeredMigrators.append(migrator)
        }
    }
    
    /// Namespace used for a variety of version migration agents.
    public final class Migration: Sendable {
        static let shared = Migration()
        
        nonisolated(unsafe) fileprivate(set) static var registeredMigrators: [any SDKVersionMigrator] = defaultMigrators()

        static func resetMigrators() {
            sharedLock.withLock {
                registeredMigrators = defaultMigrators()
            }
        }
        
        static func defaultMigrators() -> [any SDKVersionMigrator] {
            []
        }
        
        let migrators: [any SDKVersionMigrator]
        
        init(migrators: [any SDKVersionMigrator]) {
            self.migrators = migrators
        }
        
        convenience init() {
            self.init(migrators: Migration.registeredMigrators)
        }
        
        var needsMigration: Bool {
            !migrators.filter(\.needsMigration).isEmpty
        }
        
        func migrate() throws {
            try migrators
                .filter(\.needsMigration)
                .forEach { migrator in
                    try migrator.migrate()
                }
        }
    }
}
