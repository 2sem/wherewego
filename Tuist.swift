//
//  Tuist.swift
//  wherewegoManifests
//
//  Created by 영준 이 on 3/6/25.
//

import ProjectDescription

let tuist = Tuist(
    fullHandle: "gamehelper/wherewego",
    project: .tuist(
        compatibleXcodeVersions: .list([.upToNextMajor("26.0"), .upToNextMajor("27.0")]),
//                    swiftVersion: "",
//                    plugins: <#T##[PluginLocation]#>,
        generationOptions: .options(
            enableCaching: true,
            registryEnabled: true
        )
//                    installOptions: <#T##Tuist.InstallOptions#>)
    )
)
