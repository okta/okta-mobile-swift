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

/**
 * Id tokens are generated from here: https://jwt.io/
 * Header:
 *  {"kid": "FJA0HGNtsuuda_Pl45J42kvQqcsu_0C4Fg7pbJLXTHY","alg": "RS256"}
 * Payload:
 *  {"sub": "00ub41z7mgzNqryMv696","name": "Test User","email": "test@example.com","ver": 1,"iss": "https://example.okta.com/oauth2/default","aud": "unit_test_client_id","iat": 1644347069,"exp": 1644350669,"jti": "ID.55cxBtdYl8l6arKISPBwd0yOT-9UCTaXaQTXt2laRLs","amr": ["pwd"],"idp": "00o8fou7sRaGGwdn4696","sid": "idxWxklp_4kSxuC_nU1pXD-nA","preferred_username": "test@example.com","auth_time": 1644347068,"at_hash": "gMcGTbhGT1G_ldsHoJsPzQ","ds_hash": "DAeLOFRqifysbgsrbOgbog"}
 * Signature Public Key:
 *  -----BEGIN PUBLIC KEY-----
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2xcCZycepeC6tbbIldJ6
    d2qMN/absNkv84h9NA/UzOlrbBil3ZlhZ/1471fOSQ3tJjT+6OcOIH1Wp3JvOurz
    puoGrKRyHJfkPD6jNoGb+5Cm2nCM5k4BJjK4pS/X6fkNhYZO62V1jR8rVNQtuE+O
    AGjDX6QqfhBFZsimScfBF1oA4wmdTIHdfmywweT0uQoGmm0Kymnc8A4Rn3Grp6rb
    mMm9crlF3xC+Aglb4kHb5LRngyPvvP1HcI5vNph7Do09t/6Lm+Wc59ZLKhgeJLXE
    hCZOeUxMo048R/vLkNtq5SUK9glQ3vlOZHl4ldhvCShKuBtyFimkqnkL6ARjYDsM
    +QIDAQAB
    -----END PUBLIC KEY-----
 * Signature Private Key:
 *  -----BEGIN PRIVATE KEY-----
    MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDbFwJnJx6l4Lq1
    tsiV0np3aow39puw2S/ziH00D9TM6WtsGKXdmWFn/XjvV85JDe0mNP7o5w4gfVan
    cm866vOm6gaspHIcl+Q8PqM2gZv7kKbacIzmTgEmMrilL9fp+Q2Fhk7rZXWNHytU
    1C24T44AaMNfpCp+EEVmyKZJx8EXWgDjCZ1Mgd1+bLDB5PS5CgaabQrKadzwDhGf
    caunqtuYyb1yuUXfEL4CCVviQdvktGeDI++8/Udwjm82mHsOjT23/oub5Zzn1ksq
    GB4ktcSEJk55TEyjTjxH+8uQ22rlJQr2CVDe+U5keXiV2G8JKEq4G3IWKaSqeQvo
    BGNgOwz5AgMBAAECggEAZHXZiTk76W3xz08ADQsVUtqNbz/qRh5gyXfFiXDU8Bz8
    P/XRYJprOsbUhFMr6P20x3c3h84jASzX5jIn5MlFbj0TUGibVpcjdah3KJAn2SOM
    Ds/bG+OazUwmtMAKbmPgGmDqoS/Fxi8LrHsad9Aq2e8v3xQk0+dcG3RYI66v0KeA
    Rdq1GQ4DsFyICwWqhbjz0gBx45QGn5U9PPmXrpQpXR//HdUQWmYqth/549Udpt+A
    2S5QSpeK+7kZKzGK1RyOO+Guw4gku1V8NrqKEhCexgGneEXyYc35v1Sie0Zhtn6H
    4yg5zmBMi/KZZFSqEHv46dXgckPJDo0Gb8lUV/JgXQKBgQDz5iQE8zfEkUH3f+Oi
    vuiNzNlBucZEfAvgke+NDu9PNV6wJdUlU21CteDcRBeJIcGrVs8CxgZRIx6JDon3
    sBacykf5JvjZDEbvNs3h6/nuAtMx7PtRFRsyP3swC5KqRDP8Uq6PfE4aE5FsPHah
    97u+FnpI826OyNf/gnwMNXb/pwKBgQDl9cIbIdkJkFFr3iza/bAFj3bOIi4aD/KC
    itJwK/K+FbtQg/sijU3KIOKVjAdVDZ1WADG2lMcftdoav9brPgdgxPWuyeJYIfmX
    1gei9luEQkO0k36CpBkpqT3HWdSoXAoBce+JlyCARssW+zSl1Dc8J8lD2X4FBQqQ
    IjxTX7IiXwKBgQC7iE5TvAs6ShI10pDeNvoq5cJ7BfPL/rFHOA7AICajeb7XpA9S
    huYw8BX4ZybNmzYFn1bGpCqBQoadDZ/J4gxQ/DwA+BVJFmaIUlRVjRL8DhIDhlrq
    ylbB+QuoMo3P+2cZcR2lWAfZhwg+9/KjsQ8bJr9ZzktI4GcsoFDvNkDMawKBgG9X
    0yg391J+Ii5MYQOXmcbXc/rS6eeMmStD9CiD3wDSnOObQ9my+VtJGOy35ET2Vpvx
    dCCnYNKlxnj1Mias3f2o4BxFe+aYbLVr2D67cgxT2Vxxneu7cMOPQm5nvGPYTK/u
    bsD7/6ycmnECKLeyTRw/V2AWysG7cyXerb7gsuuZAoGBAKt6NNVpxqmHB6/Wdqsi
    sct6YBeZSLPuK/PtK5anVwTYlN7Omg2BjS+/yCygNuDp+px9ykHwYicSgDsJxyOt
    1Spw+uMVoNG6yvIE3q7mjhDoHDu5lUA8s6uzzcTsvDnSLR6uNV2iqDzR/Osu3+bp
    QjRCFXd0Tr5PlKpAHb6dk+aI
    -----END PRIVATE KEY-----
 */

