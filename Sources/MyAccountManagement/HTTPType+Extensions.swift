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
import HTTPTypes
import OpenAPIRuntime

extension HTTPBody {
    var data: Data {
        get async throws {
            var data = Data()
            for try await chunk in self {
                data.append(contentsOf: chunk)
            }
            return data
        }
    }
    
    convenience init?(data: Data) {
        guard !data.isEmpty else {
            return nil
        }
        
        let bytes = [UInt8](data)
        self.init(bytes, length: .known(Int64(data.count)))
    }
}

extension HTTPResponse {
    init?(response: URLResponse) {
        guard let response = response as? HTTPURLResponse
        else {
            return nil
        }
        
        let headers = response.allHeaderFields.reduce(into: [HTTPField]()) { result, pair in
            guard let key = pair.key as? String,
                  let name = HTTPField.Name(key),
                  let value = pair.value as? String
            else {
                return
            }
            result.append(HTTPField(name: name, value: value))
        }

        self.init(status: HTTPResponse.Status(code: response.statusCode),
                  headerFields: HTTPFields(headers))
    }
}
