fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios ci_build_beta
```
fastlane ios ci_build_beta
```
Builds an adhoc beta and uploads it to hockeyapp
### ios ci_build_stable
```
fastlane ios ci_build_stable
```
Builds an appstore release
### ios bump_build_number
```
fastlane ios bump_build_number
```
Bumps the build number
### ios set_version_number
```
fastlane ios set_version_number
```
Sets the version number

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
