//
//  KGDataTourImage.swift
//  wherewego
//

import Foundation

struct KGDataTourImage: Identifiable, Equatable, Hashable {
    var id: URL { url; }
    let url: URL;
    let name: String?;

    static func == (lhs: KGDataTourImage, rhs: KGDataTourImage) -> Bool {
        lhs.url == rhs.url;
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url);
    }
}
