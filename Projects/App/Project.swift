import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "App",
    options: .options(defaultKnownRegions: ["en"],
                     developmentRegion: "en"),
    packages: [
        .remote(url: "https://github.com/2sem/GADManager",
                requirement: .upToNextMajor(from: "1.4.0")),
//        .remote(url: "https://github.com/firebase/firebase-ios-sdk",
//                requirement: .upToNextMajor(from: "10.4.0")),
    ],
    settings: .settings(configurations: [
        .debug(
            name: "Debug",
            xcconfig: "Configs/app.debug.xcconfig"),
        .release(
            name: "Release",
            xcconfig: "Configs/app.release.xcconfig")
    ]),
    targets: [
        .target(
            name: "App",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "com.y2k.wherewego",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen",
                    "GADApplicationIdentifier": "ca-app-pub-9684378399371172~7031400848",
                    "GADUnitIdentifiers": ["FullAd" : "ca-app-pub-9684378399371172/8508134041",
                                           "Launch" : "ca-app-pub-9684378399371172/7315475245",
                                           "HomeBanner" : "ca-app-pub-9684378399371172/7473624288",
                                           "DetailBanner" : "ca-app-pub-9684378399371172/2251028588",
                                           "MapBanner" : "ca-app-pub-9684378399371172/6185560275",
                                           "RewardAd" : "ca-app-pub-9684378399371172/2568071527"],
                    "Itunes App Id": "1241856636",
                    "NSLocationWhenInUseUsageDescription": "WhereWeGo uses your location to find nearby attractions.",
                    "NSUserTrackingUsageDescription": "Use location information to explore nearby attractions.",
                    "SKAdNetworkItems": [],
                    "ITSAppUsesNonExemptEncryption": "NO",
                    "CFBundleShortVersionString": "${MARKETING_VERSION}",
                    "CFBundleDisplayName": "WhereWeGo",
                    "NSAppTransportSecurity": [
                        "NSAllowsArbitraryLoads": true
                    ],
                    "LSApplicationQueriesSchemes": [
                        "nmap",
                        "kakaomap",
                        "comgooglemaps"
                    ]
                ]
            ),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            //            entitlements: .file(path: .relativeToCurrentFile("Sources/gersanghelper.entitlements")),
            scripts: [.post(script: "/bin/sh \"${SRCROOT}/Scripts/merge_skadnetworks.sh\"",
                            name: "Merge SKAdNetworkItems",
                            inputPaths: ["$(SRCROOT)/Resources/InfoPlist/skNetworks.plist"],
                            outputPaths: []),
                      .post(script: """
                    # Firebase is now a Tuist-integrated dependency (Tuist/Package.swift),
                    # so its checkout lives under Tuist/.build, not Xcode's own
                    # SourcePackages directory. Path is relative to $(SRCROOT)
                    # (Projects/App).
                    CRASHLYTICS_RUN_SCRIPT="${SRCROOT}/../../Tuist/.build/checkouts/firebase-ios-sdk/Crashlytics/run"

                    if [ ! -f "$CRASHLYTICS_RUN_SCRIPT" ]; then
                      echo "error: Firebase Crashlytics run script not found at $CRASHLYTICS_RUN_SCRIPT - run 'tuist install' first"
                      exit 1
                    fi

                    "$CRASHLYTICS_RUN_SCRIPT"
                    """,
                            name: "Upload dSYM for Crashlytics",
                            inputPaths: ["${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}",
                                         "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}",
                                         "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist",
                                         "$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist",
                                         "$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)"],
                            basedOnDependencyAnalysis: false,
                            runForInstallBuildsOnly: true)],
            dependencies: [
                .Projects.ThirdParty,
                .package(product: "GADManager", type: .runtime),
                // Firebase links directly into App rather than through an intermediate
                // dynamic wrapper framework: Tuist's SPM integration doesn't reliably
                // propagate the binary XCFrameworks Firebase pulls in
                // (GoogleAppMeasurement, nanopb, ...) through such a wrapper, which
                // shows up as undefined symbols at the *app* target's link/archive
                // step even though the wrapper itself builds fine.
                .external(name: "FirebaseCrashlytics"),
                .external(name: "FirebaseAnalytics"),
                .external(name: "FirebaseMessaging"),
                .external(name: "FirebaseRemoteConfig"),
            ],
            settings: .settings(
                base: [
                    // The Crashlytics "run" tool lives under Tuist/.build/checkouts,
                    // outside $(SRCROOT), and reads files (GoogleService-Info.plist,
                    // dSYMs, its own sibling binary) that User Script Sandboxing
                    // would otherwise block regardless of the phase's declared
                    // Input Files. Disabling sandboxing for this target only (not
                    // project-wide) is the reliable fix.
                    "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
                ],
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig: "Configs/app.debug.xcconfig"),
                    .release(
                        name: "Release",
                        xcconfig: "Configs/app.release.xcconfig")
                ]
            )
        ),
    ], resourceSynthesizers: []
)
