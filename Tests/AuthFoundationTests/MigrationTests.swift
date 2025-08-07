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
import Testing

@testable import AuthFoundation

enum TestMigratorError: Error {
    case generic
}

class TestMigrator: SDKVersionMigrator {
    var error: (any Error)?
    private(set) var migrationCalled: Bool = false

    func reset() {
        error = nil
        migrationCalled = false
    }
    
    var needsMigration: Bool = true
    
    func migrate() throws {
        migrationCalled = true
        
        if let error = error {
            throw error
        }
    }
}

@Suite("Version migration tests", .serialized, .disabled("Debugging test deadlocks within CI"))
final class MigrationTests {
    init() {
        Migration.shared.resetMigrators()
    }
    
    deinit {
        Migration.shared.resetMigrators()
    }
    
    @Test("Migrator registration")
    func testMigratorRegistration() throws {
        let migratorA = TestMigrator()
        let migratorB = TestMigrator()
        
        migratorA.needsMigration = false
        migratorB.needsMigration = false
        
        let migration = Migration(migrators: [migratorA, migratorB])

        // Ensure migration is not called when not needed
        #expect(!migration.isMigrationNeeded)
        try migration.migrateIfNeeded()
        #expect(!migratorA.migrationCalled)
        #expect(!migratorB.migrationCalled)
        migratorA.reset()
        migratorB.reset()
        
        // Ensure only necessary migrators are called
        migratorA.needsMigration = true
        #expect(migration.isMigrationNeeded)
        try migration.migrateIfNeeded()
        #expect(migratorA.migrationCalled)
        #expect(!migratorB.migrationCalled)
        migratorA.reset()
        migratorB.reset()
        
        // Ensure an exception prevents subsequent migrators from running
        migratorA.needsMigration = true
        migratorA.error = TestMigratorError.generic
        migratorB.needsMigration = true
        #expect(migration.isMigrationNeeded)
        let error = #expect(throws: TestMigratorError.self) {
            try migration.migrateIfNeeded()
        }
        #expect(error == .generic)
        #expect(migratorA.migrationCalled)
        #expect(!migratorB.migrationCalled)
        migratorA.reset()
        migratorB.reset()
    }
    
    @Test("Registered migrators")
    func testRegisteredMigrators() throws {
        #expect(Migration.shared.registeredMigrators.isEmpty)

        // Test adding a migrator
        let migratorA = TestMigrator()
        Migration.register(migrator: migratorA)
        #expect(Migration.shared.registeredMigrators.contains(where: { $0 === migratorA }))
        #expect(Migration.shared.registeredMigrators.count == 1)

        // Ensure duplicate migrators aren't added
        Migration.register(migrator: migratorA)
        #expect(Migration.shared.registeredMigrators.contains(where: { $0 === migratorA }))
        #expect(Migration.shared.registeredMigrators.count == 1)

        // Allow multiple migrators of the same type
        let migratorB = TestMigrator()
        Migration.register(migrator: migratorB)
        #expect(Migration.shared.registeredMigrators.count == 2)
    }
}
