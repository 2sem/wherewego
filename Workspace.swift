//
//  Workspace.swift
//  
//
//  Created by 영준 이 on 10/10/24.
//

import ProjectDescription

fileprivate let projects: [Path] = ["App", "ThirdParty", "DynamicThirdParty"]
    .map{ "Projects/\($0)" }

let workspace = Workspace(name: "wherewego", projects: projects)
