// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import AppCenterDistribute
import MaterialComponents.MaterialSnackbar
import os
import SwinjectStoryboard
import UIKit

fileprivate let snackbarCategory = "appUpgradeNeeded"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let _resources = Resource()
    var window: UIWindow?
    private let log = OSLog()

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        os_log("didFinishLaunchingWithOptions", log: log, type: .info)

        #if !CONFIGURATION_DEBUG
            os_log("Starting AppCenter services", log: log, type: .debug)
            MSAppCenter.start(Constants.appCenterAppSecret, withServices: [MSAnalytics.self, MSCrashes.self, MSDistribute.self])
        #endif

        let appData = SwinjectStoryboard.defaultContainer.resolve(AppDataController.self)
        if appData?.userAuthToken != nil {
            // If the user is logged in, land them on the audiobooks collection screen
            let landingController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "MainTabBarController")
            window?.rootViewController = landingController
        }

        let alamofireApolloTransport = SwinjectStoryboard.defaultContainer.resolve(AlamofireApolloTransport.self)!
        _resources.aggregate(resource: alamofireApolloTransport.unsupportedAppVersion.watch(invokeNow: false, watchHandler: { unsupportedAppVersion in
            guard unsupportedAppVersion == true else { return }
            let message = MDCSnackbarMessage()
            message.text = "Unsupported application version, please update"
            message.duration = MDCSnackbarMessageDurationMax
            message.category = snackbarCategory
            MDCSnackbarManager.show(message)
        }))

        // Dump the app support directory to the console, aids in debugging FS content while running on simulator
        let fileManager = FileManager()
        let applicationSupportDirectory = try! fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        os_log("%@", log: log, type: .debug, applicationSupportDirectory.debugDescription)

        return true
    }

    func applicationWillResignActive(_: UIApplication) {
        os_log("applicationWillResignActive", log: log, type: .info)
    }

    func applicationDidEnterBackground(_: UIApplication) {
        os_log("applicationDidEnterBackground", log: log, type: .default)
        let model = SwinjectStoryboard.defaultContainer.resolve(Model.self)
        model?.save()
    }

    func applicationWillEnterForeground(_: UIApplication) {
        os_log("applicationWillEnterForeground", log: log, type: .info)
    }

    func applicationDidBecomeActive(_: UIApplication) {
        os_log("applicationDidBecomeActive", log: log, type: .default)
        let model = SwinjectStoryboard.defaultContainer.resolve(Model.self)
        model?.fileResourceController.createURLSessionOnce()
        model?.fileResourceController.synchroniseURLSessionOnce()
    }

    func applicationWillTerminate(_: UIApplication) {
        os_log("applicationWillTerminate", log: log, type: .info)
    }

    func application(_: UIApplication, handleEventsForBackgroundURLSession _: String, completionHandler handler: @escaping () -> Void) {
        os_log("handleEventsForBackgroundURLSession", log: log, type: .default)
        let model = SwinjectStoryboard.defaultContainer.resolve(Model.self)
        model?.fileResourceController.handleEventsForBackgroundURLSessionCompletionHandler = handler
        model?.fileResourceController.createURLSessionOnce()
    }
}
