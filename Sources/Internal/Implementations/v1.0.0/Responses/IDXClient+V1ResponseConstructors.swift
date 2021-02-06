//
//  IDXClient+Responses.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-16.
//

import Foundation

typealias V1 = IDXClient.APIVersion1

protocol IDXContainsRelatableObjects {
    typealias RelatesTo = IDXClient.APIVersion1.Response.RelatesTo
    func nestedRelatableObjects() -> [IDXHasRelatedObjects]

    func find(relatesTo: IDXClient.APIVersion1.Response.RelatesTo?,
              root: IDXContainsRelatableObjects) -> AnyObject?
    func find(relatesTo: [IDXClient.APIVersion1.Response.RelatesTo]?,
              root: IDXContainsRelatableObjects) -> [AnyObject]?
}

extension IDXContainsRelatableObjects {
    func find(relatesTo: IDXClient.APIVersion1.Response.RelatesTo?,
              root: IDXContainsRelatableObjects) -> AnyObject?
    {
        guard let relatesTo = relatesTo else { return nil }
        var result: AnyObject? = self as AnyObject
        for item in relatesTo.path {
            switch item {
            case .root:
                result = root as AnyObject
            case .property(name: let name):
                if result?.responds(to: Selector(name)) ?? false,
                    let object = result?.value(forKey: name) {
                    result = object as AnyObject
                }
            case .array(index: let index):
                if let array = result as? Array<AnyObject> {
                    result = array[index]
                }
            }
        }
        return result
    }
    
    func find(relatesTo: [IDXClient.APIVersion1.Response.RelatesTo]?,
              root: IDXContainsRelatableObjects) -> [AnyObject]?
    {
        guard let relatesTo = relatesTo else { return nil }
        return relatesTo.compactMap { find(relatesTo: $0, root: root) }
    }
}

protocol IDXHasRelatedObjects: IDXContainsRelatableObjects {
    func findRelatedObjects(from root: IDXContainsRelatableObjects)
}

extension IDXClient.Response: IDXContainsRelatableObjects {
    internal convenience init(api: IDXClientAPIImpl, v1 response: V1.Response) {
        self.init(api: api,
                  stateHandle: response.stateHandle,
                  version: response.version,
                  expiresAt: response.expiresAt,
                  intent: response.intent,
                  authenticators: response.authenticators?.value.compactMap { IDXClient.Authenticator(v1: $0) },
                  authenticatorEnrollments: response.authenticatorEnrollments?.value.compactMap { IDXClient.Authenticator(v1: $0) },
                  currentAuthenticatorEnrollment: IDXClient.Authenticator.CurrentEnrollment(api: api, v1: response.currentAuthenticatorEnrollment?.value),
                  remediation: IDXClient.Remediation(api: api, v1: response.remediation),
                  cancel: IDXClient.Remediation.Option(api: api, v1: response.cancel),
                  success: IDXClient.Remediation.Option(api: api, v1:  response.successWithInteractionCode),
                  messages: response.messages?.value.compactMap { IDXClient.Message(api: api, v1: $0) },
                  app: IDXClient.Application(v1: response.app?.value),
                  user: IDXClient.User(v1: response.user?.value))

        nestedRelatableObjects().forEach { (object) in
            object.findRelatedObjects(from: self)
        }
    }
    
    func nestedRelatableObjects() -> [IDXHasRelatedObjects] {
        var result: [IDXHasRelatedObjects] = []
        result.append(contentsOf: remediation?.nestedRelatableObjects() ?? [])
        result.append(contentsOf: cancelRemediationOption?.nestedRelatableObjects() ?? [])
        result.append(contentsOf: successResponse?.nestedRelatableObjects() ?? [])
        return result
    }
}

extension IDXClient.Message {
    internal convenience init?(api: IDXClientAPIImpl, v1 object: V1.Response.Message?) {
        guard let object = object else { return nil }
        self.init(type: object.type,
                  localizationKey: object.i18n?.key,
                  message: object.message)
    }
}

extension IDXClient.Application {
    internal convenience init?(v1 object: V1.Response.App?) {
        guard let object = object else { return nil }
        self.init(id: object.id,
                  label: object.label,
                  name: object.name)
    }
}

extension IDXClient.User {
    internal convenience init?(v1 object: V1.Response.User?) {
        guard let object = object else { return nil }
        self.init(id: object.id)
    }
}