import XCTest
@testable import AuthFoundation
import TestCommon

struct MockTokenContext: IDTokenValidatorContext {
    let nonce: String?
    let maxAge: TimeInterval?
}

final class DefaultIDTokenValidatorTests: XCTestCase {
    var validator = DefaultIDTokenValidator()
    let issuer = URL(string: "https://example.okta.com/oauth2/default")!
    let clientId = "unit_test_client_id"
    let baselineTime: TimeInterval = 1644347069 // The date the ID tokens were created
    var mockTime: MockTimeCoordinator!
    
    let validToken = "eyJraWQiOiJGSkEwSEdOdHN1dWRhX1BsNDVKNDJrdlFxY3N1XzBDNEZnN3BiSkxYVEhZIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHViNDF6N21nek5xcnlNdjY5NiIsIm5hbWUiOiJUZXN0IFVzZXIiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJ2ZXIiOjEsImlzcyI6Imh0dHBzOi8vZXhhbXBsZS5va3RhLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6InVuaXRfdGVzdF9jbGllbnRfaWQiLCJpYXQiOjE2NDQzNDcwNjksImV4cCI6MTY0NDM1MDY2OSwianRpIjoiSUQuNTVjeEJ0ZFlsOGw2YXJLSVNQQndkMHlPVC05VUNUYVhhUVRYdDJsYVJMcyIsImFtciI6WyJwd2QiXSwiaWRwIjoiMDBvOGZvdTdzUmFHR3dkbjQ2OTYiLCJzaWQiOiJpZHhXeGtscF80a1N4dUNfblUxcFhELW5BIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidGVzdEBleGFtcGxlLmNvbSIsImF1dGhfdGltZSI6MTY0NDM0NzA2OCwiYXRfaGFzaCI6ImdNY0dUYmhHVDFHX2xkc0hvSnNQelEiLCJkc19oYXNoIjoiREFlTE9GUnFpZnlzYmdzcmJPZ2JvZyJ9.LvWXuIL5oinAfTfZFBo9a2Q1SGZcu9GZZ2LOYbWekRvKw3eFJk8aZHeFDQx3c3J_NpCYqjxlOnb5YJ1emRS2sSU9YOoMjm-15TeM_O5AMHk06jJkBiJlhDr0IaCSXw8dB2Hnj4mfGJ3HxknA8nWnHZUhkzu1196QCHGQwwK-EbYzaQAzkU9itcJZmQObV56rNsvSL4RQUfI1auoz0IAj3gAee-g6O1y7sTdsRmXgtKM8AoKqehBO9QXOdrlv7648Ixo2NgB7iobFLIQ-FxChp_mwhfgqG1RtQBCJGG4eow7ER5lPIYJkUlzgc79sFoiZKo3KZfUFwlwWXPAwAqVdmg"
    
    override func setUpWithError() throws {
        mockTime = MockTimeCoordinator()
        Date.coordinator = mockTime
        
        let offset = baselineTime - Date().timeIntervalSince1970
        mockTime.offset = offset
    }
    
    override func tearDownWithError() throws {
        DefaultTimeCoordinator.resetToDefault()
        mockTime = nil
    }
    
