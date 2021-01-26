//
//  IDXClient+Responses.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-16.
//

import Foundation

typealias V1 = IDXClient.APIVersion1

extension IDXClient.Response {
    internal convenience init(client: IDXClientAPIImpl, v1 object: V1.Response) {
        self.init(client: client,
                  stateHandle: object.stateHandle,
                  version: object.version,
                  expiresAt: object.expiresAt,
                  intent: object.intent,
                  authenticators: object.authenticators?.value.compactMap { IDXClient.Authenticator(v1: $0) },
                  authenticatorEnrollments: object.authenticatorEnrollments?.value.compactMap { IDXClient.Authenticator(v1: $0) },
                  currentAuthenticatorEnrollment: IDXClient.Authenticator.CurrentEnrollment(client: client, v1: object.currentAuthenticatorEnrollment?.value),
                  remediation: IDXClient.Remediation(client: client, v1: object.remediation),
                  cancel: IDXClient.Remediation.Option(client: client, v1: object.cancel),
                  success: IDXClient.Remediation.Option(client: client, v1: object.successWithInteractionCode),
                  messages: object.messages?.value.compactMap { IDXClient.Message(client: client, v1: $0) },
                  app: IDXClient.Application(v1: object.app?.value),
                  user: IDXClient.User(v1: object.user?.value))
    }
}

extension IDXClient.Message {
    internal convenience init?(client: IDXClientAPIImpl, v1 object: V1.Response.Message?) {
        guard let object = object else { return nil }
        self.init(type: object.type,
                  localizationKey: object.i18n.key,
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
    internal convenience init?(client: IDXClientAPIImpl, v1 object: V1.Response.CurrentAuthenticatorEnrollment?) {
        guard let object = object else { return nil }
        self.init(id: object.id,
                  displayName: object.displayName,
                  type: object.type,
                  methods: object.methods,
                  profile: object.profile,
                  send: IDXClient.Remediation.Option(client: client, v1: object.send),
                  resend: IDXClient.Remediation.Option(client: client, v1: object.resend),
                  poll: IDXClient.Remediation.Option(client: client, v1: object.poll),
                  recover: IDXClient.Remediation.Option(client: client, v1: object.recover))
    }
}

extension IDXClient.Remediation {
    internal convenience init?(client: IDXClientAPIImpl, v1 object: V1.Response.IonCollection<V1.Response.Form>?) {
        guard let object = object,
              let type = object.type else {
            return nil
        }
        self.init(client: client,
                  type: type,
                  remediationOptions: object.value.compactMap { (value) in
                    IDXClient.Remediation.Option(client: client, v1: value)
                  })
    }
}

extension IDXClient.Remediation.Option {
    internal convenience init?(client: IDXClientAPIImpl, v1 object: V1.Response.Form?) {
        guard let object = object else { return nil }
        self.init(client: client,
                  rel: object.rel,
                  name: object.name,
                  method: object.method,
                  href: object.href,
                  accepts: object.accepts,
                  form: object.value.map { (value) in
                    IDXClient.Remediation.FormValue(client: client, v1: value)
                  },
                  refresh: object.refresh)
    }
}

extension IDXClient.Remediation.FormValue {
    internal convenience init(client: IDXClientAPIImpl, v1 object: V1.Response.FormValue) {
        self.init(name: object.name,
                  label: object.label,
                  type: object.type,
                  value: object.value?.toAnyObject(),
                  visible: object.visible ?? (object.label != nil),
                  mutable: object.mutable ?? true,
                  required: object.required ?? false,
                  secret: object.secret ?? false,
                  form: object.form?.value.map { IDXClient.Remediation.FormValue(client: client, v1: $0) },
                  options: object.options?.map { IDXClient.Remediation.FormValue(client: client, v1: $0) },
                  messages: object.messages?.value.compactMap { IDXClient.Message(client: client, v1: $0) })
    }
}

extension IDXClient.Token {
    internal convenience init(client: IDXClientAPIImpl, v1 object: V1.Token) {
        self.init(accessToken: object.accessToken,
                  refreshToken: object.refreshToken,
                  expiresIn: TimeInterval(object.expiresIn),
                  idToken: object.idToken,
                  scope: object.scope,
                  tokenType: object.tokenType)
    }
}
