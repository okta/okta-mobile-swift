//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
import AuthFoundation

extension Response {
    internal convenience init(flow: InteractionCodeFlowAPI, ion response: IonResponse) throws {
        let authenticators = try Authenticator.Collection(flow: flow, ion: response)
        let remediations = Remediation.Collection(flow: flow, ion: response)
        let successRemediationOption = Remediation(flow: flow, ion: response.successWithInteractionCode)
        let messages = Response.Message.Collection(messages: response.messages?.value.compactMap { Response.Message(flow: flow, ion: $0) },
                                                   nestedMessages: remediations.nestedMessages())
        
        self.init(flow: flow,
                  expiresAt: response.expiresAt,
                  intent: Intent(string: response.intent),
                  authenticators: authenticators,
                  remediations: remediations,
                  successRemediationOption: successRemediationOption,
                  messages: messages,
                  app: Response.Application(ion: response.app?.value),
                  user: Response.User(ion: response.user?.value))

        try loadRelatedObjects()
    }
}

extension Response.Message {
    internal convenience init?(flow: InteractionCodeFlowAPI, ion object: IonMessage?) {
        guard let object = object else { return nil }
        self.init(type: object.type,
                  localizationKey: object.i18n?.key,
                  message: object.message)
    }
}

extension Response.Application {
    internal init?(ion object: IonApp?) {
        guard let object = object else { return nil }
        self.init(id: object.id,
                  label: object.label,
                  name: object.name)
    }
}

extension Response.User {
    internal init?(ion object: IonUser?) {
        guard let object = object,
              let userId = object.id
        else { return nil }
        self.init(id: userId)
    }
}

extension IonResponse {
    struct AuthenticatorMapping {
        let jsonPath: String
        let authenticator: IonAuthenticator
    }

    func authenticatorState(for authenticators: [IonAuthenticator],
                            in jsonPaths: [String]) -> Authenticator.State
    {
        var state = [OktaIdx.Authenticator.State]()
        state = jsonPaths.reduce(into: state, { state, jsonPath in
            switch jsonPath {
            case "$.currentAuthenticatorEnrollment":
                state.append(.enrolling)
                
            case "$.currentAuthenticator":
                state.append(.authenticating)
                
            case "$.recoveryAuthenticator":
                state.append(.recovery)
                
            default:
                if jsonPath.hasPrefix("$.authenticatorEnrollments") {
                    state.append(.enrolled)
                }
                
                else if jsonPath.hasPrefix("$.authenticators") {
                    state.append(.normal)
                }
            }
        })
        
        return state.sorted(by: { $0 > $1 }).first ?? .normal
    }
    
    func allAuthenticators() -> [AuthenticatorMapping] {
        var allAuthenticators: [AuthenticatorMapping] = []
        if let authenticator = currentAuthenticatorEnrollment?.value {
            allAuthenticators.append(.init(jsonPath: "$.currentAuthenticatorEnrollment",
                                           authenticator: authenticator))
        }
        
        if let authenticator = currentAuthenticator?.value {
            allAuthenticators.append(.init(jsonPath: "$.currentAuthenticator",
                                           authenticator: authenticator))
        }
        
        if let authenticator = recoveryAuthenticator?.value {
            allAuthenticators.append(.init(jsonPath: "$.recoveryAuthenticator",
                                           authenticator: authenticator))
        }
        
        if let authenticators = authenticatorEnrollments?.value,
           !authenticators.isEmpty
        {
            for index in 0 ... authenticators.count - 1 {
                allAuthenticators.append(.init(jsonPath: "$.authenticatorEnrollments.value[\(index)]",
                                               authenticator: authenticators[index]))
            }
        }
        
        if let authenticators = authenticators?.value,
           !authenticators.isEmpty
        {
            for index in 0 ... authenticators.count - 1 {
                allAuthenticators.append(.init(jsonPath: "$.authenticators.value[\(index)]",
                                               authenticator: authenticators[index]))
            }
        }

        return allAuthenticators
    }
}

