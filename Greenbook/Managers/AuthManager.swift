//
//  AuthManager.swift
//  Greenbook
//
//  Created by Charlie Daniel on 3/25/25.
//

import FirebaseAuth
import GoogleSignIn
import UIKit

class AuthManager {
    static let shared = AuthManager()
    
    private init() {}

    // Sign up with email & password
    func signUp(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        completion: @escaping (Result<User, Error>) -> Void
    ) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let firebaseUser = authResult?.user else {
                completion(.failure(AuthError.userCreationFailed))
                return
            }
            
            // Create user profile after successful Firebase Auth creation
            Task {
                do {
                    let user = try await self?.createUserProfile(
                        firebaseUser: firebaseUser,
                        firstName: firstName,
                        lastName: lastName
                    )
                    
                    if let user = user {
                        await MainActor.run {
                            completion(.success(user))
                        }
                    }
                } catch {
                    await MainActor.run {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    // Sign in with email & password
    func signIn(email: String, password: String, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = authResult?.user {
                completion(.success(user))
            }
        }
    }

    // Google Sign-In with profile creation
    func signInWithGoogle(completion: @escaping (Result<User, Error>) -> Void) {
        guard let rootViewController = getRootViewController() else {
            completion(.failure(AuthError.noRootViewController))
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] signInResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let idToken = signInResult?.user.idToken else {
                completion(.failure(AuthError.noIDToken))
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken.tokenString,
                accessToken: signInResult?.user.accessToken.tokenString ?? ""
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let firebaseUser = authResult?.user else {
                    completion(.failure(AuthError.userCreationFailed))
                    return
                }
                
                // Check if user profile exists, create if not
                Task {
                    do {
                        let user = try await self?.handleGoogleSignIn(firebaseUser: firebaseUser, googleUser: signInResult?.user)
                        
                        if let user = user {
                            await MainActor.run {
                                completion(.success(user))
                            }
                        }
                    } catch {
                        await MainActor.run {
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
    }

    // Sign out
    func signOut() -> Result<Void, Error> {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            return .success(())
        } catch let error {
            return .failure(error)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
    
    private func createUserProfile(
        firebaseUser: FirebaseAuth.User,
        firstName: String,
        lastName: String
    ) async throws -> User {
        let displayName = "\(firstName) \(lastName)"
        
        let user = User(
            email: firebaseUser.email ?? "",
            displayName: displayName,
            firstName: firstName,
            lastName: lastName
        )
        
        // Save to Firestore
        try await UserService.shared.createUser(user, userId: firebaseUser.uid)
        return user
    }
    
    private func handleGoogleSignIn(
        firebaseUser: FirebaseAuth.User,
        googleUser: GIDGoogleUser?
    ) async throws -> User {
        // First, try to get existing user profile
        do {
            let existingUser = try await UserService.shared.getUser(userId: firebaseUser.uid)
            return existingUser
        } catch {
            // User profile doesn't exist, create one
            return try await createUserProfileFromGoogle(firebaseUser: firebaseUser, googleUser: googleUser)
        }
    }
    
    private func createUserProfileFromGoogle(
        firebaseUser: FirebaseAuth.User,
        googleUser: GIDGoogleUser?
    ) async throws -> User {
        let displayName = firebaseUser.displayName ?? googleUser?.profile?.name ?? "User"
        let email = firebaseUser.email ?? googleUser?.profile?.email ?? ""
        
        // Parse first and last name from display name
        let nameComponents = displayName.components(separatedBy: " ")
        let firstName = nameComponents.first ?? "User"
        let lastName = nameComponents.count > 1 ? nameComponents.dropFirst().joined(separator: " ") : ""
        
        let user = User(
            email: email,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName,
            profileImageURL: googleUser?.profile?.imageURL(withDimension: 200)?.absoluteString
        )
        
        // Save to Firestore
        try await UserService.shared.createUser(user, userId: firebaseUser.uid)
        return user
    }
}

// MARK: - Custom Error Types
enum AuthError: LocalizedError {
    case userCreationFailed
    case noRootViewController
    case noIDToken
    case profileCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .userCreationFailed:
            return "Failed to create user account"
        case .noRootViewController:
            return "No root view controller found"
        case .noIDToken:
            return "No ID token found"
        case .profileCreationFailed:
            return "Failed to create user profile"
        }
    }
}
