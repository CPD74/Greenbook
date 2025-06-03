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
    
    // Published properties for reactive UI updates
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Create User Profile
    
    /// Creates a new user profile in Firestore
    /// - Parameters:
    ///   - user: The User object to create
    ///   - userId: The Firebase Auth user ID to use as document ID
    /// - Throws: FirestoreError if creation fails
    func createUser(_ user: User, userId: String) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let userData = user.dictionary
            try await db.collection(usersCollection).document(userId).setData(userData)
            
            await MainActor.run {
                isLoading = false
            }
            
            print("✅ User profile created successfully for userId: \(userId)")
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to create user profile: \(error.localizedDescription)"
            }
            
            print("❌ Error creating user profile: \(error)")
            throw UserServiceError.createFailed(error)
        }
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
    
    // MARK: - Update User Profile
    
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
            let userData = updatedUser.dictionary
            
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
            try await db.collection(usersCollection).document(userId).delete()
            
            await MainActor.run {
                isLoading = false
            }
            
            print("✅ User profile deleted successfully for userId: \(userId)")
            
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
    
    // MARK: - Helper Methods
    
    /// Decodes user data from Firestore document
    private func decodeUser(from data: [String: Any], documentId: String) throws -> User {
        // Create User directly from Firebase data using manual parsing
        let email = data["email"] as? String ?? ""
        let displayName = data["displayName"] as? String ?? ""
        let firstName = data["firstName"] as? String ?? ""
        let lastName = data["lastName"] as? String ?? ""
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

// MARK: - Error Types

enum UserServiceError: LocalizedError {
    case userNotFound
    case invalidData
    case missingUserId
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