extension Capability.PasswordSettings {
    init?(with settings: [String: JSONValue]?) {
        guard let settings = settings,
              let complexity = settings["complexity"]?.toAnyObject() as? [String: Any]
        else { return nil }
        
        self.init(daysToExpiry: settings["daysToExpiry"]?.numberValue() as? Int ?? 0,
                  minLength: complexity["minLength"] as? Int ?? 0,
                  minLowerCase: complexity["minLowerCase"] as? Int ?? 0,
                  minUpperCase: complexity["minUpperCase"] as? Int ?? 0,
                  minNumber: complexity["minNumber"] as? Int ?? 0,
                  minSymbol: complexity["minSymbol"] as? Int ?? 0,
                  excludeUsername: complexity["excludeUsername"] as? Bool ?? false,
                  excludeAttributes: complexity["excludeAttributes"] as? [String] ?? [])
    }
}

extension Authenticator.Collection {
    convenience init(flow: InteractionCodeFlowAPI, ion object: IonResponse) throws {
        let authenticatorMapping: [String: [IonResponse.AuthenticatorMapping]]
        authenticatorMapping = object
            .allAuthenticators()
            .reduce(into: [:]) { (result, mapping) in
                let authenticatorType = "\(mapping.authenticator.type):\(mapping.authenticator.id ?? "-")"
                var collection: [IonResponse.AuthenticatorMapping] = result[authenticatorType] ?? []
                collection.append(mapping)
                result[authenticatorType] = collection
            }
        
        let authenticators: [Authenticator] = try authenticatorMapping
            .values
            .compactMap({ (mappingArray) in
                return try Authenticator.makeAuthenticator(flow: flow,
                                                                     ion: mappingArray.map(\.authenticator),
                                                                     jsonPaths: mappingArray.map(\.jsonPath),
                                                                     in: object)
            })
        
        self.init(authenticators: authenticators)
    }
}

extension Remediation.Collection {
    convenience init(flow: InteractionCodeFlowAPI, ion object: IonResponse?) {
        var remediations: [Remediation] = object?.remediation?.value.compactMap { (value) in
            Remediation.makeRemediation(flow: flow, ion: value)
        } ?? []
        
        if let cancelResponse = Remediation.makeRemediation(flow: flow, ion: object?.cancel) {
            remediations.append(cancelResponse)
        }

        if let successResponse = Remediation.makeRemediation(flow: flow, ion: object?.successWithInteractionCode) {
            remediations.append(successResponse)
        }
        
        self.init(remediations: remediations)
    }
}

extension Capability.Sendable {
    init?(flow: InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        guard let authenticator = authenticators.compactMap(\.send).first,
              let remediation = Remediation.makeRemediation(flow: flow, ion: authenticator)
        else {
            return nil
        }
        self.init(remediation: remediation)
    }
}

extension Capability.Resendable {
    init?(flow: InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        guard let authenticator = authenticators.compactMap(\.resend).first,
              let remediation = Remediation.makeRemediation(flow: flow, ion: authenticator)
        else {
            return nil
        }
        self.init(remediation: remediation)
    }
}

extension Capability.Recoverable {
    init?(flow: InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        guard let authenticator = authenticators.compactMap(\.recover).first,
              let remediation = Remediation.makeRemediation(flow: flow, ion: authenticator)
        else {
            return nil
        }
        self.init(remediation: remediation)
    }
}

extension Capability.Pollable {
    convenience init?(flow: InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        guard let typeName = authenticators.first?.type,
              let authenticator = authenticators.compactMap(\.poll).first,
              let remediation = Remediation.makeRemediation(flow: flow, ion: authenticator)
        else {
            return nil
        }
        
        let type = Authenticator.Kind(string: typeName)
        self.init(flow: flow,
                  authenticatorType: type,
                  remediation: remediation)
    }

