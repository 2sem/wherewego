import ProjectDescription

let project = Project(
    name: "DynamicThirdParty",
    packages: [.package(id: "SDWebImage.SDWebImage", from: "5.21.7"),
               .package(id: "firebase.firebase-ios-sdk", from: "12.17.0"),
    ],
    targets: [
        .target(
            name: "DynamicThirdParty",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.y2k.wherewego.thirdparty.dynamic",
            dependencies: [.package(product: "SDWebImage", type: .runtime),
                           .package(product: "FirebaseCrashlytics", type: .runtime),
                           .package(product: "FirebaseAnalytics", type: .runtime),
                           .package(product: "FirebaseMessaging", type: .runtime),
                           .package(product: "FirebaseRemoteConfig", type: .runtime)
            ]
        ),
    ]
)
