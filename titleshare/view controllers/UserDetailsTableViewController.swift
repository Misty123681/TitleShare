// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit
import MaterialComponents.MaterialSnackbar

class UserDetailsTableViewController: UITableViewController {
    // MARK: Properties

    var model: Model!
    internal var authController: AuthenticationController?
    internal var busyState: BusyState?

    enum ViewSection: Int, CaseIterable {
        case accountDetails = 0
        case links
        case logout
    }

    enum UserMetadataFields: Int, CaseIterable {
        case firstName = 0
        case lastName
        case email
    }

    enum LinkType {
        case url
        case email
        case licences
    }

    let externalLinks: [(type: LinkType, name: String, url: String)] = [
        (LinkType.url, "Terms of Service", Constants.termsAndConditionsUrl),
        (LinkType.url, "Privacy policy", Constants.privacyUrl),
        (LinkType.licences, "Third party licences", ""),
        (LinkType.email, "Email support", "mailto:\(Constants.supportEmail)"),
        (LinkType.url, "FAQ & Support", Constants.faqUrl),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(authController != nil)
        assert(busyState != nil)
        loadCurrentUser()

        if let refreshControl = refreshControl {
            refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: UIControl.Event.valueChanged)
        }
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
        tableView.reloadData()
    }

    @objc func refresh(sender _: AnyObject) {
        loadCurrentUser()
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        return ViewSection.allCases.count
    }

    override func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == ViewSection.accountDetails.rawValue {
            return 70
        }

        return 28
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionEnum = ViewSection(rawValue: section) else {
            fatalError("Unexpected section number \(section)")
        }

        switch sectionEnum {
        case ViewSection.accountDetails:
            return UserMetadataFields.allCases.count
        case ViewSection.links:
            return externalLinks.count
        case ViewSection.logout:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionEnum = ViewSection(rawValue: indexPath.section) else {
            fatalError("Unexpected section number \(indexPath.section)")
        }

        // Configure the cell...
        switch sectionEnum {
        case ViewSection.accountDetails:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserDetailsTableViewCell", for: indexPath)
                as? UserDetailsTableViewCell else {
                fatalError("The dequeued cell is not an instance of UserDetailsTableViewCell.")
            }

            guard let metadataField = UserMetadataFields(rawValue: indexPath.row) else {
                fatalError("Unexpected metadata field row \(indexPath.row)")
            }

            let metadata = model.userState.user.value?.metadata.value
            switch metadataField {
            case UserMetadataFields.firstName:
                cell.fieldLabel.text = "First name"
                cell.fieldValueLabel.text = metadata?.firstName ?? ""
                break
            case UserMetadataFields.lastName:
                cell.fieldLabel.text = "Last name"
                cell.fieldValueLabel.text = metadata?.lastName ?? ""
                break
            case UserMetadataFields.email:
                cell.fieldLabel.text = "Email"
                cell.fieldValueLabel.text = metadata?.email ?? ""
                break
            }
            return cell
        case ViewSection.links:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "LinkTableViewCell", for: indexPath)
                as? LinkTableViewCell else {
                fatalError("The dequeued cell is not an instance of LinkTableViewCell.")
            }

            let link = externalLinks[indexPath.row]
            cell.linkTextLabel.text = link.name
            return cell
        case ViewSection.logout:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "LinkTableViewCell", for: indexPath)
                as? LinkTableViewCell else {
                fatalError("The dequeued cell is not an instance of LinkTableViewCell.")
            }

            cell.linkTextLabel.text = "Logout"
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == ViewSection.accountDetails.rawValue {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderTableViewCell")
                as? HeaderTableViewCell else {
                fatalError("The dequeued cell is not an instance of HeaderTableViewCell.")
            }

            cell.headerText = "ACCOUNT DETAILS"
            return cell
        }

        return nil
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sectionEnum = ViewSection(rawValue: indexPath.section) else {
            fatalError("Unexpected section number \(indexPath.section)")
        }
        switch sectionEnum {
        case ViewSection.links:
            let link = externalLinks[indexPath.row]

            switch link.type {
            case .url:
                self.showTermsCondition(urlString: link.url)
//                guard let url = URL(string: link.url) else {
//                    fatalError("Invalid url for \(link.name)")
//                }
//
//                UIApplication.shared.open(url, options: [:], completionHandler: nil)

            case .email:
                guard let url = URL(string: link.url) else {
                    fatalError("Invalid email for \(link.name)")
                }

                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)

                } else {
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: "", message: "titleShare could not launch your email system. \n To contact support, email support@booktrack.com", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default))
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            case .licences:
                performSegue(withIdentifier: "showLicenses", sender: self)
                return
            }
            
        case ViewSection.logout:
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: nil, message: "This will log you out across all devices and from the website", preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: "Logout", style: .default) { [weak self] _ in
                    guard let self = self else { return }
                    let exitBusyState = self.busyState!.enter()
                    self.authController!.logout {
                        exitBusyState()
                        LoginState.requestWelcomeScene()
                        MDCSnackbarMessage.show(text: "You have been logged out")
                    }
                })
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                if let popoverPresentationController = alertController.popoverPresentationController {
                    popoverPresentationController.sourceView = self.tableView
                    popoverPresentationController.sourceRect = self.tableView.rectForRow(at: indexPath)
                }
                self.present(alertController, animated: true, completion: nil)
            }
            return
        default:
            return
        }
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        switch segue.identifier {
        case "editUserDetails":
            break
        default:
            // Do nothing
            break
        }
    }

    // MARK: Private Functions

    private func loadCurrentUser() {
        let exitBusyState = busyState!.enter()

        model.userState.fetchCurrentUser { result in
            exitBusyState()
            self.refreshControl?.endRefreshing()

            switch result {
            case .success:
                self.tableView.reloadData()
            case .networkError:
                MDCSnackbarMessage.showNetworkRefreshError()
            case .unauthenticated:
                LoginState.requestLogin()
                MDCSnackbarMessage.showUnexpectedLogoutError()
            case .serverError:
                MDCSnackbarMessage.showServerRefreshError()
            case .cancelled:
                break
            }
        }
    }
    
    //MARK: -  showTermsCondition Method for open URl in the safari view controller inside the app.
        
       func showTermsCondition(urlString:String){
              let storyboard = UIStoryboard(name: "Main", bundle: nil)
               let controller = storyboard.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
              controller.urlString = urlString
               self.navigationController?.pushViewController(controller, animated: false)
          }
}
