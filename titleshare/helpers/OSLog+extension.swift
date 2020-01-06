// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation
import os

extension OSLog {
    convenience init(category: String = #function) {
        self.init(subsystem: Bundle.main.bundleIdentifier!, category: category)
    }
}
