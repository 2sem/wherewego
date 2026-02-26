//
//  KGDataTourImage.swift
//  wherewego
//

import Foundation

struct KGDataTourImage: Identifiable, Equatable, Hashable {
    var id: URL { url; }
    let url: URL;
    let name: String?;
}