extension IDXClient.Authenticator {
    internal convenience init?(v1 object: V1.Response.Authenticator?) {
        guard let object = object else { return nil }
        self.init(id: object.id,
                  displayName: object.displayName,
                  type: object.type,
                  methods: object.methods,
                  profile: nil)
    }

    internal convenience init?(v1 object: V1.Response.AuthenticatorEnrollment?) {
        guard let object = object else { return nil }
        self.init(id: object.id,
                  displayName: object.displayName,
                  type: object.type,
                  methods: object.methods,
                  profile: object.profile)
    }
}

extension IDXClient.Authenticator.CurrentEnrollment {
    internal convenience init?(api: IDXClientAPIImpl, v1 object: V1.Response.CurrentAuthenticatorEnrollment?) {
        guard let object = object else { return nil }
        self.init(id: object.id,
                  displayName: object.displayName,
                  type: object.type,
                  methods: object.methods,
                  profile: object.profile,
                  send: IDXClient.Remediation.Option(api: api, v1: object.send),
                  resend: IDXClient.Remediation.Option(api: api, v1: object.resend),
                  poll: IDXClient.Remediation.Option(api: api, v1: object.poll),
                  recover: IDXClient.Remediation.Option(api: api, v1: object.recover))
    }
}

extension IDXClient.Remediation: IDXContainsRelatableObjects {
    internal convenience init?(api: IDXClientAPIImpl, v1 object: V1.Response.IonCollection<V1.Response.Form>?) {
        guard let object = object,
              let type = object.type else {
            return nil
        }
        self.init(api: api,
                  type: type,
                  remediationOptions: object.value.compactMap { (value) in
                    IDXClient.Remediation.Option(api: api, v1: value)
                  })
    }
    
    func nestedRelatableObjects() -> [IDXHasRelatedObjects] {
        return remediationOptions.flatMap { $0.nestedRelatableObjects() }
    }
}

extension IDXClient.Remediation.Option: IDXHasRelatedObjects {
    internal convenience init?(api: IDXClientAPIImpl, v1 object: V1.Response.Form?) {
        guard let object = object else { return nil }
        self.init(api: api,
                  rel: object.rel,
                  name: object.name,
                  method: object.method,
                  href: object.href,
                  accepts: object.accepts,
                  form: object.value.map { (value) in
                    IDXClient.Remediation.FormValue(api: api, v1: value)
                  },
                  relatesTo: object.relatesTo,
                  refresh: (object.refresh != nil) ? Double(object.refresh!) / 1000.0 : nil)
    }
    
    func nestedRelatableObjects() -> [IDXHasRelatedObjects] {
        var result = form.flatMap { $0.nestedRelatableObjects() }
        result.append(self)
        return result
    }
    
    func findRelatedObjects(from root: IDXContainsRelatableObjects) {
        relatesTo = find(relatesTo: v1RelatesTo, root: root)
    }
}

extension IDXClient.Remediation.FormValue: IDXHasRelatedObjects {
    internal convenience init(api: IDXClientAPIImpl, v1 object: V1.Response.FormValue) {
        self.init(name: object.name,
                  label: object.label,
                  type: object.type,
                  value: object.value?.toAnyObject(),
                  visible: object.visible ?? (object.label != nil),
                  mutable: object.mutable ?? true,
                  required: object.required ?? false,
                  secret: object.secret ?? false,
                  form: object.form?.value.map { IDXClient.Remediation.FormValue(api: api, v1: $0) },
                  relatesTo: object.relatesTo,
                  options: object.options?.map { IDXClient.Remediation.FormValue(api: api, v1: $0) },
                  messages: object.messages?.value.compactMap { IDXClient.Message(api: api, v1: $0) })
    }
    
    func nestedRelatableObjects() -> [IDXHasRelatedObjects] {
        var result: [IDXHasRelatedObjects] = [self]
        result.append(contentsOf: form?.flatMap { $0.nestedRelatableObjects() } ?? [])
        result.append(contentsOf: options?.flatMap { $0.nestedRelatableObjects() } ?? [])
        return result
    }
    
    func findRelatedObjects(from root: IDXContainsRelatableObjects) {
        relatesTo = find(relatesTo: v1RelatesTo, root: root)
    }
}

extension IDXClient.Token {
    internal convenience init(api: IDXClientAPIImpl, v1 object: V1.Token) {
        self.init(accessToken: object.accessToken,
                  refreshToken: object.refreshToken,
                  expiresIn: TimeInterval(object.expiresIn),
                  idToken: object.idToken,
                  scope: object.scope,
                  tokenType: object.tokenType)
    }
}
