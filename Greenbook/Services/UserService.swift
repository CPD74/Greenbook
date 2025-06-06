//
//  UserService.swift
//  Greenbook
//
//  Created by Charlie Daniel on 6/2/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class UserService: ObservableObject {
    static let shared = UserService()
    
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    private let usernamesCollection = "usernames"
    
    // Published properties for reactive UI updates
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Username Methods
    
    /// Checks if a username is available
    /// - Parameter username: The username to check (will be normalized)
    /// - Returns: True if available, false if taken
    /// - Throws: UserServiceError if check fails
    func checkUsernameAvailability(username: String) async throws -> Bool {
        let normalizedUsername = User.normalizeUsername(username)
        
        // First validate the username format
        guard User.isValidUsername(normalizedUsername) else {
            print("❌ Username validation failed for: '\(normalizedUsername)'")
            return false
        }
        
        do {
            print("🔍 Checking availability for username: '\(normalizedUsername)'")
            
            // Use a simple document read instead of listener
            let document = try await db.collection(usernamesCollection).document(normalizedUsername).getDocument()
            let isAvailable = !document.exists
            
            print(isAvailable ? "✅ Username '\(normalizedUsername)' is available" : "❌ Username '\(normalizedUsername)' is taken")
            return isAvailable
            
        } catch {
            print("❌ Error checking username availability: \(error)")
            
            // Handle specific error cases
            if let firestoreError = error as NSError?,
               firestoreError.domain == "FIRFirestoreErrorDomain" {
                switch firestoreError.code {
                case 7: // Permission denied
                    print("⚠️ Permission denied - check if user is authenticated and Firestore rules allow read access")
                    // For now, return true to allow the flow to continue during development
                    return true
                case 8: // Network error
                    print("⚠️ Network error - user might be offline")
                    throw UserServiceError.usernameCheckFailed(error)
                default:
                    print("⚠️ Other Firestore error: \(firestoreError.localizedDescription)")
                    throw UserServiceError.usernameCheckFailed(error)
                }
            }
            
            // For other errors, assume available for now during development
            print("⚠️ Unknown error type, assuming username is available")
            return true
        }
    }
    
    /// Reserves a username for a user (atomic operation)
    /// - Parameters:
    ///   - username: The username to reserve (will be normalized)
    ///   - userId: The user ID who is claiming the username
    /// - Throws: UserServiceError if reservation fails
    private func reserveUsername(username: String, userId: String) async throws {
        let normalizedUsername = User.normalizeUsername(username)
        
        do {
            let usernameData: [String: Any] = [
                "userId": userId,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            try await db.collection(usernamesCollection).document(normalizedUsername).setData(usernameData)
            print("✅ Username '\(normalizedUsername)' reserved for user: \(userId)")
            
        } catch {
            print("❌ Error reserving username: \(error)")
            throw UserServiceError.usernameReservationFailed(error)
        }
    }
    
    /// Creates a user with username in an atomic batch operation
    /// - Parameters:
    ///   - user: The User object to create (must include username)
    ///   - userId: The Firebase Auth user ID to use as document ID
    /// - Throws: UserServiceError if creation fails
    func createUserWithUsername(_ user: User, userId: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let normalizedUsername = User.normalizeUsername(user.username)
        
        // Validate username before proceeding
        guard User.isValidUsername(normalizedUsername) else {
            await MainActor.run {
                isLoading = false
                errorMessage = User.getUsernameValidationError(user.username) ?? "Invalid username"
            }
            throw UserServiceError.invalidUsername
        }
        
        do {
            // Create batch operation for atomic username creation
            let batch = db.batch()
            
            // Add user document to batch
            let userRef = db.collection(usersCollection).document(userId)
            let userData = user.dictionary
            batch.setData(userData, forDocument: userRef)
            
            // Add username reservation to batch
            let usernameRef = db.collection(usernamesCollection).document(normalizedUsername)
            let usernameData: [String: Any] = [
                "userId": userId,
                "createdAt": FieldValue.serverTimestamp()
            ]
            batch.setData(usernameData, forDocument: usernameRef)
            
            // Commit the batch (atomic operation)
            try await batch.commit()
            
            await MainActor.run {
                isLoading = false
            }
            
            print("✅ User profile and username created successfully for userId: \(userId), username: \(normalizedUsername)")
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to create user profile: \(error.localizedDescription)"
            }
            
            print("❌ Error creating user with username: \(error)")
            throw UserServiceError.createFailed(error)
        }
    }
    
    /// Updates a user's username (handles both user document and username reservation)
    /// - Parameters:
    ///   - newUsername: The new username to assign
    ///   - userId: The user ID
    /// - Throws: UserServiceError if update fails
    func updateUsername(newUsername: String, userId: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let normalizedUsername = User.normalizeUsername(newUsername)
        
        // Validate new username
        guard User.isValidUsername(normalizedUsername) else {
            await MainActor.run {
                isLoading = false
                errorMessage = User.getUsernameValidationError(newUsername) ?? "Invalid username"
            }
            throw UserServiceError.invalidUsername
        }
        
        // Check if new username is available
        let isAvailable = try await checkUsernameAvailability(username: normalizedUsername)
        guard isAvailable else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Username is already taken"
            }
            throw UserServiceError.usernameTaken
        }
        
        do {
            // Get current user to find old username
            let currentUser = try await getUser(userId: userId)
            let oldUsername = User.normalizeUsername(currentUser.username)
            
            // Create batch operation
            let batch = db.batch()
            
            // Update user document with new username
            let userRef = db.collection(usersCollection).document(userId)
            batch.updateData([
                "username": normalizedUsername,
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: userRef)
            
            // Reserve new username
            let newUsernameRef = db.collection(usernamesCollection).document(normalizedUsername)
            let usernameData: [String: Any] = [
                "userId": userId,
                "createdAt": FieldValue.serverTimestamp()
            ]
            batch.setData(usernameData, forDocument: newUsernameRef)
            
            // Delete old username reservation
            let oldUsernameRef = db.collection(usernamesCollection).document(oldUsername)
            batch.deleteDocument(oldUsernameRef)
            
            // Commit the batch
            try await batch.commit()
            
            await MainActor.run {
                isLoading = false
            }
            
            print("✅ Username updated successfully from '\(oldUsername)' to '\(normalizedUsername)' for user: \(userId)")
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to update username: \(error.localizedDescription)"
            }
            
            print("❌ Error updating username: \(error)")
            throw UserServiceError.usernameUpdateFailed(error)
        }
    }
    
    /// Finds a user by their username
    /// - Parameter username: The username to search for
    /// - Returns: User object if found
    /// - Throws: UserServiceError if user not found
    func getUserByUsername(username: String) async throws -> User {
        let normalizedUsername = User.normalizeUsername(username)
        
        do {
            // First get the username document to find the userId
            let usernameDoc = try await db.collection(usernamesCollection).document(normalizedUsername).getDocument()
            
            guard usernameDoc.exists,
                  let usernameData = usernameDoc.data(),
                  let userId = usernameData["userId"] as? String else {
                throw UserServiceError.userNotFound
            }
            
            // Now get the actual user document
            return try await getUser(userId: userId)
            
        } catch {
            print("❌ Error finding user by username: \(error)")
            throw UserServiceError.fetchFailed(error)
        }
    }
    
    // MARK: - Create User Profile (Updated to use createUserWithUsername)
    
    /// Creates a new user profile in Firestore
    /// - Parameters:
    ///   - user: The User object to create
    ///   - userId: The Firebase Auth user ID to use as document ID
    /// - Throws: FirestoreError if creation fails
    func createUser(_ user: User, userId: String) async throws {
        // For backward compatibility, but new users should use createUserWithUsername
        // This method now requires a username as per the updated User model
        try await createUserWithUsername(user, userId: userId)
    }
    
    // MARK: - Get User Profile
    
    /// Retrieves a user profile from Firestore
    /// - Parameter userId: The Firebase Auth user ID
    /// - Returns: User object if found
    /// - Throws: UserServiceError if user not found or fetch fails
    func getUser(userId: String) async throws -> User {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let document = try await db.collection(usersCollection).document(userId).getDocument()
            
            guard document.exists else {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "User profile not found"
                }
                throw UserServiceError.userNotFound
            }
            
            guard let data = document.data() else {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid user data"
                }
                throw UserServiceError.invalidData
            }
            
            // Decode user data
            let user = try decodeUser(from: data, documentId: document.documentID)
            
            await MainActor.run {
                isLoading = false
            }
            
            print("✅ User profile loaded successfully for userId: \(userId)")
            return user
            
        } catch let error as UserServiceError {
            await MainActor.run {
                isLoading = false
            }
            throw error
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to load user profile: \(error.localizedDescription)"
            }
            
            print("❌ Error loading user profile: \(error)")
            throw UserServiceError.fetchFailed(error)
        }
    }
    
    // MARK: - Update User Profile (FIXED VERSION)
    
    /// Updates an existing user profile in Firestore
    /// - Parameter user: The updated User object
    /// - Throws: UserServiceError if update fails
    func updateUser(_ user: User) async throws {
        guard let userId = user.id else {
            throw UserServiceError.missingUserId
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Create updated user with new timestamp
            let updatedUser = user.withUpdatedTimestamp()
            var userData = updatedUser.dictionary
            
            // Handle nil values explicitly for Firebase
            // If homeCourseId is nil, we need to delete it from Firebase
            if updatedUser.homeCourseId == nil {
                userData["homeCourseId"] = FieldValue.delete()
            }
            
            // If homeCourseName is nil, we need to delete it from Firebase
            if updatedUser.homeCourseName == nil {
                userData["homeCourseName"] = FieldValue.delete()
            }
            
            // Handle bio field
            if updatedUser.bio == nil {
                userData["bio"] = FieldValue.delete()
            }
            
            // Handle profileImageURL field
            if updatedUser.profileImageURL == nil {
                userData["profileImageURL"] = FieldValue.delete()
            }
            
            try await db.collection(usersCollection).document(userId).updateData(userData)
            
            await MainActor.run {
                isLoading = false
            }
            
            print("✅ User profile updated successfully for userId: \(userId)")
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to update user profile: \(error.localizedDescription)"
            }
            
            print("❌ Error updating user profile: \(error)")
            throw UserServiceError.updateFailed(error)
        }
    }
    
    // MARK: - Delete User Profile
    
    /// Deletes a user profile from Firestore
    /// - Parameter userId: The Firebase Auth user ID
    /// - Throws: UserServiceError if deletion fails
    func deleteUser(userId: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Get user first to find their username
            let user = try await getUser(userId: userId)
            let username = User.normalizeUsername(user.username)
            
            // Create batch operation to delete both user and username reservation
            let batch = db.batch()
            
            // Delete user document
            let userRef = db.collection(usersCollection).document(userId)
            batch.deleteDocument(userRef)
            
            // Delete username reservation
            let usernameRef = db.collection(usernamesCollection).document(username)
            batch.deleteDocument(usernameRef)
            
            // Commit the batch
            try await batch.commit()
            
            await MainActor.run {
                isLoading = false
            }
            
            print("✅ User profile and username deleted successfully for userId: \(userId)")
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to delete user profile: \(error.localizedDescription)"
            }
            
            print("❌ Error deleting user profile: \(error)")
            throw UserServiceError.deleteFailed(error)
        }
    }
    
    // MARK: - Search Users (Future Feature)
    
    /// Searches for users by name (requires Firestore indexes)
    /// - Parameters:
    ///   - firstName: First name to search for
    ///   - lastName: Last name to search for (optional)
    /// - Returns: Array of matching users
    /// - Throws: UserServiceError if search fails
    func searchUsers(firstName: String, lastName: String? = nil) async throws -> [User] {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            var query: Query = db.collection(usersCollection)
                .whereField("firstName", isEqualTo: firstName)
            
            if let lastName = lastName {
                query = query.whereField("lastName", isEqualTo: lastName)
            }
            
            let querySnapshot = try await query.getDocuments()
            
            let users = try querySnapshot.documents.compactMap { document in
                try decodeUser(from: document.data(), documentId: document.documentID)
            }
            
            await MainActor.run {
                isLoading = false
            }
            
            print("✅ Found \(users.count) users matching search criteria")
            return users
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to search users: \(error.localizedDescription)"
            }
            
            print("❌ Error searching users: \(error)")
            throw UserServiceError.searchFailed(error)
        }
    }
    
    /// Searches for users by username (using the new username index)
    /// - Parameter usernameQuery: Partial username to search for
    /// - Returns: Array of matching users
    /// - Throws: UserServiceError if search fails
    func searchUsersByUsername(usernameQuery: String) async throws -> [User] {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Search users collection by username field
            let normalizedQuery = User.normalizeUsername(usernameQuery)
            
            let querySnapshot = try await db.collection(usersCollection)
                .whereField("username", isGreaterThanOrEqualTo: normalizedQuery)
                .whereField("username", isLessThan: normalizedQuery + "\u{f8ff}")
                .limit(to: 20)
                .getDocuments()
            
            let users = try querySnapshot.documents.compactMap { document in
                try decodeUser(from: document.data(), documentId: document.documentID)
            }
            
            await MainActor.run {
                isLoading = false
            }
            
            print("✅ Found \(users.count) users matching username query: \(usernameQuery)")
            return users
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to search users by username: \(error.localizedDescription)"
            }
            
            print("❌ Error searching users by username: \(error)")
            throw UserServiceError.searchFailed(error)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Decodes user data from Firestore document (Updated with username support)
    private func decodeUser(from data: [String: Any], documentId: String) throws -> User {
        // Create User directly from Firebase data using manual parsing
        let email = data["email"] as? String ?? ""
        let displayName = data["displayName"] as? String ?? ""
        let firstName = data["firstName"] as? String ?? ""
        let lastName = data["lastName"] as? String ?? ""
        let username = data["username"] as? String ?? ""
        let bio = data["bio"] as? String
        let homeCourseId = data["homeCourseId"] as? String
        let homeCourseName = data["homeCourseName"] as? String
        let profileImageURL = data["profileImageURL"] as? String
        
        // Note: We're not using the Firebase timestamps since the User model
        // creates its own timestamps in the initializer
        
        // Create user with parsed data
        var user = User(
            email: email,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName,
            username: username,
            bio: bio,
            homeCourseId: homeCourseId,
            homeCourseName: homeCourseName,
            profileImageURL: profileImageURL
        )
        
        // Set the document ID
        user.id = documentId
        
        return user
    }
    
    /// Gets the current authenticated user's ID
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    /// Checks if a user profile exists
    func userExists(userId: String) async throws -> Bool {
        do {
            let document = try await db.collection(usersCollection).document(userId).getDocument()
            return document.exists
        } catch {
            print("❌ Error checking if user exists: \(error)")
            throw UserServiceError.fetchFailed(error)
        }
    }
}

// MARK: - Error Types (Enhanced with Username Errors)

enum UserServiceError: LocalizedError {
    case userNotFound
    case invalidData
    case missingUserId
    case invalidUsername
    case usernameTaken
    case usernameCheckFailed(Error)
    case usernameReservationFailed(Error)
    case usernameUpdateFailed(Error)
    case createFailed(Error)
    case fetchFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case searchFailed(Error)
    case decodingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User profile not found"
        case .invalidData:
            return "Invalid user data received"
        case .missingUserId:
            return "User ID is required"
        case .invalidUsername:
            return "Username format is invalid"
        case .usernameTaken:
            return "Username is already taken"
        case .usernameCheckFailed(let error):
            return "Failed to check username availability: \(error.localizedDescription)"
        case .usernameReservationFailed(let error):
            return "Failed to reserve username: \(error.localizedDescription)"
        case .usernameUpdateFailed(let error):
            return "Failed to update username: \(error.localizedDescription)"
        case .createFailed(let error):
            return "Failed to create user profile: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch user profile: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update user profile: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete user profile: \(error.localizedDescription)"
        case .searchFailed(let error):
            return "Failed to search users: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode user data: \(error.localizedDescription)"
        }
    }
}
