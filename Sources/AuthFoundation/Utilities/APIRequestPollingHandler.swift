//
// Copyright (c) 2025-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

@_documentation(visibility: internal)
public enum APIRequestPollingHandlerError: Error {
    case invalidInterval
    case alreadyStarted
    case missingRequest
    case timeout
}

/// Utility actor class used to represent a pollable request.
@_documentation(visibility: internal)
public actor APIRequestPollingHandler<RequestType: Sendable, ResultType: Sendable> {
    public typealias OperationBlock = @Sendable (_ pollingHandler: APIRequestPollingHandler<RequestType, ResultType>,
                                       _ request: RequestType) async throws -> Status
    
    /// Status of an individual poll request.
    public enum Status: Sendable {
        case `continue`
        case continueWith(request: RequestType? = nil, interval: TimeInterval? = nil)
        case success(ResultType)
        case failure(any Error)
    }

    public private(set) var isActive: Bool = false
    public private(set) var interval: TimeInterval
    public let slowDownInterval: TimeInterval
    public let expirationDate: Date?
    public private(set) var nextRequest: RequestType?
    
    private let operationBlock: OperationBlock

    public init(interval: TimeInterval = 5.0,
                expiresIn: TimeInterval? = nil,
                slowDownInterval: TimeInterval = 5.0,
                operation block: @escaping OperationBlock) throws
    {
        guard interval > 0 else {
            throw APIRequestPollingHandlerError.invalidInterval
        }
        
        self.interval = interval
        self.slowDownInterval = slowDownInterval
        self.operationBlock = block

        if let expiresIn = expiresIn {
            self.expirationDate = Date(timeIntervalSinceNow: expiresIn)
        } else {
            self.expirationDate = nil
        }
    }

    deinit {
        isActive = false
    }
    
    /// Starts a polling operation, beginning with the given request.
    /// - Parameters:
    ///   - request: Request definition to perform
    ///   - delay: Optional delay before the request should begin.
    /// - Returns: The expected successful response result.
    public func start(with request: RequestType, delay: TimeInterval? = nil) async throws -> ResultType {
        guard !isActive else {
            throw APIRequestPollingHandlerError.alreadyStarted
        }

        isActive = true
        nextRequest = request

        var delay = delay ?? 0.0
        pollLoop: while isActive {
            if delay > 0 {
                try await Task.sleep(delay: delay)
            } else {
                delay = interval
            }

            try Task.checkCancellation()

            if let expirationDate = expirationDate,
               Date() > expirationDate
            {
                break pollLoop
            }
            
            let status: Status
            do {
                guard let request = nextRequest else {
                    throw APIRequestPollingHandlerError.missingRequest
                }
                status = try await operationBlock(self, request)
            } catch {
                status = .failure(error)
            }
            
            switch status {
            case .success(let response):
                isActive = false
                return response
            case .continueWith(request: let newRequest, interval: let newInterval):
                if let newRequest = newRequest {
                    nextRequest = newRequest
                }
                if let newInterval = newInterval {
                    interval = newInterval
                }
                fallthrough
            case .continue:
                delay = interval
            case .failure(let error):
                if let error = error as? APIClientError,
                   case .httpError(let serverError) = error,
                   let oauthError = serverError as? OAuth2ServerError
                {
                    switch oauthError.code {
                    case .slowDown:
                        interval += slowDownInterval
                        continue pollLoop
                    case .authorizationPending, .directAuthAuthorizationPending:
                        continue pollLoop
                    default: break
                    }
                }

                isActive = false
                throw error
            }
        }
        
        isActive = false
        throw APIRequestPollingHandlerError.timeout
    }
}