    func testValidIDToken() throws {
        let jwt = try JWT(validToken)
        let validationIntents: [DefaultIDTokenValidator.Intent] = [
            .validateIssuer(token: jwt, issuer: issuer),
            .validateAudience(token: jwt, clientId: clientId),
            .validateScheme(token: jwt),
            .validateAlgorithm(token: jwt),
            .validateExpirationTime(token: jwt),
            .validateIssuedAtTime(token: jwt),
            .validateNonce(token: jwt, context: nil),
            .validateAuthTime(token: jwt, context: nil),
            .validateMaxAge(token: jwt, context: nil),
            .validateSubject(token: jwt)
        ]
        
        XCTAssertNoThrow(try validator.validate(token: jwt, issuer: issuer, clientId: clientId, context: nil))
        
        XCTAssertNoThrow(try validator.validate(using: validationIntents))
    }

    func testInvalidIssuer() throws {
        let jwt = try JWT("eyJraWQiOiJGSkEwSEdOdHN1dWRhX1BsNDVKNDJrdlFxY3N1XzBDNEZnN3BiSkxYVEhZIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHViNDF6N21nek5xcnlNdjY5NiIsIm5hbWUiOiJUZXN0IFVzZXIiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJ2ZXIiOjEsImlzcyI6Imh0dHBzOi8vb3RoZXItc2VydmVyLm9rdGEuY29tIiwiYXVkIjoidW5pdF90ZXN0X2NsaWVudF9pZCIsImlhdCI6MTY0NDM0NzA2OSwiZXhwIjoxNjQ0MzUwNjY5LCJqdGkiOiJJRC41NWN4QnRkWWw4bDZhcktJU1BCd2QweU9ULTlVQ1RhWGFRVFh0MmxhUkxzIiwiYW1yIjpbInB3ZCJdLCJpZHAiOiIwMG84Zm91N3NSYUdHd2RuNDY5NiIsInNpZCI6ImlkeFd4a2xwXzRrU3h1Q19uVTFwWEQtbkEiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiYXV0aF90aW1lIjoxNjQ0MzQ3MDY4LCJhdF9oYXNoIjoiZ01jR1RiaEdUMUdfbGRzSG9Kc1B6USIsImRzX2hhc2giOiJEQWVMT0ZScWlmeXNiZ3NyYk9nYm9nIn0.bYbmOb56ei9cEwGGOdjCP2niCcemeUhuvmIJ02cp9bqCEmtbr9HCGxQFiLXLFX1uj4pa0RBaAFvI25wGG8_3tjBUm1kiwP8bggbG49oGaLslkqdof1f58AU1LED4CmmaJdMV8Rl9h5WXzTv-So5euqonMwDVB04kO9B7jjCwQ1RmjLm4rdfN5_WzMuBXX7ENhELkOjwkEmsB9h_yQtow0RQKHKgJQN9PF_YAR1H2LT0rnCB0aGXF8cbE69qIC-iQ5jpHOh9lQY7QYJJ9CEpugZIbqJP1BEjOVvSNgTa7WzILvs18fvBeQmP6RLE9G8UlvVBNCt8ALekxeH1kEYFSyQ")
        
        XCTAssertThrowsError(try validator.validate(token: jwt, issuer: issuer, clientId: clientId, context: nil)) { error in
            XCTAssertEqual(error as? JWTError, JWTError.invalidIssuer)
        }
        
        XCTAssertThrowsError(try validator.validate(using: [.validateIssuer(token: jwt, issuer: issuer)])) { error in
            XCTAssertEqual(error as? JWTError, JWTError.invalidIssuer)
        }
    }

