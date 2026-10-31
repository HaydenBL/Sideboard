# Sideboard

Keeps track of when my sideloaded iOS apps expire, so I rebuild them before they stop launching.

- **`Sources/SideloadKit/`**: a Swift package that each app calls at launch with `SideloadReporter.report()`. It reads the app's `embedded.mobileprovision` and saves the install and expiry dates to the shared App Group `group.se.haydenblai.sideload`.
- **`Sideboard/`**: the dashboard app and its widget. They list every reporting app by expiry date and send notifications 14, 7 and 1 days before an app expires.

## Adding an app
1. Add the App Group `group.se.haydenblai.sideload` to the app target.
2. Add this repo as a package dependency (File → Add Package Dependencies, `https://github.com/HaydenBL/Sideboard`, branch `master`) and link `SideloadKit` to the app target.
3. Call `SideloadReporter.report()` at launch.
