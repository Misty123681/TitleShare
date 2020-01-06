// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

class UserDetailsTableViewCell: UITableViewCell {
    @IBOutlet var fieldLabel: UILabel!
    @IBOutlet var fieldValueLabel: UILabel!
    @IBOutlet var textField: UITextField!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