    func testInvalidAudience() throws {
        let jwt = try JWT("eyJraWQiOiJGSkEwSEdOdHN1dWRhX1BsNDVKNDJrdlFxY3N1XzBDNEZnN3BiSkxYVEhZIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHViNDF6N21nek5xcnlNdjY5NiIsIm5hbWUiOiJUZXN0IFVzZXIiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJ2ZXIiOjEsImlzcyI6Imh0dHBzOi8vZXhhbXBsZS5va3RhLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6Im90aGVyX2NsaWVudF9pZCIsImlhdCI6MTY0NDM0NzA2OSwiZXhwIjoxNjQ0MzUwNjY5LCJqdGkiOiJJRC41NWN4QnRkWWw4bDZhcktJU1BCd2QweU9ULTlVQ1RhWGFRVFh0MmxhUkxzIiwiYW1yIjpbInB3ZCJdLCJpZHAiOiIwMG84Zm91N3NSYUdHd2RuNDY5NiIsInNpZCI6ImlkeFd4a2xwXzRrU3h1Q19uVTFwWEQtbkEiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiYXV0aF90aW1lIjoxNjQ0MzQ3MDY4LCJhdF9oYXNoIjoiZ01jR1RiaEdUMUdfbGRzSG9Kc1B6USIsImRzX2hhc2giOiJEQWVMT0ZScWlmeXNiZ3NyYk9nYm9nIn0.X0E7hCwAsvCUW6kTKDVZMTkxqfZ0wpb5IBmmBJOMxB9xzhz7N041mWXZ2cjNmdP29UuZ4FgFTBoTfc15EiQqLcxkvm4r7mERJv4QjEUtoQPgKIN1xbq3ISzBXsL9pLZvwIPmGSgZGlyzFgUG7-GKdcF7g0kHpOk4237mE78PpvYuo7CK-Ri0uQ_29DGLDUH_KhxI8SH0A5v4wHN75gDfm9LEpgdC0LIONPBCFEyemNFkNhE81YHOSvNCvqaprm3-OfeHKphzsScDc1kem8OL8sga8FT_huqG03y2yYVE5tvqYlq_WB4eMM1QOJTeCqctzM6rNa7yQK8HDrnOu8KCHg")

        XCTAssertThrowsError(try validator.validate(token: jwt, issuer: issuer, clientId: clientId, context: nil)) { error in
            XCTAssertEqual(error as? JWTError, JWTError.invalidAudience)
        }
        
        XCTAssertThrowsError(try validator.validate(using: [.validateAudience(token: jwt, clientId: clientId)])) { error in
            XCTAssertEqual(error as? JWTError, JWTError.invalidAudience)
        }
    }
    
    func testInvalidURLScheme() throws {
        let jwt = try JWT("eyJraWQiOiJGSkEwSEdOdHN1dWRhX1BsNDVKNDJrdlFxY3N1XzBDNEZnN3BiSkxYVEhZIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHViNDF6N21nek5xcnlNdjY5NiIsIm5hbWUiOiJUZXN0IFVzZXIiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJ2ZXIiOjEsImlzcyI6Imh0dHA6Ly9leGFtcGxlLm9rdGEuY29tL29hdXRoMi9kZWZhdWx0IiwiYXVkIjoidW5pdF90ZXN0X2NsaWVudF9pZCIsImlhdCI6MTY0NDM0NzA2OSwiZXhwIjoxNjQ0MzUwNjY5LCJqdGkiOiJJRC41NWN4QnRkWWw4bDZhcktJU1BCd2QweU9ULTlVQ1RhWGFRVFh0MmxhUkxzIiwiYW1yIjpbInB3ZCJdLCJpZHAiOiIwMG84Zm91N3NSYUdHd2RuNDY5NiIsInNpZCI6ImlkeFd4a2xwXzRrU3h1Q19uVTFwWEQtbkEiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiYXV0aF90aW1lIjoxNjQ0MzQ3MDY4LCJhdF9oYXNoIjoiZ01jR1RiaEdUMUdfbGRzSG9Kc1B6USIsImRzX2hhc2giOiJEQWVMT0ZScWlmeXNiZ3NyYk9nYm9nIn0.UMO7oK_YYWPqob7W4jhKdcaUpxyYDKPo33PnJEtzMvv7dSfqLoM9A-E-daVXCqL0-ZER70B2jRonJvOCSKZdXIxgQJtUroVS0rL6Wchda4Yg97gYqvcynRuWaT2i5DHhP-Hq-W0DqseGTlI269-0qy-1fhXqDF0Nvu129GdjCLyUJ1K8WXPp_0tNXl97cmGY3zlNS9VLHoixgy98bBDkUGclIsHYMcE0RPdqFx2YC8n1eHqhqpqA-PTyYB2HibCCylqd28DRGXTY64LJnL9rhgjKm0MPpNC1EhbvFV23eZH_mnX-_ogMtVHCGLt3r8alOlBPlF4cLsuKTbbcZ2E6Sw")
        
        XCTAssertThrowsError(try validator.validate(using: [.validateScheme(token: jwt)])) { error in
            XCTAssertEqual(error as? JWTError, JWTError.issuerRequiresHTTPS)
        }
        
        XCTAssertThrowsError(try validator.validate(token: jwt, issuer: URL(string: "http://example.okta.com/oauth2/default")!, clientId: clientId, context: nil)) { error in
            XCTAssertEqual(error as? JWTError, JWTError.issuerRequiresHTTPS)
        }
    }
    
