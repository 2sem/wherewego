import SwiftUI

/// Map marker / list badge styling per content type, shared by the map pins
/// and the nearby-places panel so both always agree.
extension KGDataTourInfo.ContentType {
    var markerIconName: String {
        switch self {
        case .Tour, .Tour_Foreign:           return "camera.fill"              // 관광지
        case .Culture, .Culture_Foreign:     return "building.columns.fill"    // 문화시설
        case .Event, .Event_Foreign:         return "party.popper.fill"        // 행사/공연/축제
        case .Course:                        return "map.fill"                 // 여행코스
        case .Leports, .Leports_Foreign:     return "figure.run"               // 레포츠
        case .Hotel, .Hotel_Foreign:         return "bed.double.fill"          // 숙박
        case .Shopping, .Shopping_Foreign:   return "cart.fill"                // 쇼핑
        case .Food, .Food_Foreign:           return "fork.knife"               // 음식점
        case .Travel, .Travel_Foreign:       return "airplane"                 // 여행
        }
    }

    var markerColor: Color {
        switch self {
        case .Tour, .Tour_Foreign:           return Color("TourMarkerColor")       // 관광지
        case .Culture, .Culture_Foreign:     return Color("CultureMarkerColor")    // 문화시설
        case .Event, .Event_Foreign:         return Color("EventMarkerColor")      // 행사/공연/축제
        case .Course:                        return Color("CourseMarkerColor")     // 여행코스
        case .Leports, .Leports_Foreign:     return Color("LeportsMarkerColor")    // 레포츠
        case .Hotel, .Hotel_Foreign:         return Color("HotelMarkerColor")      // 숙박
        case .Shopping, .Shopping_Foreign:   return Color("ShoppingMarkerColor")   // 쇼핑
        case .Food, .Food_Foreign:           return Color("FoodMarkerColor")       // 음식점
        case .Travel, .Travel_Foreign:       return Color("TravelMarkerColor")     // 여행
        }
    }
}
