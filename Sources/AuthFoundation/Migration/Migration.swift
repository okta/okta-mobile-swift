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
import CommonSupport

/// Namespace used for a variety of version migration agents.
public final class Migration {
    /// Determines whether or not some user data needs to be migrated.
    ///
    /// This may be if a user has upgraded to a newer version of the SDK.
    public static var isMigrationNeeded: Bool {
        shared.isMigrationNeeded
    }

    /// Migrates user data, if necessary.
    public static func migrateIfNeeded() throws {
        try shared.migrateIfNeeded()
    }

    /// Registers an SDK version migrator for use within a migration process.
    ///
    /// Version migrators are utilized to migrate user data on an as-needed basis.
    /// - Parameter migrator: Migrator to register.
    public static func register(migrator: any SDKVersionMigrator) {
        shared.register(migrator: migrator)
    }

    // MARK: Internal properties / methods
    nonisolated(unsafe) static let shared = Migration()
    nonisolated(unsafe) private(set) var registeredMigrators: [any SDKVersionMigrator]

    init(migrators: [any SDKVersionMigrator]? = nil) {
        assert(SDKVersion.authFoundation != nil)
        self.registeredMigrators = migrators ?? Self.defaultMigrators
    }

    func register(migrator: any SDKVersionMigrator) {
        lock.withLock {
            guard !registeredMigrators.contains(where: { $0 === migrator })
            else {
                return
            }

            registeredMigrators.append(migrator)
        }
    }

    func migrateIfNeeded() throws {
        try lock.withLock {
            try registeredMigrators
                .filter(\.needsMigration)
                .forEach { migrator in
                    try migrator.migrate()
                }
        }
    }

    var isMigrationNeeded: Bool {
        lock.withLock {
            !registeredMigrators
                .filter(\.needsMigration)
                .isEmpty
        }
    }

    func resetMigrators() {
        lock.withLock {
            registeredMigrators = Self.defaultMigrators
        }
    }

    // MARK: Private properties / methods
    private let lock = Lock()
    nonisolated(unsafe) private static let defaultMigrators: [any SDKVersionMigrator] = {
        []
    }()
}