    func testUnsupportedAlgorithm() throws {
        let jwt = try JWT("eyJraWQiOiJGSkEwSEdOdHN1dWRhX1BsNDVKNDJrdlFxY3N1XzBDNEZnN3BiSkxYVEhZIiwiYWxnIjoiUlMzODQifQ.eyJzdWIiOiIwMHViNDF6N21nek5xcnlNdjY5NiIsIm5hbWUiOiJUZXN0IFVzZXIiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJ2ZXIiOjEsImlzcyI6Imh0dHBzOi8vZXhhbXBsZS5va3RhLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6InVuaXRfdGVzdF9jbGllbnRfaWQiLCJpYXQiOjE2NDQzNDcwNjksImV4cCI6MTY0NDM1MDY2OSwianRpIjoiSUQuNTVjeEJ0ZFlsOGw2YXJLSVNQQndkMHlPVC05VUNUYVhhUVRYdDJsYVJMcyIsImFtciI6WyJwd2QiXSwiaWRwIjoiMDBvOGZvdTdzUmFHR3dkbjQ2OTYiLCJzaWQiOiJpZHhXeGtscF80a1N4dUNfblUxcFhELW5BIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidGVzdEBleGFtcGxlLmNvbSIsImF1dGhfdGltZSI6MTY0NDM0NzA2OCwiYXRfaGFzaCI6ImdNY0dUYmhHVDFHX2xkc0hvSnNQelEiLCJkc19oYXNoIjoiREFlTE9GUnFpZnlzYmdzcmJPZ2JvZyJ9.1Wnn-ozvVDJHwYrxCoWtiTZnNgb2E1ySyplbngwFF7-gi8FN5VNLMHYH0JitIp-SXB2lfoXZBfx0C5HPC1mYyqOTfc0eysvo3WAdAfDbK2H3Du5hGwt-dedPZjePM3f-vGTcNmKCWE0OjjaPn8wVJzl0iyCQ94EhVptc6zL2vTBnHFkV_TMlB0uqgzaixPhl9JYBKXqbGSg_olpnaKbpYBOR2Fq-yBk3Z9b44JjzhjYI5oRp_9xul6nCXt1RJTFg0qflHAN2LgqoFuvlNMmXRhy_F0CP4U4N35s-X2l_Qd74LwP5X1AmucBPvv2OCdJJo9KRl9Up-7tCBB1Pc2Oxrg")
        
        XCTAssertThrowsError(try validator.validate(token: jwt, issuer: issuer, clientId: clientId, context: nil)) { error in
            XCTAssertEqual(error as? JWTError, JWTError.unsupportedAlgorithm(.rs384))
        }
        
        XCTAssertThrowsError(try validator.validate(using: [.validateAlgorithm(token: jwt)])) { error in
            XCTAssertEqual(error as? JWTError, JWTError.unsupportedAlgorithm(.rs384))
        }
    }

    func testExpired() throws {
        mockTime?.offset = 0
        let jwt = try JWT("eyJraWQiOiJGSkEwSEdOdHN1dWRhX1BsNDVKNDJrdlFxY3N1XzBDNEZnN3BiSkxYVEhZIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHViNDF6N21nek5xcnlNdjY5NiIsIm5hbWUiOiJUZXN0IFVzZXIiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJ2ZXIiOjEsImlzcyI6Imh0dHBzOi8vZXhhbXBsZS5va3RhLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6InVuaXRfdGVzdF9jbGllbnRfaWQiLCJpYXQiOjE2NDQzNDcwNjksImV4cCI6MTY0NDM1MDY2OSwianRpIjoiSUQuNTVjeEJ0ZFlsOGw2YXJLSVNQQndkMHlPVC05VUNUYVhhUVRYdDJsYVJMcyIsImFtciI6WyJwd2QiXSwiaWRwIjoiMDBvOGZvdTdzUmFHR3dkbjQ2OTYiLCJzaWQiOiJpZHhXeGtscF80a1N4dUNfblUxcFhELW5BIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidGVzdEBleGFtcGxlLmNvbSIsImF1dGhfdGltZSI6MTY0NDM0NzA2OCwiYXRfaGFzaCI6ImdNY0dUYmhHVDFHX2xkc0hvSnNQelEiLCJkc19oYXNoIjoiREFlTE9GUnFpZnlzYmdzcmJPZ2JvZyJ9.LvWXuIL5oinAfTfZFBo9a2Q1SGZcu9GZZ2LOYbWekRvKw3eFJk8aZHeFDQx3c3J_NpCYqjxlOnb5YJ1emRS2sSU9YOoMjm-15TeM_O5AMHk06jJkBiJlhDr0IaCSXw8dB2Hnj4mfGJ3HxknA8nWnHZUhkzu1196QCHGQwwK-EbYzaQAzkU9itcJZmQObV56rNsvSL4RQUfI1auoz0IAj3gAee-g6O1y7sTdsRmXgtKM8AoKqehBO9QXOdrlv7648Ixo2NgB7iobFLIQ-FxChp_mwhfgqG1RtQBCJGG4eow7ER5lPIYJkUlzgc79sFoiZKo3KZfUFwlwWXPAwAqVdmg")
        XCTAssertThrowsError(try validator.validate(using: [.validateExpirationTime(token: jwt)])) { error in
            XCTAssertEqual(error as? JWTError, JWTError.expired)
        }
                             
        XCTAssertThrowsError(try validator.validate(token: jwt, issuer: issuer, clientId: clientId, context: nil)) { error in
            XCTAssertEqual(error as? JWTError, JWTError.expired)
        }
    }

