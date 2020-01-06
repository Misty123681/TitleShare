// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Foundation
import MaterialComponents.MaterialSnackbar

fileprivate let defaultDuration = 6.0

extension MDCSnackbarMessage {
    
    static func show(text: String, category: String? = nil) {
        MDCSnackbarManager.dismissAndCallCompletionBlocks(withCategory: category)
        let message = MDCSnackbarMessage()
        message.text = text
        message.duration = defaultDuration
        message.category = category
        MDCSnackbarManager.show(message)
    }
    
    static func showNetworkError(category: String? = nil) {
        show(text: "A network error occurred, please try again", category: category)
    }
    
    static func showNetworkRefreshError(category: String? = nil) {
        show(text: "Failed to refesh due to a network issue", category: category)
    }
    
    static func showUnexpectedLogoutError(category: String? = nil) {
        show(text:  "You have been logged out. Please login again", category: category)
    }
    
    static func showGenericServerError(category: String? = nil) {
        show(text: "A server error occurred, please try again", category: category)
    }
    
    static func showServerRefreshError(category: String? = nil) {
        show(text: "Failed to refesh due to a server issue", category: category)
    }
}
