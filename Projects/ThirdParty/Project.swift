import ProjectDescription

let project = Project(
    name: "ThirdParty",
    packages: [
        .remote(url: "https://github.com/kakao/kakao-ios-sdk",
                requirement: .upToNextMajor(from: "2.22.2")),
        .remote(url: "https://github.com/jdg/MBProgressHUD.git",
                requirement: .upToNextMajor(from: "1.2.0")),
        .remote(url: "https://github.com/2sem/LSExtensions",
                               requirement: .exact("0.1.22")),
        .remote(url: "https://github.com/2sem/StringLogger",
                requirement: .upToNextMajor(from: "0.7.0")),
        .remote(url: "https://github.com/2sem/DownPicker",
                requirement: .branch("spm")),
//        .local(path: "../../../../../spms/DownPicker")
    ],
    targets: [
        .target(
            name: "ThirdParty",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.y2k.wherewego.thirdparty",
            dependencies: [.package(product: "KakaoSDK", type: .runtime),
                           .package(product: "MBProgressHUD", type: .runtime),
                           .package(product: "LSExtensions", type: .runtime),
                           .package(product: "StringLogger", type: .runtime),
                           .package(product: "DownPicker", type: .runtime),
            ]
        ),
    ]
)