    func testIssuedAtExceedsGracePeriod() throws {
        mockTime?.offset += 320
        let jwt = try JWT(validToken)
        
        XCTAssertThrowsError(try validator.validate(using: [.validateIssuedAtTime(token: jwt)])) { error in
            XCTAssertEqual(error as? JWTError, JWTError.issuedAtTimeExceedsGraceInterval)
        }
        
        XCTAssertThrowsError(try validator.validate(token: jwt, issuer: issuer, clientId: clientId, context: nil)) { error in
            XCTAssertEqual(error as? JWTError, JWTError.issuedAtTimeExceedsGraceInterval)
        }
    }
    
    func testNonce() throws {
        let jwt = try JWT("eyJraWQiOiJGSkEwSEdOdHN1dWRhX1BsNDVKNDJrdlFxY3N1XzBDNEZnN3BiSkxYVEhZIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHViNDF6N21nek5xcnlNdjY5NiIsIm5hbWUiOiJUZXN0IFVzZXIiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJ2ZXIiOjEsImlzcyI6Imh0dHBzOi8vZXhhbXBsZS5va3RhLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6InVuaXRfdGVzdF9jbGllbnRfaWQiLCJpYXQiOjE2NDQzNDcwNjksImV4cCI6MTY0NDM1MDY2OSwianRpIjoiSUQuNTVjeEJ0ZFlsOGw2YXJLSVNQQndkMHlPVC05VUNUYVhhUVRYdDJsYVJMcyIsImFtciI6WyJwd2QiXSwiaWRwIjoiMDBvOGZvdTdzUmFHR3dkbjQ2OTYiLCJzaWQiOiJpZHhXeGtscF80a1N4dUNfblUxcFhELW5BIiwicHJlZmVycmVkX3VzZXJuYW1lIjoidGVzdEBleGFtcGxlLmNvbSIsImF1dGhfdGltZSI6MTY0NDM0NzA2OCwiYXRfaGFzaCI6ImdNY0dUYmhHVDFHX2xkc0hvSnNQelEiLCJkc19oYXNoIjoiREFlTE9GUnFpZnlzYmdzcmJPZ2JvZyIsIm5vbmNlIjoiQjM0QUFFMDEtNTc1Ny00QTBCLTkzNjItQjAyRjZGMDJBM0IxIn0.Ac8qsEiu0nbQoUszIdB_fkrFHVKBd5g2r-fkK_lPZ8_lyxZSJzj6saoA3746dh6wpZxcEwJikrFsoEEWMdHZITx8fou3TiYSffk-6z2VKivk0xeGMQxh5fh9tlSfYwHFf1K4LDyNr9bsNF8HMmdlOf-JJv9YU6scpr9VnYGnF4JgMVtlGqlIq56fmjjWry-SYZU6hjlHcdYOKg5UKspz1JMvN403HegZIcPOmvFcIlumgZYXk3TO7gWlMwD2WLRoqurjUuvhFYkfoNgKnElTQeAWi20lb2p43XBn4fU_jJse49lXw3cBw_hEU9bK_i3GB1z3K-YZEeWhX8JXBi9Ilg")
        
        XCTAssertThrowsError(try validator.validate(using: [.validateNonce(token: jwt, context: nil)])) { error in
            XCTAssertEqual(error as? JWTError, JWTError.nonceMismatch)
        }
        
        XCTAssertThrowsError(try validator.validate(token: jwt, issuer: issuer, clientId: clientId, context: nil)) { error in
            XCTAssertEqual(error as? JWTError, JWTError.nonceMismatch)
        }

        XCTAssertThrowsError(try validator.validate(using: [.validateNonce(token: jwt, context: MockTokenContext(nonce: "does_not_match", maxAge: nil))])) { error in
            XCTAssertEqual(error as? JWTError, JWTError.nonceMismatch)
        }
        
        XCTAssertThrowsError(try validator.validate(token: jwt, issuer: issuer, clientId: clientId, context: MockTokenContext(nonce: "does_not_match", maxAge: nil))) { error in
            XCTAssertEqual(error as? JWTError, JWTError.nonceMismatch)
        }
        
        XCTAssertNoThrow(try validator.validate(using: [.validateNonce(token: jwt, context: MockTokenContext(nonce: "B34AAE01-5757-4A0B-9362-B02F6F02A3B1", maxAge: nil))]))
        
        XCTAssertNoThrow(try validator.validate(token: jwt, issuer: issuer, clientId: clientId, context: MockTokenContext(nonce: "B34AAE01-5757-4A0B-9362-B02F6F02A3B1", maxAge: nil)))
    }

