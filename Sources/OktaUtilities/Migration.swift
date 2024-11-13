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

struct SDKVersion {
    @available(*, deprecated, renamed: "Migration", message: "Migration moved to a top-level namespace")
    public struct Migration {}
}

/// Namespace used for a variety of version migration agents.
@HasLock
public final class Migration: Sendable {
    /// Determines whether or not some user data needs to be migrated.
    ///
    /// This may be if a user has upgraded to a newer version of the SDK.
    public static var isMigrationNeeded: Bool {
        shared.needsMigration
    }
    
    /// Migrates user data, if necessary.
    public static func migrateIfNeeded() throws {
        try shared.migrate()
    }
    
    /// Registers an SDK version migrator for use within a migration process.
    ///
    /// Version migrators are utilized to migrate user data on an as-needed basis.
    /// - Parameter migrator: Migrator to register.
    public static func register(migrator: any SDKVersionMigrator) {
        shared.register(migrator: migrator)
    }
    
    static let shared = Migration()

    func resetMigrators() {
        withLock {
            _migrators = Self.defaultMigrators()
        }
    }
    
    static func defaultMigrators() -> [any SDKVersionMigrator] {
        []
    }
    
    @Synchronized
    var migrators: [any SDKVersionMigrator]
    
    init(migrators: [any SDKVersionMigrator]) {
        _migrators = migrators
    }
    
    convenience init() {
        self.init(migrators: Self.defaultMigrators())
    }
    
    func register(migrator: any SDKVersionMigrator) {
        withLock {
            _migrators.append(migrator)
        }
    }

    var needsMigration: Bool {
        withLock {
            !_migrators
                .filter(\.needsMigration)
                .isEmpty
        }
    }
    
    func migrate() throws {
        try withLock {
            try _migrators
                .filter(\.needsMigration)
                .forEach { migrator in
                    try migrator.migrate()
                }
        }
    }
}
