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
            
            // If user profile doesn't exist, handle the edge case
            if let firebaseUser = Auth.auth().currentUser {
                await handleMissingUserProfile(firebaseUser)
            } else {
                self.currentUser = nil
            }
        }
    }
    
    @MainActor
    private func handleMissingUserProfile(_ firebaseUser: FirebaseAuth.User) async {
        print("⚠️ No user profile found for authenticated user")
        print("📧 Firebase user email: \(firebaseUser.email ?? "unknown")")
        print("🆔 Firebase user ID: \(firebaseUser.uid)")
        
        // Don't immediately sign out - the profile might be in the process of being created
        // Just set currentUser to nil but keep them authenticated
        print("⏳ Keeping user authenticated while profile creation may be in progress")
        self.currentUser = nil
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
