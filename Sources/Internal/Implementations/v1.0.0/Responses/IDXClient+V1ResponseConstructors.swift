//
//  IDXClient+Responses.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-16.
//

import Foundation

extension IDXClient.Response {
    internal convenience init(client: IDXClientAPIImpl, v1 object: IDXClient.APIVersion1.Response) {
        self.init(client: client,
                  stateHandle: object.stateHandle,
                  version: object.version,
                  expiresAt: object.expiresAt,
                  intent: object.intent,
                  remediation: IDXClient.Remediation(client: client, v1: object.remediation),
                  cancel: IDXClient.Remediation.Option(client: client, v1: object.cancel),
                  success: IDXClient.Remediation.Option(client: client, v1: object.successWithInteractionCode))
    }
}

extension IDXClient.Remediation {
    internal convenience init?(client: IDXClientAPIImpl, v1 object: IDXClient.APIVersion1.Response.FormCollection?) {
        guard let object = object else { return nil }
        self.init(client: client,
                  type: object.type,
                  remediationOptions: object.value.compactMap { (form) -> Option in
                    Option(client: client, v1: form)!
                  })
    }
}

extension IDXClient.Remediation.Option {
    internal convenience init?(client: IDXClientAPIImpl, v1 object: IDXClient.APIVersion1.Response.Form?) {
        guard let object = object else { return nil }
        self.init(client: client,
                  rel: object.rel,
                  name: object.name,
                  method: object.method,
                  href: object.href,
                  accepts: object.accepts,
                  form: object.value.map { (value) in
                    IDXClient.Remediation.FormValue(client: client, v1: value)
                  })
    }
}

extension IDXClient.Remediation.FormValue {
    internal convenience init(client: IDXClientAPIImpl, v1 object: IDXClient.APIVersion1.Response.FormValue) {
        self.init(name: object.name,
                  label: object.label,
                  type: object.type,
                  value: object.value?.toAnyObject(),
                  visible: object.visible ?? true,
                  mutable: object.mutable ?? true,
                  required: object.required ?? false,
                  secret: object.secret ?? false,
                  form: nil/*object.form?.map { IDXClient.FormValue(client: client, v1: $0) }*/,
                  options: nil/*object.options?.map { IDXClient.FormValue(client: client, v1: $0) }*/)
    }
}

extension IDXClient.Token {
    internal convenience init(client: IDXClientAPIImpl, v1 object: IDXClient.APIVersion1.Token) {
        self.init(accessToken: object.accessToken,
                  refreshToken: object.refreshToken,
                  expiresIn: TimeInterval(object.expiresIn),
                  idToken: object.idToken,
                  scope: object.scope,
                  tokenType: object.tokenType)
    }
}
