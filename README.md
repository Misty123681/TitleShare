# titleshare-ios

## Certificates

We are using fastlane for certificate management, and we build hockey app and app store builds using our CI server.

Local development should "just work".

## Releasing beta builds

- `git checkout beta`
- `git merge master` (or whatever)
- `fastlane set_version_number version_number:"1.0.0"` (if required)
- `fastlane bump_build_number` (for each build)
- `git add .`
- `git commit -m "release xxx"` (or whatever. NOTE this commit message is used as the 'release notes' for the app center beta build)
- `git push`

Pushing to the `beta` branch will trigger circle-ci to produce a beta build which will automatically be uploaded to hockeyapp.

Releasing to the app store follows a similar procedure but with the difference being that the `stable` branch must be used.

For simplicity, the build number is shared between the beta and stable branches. Thus, care must be taken to merge the branch changes back into master ASAP.

## Graphql

We are using Apollo to generate our graphql client-side classes etc. It has a development-time dependency on nodejs. We use yarn to lock the versions.

On a development machine, it is necessary to have a recent nodejs environment available (nvm is useful for this, tested with nodejs v10.11.0 but anything in v10.* should work), as well as yarn, if one needs to regenerate the APIs.

There are scripts in `package.json` that fetch the latest schema from a locally running server and that generate the API. The code generator will automatically locate all `*.graphql` files within the titleshare directory and below.

These scripts can be invoked via:
* `yarn fetch-schema`
* `yarn generate-graphql-types`

`schema.json` is in source control so that developers aren't _required_ to have the server running locally when adding new functionality.

`API.swift` is in source control so that the CI process doesn't require a dependency on a nodejs environment just to produce a build (worth mentioning since the default setup instructions for Apollo iOS force API regeneration upon each build).

## Code formatting

We depend upon a Pod called SwiftFormat which consistently formats our swift code as per the default settings.

It can be run with `Pods/SwiftFormat/CommandLineTool/swiftformat .` (or `yarn format-code`) from the root of the repository. Please run this periodically to whip our code into shape.

Note that unlike the other Pods we rely upon, SwiftFormat is __not__ checked into source control. Thus, the local developer will need to run `pod install` to obtain it. The rationale is that the binary is > 10 MB, and it isn't needed for CI tasks.
