/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import UIKit
import OktaOAuth2

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
    var user: Credential? {
        didSet {
            user?.userInfo { result in
                guard case let .success(userInfo) = result else { return }
                DispatchQueue.main.async {
                    self.configure(userInfo)
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
            self.user = user
        }
        user = Credential.default
    }
    
    func row(at indexPath: IndexPath) -> Row? {
        guard let tableSection = Section(rawValue: indexPath.section),
              let row = tableContent[tableSection]?[indexPath.row]
        else {
            return nil
        }
        
        return row
    }
    
    func configure(_ userInfo: UserInfo) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .long

        navigationItem.title = userInfo.name

        tableContent = [
            .profile: [
                .init(kind: .rightDetail, id: "givenName", title: "Given name", detail: userInfo.givenName),
                .init(kind: .rightDetail, id: "familyName", title: "Family name", detail: userInfo.familyName),
                .init(kind: .rightDetail, id: "locale", title: "Locale", detail: userInfo.userLocale?.identifier ?? "N/A"),
                .init(kind: .rightDetail, id: "timezone", title: "Timezone", detail: userInfo.zoneInfo?.identifier ?? "N/A")
            ],
            .details: [
                .init(kind: .rightDetail, id: "username", title: "Username", detail: userInfo.preferredUsername),
                .init(kind: .rightDetail, id: "userId", title: "User ID", detail: userInfo.sub),
                .init(kind: .rightDetail, id: "createdAt", title: "Created at", detail: (userInfo.updatedAt != nil) ? dateFormatter.string(from: userInfo.updatedAt!) : "N/A"),
                .init(kind: .disclosure, id: "details", title: "Token details"),
                .init(kind: .action, id: "refresh", title: "Refresh")
            ],
            .actions: [
                .init(kind: .destructive, id: "signout", title: "Sign Out")
            ]
        ]

        tableView.reloadData()
    }
    
    func show(error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            self.show(alert, sender: nil)
        }
    }
    
    func signout() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(.init(title: "Remove", style: .default, handler: { _ in
            try? self.user?.remove()
            self.user = nil
        }))
        alert.addAction(.init(title: "Revoke tokens", style: .destructive, handler: { _ in
            self.user?.revoke(type: .accessToken) { result in
                if case let .failure(error) = result {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Sign out failed",
                                                      message: error.localizedDescription,
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }))
        alert.addAction(.init(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    func refresh() {
        user?.refresh { result in
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
}