    convenience init?(flow: InteractionCodeFlowAPI, ion form: IonForm) {
        guard form.name == "enroll-poll" ||
                form.name == "challenge-poll"
        else {
            return nil
        }
        guard let remediation = Remediation.makeRemediation(flow: flow,
                                                                      ion: form,
                                                                      createCapabilities: false)
        else {
            return nil
        }
        
        self.init(flow: flow,
                  authenticatorType: .app,
                  remediation: remediation)
    }
}

extension Capability.NumberChallenge {
    init?(flow: InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        guard let answer = authenticators.compactMap(\.contextualData?["correctAnswer"]).first?.stringValue()
        else {
            return nil
        }
        
        self.init(correctAnswer: answer)
    }
}

extension Capability.Profile {
    init?(flow: InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        guard let profile = authenticators.compactMap(\.profile).first
        else {
            return nil
        }
        
        self.init(profile: profile)
    }
}

extension Capability.PasswordSettings {
    init?(flow: InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        guard let typeName = authenticators.first?.type,
              Authenticator.Kind(string: typeName) == .password,
              let settings = authenticators.compactMap(\.settings).first
        else {
            return nil
        }
        
        self.init(with: settings)
    }
}

extension Capability.OTP {
    init?(flow: InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        let methods = methodTypes(from: authenticators)
        guard methods.contains(.otp) || methods.contains(.totp)
        else {
            return nil
        }
        
        guard let typeName = authenticators.first?.type else { return nil }
        let type = Authenticator.Kind(string: typeName)
        
        guard type == .app,
              let contextualData = authenticators.compactMap(\.contextualData).first,
              let qrcode = contextualData["qrcode"]?.toAnyObject() as? [String: String],
              qrcode["method"] == "embedded",
              let mimeType = qrcode["type"],
              let imageUrlString = qrcode["href"],
              let imageData = imageUrlString.base64ImageData
        else {
            return nil
        }
        
        let sharedSecret = contextualData["sharedSecret"]?.stringValue()

        self.init(mimeType: mimeType,
                  imageData: imageData,
                  sharedSecret: sharedSecret)
    }
}

extension Capability.SocialIDP {
    init?(flow: InteractionCodeFlowAPI, ion object: IonForm) {
        let type = Remediation.RemediationType(string: object.name)
        guard type == .redirectIdp,
              let idpObject = object.idp,
              let idpId = idpObject["id"],
              let idpName = idpObject["name"],
              let idpType = object.type
        else {
            return nil
        }

        self.init(redirectUrl: object.href,
                  id: idpId,
                  idpName: idpName,
                  idpType: idpType,
                  service: .init(string: idpType))
    }
}

private func methodTypes(from authenticators: [IonAuthenticator]) -> [Authenticator.Method]
{
    let methods = authenticators
        .compactMap(\.methods)
        .reduce(into: [String: String]()) { (partialResult, items: [[String: String]]) in
            items.forEach { item in
                item.forEach { (key: String, value: String) in
                    partialResult[key] = value
                }
            }
        }
    let methodTypes: [Authenticator.Method] = methods
        .filter { (key, value) in
            key == "type"
        }
        .map { (key, value) in
            return Authenticator.Method(string: value)
        }
    return methodTypes
}

