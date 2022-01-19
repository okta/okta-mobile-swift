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
import TestCommon

final class JWTTests: XCTestCase {
    let accessToken = "eyJraWQiOiJrNkhOMkRLb2sta0V4akpHQkxxZ3pCeU1Dbk4xUnZ6RU9BLTF1a1RqZXhBIiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULko2amxNY1p5TnkxVmk2cnprTEIwbHEyYzBsSHFFSjhwSGN0NHV6aWxhazAub2FyOWVhenlMakFtNm13Wkc0dzQiLCJpc3MiOiJodHRwczovL21pa2UtdGVzdC1vcmcuY2xvdWRpdHVkZS5jb20vb2F1dGgyL2RlZmF1bHQiLCJhdWQiOiJhcGk6Ly9kZWZhdWx0IiwiaWF0IjoxNjQyNTMyNTYyLCJleHAiOjE2NDI1MzYxNjIsImNpZCI6IjBvYTNlbjRmSU1RM2RkYzIwNHc1IiwidWlkIjoiMDB1MnE1cDNhY1ZPWG9TYzA0dzUiLCJzY3AiOlsib2ZmbGluZV9hY2Nlc3MiLCJwcm9maWxlIiwib3BlbmlkIl0sInN1YiI6ImFydGh1ci5kZW50QG9rdGEuY29tIn0.Me-0TPufFrd0l8M9osfUjJesgfwJzOCoV9p9MYlUvGu_jMIpCOaEIeQbDSpx3I4YtgcqXja7xFGFYWwyp4-iFqCxFYe_fEy8hKIRLNj3jvhRazqAF5T-ZSFTY6FCC0LX-TeR8yg1s7yTFODXnJS1IfEgypxz1KtImCFnynkIgVrtpg0fVYYFPiUJImrP5FkKArwBWbNmJInTHDG-7gg0JjKUAxncgTkGl39y72b5xhFoMRQ2nsfsXG0hswG2cahDnCswNhi1jI6fBuhiiPipnhf_jOdtwBt6LbajfDE0IsofhqVTf7EJmikIbf1DbZp0-HR_dh410beQFelveFyaDQ"
    let idToken = "eyJraWQiOiJrNkhOMkRLb2sta0V4akpHQkxxZ3pCeU1Dbk4xUnZ6RU9BLTF1a1RqZXhBIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIwMHUycTVwM2FjVk9Yb1NjMDR3NSIsIm5hbWUiOiJBcnRodXIgRGVudCIsInZlciI6MSwiaXNzIjoiaHR0cHM6Ly9taWtlLXRlc3Qtb3JnLmNsb3VkaXR1ZGUuY29tL29hdXRoMi9kZWZhdWx0IiwiYXVkIjoiMG9hM2VuNGZJTVEzZGRjMjA0dzUiLCJpYXQiOjE2NDI1MzI1NjIsImV4cCI6MTY0MjUzNjE2MiwianRpIjoiSUQuYnI0V20zb1FHZGowZnM4U0NHcktyQ2tfT2lCZ3V0R3JrZ21kaTlVT3BlOCIsImFtciI6WyJwd2QiXSwiaWRwIjoiMDBvMnE1aG1MQUVYVG5abGg0dzUiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJhcnRodXIuZGVudEBva3RhLmNvbSIsImF1dGhfdGltZSI6MTY0MjUzMjU2MSwiYXRfaGFzaCI6IldsY3d6dC1zM3N4T3EwWV9EU3NwYWcifQ.jx4PaNo_xPO7xnhxif7kzzhkhu4wE4E-t8jrlUpwsTwcgvYyVoSFwPdVLnHE4gyD4ERx4rmHyt8JGfzOMxSZb066NPAiM9wRi3ihJogfYBL5Kxae-WGcLzF7MpmOLPmdFQKZN1lIkNLi5Eg6rS2CDUMnXR69MJf5VwoTQK3EqoT8NrYxLiUmqHLSNwdcQytmFVgr-XYcLIDgjn-FLrGZmxMz2at_dFw5PpAGThB4VTDG_k2KIVSa3_NNmCWoOrswKJKp9T7xPcVb1NL9JxLvNxIId2ngbmETjN8tuZ5yE9Uo9q3oUlgPI_7WqyFknQC0pmFBxvDBpFsuI3n2odHFYQ"

    func testAccessToken() throws {
        let token = try JWT(accessToken)
        XCTAssertEqual(token.subject, "arthur.dent@okta.com")
        XCTAssertEqual(token.scope, ["offline_access", "profile", "openid"])
        XCTAssertEqual(token[.userId], "00u2q5p3acVOXoSc04w5")
        XCTAssertEqual(token[.clientId], "0oa3en4fIMQ3ddc204w5")
    }

    func testIdToken() throws {
        let token = try JWT(idToken)
        XCTAssertEqual(token[.preferredUsername], "arthur.dent@okta.com")
        XCTAssertEqual(token[.name], "Arthur Dent")
    }
}
