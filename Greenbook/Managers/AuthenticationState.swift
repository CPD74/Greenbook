//
//  AuthenticationState.swift
//  Greenbook
//
//  Created by Charlie Daniel on 3/25/25.
//

import SwiftUI
import FirebaseAuth

class AuthenticationState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = true
    
    private var authStateListener: AuthStateDidChangeListenerHandle? // Store the listener handle
    
    init() {
        // Check initial auth state
        isAuthenticated = Auth.auth().currentUser != nil
        
        // Listen for auth state changes and store the handle
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                self?.isAuthenticated = firebaseUser != nil
                
                if let firebaseUser = firebaseUser {
                    // Load user profile when authenticated
                    await self?.loadUserProfile(for: firebaseUser.uid)
                } else {
                    // Clear user profile when signed out
                    self?.currentUser = nil
                }
                
                self?.isLoading = false
            }
        }
    }
    
    deinit {
        // Remove the listener when the object is deallocated
        if let authStateListener = authStateListener {
            Auth.auth().removeStateDidChangeListener(authStateListener)
        }
    }
    
    @MainActor
    private func loadUserProfile(for userId: String) async {
        do {
            let user = try await UserService.shared.getUser(userId: userId)
            self.currentUser = user
        } catch {
            print("Error loading user profile: \(error)")
            
            // If user profile doesn't exist, try to create one from Firebase Auth data
            if let firebaseUser = Auth.auth().currentUser {
                await createProfileFromFirebaseUser(firebaseUser)
            } else {
                self.currentUser = nil
            }
        }
    }
    
    @MainActor
    private func createProfileFromFirebaseUser(_ firebaseUser: FirebaseAuth.User) async {
        do {
            print("Creating user profile from Firebase Auth data...")
            
            // Extract name from Firebase user (if available)
            let displayName = firebaseUser.displayName ?? "User"
            let email = firebaseUser.email ?? ""
            
            // Parse first and last name from display name
            let nameComponents = displayName.components(separatedBy: " ")
            let firstName = nameComponents.first ?? "User"
            let lastName = nameComponents.count > 1 ? nameComponents.dropFirst().joined(separator: " ") : ""
            
            // Create user profile
            let user = User(
                email: email,
                displayName: displayName,
                firstName: firstName,
                lastName: lastName
            )
            
            // Save to Firestore
            try await UserService.shared.createUser(user, userId: firebaseUser.uid)
            
            // Update current user
            self.currentUser = user
            print("✅ User profile created successfully for existing user")
            
        } catch {
            print("❌ Failed to create user profile for existing user: \(error)")
            self.currentUser = nil
        }
    }
    
    @MainActor
    func updateCurrentUser(_ user: User) {
        self.currentUser = user
    }
    
    @MainActor
    func clearUser() {
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