extension Authenticator {
    static func makeAuthenticator(flow: InteractionCodeFlowAPI,
                                  ion authenticators: [IonAuthenticator],
                                  jsonPaths: [String],
                                  in response: IonResponse) throws -> Authenticator?
    {
        guard let first = authenticators.first else { return nil }

        let filteredTypes = Set(authenticators.map(\.type))
        guard filteredTypes.count == 1 else {
            throw InteractionCodeFlowError.internalMessage("Some mapped authenticators have differing types: \(filteredTypes.joined(separator: ", "))")
        }
        
        let state = response.authenticatorState(for: authenticators, in: jsonPaths)
        let key = authenticators.compactMap(\.key).first
        let methods = authenticators.compactMap(\.methods).first

        let capabilities: [AuthenticatorCapability?] = [
            Capability.Profile(flow: flow, ion: authenticators),
            Capability.Sendable(flow: flow, ion: authenticators),
            Capability.Resendable(flow: flow, ion: authenticators),
            Capability.Pollable(flow: flow, ion: authenticators),
            Capability.Recoverable(flow: flow, ion: authenticators),
            Capability.PasswordSettings(flow: flow, ion: authenticators),
            Capability.NumberChallenge(flow: flow, ion: authenticators),
            Capability.OTP(flow: flow, ion: authenticators)
        ]
        
        return Authenticator(flow: flow,
                                       v1JsonPaths: jsonPaths,
                                       state: state,
                                       id: first.id,
                                       displayName: first.displayName,
                                       type: first.type,
                                       key: key,
                                       methods: methods,
                                       capabilities: capabilities.compactMap { $0 })
    }
}

extension Remediation {
    static func makeRemediation(flow: InteractionCodeFlowAPI,
                                ion object: IonForm?,
                                createCapabilities: Bool = true) -> Remediation?
    {
        guard let object = object else { return nil }

        // swiftlint:disable force_unwrapping
        let form = Form(fields: object.value?.map({ (value) in
          .init(flow: flow, ion: value)
        })) ?? Form(fields: [])!
        let refresh = (object.refresh != nil) ? Double(object.refresh!) / 1000.0 : nil
        // swiftlint:enable force_unwrapping

        let capabilities: [RemediationCapability?] = createCapabilities ? [
            Capability.SocialIDP(flow: flow, ion: object),
            Capability.Pollable(flow: flow, ion: object)
        ] : []
        
        return Remediation(flow: flow,
                           name: object.name,
                           method: object.method,
                           href: object.href,
                           accepts: object.accepts,
                           form: form,
                           refresh: refresh,
                           relatesTo: object.relatesTo,
                           capabilities: capabilities.compactMap { $0 })
    }

    internal convenience init?(flow: InteractionCodeFlowAPI, ion object: IonForm?) {
        guard let object = object,
              let form = Form(fields: object.value?.map({ (value) in
                .init(flow: flow, ion: value)
              }))
        else { return nil }

        // swiftlint:disable force_unwrapping
        self.init(flow: flow,
                  name: object.name,
                  method: object.method,
                  href: object.href,
                  accepts: object.accepts,
                  form: form,
                  refresh: (object.refresh != nil) ? Double(object.refresh!) / 1000.0 : nil,
                  relatesTo: object.relatesTo,
                  capabilities: [])
        // swiftlint:enable force_unwrapping
    }
}

extension Remediation.Form.Field {
    internal convenience init(flow: InteractionCodeFlowAPI, ion object: IonFormValue) {
        // Fields default to visible, except there are circumstances where
        // fields (such as `id`) don't properly include a `visible: false`. As a result,
        // we need to infer visibility from other values.
        var visible = object.visible ?? true
        if let isMutable = object.mutable,
           !isMutable && object.value != nil
        {
            visible = false
        }
        
        self.init(name: object.name,
                  label: object.label,
                  type: object.type,
                  value: object.value?.toAnyObject(),
                  visible: visible,
                  mutable: object.mutable ?? true,
                  required: object.required ?? false,
                  secret: object.secret ?? false,
                  relatesTo: object.relatesTo,
                  form: Remediation.Form(fields: object.form?.value.map({ (value) in
                    .init(flow: flow, ion: value)
                  })),
                  options: object.options?.map { (value) in
                    .init(flow: flow, ion: value)
                  },
                  messages: .init(messages: object.messages?.value.compactMap {
            Response.Message(flow: flow, ion: $0)
                  }))
        self.messages.allMessages.forEach { $0.field = self }
    }
}
