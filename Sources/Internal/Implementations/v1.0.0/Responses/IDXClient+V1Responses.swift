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
                  remediation: IDXClient.Remediation(client: client, v1: object.remediation))
    }
}

extension IDXClient.Remediation {
    internal convenience init(client: IDXClientAPIImpl, v1 object: IDXClient.APIVersion1.Response.FormCollection) {
        self.init(client: client,
                  type: object.type,
                  remediationOptions: object.value.map { (form) -> Option in
                    Option(client: client, v1: form)
                  })
    }
}

extension IDXClient.Remediation.Option {
    internal convenience init(client: IDXClientAPIImpl, v1 object: IDXClient.APIVersion1.Response.Form) {
        self.init(client: client,
                  rel: object.rel,
                  name: object.name,
                  method: object.method,
                  href: object.href,
                  accepts: object.accepts,
                  form: object.value.map { (value) in
                    IDXClient.FormValue(client: client, v1: value)
                  })
    }
}

extension IDXClient.FormValue {
    internal convenience init(client: IDXClientAPIImpl, v1 object: IDXClient.APIVersion1.Response.FormValue) {
        self.init(name: object.name,
                  label: object.label,
                  type: object.type,
                  value: object.value?.toAnyObject(),
                  visible: object.visible ?? true,
                  mutable: object.mutable ?? true,
                  required: object.required ?? false,
                  secret: object.secret ?? false)
    }
}
