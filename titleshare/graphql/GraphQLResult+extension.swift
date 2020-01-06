// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Apollo
import Foundation

extension GraphQLResult {
    public func hasErrorWithExtension(code: String) -> Bool {
        guard let errors = self.errors else { return false }
        return errors.contains { error -> Bool in
            guard let extensions = error.extensions else { return false }
            guard let subjectCode = extensions["code"] as? String else { return false }
            return subjectCode == code
        }
    }
}

