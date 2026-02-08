import ProjectDescription
import ProjectDescriptionHelpers

let skAdNetworks: [Plist.Value] = ["cstr6suwn9",
                                   "4fzdc2evr5",
                                   "2fnua5tdw4",
                                   "ydx93a7ass",
                                   "5a6flpkh64",
                                   "p78axxw29g",
                                   "v72qych5uu",
                                   "c6k4g5qg8m",
                                   "s39g8k73mm",
                                   "3qy4746246",
                                   "3sh42y64q3",
                                   "f38h382jlk",
                                   "hs6bdukanm",
                                   "prcb7njmu6",
                                   "wzmmz9fp6w",
                                   "yclnxrl5pm",
                                   "4468km3ulz",
                                   "t38b2kh725",
                                   "7ug5zh24hu",
                                   "9rd848q2bz",
                                   "n6fk4nfna4",
                                   "kbd757ywx3",
                                   "9t245vhmpl",
                                   "2u9pt9hc89",
                                   "8s468mfl3y",
                                   "av6w8kgt66",
                                   "klf5c3l5u5",
                                   "ppxm28t8ap",
                                   "424m5254lk",
                                   "uw77j35x4d",
                                   "e5fvkxwrpn",
                                   "zq492l623r",
                                   "3qcr597p9d"
    ]
    .map{ .dictionary(["SKAdNetworkIdentifier" : "\($0).skadnetwork"]) }

let project = Project(
    name: "App",
    options: .options(defaultKnownRegions: ["en"],
                     developmentRegion: "en"),
    packages: [
        .remote(url: "https://github.com/2sem/GADManager",
                requirement: .upToNextMajor(from: "1.3.8")),
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
            productName: "WhereWeGo",
            bundleId: "com.y2k.wherewego",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen",
                    "GADApplicationIdentifier": "ca-app-pub-9684378399371172~7031400848",
                    "GADUnitIdentifiers": ["FullAd" : "ca-app-pub-9684378399371172/8508134041",
                                           "Launch" : "ca-app-pub-9684378399371172/7315475245",
                                           "BottomBanner" : "ca-app-pub-9684378399371172/7473624288",
                                           "RewardAd" : "ca-app-pub-9684378399371172/2568071527"],
                    "Itunes App Id": "1241856636",
                    "NSUserTrackingUsageDescription": "Use location information to explore nearby attractions.",
                    "SKAdNetworkItems": .array(skAdNetworks),
                    "ITSAppUsesNonExemptEncryption": "NO",
                    "CFBundleShortVersionString": "${MARKETING_VERSION}",
                    "CFBundleDisplayName": "WhereWeGo",
                    "NSAppTransportSecurity": [
                        "NSAllowsArbitraryLoads": true
                    ],
                    "MKDirectionsApplicationSupportedModes": [
                        "MKDirectionsModeBike",
                        "MKDirectionsModeBus",
                        "MKDirectionsModeCar",
                        "MKDirectionsModePedestrian",
                        "MKDirectionsModeSubway",
                        "MKDirectionsModeTransit",
                        "MKDirectionsModeTaxi",
                        "MKDirectionsModeRideShare",
                        "MKDirectionsModeStreetCar"
                    ],
                    "LSApplicationQueriesSchemes": [
                        "nmap",
                        "kakaomap"
                    ]
                ]
            ),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            //            entitlements: .file(path: .relativeToCurrentFile("Sources/gersanghelper.entitlements")),
            scripts: [.post(script: "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run",
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
