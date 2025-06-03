//
//  Course.swift
//  Greenbook
//
//  Created by Charlie Daniel on 5/22/25.
//

import Foundation
import FirebaseFirestore

struct Course: Identifiable, Codable {
    var id: String?
    
    let name: String
    let city: String
    let country: String
    let state: String
    let holes: Int
    let description: String  // Will handle nulls in decoder
    let location: LocationInfo
    let website: String      // Will handle nulls in decoder
    let established: Int?
    let designer: String     // Will handle nulls in decoder
    let access: String
    let source: String
    
    let createdAt: Date?
    let updatedAt: Date?
    
    var isOriginalData: Bool = true
    
    static let collectionName = "courses"
    
    // Custom init to handle null values and missing fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        city = try container.decode(String.self, forKey: .city)
        country = try container.decode(String.self, forKey: .country)
        state = try container.decode(String.self, forKey: .state)
        holes = try container.decode(Int.self, forKey: .holes)
        
        // Handle null values by providing defaults
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        website = try container.decodeIfPresent(String.self, forKey: .website) ?? ""
        designer = try container.decodeIfPresent(String.self, forKey: .designer) ?? ""
        
        location = try container.decode(LocationInfo.self, forKey: .location)
        established = try container.decodeIfPresent(Int.self, forKey: .established)
        access = try container.decode(String.self, forKey: .access)
        source = try container.decode(String.self, forKey: .source)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        
        // Use default value if isOriginalData field doesn't exist
        isOriginalData = try container.decodeIfPresent(Bool.self, forKey: .isOriginalData) ?? true
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, city, country, state, holes, description, location
        case website, established, designer, access, source
        case createdAt, updatedAt
        case isOriginalData = "is_original_data"
    }
}

// Location nested structure to match Firebase
struct LocationInfo: Codable {
    let address: String
    let formattedAddress: String
    let geoPoint: GeoPoint
}

// Use Firebase's GeoPoint type directly
typealias GeoPoint = FirebaseFirestore.GeoPoint

// Extension for helper methods
extension Course {
    var formattedLocation: String {
        return "\(city), \(state)"
    }
    
    var coordinatesString: String {
        return "\(location.geoPoint.latitude), \(location.geoPoint.longitude)"
    }
    
    // Helper to check if fields have actual content
    var hasDescription: Bool {
        return !description.isEmpty
    }
    
    var hasWebsite: Bool {
        return !website.isEmpty
    }
    
    var hasDesigner: Bool {
        return !designer.isEmpty
    }
    
    // Required encode method for Codable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(city, forKey: .city)
        try container.encode(country, forKey: .country)
        try container.encode(state, forKey: .state)
        try container.encode(holes, forKey: .holes)
        try container.encode(description, forKey: .description)
        try container.encode(location, forKey: .location)
        try container.encode(website, forKey: .website)
        try container.encodeIfPresent(established, forKey: .established)
        try container.encode(designer, forKey: .designer)
        try container.encode(access, forKey: .access)
        try container.encode(source, forKey: .source)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encode(isOriginalData, forKey: .isOriginalData)
    }
}
