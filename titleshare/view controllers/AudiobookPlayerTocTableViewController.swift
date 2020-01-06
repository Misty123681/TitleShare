// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

class AudiobookPlayerTocTableViewController: UITableViewController {
    internal var audiobook: Audiobook!
    internal var selectedAudioSectionIndex: Int?
    internal var audioSectionWasSelected: ((_ selectedIndex: Int) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return audiobook.audiobookSections.value?.items.value?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        // Configure the cell...
        cell.selectionStyle = .none
        cell.textLabel?.text = "File \(indexPath.row + 1)"

        if indexPath.row == selectedAudioSectionIndex {
            cell.accessoryView = UIImageView(image: UIImage(named: "ic_tick"))
        } else {
            cell.accessoryView = nil
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedIndex = self.selectedAudioSectionIndex, let previousCell = tableView.cellForRow(at: IndexPath(row: selectedIndex, section: 0)) {
            previousCell.accessoryView = nil
        }

        guard let selectedCell = tableView.cellForRow(at: indexPath) else {
            fatalError("Index path \(String(describing: indexPath)) did not reference an instance of a cell")
        }

        selectedCell.accessoryView = UIImageView(image: UIImage(named: "ic_tick"))
        selectedAudioSectionIndex = indexPath.row
        audioSectionWasSelected?(indexPath.row)
        navigationController?.popViewController(animated: true)
    }
}
