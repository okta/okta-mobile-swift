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
@testable import OktaUtilities

enum TestMigratorError: Error {
    case generic
}

class TestMigrator: SDKVersionMigrator, @unchecked Sendable {
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

final class SDKVersionMigrationTests: XCTestCase {
    override func tearDownWithError() throws {
        SDKVersion.Migration.resetMigrators()
    }
    
    func testMigratorRegistration() throws {
        let migratorA = TestMigrator()
        let migratorB = TestMigrator()
        
        migratorA.needsMigration = false
        migratorB.needsMigration = false
        
        let migration = SDKVersion.Migration(migrators: [migratorA, migratorB])

        // Ensure migration is not called when not needed
        XCTAssertFalse(migration.needsMigration)
        XCTAssertNoThrow(try migration.migrate())
        XCTAssertFalse(migratorA.migrationCalled)
        XCTAssertFalse(migratorB.migrationCalled)
        migratorA.reset()
        migratorB.reset()
        
        // Ensure only necessary migrators are called
        migratorA.needsMigration = true
        XCTAssertTrue(migration.needsMigration)
        XCTAssertNoThrow(try migration.migrate())
        XCTAssertTrue(migratorA.migrationCalled)
        XCTAssertFalse(migratorB.migrationCalled)
        migratorA.reset()
        migratorB.reset()
        
        // Ensure an exception prevents subsequent migrators from running
        migratorA.needsMigration = true
        migratorA.error = TestMigratorError.generic
        migratorB.needsMigration = true
        XCTAssertTrue(migration.needsMigration)
        XCTAssertThrowsError(try migration.migrate())
        XCTAssertTrue(migratorA.migrationCalled)
        XCTAssertFalse(migratorB.migrationCalled)
        migratorA.reset()
        migratorB.reset()
    }
    
    func testRegisteredMigrators() throws {
        XCTAssertTrue(SDKVersion.Migration.registeredMigrators.isEmpty)
        
//        let migratorA = TestMigrator()
//        SDKVersion.register(migrator: migratorA)
//        XCTAssertTrue(SDKVersion.Migration.registeredMigrators.contains(where: { $0 === migratorA }))
//        
//        let migration = SDKVersion.Migration()
//        XCTAssertTrue(migration.migrators.contains(where: { $0 === migratorA }))
    }
}
