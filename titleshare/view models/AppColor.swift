// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: alpha
        )
    }

    convenience init(rgb: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF,
            alpha: alpha
        )
    }
}

class AppColor {
    public static let appAqua = UIColor(rgb: 0x4FEAF2, alpha: 1.0)
    public static let appGrey = UIColor(rgb: 0xC8C7CC, alpha: 1.0)
    public static let appNavy = UIColor(rgb: 0x143566, alpha: 1.0)
    public static let appPink = UIColor(rgb: 0xED1663, alpha: 1.0)
    public static let appRed = UIColor(rgb: 0xC81C24, alpha: 1.0)
}
