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
                    SOURCE_PACKAGES_ROOT="${SOURCE_PACKAGES_DIR_PATH:-${BUILD_DIR%/Build/*}/SourcePackages}"
                    CRASHLYTICS_RUN_SCRIPT=""

                    for candidate in \
                      "$SOURCE_PACKAGES_ROOT/checkouts/firebase-ios-sdk/Crashlytics/run" \
                      "$SOURCE_PACKAGES_ROOT/registry/downloads/firebase/firebase-ios-sdk/Crashlytics/run" \
                      "$SOURCE_PACKAGES_ROOT"/registry/downloads/firebase/firebase-ios-sdk/*/Crashlytics/run
                    do
                      if [ -f "$candidate" ]; then
                        CRASHLYTICS_RUN_SCRIPT="$candidate"
                        break
                      fi
                    done

                    if [ -z "$CRASHLYTICS_RUN_SCRIPT" ]; then
                      echo "error: Firebase Crashlytics run script not found under $SOURCE_PACKAGES_ROOT"
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
                            runForInstallBuildsOnly: true)],
            dependencies: [
                .Projects.ThirdParty,
                .Projects.DynamicThirdParty,
                .package(product: "GADManager", type: .runtime)
            ],
            settings: .settings(configurations: [
                .debug(
                    name: "Debug",
                    xcconfig: "Configs/app.debug.xcconfig"),
                .release(
                    name: "Release",
                    xcconfig: "Configs/app.release.xcconfig")
            ])
        ),
    ], resourceSynthesizers: []
)
