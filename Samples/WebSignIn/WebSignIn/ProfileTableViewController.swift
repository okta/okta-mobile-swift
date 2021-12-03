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
import WebAuthenticationUI

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
    var user: User? {
        didSet {
            if let user = user {
                DispatchQueue.main.async {
                    self.configure(user)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(forName: .userChanged,
                                               object: nil,
                                               queue: .main) { (notification) in
            guard let user = notification.object as? User else { return }
            self.user = user
        }
        user = UserManager.shared.current
    }
    
    func row(at indexPath: IndexPath) -> Row? {
        guard let tableSection = Section(rawValue: indexPath.section),
              let row = tableContent[tableSection]?[indexPath.row]
        else {
            return nil
        }
        
        return row
    }
    
    func configure(_ user: User) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .long

        title = user.info.name
        self.tabBarItem.title = title

        tableContent = [
            .profile: [
                .init(kind: .rightDetail, id: "givenName", title: "Given name", detail: user.info.givenName),
                .init(kind: .rightDetail, id: "familyName", title: "Family name", detail: user.info.familyName),
                .init(kind: .rightDetail, id: "locale", title: "Locale", detail: user.info.locale),
                .init(kind: .rightDetail, id: "timezone", title: "Timezone", detail: user.info.zoneinfo)
            ],
            .details: [
                .init(kind: .rightDetail, id: "username", title: "Username", detail: user.info.preferredUsername),
                .init(kind: .rightDetail, id: "userId", title: "User ID", detail: user.info.sub),
                .init(kind: .rightDetail, id: "createdAt", title: "Created at", detail: dateFormatter.string(from: user.info.updatedAt)),
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
        let userManager = UserManager.shared
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(.init(title: "Clear tokens", style: .default, handler: { _ in
            userManager.current = nil
        }))
//        alert.addAction(.init(title: "Revoke tokens", style: .destructive, handler: { _ in
//            userManager.current?.token.revoke { (success, error) in
//                guard success else {
//                    DispatchQueue.main.async {
//                        let alert = UIAlertController(title: "Sign out failed", message: error?.localizedDescription, preferredStyle: .alert)
//                        alert.addAction(.init(title: "OK", style: .default))
//                        self.present(alert, animated: true)
//                    }
//                    return
//                }
//                userManager.current = nil
//            }
//        }))
        alert.addAction(.init(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    func refresh() {
//        guard let user = UserManager.shared.current else { return }
//        user.token.refresh { (token, error) in
//            if let token = token {
//                UserManager.shared.current = User(token: token, info: user.info)
//            } else if let error = error {
//                self.show(error: error)
//            }
//        }
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
            target.token = user?.token

        default: break
        }
    }
}
