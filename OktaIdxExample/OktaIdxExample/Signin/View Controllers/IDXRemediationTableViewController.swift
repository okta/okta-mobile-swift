//
//  IDXRemediationTableViewController.swift
//  OktaIdxExample
//
//  Created by Mike Nachbaur on 2021-01-13.
//

import UIKit
import OktaIdx
import Combine

class IDXRemediationTableViewController: UITableViewController, IDXRemediationController {
    var remediationOption: IDXClient.Remediation.Option?
    var response: IDXClient.Response?
    var signin: Signin?

    var formSections: [Signin.Section] = []
    var formValues: [String:Any] = [:]
    var chosenRemediationOption: IDXClient.Remediation.FormValue? = nil
    
    private var cancelObject: AnyCancellable?
    
    deinit {
        cancelObject?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let response = response,
           let remediationOption = remediationOption
        {
            formSections = response.remediationForm(form: remediationOption.form, delegate: self)
        }
    }

    @IBAction func continueAction(_ sender: Any) {
        guard let signin = signin else {
            showError(SigninError.genericError(message: "Signin session deallocated"))
            return
        }
        
        if let button = sender as? UIButton {
            button.isEnabled = false
        }
        
        cancelObject = remediationOption?
            .proceed(with: formValues)
            .receive(on: RunLoop.main)
            .sink { (completion) in
                switch completion {
                case .failure(let error):
                    self.showError(error)
                    signin.failure(with: error)
                case .finished: break
                }
            } receiveValue: { (response) in
                signin.proceed(to: response)
            }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        guard let signin = signin else {
            showError(SigninError.genericError(message: "Signin session deallocated"))
            return
        }

        if let button = sender as? UIButton {
            button.isEnabled = false
        }

        cancelObject = response?
            .cancel()
            .receive(on: RunLoop.main)
            .sink { (completion) in
                switch completion {
                case .failure(let error):
                    self.showError(error)
                    signin.failure(with: error)
                case .finished: break
                }
            } receiveValue: { (response) in
                signin.proceed(to: response)
            }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return formSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let formSection = formSections[section]
        return formSection.rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = formSections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.kind.reuseIdentifier, for: indexPath)

        row.configure(cell: cell, at: indexPath)

        return cell
    }
}

extension IDXRemediationTableViewController: SigninRowDelegate {
    func value(for key: String) -> Any? {
        return formValues[key]
    }
    
    func row(row: Signin.Row, changedValue: (String, Any)) {
        if let parentField = row.parent,
           let parentName = parentField.name
        {
            var childCollection = formValues[parentName] as? [String:Any] ?? [:]
            childCollection[changedValue.0] = changedValue.1
            formValues[parentName] = childCollection
        } else {
            formValues[changedValue.0] = changedValue.1
        }

        if type(of: changedValue.1) == IDXClient.Remediation.FormValue.self {
            tableView.reloadData()
        }
    }
}

extension Signin.Row.Kind {
    var reuseIdentifier: String {
        switch self {
        case .label(field: _):     return "Label"
        case .message(message: _): return "Message"
        case .text(field: _):      return "Text"
        case .toggle(field: _):    return "Toggle"
        case .option(field: _,
                     option: _):   return "Option"
        case .button:              return "Button"
        }
    }
}

extension Signin.Row {
    func configure(cell: UITableViewCell, at indexPath: IndexPath) {
        switch self.kind {
        case .label(field: let field):
            if let cell = cell as? IDXLabelTableViewCell {
                cell.fieldLabel.text = field.label
            }
            
        case .message(message: let message):
            if let cell = cell as? IDXMessageTableViewCell {
                cell.messageLabel.text = message.message
                cell.type = IDXMessageTableViewCell.MessageType(rawValue: message.type.rawValue)
            }
            
        case .text(field: let field):
            if let cell = cell as? IDXTextTableViewCell,
               let fieldName = field.name
            {
                cell.fieldLabel.text = field.label
                cell.textField.isSecureTextEntry = field.secret
                cell.textField.text = (delegate?.value(for: fieldName) ?? field.value as Any) as? String
                cell.update = { value in
                    self.delegate?.row(row: self, changedValue: (fieldName, value))
                }
            }
            
        case .toggle(field: let field):
            if let cell = cell as? IDXToggleTableViewCell,
               let fieldName = field.name
             {
                cell.fieldLabel.text = field.label
                cell.switchView.isOn = (delegate?.value(for: fieldName) ?? field.value as Any) as? Bool ?? false
            }
            
        case .option(field: let field, option: let option):
            if let cell = cell as? IDXOptionTableViewCell,
               let fieldName = field.name {
                let currentValue = self.delegate?.value(for: fieldName) as? IDXClient.Remediation.FormValue
                
                cell.fieldLabel.text = option.label
                cell.state = (currentValue == option) ? .checked : .unchecked
                cell.update = {
                    self.delegate?.row(row: self, changedValue: (fieldName, option))
                }
            }
            
        case .button(kind: let kind):
            if let cell = cell as? IDXButtonTableViewCell {
                cell.displayKinds = kind
            }
        }
    }
}
