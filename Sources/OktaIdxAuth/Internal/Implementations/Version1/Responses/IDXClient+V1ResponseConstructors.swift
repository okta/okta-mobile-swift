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

#if !COCOAPODS
import JSON
#endif

protocol ReferencesParent: AnyObject {
    func assign<ParentType>(parent: ParentType?)
}

struct IonRemediationContext {
    let webAuthnAutofillUIChallenge: IonObject<IonChallengeData>?
    let authenticatorCollection: Authenticator.Collection?
}

extension Response {
    internal convenience init(flow: any InteractionCodeFlowAPI, ion response: IonResponse) throws {
        let authenticators = try Authenticator.Collection(flow: flow, ion: response)
        let remediations = Remediation.Collection(flow: flow, ion: response, authenticatorCollection: authenticators)
        let successRemediationOption = Remediation(flow: flow, ion: response.successWithInteractionCode)
        let messages = Response.Message.Collection(response.messages?.value.compactMap { Response.Message(flow: flow, ion: $0) },
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
    internal convenience init?(flow: any InteractionCodeFlowAPI, ion object: IonMessage?) {
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
        self.init(id: userId,
                  username: object.identifier,
                  profile: .init(ion: object.profile?.compactMapValues({ $0 })))
    }
}

extension Response.User.Profile {
    internal init?(ion object: [String: String]?) {
        guard let object = object else { return nil }

        var timeZone: TimeZone?
        if let string = object["timeZone"] {
            timeZone = TimeZone(identifier: string)
        }

        var locale: Locale?
        if let string = object["locale"] {
            locale = Locale(identifier: string)
        }

        self.init(firstName: object["firstName"],
                  lastName: object["lastName"],
                  timeZone: timeZone,
                  locale: locale)
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
        var state = [Authenticator.State]()
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

extension PasswordSettingsCapability {
    init?(with settings: JSON.Value?) {
        guard let complexity = settings?["complexity"]?.object
        else { return nil }

        self.init(daysToExpiry: settings?["daysToExpiry"]?.int ?? 0,
                  minLength: complexity["minLength"]?.int ?? 0,
                  minLowerCase: complexity["minLowerCase"]?.int ?? 0,
                  minUpperCase: complexity["minUpperCase"]?.int ?? 0,
                  minNumber: complexity["minNumber"]?.int ?? 0,
                  minSymbol: complexity["minSymbol"]?.int ?? 0,
                  maxConsecutiveRepeatingCharacters: complexity["maxConsecutiveRepeatingCharacters"]?.int ?? 0,
                  excludeUsername: complexity["excludeUsername"]?.bool ?? false,
                  excludeAttributes: complexity["excludeAttributes"]?.array?.compactMap(\.string) ?? [])
    }
}

extension Authenticator.Collection {
    convenience init(flow: any InteractionCodeFlowAPI, ion object: IonResponse) throws {
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
        
        self.init(authenticators)
    }
}

extension Remediation.Collection {
    convenience init(flow: any InteractionCodeFlowAPI,
                     ion object: IonResponse?,
                     authenticatorCollection: Authenticator.Collection)
    {
        let remediationContext = IonRemediationContext(
            webAuthnAutofillUIChallenge: object?.webauthnAutofillUIChallenge,
            authenticatorCollection: authenticatorCollection)

        var remediations: [Remediation] = object?.remediation?.value.compactMap { (value) in
            Remediation.makeRemediation(flow: flow,
                                        ion: value,
                                        context: remediationContext)
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

extension SendCapability {
    init?(flow: any InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        guard let authenticator = authenticators.compactMap(\.send).first,
              let remediation = Remediation.makeRemediation(flow: flow, ion: authenticator)
        else {
            return nil
        }
        self.init(remediation: remediation)
    }
}

extension ResendCapability {
    init?(flow: any InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        guard let authenticator = authenticators.compactMap(\.resend).first,
              let remediation = Remediation.makeRemediation(flow: flow, ion: authenticator)
        else {
            return nil
        }
        self.init(remediation: remediation)
    }
}

extension RecoverCapability {
    init?(flow: any InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        guard let authenticator = authenticators.compactMap(\.recover).first,
              let remediation = Remediation.makeRemediation(flow: flow, ion: authenticator)
        else {
            return nil
        }
        self.init(remediation: remediation)
    }
}

extension PollCapability {
    convenience init?(flow: any InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        guard let type = authenticators.first?.type,
              let authenticator = authenticators.compactMap(\.poll).first,
              let remediation = Remediation.makeRemediation(flow: flow, ion: authenticator)
        else {
            return nil
        }
        
        self.init(flow: flow,
                  authenticatorType: type,
                  remediation: remediation)
    }

    convenience init?(flow: any InteractionCodeFlowAPI, ion form: IonForm) {
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

extension NumberChallengeCapability {
    init?(flow: any InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        guard let answer = authenticators.compactMap(\.contextualData?["correctAnswer"]).first?.string
        else {
            return nil
        }
        
        self.init(correctAnswer: answer)
    }
}

extension ProfileCapability {
    init?(flow: any InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        guard let profile = authenticators.compactMap(\.profile).first
        else {
            return nil
        }
        
        self.init(profile: profile)
    }
}

extension PasswordSettingsCapability {
    init?(flow: any InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        guard let type = authenticators.first?.type,
              type == .password,
              let settings = authenticators.compactMap(\.settings).first
        else {
            return nil
        }
        
        self.init(with: settings)
    }
}

extension OTPCapability {
    init?(flow: any InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        let methods = methodTypes(from: authenticators)
        guard methods.contains(.otp) || methods.contains(.totp)
        else {
            return nil
        }

        guard let authenticator = authenticators.first(where: { $0.type == .app })
        else {
            return nil
        }

        guard let contextualData = authenticator.contextualData,
              case let .object(qrcode) = contextualData["qrcode"],
              let method = qrcode["method"]?.string,
              method == "embedded",
              let mimeType = qrcode["type"]?.string,
              let href = qrcode["href"]?.string,
              let imageData = href.base64ImageData
        else {
            return nil
        }
        
        var sharedSecret: String?
        if let value = contextualData["sharedSecret"]?.string {
            sharedSecret = value
        }

        self.init(mimeType: mimeType,
                  imageData: imageData,
                  sharedSecret: sharedSecret)
    }
}

extension DuoCapability {
    convenience init?(flow: any InteractionCodeFlowAPI, ion authenticators: [IonAuthenticator]) {
        // Exit early if none of the authenticators have a "duo" method
        let methods = methodTypes(from: authenticators)
        guard methods.contains(.duo) else {
            return nil
        }

        // Extract the duo authenticator data
        let duoAuthenticators = authenticators.filter({ $0.type == .app && $0.key == "duo" })
        guard let authenticator = duoAuthenticators.first(where: { $0.contextualData != nil }),
              let contextualData = authenticator.contextualData,
              let host = contextualData["host"]?.string,
              let signedToken = contextualData["signedToken"]?.string,
              let script = contextualData["script"]?.string
        else {
            return nil
        }
        
        self.init(host: host, signedToken: signedToken, script: script)
    }
}

extension SocialIDPCapability {
    init?(flow: any InteractionCodeFlowAPI, ion object: IonForm) {
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

extension WebAuthnRegistrationCapability {
    convenience init?(flow: any InteractionCodeFlowAPI,
                      ion object: IonForm?,
                      context: IonRemediationContext?) throws
    {
        // WebAuthn registration information is listed on the currentAuthenticator,
        // but is actionable by the Remediation. So we need to enure this capability
        // can access the authenticator contextualData information, and that the
        // registration capability is only bound to the remediation capable of
        // carrying out the operation.
        guard let authenticatorCollection = context?.authenticatorCollection,
              object?.relatesTo != nil
        else { return nil }

        let webAuthnAuthenticators = authenticatorCollection.filter { authenticator in
            authenticator.type == .securityKey && authenticator.key == "webauthn"
        }

        guard let contextualData = webAuthnAuthenticators.compactMap(\.context).first,
              let activationData = contextualData["activationData"]
        else {
            return nil
        }

        try self.init(issuerURL: flow.client.configuration.issuerURL,
                      rawActivationJSON: activationData)
    }
}

extension WebAuthnAuthenticationCapability {
    convenience init?(flow: any InteractionCodeFlowAPI,
                      ion object: IonForm?,
                      context: IonRemediationContext?) throws
    {
        if let challengeData = context?.webAuthnAutofillUIChallenge {
            try self.init(flow: flow,
                          ion: object,
                          challengeData: challengeData.value)
        } else if let authenticatorCollection = context?.authenticatorCollection {
            try self.init(flow: flow,
                          ion: object,
                          authenticatorCollection: authenticatorCollection)
        } else {
            return nil
        }
    }

    convenience init?(flow: any InteractionCodeFlowAPI,
                      ion object: IonForm?,
                      authenticatorCollection: Authenticator.Collection) throws
    {
        guard object?.relatesTo != nil
        else { return nil }

        let webAuthnAuthenticators = authenticatorCollection.filter { authenticator in
            authenticator.type == .securityKey && authenticator.key == "webauthn"
        }

        guard let contextualData = webAuthnAuthenticators.compactMap(\.context).first,
              let challengeData = contextualData["challengeData"]
        else {
            return nil
        }

        try self.init(issuerURL: flow.client.configuration.issuerURL,
                      rawChallengeJSON: challengeData)
    }

    convenience init?(flow: any InteractionCodeFlowAPI,
                      ion object: IonForm?,
                      challengeData: IonChallengeData) throws
    {
        guard let object,
              let relatesTo = object.relatesTo,
              object.name == "challenge-webauthn-autofillui-authenticator",
              relatesTo.contains("webauthnAutofillUIChallenge")
        else {
            return nil
        }

        try self.init(issuerURL: flow.client.configuration.issuerURL,
                      rawChallengeJSON: challengeData.challengeData)
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
            return Authenticator.Method(rawValue: value)
        }
    return methodTypes
}

extension Authenticator {
    static func makeAuthenticator(flow: any InteractionCodeFlowAPI,
                                  ion authenticators: [IonAuthenticator],
                                  jsonPaths: [String],
                                  in response: IonResponse) throws -> Authenticator?
    {
        guard let first = authenticators.first else { return nil }

        let filteredTypes = Set(authenticators.map(\.type))
        guard filteredTypes.count == 1 else {
            throw InteractionCodeFlowError.responseValidationFailed("Some mapped authenticators have differing types: \(filteredTypes.map(\.rawValue).joined(separator: ", "))")
        }
        
        let state = response.authenticatorState(for: authenticators, in: jsonPaths)
        let key = authenticators.compactMap(\.key).first
        let methods = authenticators.compactMap(\.methods).first
        let contextualData = authenticators.compactMap(\.contextualData).first

        let capabilities: [(any Capability)?] = [
            ProfileCapability(flow: flow, ion: authenticators),
            SendCapability(flow: flow, ion: authenticators),
            ResendCapability(flow: flow, ion: authenticators),
            PollCapability(flow: flow, ion: authenticators),
            RecoverCapability(flow: flow, ion: authenticators),
            PasswordSettingsCapability(flow: flow, ion: authenticators),
            NumberChallengeCapability(flow: flow, ion: authenticators),
            OTPCapability(flow: flow, ion: authenticators),
            DuoCapability(flow: flow, ion: authenticators)
        ]
        
        return Authenticator(flow: flow,
                             v1JsonPaths: jsonPaths,
                             state: state,
                             id: first.id,
                             displayName: first.displayName,
                             type: first.type,
                             key: key,
                             methods: methods,
                             contextualData: contextualData,
                             capabilities: capabilities.compactMap { $0 })
    }
}

extension Remediation {
    static func makeRemediation(flow: any InteractionCodeFlowAPI,
                                ion object: IonForm?,
                                context: IonRemediationContext? = nil,
                                createCapabilities: Bool = true) -> Remediation?
    {
        guard let object = object else { return nil }

        // swiftlint:disable force_unwrapping
        let form = Form(fields: object.value?.map({ (value) in
                .init(flow: flow, ion: value)
        })) ?? Form(fields: [])!
        let refresh = (object.refresh != nil) ? Double(object.refresh!) / 1000.0 : nil
        // swiftlint:enable force_unwrapping

        let capabilities: [(any Capability)?] = createCapabilities ? [
            SocialIDPCapability(flow: flow, ion: object),
            PollCapability(flow: flow, ion: object),
            try? WebAuthnRegistrationCapability(flow: flow,
                                                ion: object,
                                                context: context),
            try? WebAuthnAuthenticationCapability(flow: flow,
                                                  ion: object,
                                                  context: context),
        ] : []

        let remediation = Remediation(flow: flow,
                                      name: object.name,
                                      method: object.method,
                                      href: object.href,
                                      accepts: object.accepts,
                                      form: form,
                                      refresh: refresh,
                                      relatesTo: object.relatesTo,
                                      capabilities: capabilities.compactMap { $0 })
        remediation?
            .capabilities
            .compactMap { $0.capabilityValue as? any ReferencesParent }
            .forEach {
                $0.assign(parent: remediation)
            }

        return remediation
    }

    internal convenience init?(flow: any InteractionCodeFlowAPI, ion object: IonForm?) {
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
    internal convenience init(flow: any InteractionCodeFlowAPI, ion object: IonFormValue) {
        // Fields default to visible, except there are circumstances where
        // fields (such as `id`) don't properly include a `visible: false`. As a result,
        // we need to infer visibility from other values.
        var visible = object.visible ?? true
        if let isMutable = object.mutable,
           !isMutable && object.value != .null
        {
            visible = false
        }
        
        self.init(name: object.name,
                  label: object.label,
                  type: object.type,
                  value: object.value,
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
                  messages: .init(object.messages?.value.compactMap {
            Response.Message(flow: flow, ion: $0)
                  }))
        self.messages.allMessages.forEach { $0.field = self }
    }
}