    func testMissingSubject() throws {
        let jwt = try JWT("eyJraWQiOiJGSkEwSEdOdHN1dWRhX1BsNDVKNDJrdlFxY3N1XzBDNEZnN3BiSkxYVEhZIiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImlzcyI6Imh0dHBzOi8vZXhhbXBsZS5va3RhLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6InVuaXRfdGVzdF9jbGllbnRfaWQiLCJpYXQiOjE2NDQzNDcwNjksImV4cCI6MTY0NDM1MDY2OSwianRpIjoiSUQuNTVjeEJ0ZFlsOGw2YXJLSVNQQndkMHlPVC05VUNUYVhhUVRYdDJsYVJMcyIsImFtciI6WyJwd2QiXSwiaWRwIjoiMDBvOGZvdTdzUmFHR3dkbjQ2OTYiLCJzaWQiOiJpZHhXeGtscF80a1N4dUNfblUxcFhELW5BIiwiYXV0aF90aW1lIjoxNjQ0MzQ3MDY4fQ.SJSlvVEdwQh29Fi2Py4cNEvGSU8tuutsQlAhTJNpT40g_EuXRFIXOk7x6XII2r0ymN5oJBUP1ZTxi2-ME1JdeM6Dhp2BZEZg-uFW7bCGHDS5c_PlqISWydiXs74BbnyMFX2kX5aJHVOcWW_XC8z-A127i-Ur3cAhrptDPpajpYDg9tTTsURENXwBAn2vVNWEmDCC1h8A8lhlJniEIj3pjHnNnq6Lr-L2P_aSm6yiD4MnuBOToJ9hRRAWGvOz7LkmVuqBEIJY7k1LXEdakBC3eyFx-xJjjTfSx8JBx5VEnaPVwl_MDr3h3wJjW9idpUML_-NtMR2RmPS4PgDD1pS4gQ")

        XCTAssertThrowsError(try validator.validate(using: [.validateSubject(token: jwt)])) { error in
            XCTAssertEqual(error as? JWTError, JWTError.invalidSubject)
        }
        
        XCTAssertThrowsError(try validator.validate(token: jwt, issuer: issuer, clientId: clientId, context: nil)) { error in
            XCTAssertEqual(error as? JWTError, JWTError.invalidSubject)
        }
    }
    
