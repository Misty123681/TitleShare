// Copyright © 2019 Booktrack Holdings Limited. All rights reserved.

import Alamofire
import Apollo
import Swinject
import SwinjectStoryboard
import UIKit

extension SwinjectStoryboard {
    @objc
    class func setup() {
        defaultContainer.register(AlamofireApolloTransport.self) { _ in
            let graphqlUrl = URL(string: Constants.graphqlEndpoint)!
            return AlamofireApolloTransport(url: graphqlUrl, userAgent: Constants.userAgent, loggingEnabled: Constants.httpLoggingEnabled)
        }.inObjectScope(.container)

        defaultContainer.register(ApolloClient.self) { r in
            ApolloClient(networkTransport: r.resolve(AlamofireApolloTransport.self)!, store: ApolloStore(cache: DisabledApolloCache()))
        }.inObjectScope(.container)

        defaultContainer.register(CryptController.self) { _ in
            CryptController()
        }.inObjectScope(.container)

        defaultContainer.register(AppDataController.self) { _ in
            AppDataController()
        }.inObjectScope(.container)

        defaultContainer.register(AuthenticationController.self) { r in
            AuthenticationController(alamofireApolloTransport: r.resolve(AlamofireApolloTransport.self)!, apollo: r.resolve(ApolloClient.self)!, appData: r.resolve(AppDataController.self)!)
        }.inObjectScope(.container)

        defaultContainer.register(UserController.self) { r in
            UserController(apollo: r.resolve(ApolloClient.self)!, authController: r.resolve(AuthenticationController.self)!)
        }.inObjectScope(.container)

        defaultContainer.register(AudiobooksController.self) { r in
            AudiobooksController(apolloClient: r.resolve(ApolloClient.self)!, authenticationController: r.resolve(AuthenticationController.self)!)
        }.inObjectScope(.container)

        defaultContainer.register(BusyState.self) { _ in
            BusyState()
        }.inObjectScope(.container)

        defaultContainer.register(Model.self) { r in
            Model(userController: r.resolve(UserController.self)!, audiobooksController: r.resolve(AudiobooksController.self)!, applicationFileURLs: r.resolve(ApplicationFileURLs.self)!, authenticationController: r.resolve(AuthenticationController.self)!, cryptController: r.resolve(CryptController.self)!)
        }.inObjectScope(.container)

        defaultContainer.register(ApplicationFileURLs.self) { _ in
            ApplicationFileURLs()
        }.inObjectScope(.container)

        defaultContainer.register(AudiobookRegistry.self) { r in
            r.resolve(Model.self)!.audiobookRegistry
        }.inObjectScope(.container)

        defaultContainer.register(FileResourceController.self) { r in
            r.resolve(Model.self)!.fileResourceController
        }.inObjectScope(.container)

        defaultContainer.register(UserAudiobooks.self) { r in
            r.resolve(Model.self)!.userAudiobooks
        }.inObjectScope(.container)

        defaultContainer.storyboardInitCompleted(UINavigationController.self) { _, _ in
        }

        defaultContainer.storyboardInitCompleted(UITabBarController.self) { _, _ in
        }

        defaultContainer.storyboardInitCompleted(WelcomeViewController.self) { _, _ in
        }

        defaultContainer.storyboardInitCompleted(LoginViewController.self) { r, c in
            c.authenticationController = r.resolve(AuthenticationController.self)!
            c.busyState = r.resolve(BusyState.self)!
        }
        
        defaultContainer.storyboardInitCompleted(SignUpWithCodeViewController.self) { r, c in
            c.authenticationController = r.resolve(AuthenticationController.self)!
            c.busyState = r.resolve(BusyState.self)!
        }

        defaultContainer.storyboardInitCompleted(ResetPasswordViewController.self) { r, c in
            c.authenticationController = r.resolve(AuthenticationController.self)!
            c.busyState = r.resolve(BusyState.self)!
        }

        defaultContainer.storyboardInitCompleted(AudiobooksCollectionViewController.self) { r, c in
            c.model = r.resolve(Model.self)!
        }

        defaultContainer.storyboardInitCompleted(AudiobookDetailsViewController.self) { _, _ in
        }

        defaultContainer.storyboardInitCompleted(AudiobookPlayerViewController.self) { r, c in
            c.cryptController = r.resolve(CryptController.self)!
            c.model = r.resolve(Model.self)!
        }

        defaultContainer.storyboardInitCompleted(UserDetailsTableViewController.self) { r, c in
            c.model = r.resolve(Model.self)!
            c.authController = r.resolve(AuthenticationController.self)!
            c.busyState = r.resolve(BusyState.self)!
        }

        defaultContainer.storyboardInitCompleted(EditUserDetailsTableViewController.self) { r, c in
            c.model = r.resolve(Model.self)!
            c.busyState = r.resolve(BusyState.self)!
        }
    }
}
