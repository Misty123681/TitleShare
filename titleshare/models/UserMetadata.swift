// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation

class UserMetadata: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let roles: [UserRole]

    init(
        firstName: String,
        lastName: String,
        email: String,
        roles: [UserRole]
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.roles = roles
    }
}

struct UserRole: Codable {
    let organisationId: String?
    let roleType: UserRoleType?
}

enum UserRoleType: String, Codable {
    case sysAdmin
    case orgAdmin
    case consumer
}