    func testInvalidAuthTime() throws {
        let jwt = try JWT("eyJraWQiOiJGSkEwSEdOdHN1dWRhX1BsNDVKNDJrdlFxY3N1XzBDNEZnN3BiSkxYVEhZIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHViNDF6N21nek5xcnlNdjY5NiIsInZlciI6MSwiaXNzIjoiaHR0cHM6Ly9leGFtcGxlLm9rdGEuY29tL29hdXRoMi9kZWZhdWx0IiwiYXVkIjoidW5pdF90ZXN0X2NsaWVudF9pZCIsImlhdCI6MTY0NDM0NzM2OSwiZXhwIjoxNjQ0MzUwOTY5LCJqdGkiOiJJRC41NWN4QnRkWWw4bDZhcktJU1BCd2QweU9ULTlVQ1RhWGFRVFh0MmxhUkxzIiwiYW1yIjpbInB3ZCJdLCJpZHAiOiIwMG84Zm91N3NSYUdHd2RuNDY5NiIsInNpZCI6ImlkeFd4a2xwXzRrU3h1Q19uVTFwWEQtbkEifQ.04MxyXdDjihUpRKPYyBuHEbxVTlAfVk4Jm7_Of1eZ1SybQNRIEEgEEcvUzMv2VNjLOVpkJJ6mWuozrV6HgG-gEbhQvweVVhJld1dxkAGb0Z7z6ESBA-ZXvVMfm7BYip3aIdcyn7PN-2VD5r92-gvhRbZikwYaDMNLpnyfi1sZysPt251E4YOmmmxyFgKNz2kofFtEef2c1tT1Il0ILt1HYpwDA0RntRdrJKVsJryAuvl0IYIvHi8qrGuy36TM0XgMEtA_Tw_qt8662l4EhVxyLx6lrStnqeokF83g0PCT1tUaEH1bQHaJ5Q0dOkYIRFKwxdXz8YzjQO6rcObEKVPYg")

        XCTAssertNoThrow(try validator.validate(using: [.validateAuthTime(token: jwt, context: nil)]))
        
        XCTAssertNoThrow(try validator.validate(token: jwt, issuer: issuer, clientId: clientId, context: nil))

        XCTAssertThrowsError(try validator.validate(token: jwt, issuer: issuer, clientId: clientId, context: MockTokenContext(nonce: nil, maxAge: 300))) { error in
            XCTAssertEqual(error as? JWTError, JWTError.invalidAuthenticationTime)
        }
        
        XCTAssertThrowsError(try validator.validate(using: [.validateAuthTime(token: jwt, context: MockTokenContext(nonce: nil, maxAge: 300))])) { error in
            XCTAssertEqual(error as? JWTError, JWTError.invalidAuthenticationTime)
        }
    }

    func testExceedsMaxAge() throws {
        let jwt = try JWT("eyJraWQiOiJGSkEwSEdOdHN1dWRhX1BsNDVKNDJrdlFxY3N1XzBDNEZnN3BiSkxYVEhZIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHViNDF6N21nek5xcnlNdjY5NiIsInZlciI6MSwiaXNzIjoiaHR0cHM6Ly9leGFtcGxlLm9rdGEuY29tL29hdXRoMi9kZWZhdWx0IiwiYXVkIjoidW5pdF90ZXN0X2NsaWVudF9pZCIsImlhdCI6MTY0NDM0NzM2OSwiZXhwIjoxNjQ0MzUwOTY5LCJqdGkiOiJJRC41NWN4QnRkWWw4bDZhcktJU1BCd2QweU9ULTlVQ1RhWGFRVFh0MmxhUkxzIiwiYW1yIjpbInB3ZCJdLCJpZHAiOiIwMG84Zm91N3NSYUdHd2RuNDY5NiIsInNpZCI6ImlkeFd4a2xwXzRrU3h1Q19uVTFwWEQtbkEiLCJhdXRoX3RpbWUiOjE2NDQzNDcwNjh9.fvcOQ1wUMu-ODi6WIVwKIZb4Q1wvK_aHUOZ-l3TlZCNuywqcv96_ziv9n5CI9YKKForZjTJCmbJ6r9aXDdhKC2sz6M17NRpe8QbtKkFrXITOcEOOK3OYvTUQAK0ctsuXRdnP4m9s_F938o_xciWIhx_9eMw2RXZ_bO5avlPDWkHQ8frXhEo2dDlrCG5nsERV7c352KsPCKm5p7Z0ymV5lblW68vHYf3VyWwxnzhooajz5iuIa8GRt8QjRZJ9A_6Jo7Vk5LR8uCTEckkE1cNLAQGf_d2-2fjsg6vGzmvY8s9_ulFX3VXxoO91bJtoHu3jSYUbu2yrMpiZwX9-Ql4q3Q")

        XCTAssertNoThrow(try validator.validate(using: [.validateMaxAge(token: jwt, context: nil)]))
        
        XCTAssertNoThrow(try validator.validate(token: jwt, issuer: issuer, clientId: clientId, context: nil))

        XCTAssertNoThrow(try validator.validate(using: [.validateMaxAge(token: jwt, context: MockTokenContext(nonce: nil, maxAge: 400))]))
        
        XCTAssertNoThrow(try validator.validate(token: jwt, issuer: issuer, clientId: clientId, context: MockTokenContext(nonce: nil, maxAge: 400)))

        XCTAssertThrowsError(try validator.validate(using: [.validateMaxAge(token: jwt, context: MockTokenContext(nonce: nil, maxAge: 200))])) { error in
            XCTAssertEqual(error as? JWTError, JWTError.exceedsMaxAge)
        }
        
        XCTAssertThrowsError(try validator.validate(token: jwt, issuer: issuer, clientId: clientId, context: MockTokenContext(nonce: nil, maxAge: 200))) { error in
            XCTAssertEqual(error as? JWTError, JWTError.exceedsMaxAge)
        }
    }
}
