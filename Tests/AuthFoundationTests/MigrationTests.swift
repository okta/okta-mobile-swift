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

import XCTest
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

final class MigrationTests: XCTestCase {
    override func setUpWithError() throws {
        Migration.shared.resetMigrators()
    }
    
    override func tearDownWithError() throws {
        Migration.shared.resetMigrators()
    }
    
    func testMigratorRegistration() throws {
        let migratorA = TestMigrator()
        let migratorB = TestMigrator()
        
        migratorA.needsMigration = false
        migratorB.needsMigration = false
        
        let migration = Migration(migrators: [migratorA, migratorB])

        // Ensure migration is not called when not needed
        XCTAssertFalse(migration.isMigrationNeeded)
        XCTAssertNoThrow(try migration.migrateIfNeeded())
        XCTAssertFalse(migratorA.migrationCalled)
        XCTAssertFalse(migratorB.migrationCalled)
        migratorA.reset()
        migratorB.reset()
        
        // Ensure only necessary migrators are called
        migratorA.needsMigration = true
        XCTAssertTrue(migration.isMigrationNeeded)
        XCTAssertNoThrow(try migration.migrateIfNeeded())
        XCTAssertTrue(migratorA.migrationCalled)
        XCTAssertFalse(migratorB.migrationCalled)
        migratorA.reset()
        migratorB.reset()
        
        // Ensure an exception prevents subsequent migrators from running
        migratorA.needsMigration = true
        migratorA.error = TestMigratorError.generic
        migratorB.needsMigration = true
        XCTAssertTrue(migration.isMigrationNeeded)
        XCTAssertThrowsError(try migration.migrateIfNeeded())
        XCTAssertTrue(migratorA.migrationCalled)
        XCTAssertFalse(migratorB.migrationCalled)
        migratorA.reset()
        migratorB.reset()
    }
    
    func testRegisteredMigrators() throws {
        XCTAssertTrue(Migration.shared.registeredMigrators.isEmpty)

        // Test adding a migrator
        let migratorA = TestMigrator()
        Migration.register(migrator: migratorA)
        XCTAssertTrue(Migration.shared.registeredMigrators.contains(where: { $0 === migratorA }))
        XCTAssertEqual(Migration.shared.registeredMigrators.count, 1)

        // Ensure duplicate migrators aren't added
        Migration.register(migrator: migratorA)
        XCTAssertTrue(Migration.shared.registeredMigrators.contains(where: { $0 === migratorA }))
        XCTAssertEqual(Migration.shared.registeredMigrators.count, 1)

        // Allow multiple migrators of the same type
        let migratorB = TestMigrator()
        Migration.register(migrator: migratorB)
        XCTAssertEqual(Migration.shared.registeredMigrators.count, 2)
    }
}
