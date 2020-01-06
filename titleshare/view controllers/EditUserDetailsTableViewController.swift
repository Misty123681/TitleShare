// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit
import MaterialComponents.MaterialSnackbar

class EditUserDetailsTableViewController: UITableViewController {
    // MARK: Properties

    var model: Model!
    internal var busyState: BusyState?
    @IBOutlet var saveButton: UIBarButtonItem!

    enum UserMetadataFields: Int, CaseIterable {
        case firstName = 0
        case lastName
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(busyState != nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return UserMetadataFields.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserDetailsTableViewCell", for: indexPath)
            as? UserDetailsTableViewCell else {
            fatalError("The dequeued cell is not an instance of UserDetailsTableViewCell.")
        }

        guard let metadataField = UserMetadataFields(rawValue: indexPath.row) else {
            fatalError("Unexpected metadata field row \(indexPath.row)")
        }

        cell.fieldLabel.text = getFieldLabel(for: metadataField)
        cell.textField.placeholder = cell.fieldLabel.text
        if metadataField.rawValue == 0 {
            cell.textField.becomeFirstResponder()
        }

        let metadata = model.userState.user.value?.metadata.value
        switch metadataField {
        case UserMetadataFields.firstName:
            cell.textField.text = metadata?.firstName ?? ""
            break
        case UserMetadataFields.lastName:
            cell.textField.text = metadata?.lastName ?? ""
            break
        }

        return cell
    }

    // MARK: - Navigation

    @IBAction func cancel(_: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func save(_: UIBarButtonItem) {
        save()
    }

    // MARK: Private functions

    private func getCell(for field: UserMetadataFields) -> UserDetailsTableViewCell {
        guard let cell = self.tableView.cellForRow(at: IndexPath(row: field.rawValue, section: 0)) as? UserDetailsTableViewCell else {
            fatalError("The cell at row \(field.rawValue) is not an instance of UserDetailsTableViewCell.")
        }

        let expectedFieldLabel = getFieldLabel(for: field)
        if cell.fieldLabel.text != expectedFieldLabel {
            fatalError("Unexpected UserDetailsTableViewCell field label, Expected \(expectedFieldLabel) but got \(String(describing: cell.fieldLabel.text))")
        }

        return cell
    }

    private func getFieldLabel(for field: UserMetadataFields) -> String {
        switch field {
        case .firstName:
            return "First name"
        case .lastName:
            return "Last name"
        }
    }

    private func save() {
        let firstNameCell = getCell(for: .firstName)
        let lastNameCell = getCell(for: .lastName)

        let exitBusyState = busyState!.enter()
        model.userState.update(firstname: firstNameCell.textField.text, lastname: lastNameCell.textField.text) { result in
            exitBusyState()

            switch result {
            case .success:
                self.dismiss(animated: true, completion: nil)
            case .networkError:
                MDCSnackbarMessage.showNetworkError()
            case .unauthenticated:
                LoginState.requestLogin()
                MDCSnackbarMessage.showUnexpectedLogoutError()
            case .serverError:
                MDCSnackbarMessage.showGenericServerError()
            case .cancelled:
                break
            }
        }
    }
}
