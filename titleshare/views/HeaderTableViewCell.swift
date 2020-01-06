// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

class HeaderTableViewCell: UITableViewCell {
    @IBOutlet var headerTextLabel: UILabel!

    var headerText: String {
        get {
            return self.headerTextLabel.text ?? ""
        }
        set(value) {
            self.headerTextLabel.text = value
            self.formatHeaderText()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: Private functions

    private func formatHeaderText() {
        let attributedString = NSMutableAttributedString(string: headerText)
        let listItems = headerText.components(separatedBy: " ")
        if listItems.count <= 1 {
            return
        }

        let boldStr = listItems[1]
        let boldRange = NSString(string: headerText).range(of: boldStr)

        attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "Avenir-Black", size: 16)!, range: boldRange)

        headerTextLabel.attributedText = attributedString
    }
}
