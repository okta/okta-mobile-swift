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
import Testing

@testable import AuthFoundation
@testable import TestCommon

fileprivate struct TestRequest: APIRequest {
    typealias ResponseType = String

    let url: URL
    var httpMethod: APIRequestMethod { .post }
    var contentType: APIContentType? { .formEncoded }

    let name: String

    init(name: String) throws {
        self.name = name
        self.url = try URL(requiredString: "https://example.com/\(name)")
    }
}

fileprivate struct TestStep: Equatable {
    let name: String
    let interval: TimeInterval
}

fileprivate actor TestContainer {
    private(set) var steps: [TestStep] = []

    func append(_ step: TestStep) {
        steps.append(step)
    }
}

fileprivate enum TestError: Error {
    case test
}

@Suite("APIRequest Polling Handler")
struct APIRequestPollingHandlerTests {
    @Test("Successful polling")
    func testPollingHandler() async throws {
        let container = TestContainer()

        let startTimestamp = Date.timeIntervalSinceReferenceDate
        let poll = try APIRequestPollingHandler<TestRequest, String>(interval: 0.1, options: .delayFirstRequest)
        { pollingHandler, request in
            let currentTimestamp = Date.timeIntervalSinceReferenceDate

            await container.append(.init(name: request.url.pathComponents.last!,
                                         interval: await pollingHandler.interval))
            let stepCount = await container.steps.count

            if stepCount == 0 {
                // Test the initial "delay" supplied to the start function
                #expect(startTimestamp.is(currentTimestamp, accuracy: 0.1))
            }

            if stepCount < 2 {
                return .continue
            } else if stepCount < 4 {
                let newRequest = try TestRequest(name: "zaphod")
                return .continueWith(request: newRequest, interval: 0.2)
            } else if stepCount < 6 {
                return .continueWith(interval: 0.3)
            } else if stepCount < 7 {
                let newRequest = try TestRequest(name: "ford")
                return .continueWith(request: newRequest)
            } else {
                return .success("done")
            }
        }

        let initialRequest = try TestRequest(name: "trillian")
        let result = try await poll.start(with: initialRequest)

        #expect(result == "done")

        let steps = await container.steps
        #expect(steps == [
            .init(name: "trillian", interval: 0.1),
            .init(name: "trillian", interval: 0.1),
            .init(name: "zaphod", interval: 0.2),
            .init(name: "zaphod", interval: 0.2),
            .init(name: "zaphod", interval: 0.3),
            .init(name: "zaphod", interval: 0.3),
            .init(name: "ford", interval: 0.3),
        ])
    }

    @Test("Expiration")
    func testExpiration() async throws {
        let container = TestContainer()
        
        let poll = try APIRequestPollingHandler<TestRequest, String>(
            interval: 0.25,
            expiresIn: 1.0)
        { pollingHandler, request in
            await container.append(.init(name: request.url.pathComponents.last!,
                                         interval: await pollingHandler.interval))
            let stepCount = await container.steps.count
            
            if stepCount > 5 {
                Issue.record("It should have expired by now")
                return .success("Failure")
            }
            
            return .continue
        }
        
        let initialRequest = try TestRequest(name: "request")
        
        let startTime = Date.timeIntervalSinceReferenceDate
        let error = await #expect(throws: APIRequestPollingHandlerError.self) {
            try await poll.start(with: initialRequest)
        }
        let endTime = Date.timeIntervalSinceReferenceDate

        #expect(error == .timeout)

        let steps = await container.steps
        #expect(steps.count.is(4, accuracy: 2))
        #expect((endTime - startTime).is(1.0, accuracy: 0.5))
    }

    @Test("Failure")
    func testFailure() async throws {
        let container = TestContainer()

        let poll = try APIRequestPollingHandler<TestRequest, String>(interval: 0.1)
        { pollingHandler, request in
            await container.append(.init(name: request.url.pathComponents.last!,
                                         interval: await pollingHandler.interval))
            let stepCount = await container.steps.count

            if stepCount < 2 {
                return .continue
            } else {
                return .failure(TestError.test)
            }
        }

        let initialRequest = try TestRequest(name: "request")
        let error = await #expect(throws: TestError.self) {
            try await poll.start(with: initialRequest)
        }

        #expect(error == .test)

        let steps = await container.steps
        #expect(steps.count == 2)
    }

    @Test("HTTP error response handling")
    func testHTTPErrorHandling() async throws {
        let container = TestContainer()

        let poll = try APIRequestPollingHandler<TestRequest, String>(interval: 0.1,
                                                                     slowDownInterval: 0.2)
        { pollingHandler, request in
            await container.append(.init(name: request.url.pathComponents.last!,
                                         interval: await pollingHandler.interval))
            let stepCount = await container.steps.count
            let interval = await pollingHandler.interval

            switch stepCount {
            case 1:
                #expect(interval.is(0.1, accuracy: 0.01))
                return .failure(APIClientError.httpError(OAuth2ServerError(code: "authorization_pending",
                                                                           description: "Authorization pending")))
            case 2:
                #expect(interval.is(0.1, accuracy: 0.01))
                return .failure(APIClientError.httpError(OAuth2ServerError(code: "slow_down",
                                                                           description: "Slow down")))
            case 3:
                #expect(interval.is(0.3, accuracy: 0.01))
                return .failure(APIClientError.httpError(OAuth2ServerError(code: "direct_auth_authorization_pending",
                                                                           description: "Direct Auth Authorization pending")))
            case 4:
                #expect(interval.is(0.3, accuracy: 0.01))
                return .failure(APIClientError.httpError(OAuth2ServerError(code: "slow_down",
                                                                           description: "Slow down")))
            case 5:
                #expect(interval.is(0.5, accuracy: 0.01))
                return .failure(APIClientError.httpError(OAuth2ServerError(code: "slow_down",
                                                                           description: "Slow down")))
            default:
                return .success("done")
            }
        }

        let initialRequest = try TestRequest(name: "http_errors")
        let result = try await poll.start(with: initialRequest)

        #expect(result == "done")

        let steps = await container.steps
        #expect(steps.count == 6)
        #expect(steps[0].interval.is(0.1, accuracy: 0.01))
        #expect(steps[1].interval.is(0.1, accuracy: 0.01))
        #expect(steps[2].interval.is(0.3, accuracy: 0.01))
        #expect(steps[3].interval.is(0.3, accuracy: 0.01))
        #expect(steps[4].interval.is(0.5, accuracy: 0.01))
        #expect(steps[5].interval.is(0.7, accuracy: 0.01))
    }
}
