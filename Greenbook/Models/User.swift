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
    var username: String
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
    
    // Computed property for display handle
    var displayHandle: String {
        return "@\(username)"
    }
    
    // Custom initializer for creating new users
    init(
        email: String,
        displayName: String,
        firstName: String,
        lastName: String,
        username: String,
        bio: String? = nil,
        homeCourseId: String? = nil,
        homeCourseName: String? = nil,
        profileImageURL: String? = nil
    ) {
        self.email = email
        self.displayName = displayName
        self.firstName = firstName
        self.lastName = lastName
        self.username = User.normalizeUsername(username)
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
        username = try container.decode(String.self, forKey: .username)
        
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
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(homeCourseId, forKey: .homeCourseId)
        try container.encodeIfPresent(homeCourseName, forKey: .homeCourseName)
        try container.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
        
        // Convert Date to Timestamp for Firebase
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        try container.encode(Timestamp(date: updatedAt), forKey: .updatedAt)
    }
    
    private enum CodingKeys: String, CodingKey {
        case email, displayName, firstName, lastName, username, bio
        case homeCourseId, homeCourseName, profileImageURL
        case createdAt, updatedAt
    }
}

// MARK: - Username Validation Extension (UPDATED with Profanity Filtering)
extension User {
    
    // UPDATED: Main validation method now includes profanity checking
    static func isValidUsername(_ username: String) -> Bool {
        let normalizedUsername = normalizeUsername(username)
        
        return isValidUsernameLength(normalizedUsername) &&
               isValidUsernameFormat(normalizedUsername) &&
               !isReservedUsername(normalizedUsername) &&
               !ProfanityFilter.shared.containsProfanity(normalizedUsername)
    }
    
    static func isValidUsernameLength(_ username: String) -> Bool {
        return username.count >= 3 && username.count <= 20
    }
    
    static func isValidUsernameFormat(_ username: String) -> Bool {
        // Allow alphanumeric characters, underscores, and hyphens
        // Must start with a letter or number
        let usernameRegex = "^[a-zA-Z0-9][a-zA-Z0-9_-]*$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }
    
    static func isReservedUsername(_ username: String) -> Bool {
        let reserved = [
            "admin", "support", "help", "api", "www", "mail", "ftp",
            "greenbook", "golf", "course", "user", "account", "profile",
            "settings", "about", "contact", "privacy", "terms", "legal",
            "moderator", "mod", "staff", "team", "official", "verified"
        ]
        return reserved.contains(username.lowercased())
    }
    
    // UPDATED: Enhanced error handling with profanity detection
    static func getUsernameValidationError(_ username: String) -> String? {
        if username.isEmpty {
            return "Username cannot be empty"
        }
        
        let normalizedUsername = normalizeUsername(username)
        
        if !isValidUsernameLength(normalizedUsername) {
            if normalizedUsername.count < 3 {
                return "Username must be at least 3 characters long"
            } else {
                return "Username must be 20 characters or less"
            }
        }
        
        if !isValidUsernameFormat(normalizedUsername) {
            return "Username can only contain letters, numbers, underscores, and hyphens"
        }
        
        if isReservedUsername(normalizedUsername) {
            return "This username is reserved and cannot be used"
        }
        
        // NEW: Check for profanity
        if ProfanityFilter.shared.containsProfanity(normalizedUsername) {
            return ProfanityFilter.shared.getProfanityErrorMessage()
        }
        
        return nil
    }
    
    static func normalizeUsername(_ username: String) -> String {
        // Convert to lowercase for storage consistency
        return username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func formatUsernameForDisplay(_ username: String) -> String {
        // Keep original case for display
        return username.trimmingCharacters(in: .whitespacesAndNewlines)
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
            "username": username,
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
    
    // Helper method to update username and timestamp
    func withUsername(_ newUsername: String) -> User {
        var updatedUser = self
        updatedUser.username = User.normalizeUsername(newUsername)
        updatedUser.updatedAt = Date()
        return updatedUser
    }
}
