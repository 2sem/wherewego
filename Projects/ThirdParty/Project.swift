import ProjectDescription

let project = Project(
    name: "ThirdParty",
    packages: [
        .package(id: "kakao.kakao-ios-sdk", from: "2.27.3"),
        .remote(url: "https://github.com/2sem/LSExtensions",
                               requirement: .exact("0.1.24")),
        .remote(url: "https://github.com/2sem/StringLogger",
                requirement: .upToNextMajor(from: "0.7.0")),
    ],
    targets: [
        .target(
            name: "ThirdParty",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.y2k.wherewego.thirdparty",
            deploymentTargets: .iOS("18.0"),
            dependencies: [.package(product: "KakaoSDK", type: .runtime),
                           .package(product: "LSExtensions", type: .runtime),
                           .package(product: "StringLogger", type: .runtime),
            ]
        ),
    ]
)
