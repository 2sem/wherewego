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
        compatibleXcodeVersions: .upToNextMajor("26.0"),
//                    swiftVersion: "",
//                    plugins: <#T##[PluginLocation]#>,
        generationOptions: .options(
            enableCaching: true
        )
//                    installOptions: <#T##Tuist.InstallOptions#>)
    )
)
