//
//  User.swift
//  Greenbook
//
//  Created by Charlie Daniel on 6/2/25.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var firstName: String
    var lastName: String
    var bio: String?
    var homeCourseId: String?
    var homeCourseName: String?
    var profileImageURL: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Computed property for initials
    var initials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return firstInitial + lastInitial
    }
    
    // Custom initializer for creating new users
    init(
        email: String,
        displayName: String,
        firstName: String,
        lastName: String,
        bio: String? = nil,
        homeCourseId: String? = nil,
        homeCourseName: String? = nil,
        profileImageURL: String? = nil
    ) {
        self.email = email
        self.displayName = displayName
        self.firstName = firstName
        self.lastName = lastName
        self.bio = bio
        self.homeCourseId = homeCourseId
        self.homeCourseName = homeCourseName
        self.profileImageURL = profileImageURL
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Custom decoding to handle Firebase data inconsistencies
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        email = try container.decode(String.self, forKey: .email)
        displayName = try container.decode(String.self, forKey: .displayName)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        
        // Optional fields with fallbacks
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        homeCourseId = try container.decodeIfPresent(String.self, forKey: .homeCourseId)
        homeCourseName = try container.decodeIfPresent(String.self, forKey: .homeCourseName)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        
        // Handle Firebase Timestamps
        if let timestamp = try container.decodeIfPresent(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        if let timestamp = try container.decodeIfPresent(Timestamp.self, forKey: .updatedAt) {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = Date()
        }
    }
    
    // Custom encoding for Firebase
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(email, forKey: .email)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(homeCourseId, forKey: .homeCourseId)
        try container.encodeIfPresent(homeCourseName, forKey: .homeCourseName)
        try container.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
        
        // Convert Date to Timestamp for Firebase
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        try container.encode(Timestamp(date: updatedAt), forKey: .updatedAt)
    }
    
    private enum CodingKeys: String, CodingKey {
        case email, displayName, firstName, lastName, bio
        case homeCourseId, homeCourseName, profileImageURL
        case createdAt, updatedAt
    }
}

// Extension for easier dictionary conversion (useful for Firebase operations)
extension User {
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "email": email,
            "displayName": displayName,
            "firstName": firstName,
            "lastName": lastName,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        if let bio = bio { dict["bio"] = bio }
        if let homeCourseId = homeCourseId { dict["homeCourseId"] = homeCourseId }
        if let homeCourseName = homeCourseName { dict["homeCourseName"] = homeCourseName }
        if let profileImageURL = profileImageURL { dict["profileImageURL"] = profileImageURL }
        
        return dict
    }
    
    // Helper method to update updatedAt timestamp
    func withUpdatedTimestamp() -> User {
        var updatedUser = self
        updatedUser.updatedAt = Date()
        return updatedUser
    }
}
