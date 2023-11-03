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

import UIKit

#if os(tvOS)
import OktaOAuth2
#elseif canImport(WebAuthenticationUI) && !WEB_AUTH_DISABLED
import WebAuthenticationUI
#else
import AuthFoundation
#endif

class ProfileTableViewController: UITableViewController {
    enum Section: Int {
        case profile = 0, details, actions, count
    }
    
    struct Row {
        enum Kind: String {
            case destructive, action, disclosure, leftDetail, rightDetail
        }
        
        let kind: Kind
        let id: String?
        let title: String
        let detail: String?
        init(kind: Kind, id: String? = nil, title: String, detail: String? = nil) {
            self.kind = kind
            self.id = id
            self.title = title
            self.detail = detail
        }
    }

    var tableContent: [Section: [Row]] = [:]
    var credential: Credential? {
        didSet {
            configure(credential?.userInfo)
            credential?.automaticRefresh = true
            credential?.refreshIfNeeded { result in
                switch result {
                case .success:
                    self.credential?.userInfo { result in
                        guard case let .success(userInfo) = result else { return }
                        DispatchQueue.main.async {
                            self.configure(userInfo)
                        }
                    }
                    
                case .failure(let error):
                    self.show(error: error)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(forName: .defaultCredentialChanged,
                                               object: nil,
                                               queue: .main) { (notification) in
            guard let user = notification.object as? Credential else { return }
            self.credential = user
        }
        credential = Credential.default
    }
    
    func row(at indexPath: IndexPath) -> Row? {
        guard let tableSection = Section(rawValue: indexPath.section),
              let row = tableContent[tableSection]?[indexPath.row]
        else {
            return nil
        }
        
        return row
    }
    
    func configure(_ user: UserInfo?) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .long

        navigationItem.title = user?.name
        
        let updatedAt: String
        if let updatedDate = user?.updatedAt {
            updatedAt = dateFormatter.string(from: updatedDate)
        } else {
            updatedAt = "N/A"
        }
        
        let defaultValue: String
        if Credential.default?.id == credential?.id {
            defaultValue = "Yes"
        } else {
            defaultValue = "No"
        }

        tableContent = [:]
        if let user = user {
            tableContent[.profile] = [
                .init(kind: .rightDetail, id: "givenName", title: "Given name", detail: user.givenName),
                .init(kind: .rightDetail, id: "familyName", title: "Family name", detail: user.familyName),
                .init(kind: .rightDetail, id: "locale", title: "Locale", detail: user.userLocale?.identifier ?? "N/A"),
                .init(kind: .rightDetail, id: "timezone", title: "Timezone", detail: user.timeZone?.identifier ?? "N/A")
            ]
            tableContent[.details] = [
                .init(kind: .rightDetail, id: "username", title: "Username", detail: user.preferredUsername),
                .init(kind: .rightDetail, id: "userId", title: "User ID", detail: user.subject),
                .init(kind: .rightDetail, id: "createdAt", title: "Created at", detail: updatedAt),
                .init(kind: .rightDetail, id: "isDefaultCredential", title: "Is Default", detail: defaultValue),
                .init(kind: .disclosure, id: "details", title: "Token details")
            ]
        }
        
        tableContent[.actions] = [
            .init(kind: .action, id: "refresh", title: "Refresh"),
            .init(kind: .destructive, id: "signout", title: "Sign Out")
        ]

        tableView.reloadData()
    }
    
    func show(error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            
            #if os(tvOS)
            self.show(alert, sender: nil)
            #else
            self.present(alert, animated: true)
            #endif
        }
    }
    
    func signout() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(.init(title: "Remove", style: .default, handler: { _ in
            #if !os(tvOS)
            try? Keychain.deleteTokens()
            #endif
            
            try? self.credential?.remove()
            self.credential = nil
        }))
        alert.addAction(.init(title: "Revoke tokens", style: .destructive, handler: { _ in
            self.credential?.revoke { result in
                if case let .failure(error) = result {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Sign out failed", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }))
        
        #if !os(tvOS) && canImport(WebAuthenticationUI) && !WEB_AUTH_DISABLED
        if let token = Credential.default?.token {
            var options: [WebAuthentication.Option]?
            options = []
            // TODO: Uncomment the following line to force a user to sign in again while signing out.
            // options = [.prompt(.login)]
            
            alert.addAction(.init(title: "End a session", style: .destructive) { _ in
                WebAuthentication.shared?.signOut(token: token, options: options) { result in
                    switch result {
                    case .success:
                        try? Keychain.deleteTokens()
                        try? self.credential?.remove()
                        self.credential = nil
                    case .failure(let error):
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Sign out failed",
                                                          message: error.localizedDescription,
                                                          preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(alert, animated: true)
                        }
                    }
                }
            })
        }
        #endif
        
        alert.addAction(.init(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    func refresh() {
        credential?.refresh { result in
            if case let .failure(error) = result {
                DispatchQueue.main.async {
                    self.show(error: error)
                }
            }
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count.rawValue
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableSection = Section(rawValue: section),
              let rows = tableContent[tableSection]
        else { return 0 }
        return rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = row(at: indexPath) else {
            return UITableViewCell()
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: row.kind.rawValue, for: indexPath)
        cell.accessibilityIdentifier = row.id
        cell.textLabel?.text = row.title
        cell.detailTextLabel?.text = row.detail

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = row(at: indexPath) else { return }

        switch row.id {
        case "signout":
            signout()

        case "refresh":
            refresh()
            
        case "details":
            performSegue(withIdentifier: "TokenDetail", sender: tableView)

        default: break
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "TokenDetail":
            guard let target = segue.destination as? TokenDetailViewController else { break }
            target.credential = Credential.default

        default: break
        }
    }
}
