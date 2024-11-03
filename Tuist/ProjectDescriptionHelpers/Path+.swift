//
//  Path+.swift
//  AppManifests
//
//  Created by 영준 이 on 10/13/24.
//

import Foundation
import ProjectDescription

public extension Path {
    static func projects(_ path: String) -> Path { .relativeToRoot("Projects/\(path)") }
}
