//
//  AuthManager.swift
//  Greenbook
//
//  Created by Charlie Daniel on 3/25/25.
//

import FirebaseAuth
import GoogleSignIn
import UIKit
import AuthenticationServices
import CryptoKit

class AuthManager {
    static let shared = AuthManager()
    
    // Add this property to retain the Apple Sign-In delegate
    private var currentAppleSignInDelegate: AppleSignInDelegate?
    
    private init() {}

    // Sign up with email & password (UPDATED - now creates username automatically)
    func signUp(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        completion: @escaping (Result<User, Error>) -> Void
    ) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                let mappedError = mapFirebaseError(error)
                completion(.failure(mappedError))
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
                let mappedError = mapFirebaseError(error)
                completion(.failure(mappedError))
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
                let mappedError = mapFirebaseError(error)
                completion(.failure(mappedError))
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
                    let mappedError = mapFirebaseError(error)
                    completion(.failure(mappedError))
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

    // Apple Sign-In with profile creation (FIXED - delegate retention)
    func signInWithApple(completion: @escaping (Result<User, Error>) -> Void) {
        print("🍎 Starting Apple Sign-In process")
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        // Generate nonce for security
        let nonce = randomNonceString()
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        
        // Store delegate as property to prevent deallocation
        currentAppleSignInDelegate = AppleSignInDelegate { [weak self] result in
            print("🍎 Apple Sign-In delegate callback received")
            
            // Clear the delegate reference after completion to prevent memory leaks
            self?.currentAppleSignInDelegate = nil
            
            switch result {
            case .success(let appleAuthResult):
                print("🍎 Apple authorization successful, creating Firebase credential")
                
                let credential = OAuthProvider.credential(
                    providerID: AuthProviderID.apple,
                    idToken: appleAuthResult.identityToken,
                    rawNonce: nonce
                )
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        print("🍎 Firebase Auth sign-in failed: \(error)")
                        let mappedError = mapFirebaseError(error)
                        completion(.failure(mappedError))
                        return
                    }
                    
                    guard let firebaseUser = authResult?.user else {
                        print("🍎 No Firebase user returned after sign-in")
                        completion(.failure(AuthError.userCreationFailed))
                        return
                    }
                    
                    print("🍎 Firebase Auth sign-in successful, handling user profile")
                    
                    // Handle Apple Sign-In user profile
                    Task {
                        do {
                            let user = try await self?.handleAppleSignIn(
                                firebaseUser: firebaseUser,
                                appleAuthResult: appleAuthResult
                            )
                            
                            if let user = user {
                                await MainActor.run {
                                    print("🍎 Apple Sign-In completed successfully")
                                    completion(.success(user))
                                }
                            }
                        } catch {
                            await MainActor.run {
                                print("🍎 Error handling Apple Sign-In profile: \(error)")
                                completion(.failure(error))
                            }
                        }
                    }
                }
                
            case .failure(let error):
                print("🍎 Apple authorization failed: \(error)")
                let mappedError = mapFirebaseError(error)
                completion(.failure(mappedError))
            }
        }
        
        authorizationController.delegate = currentAppleSignInDelegate
        authorizationController.presentationContextProvider = currentAppleSignInDelegate
        
        print("🍎 Presenting Apple Sign-In authorization controller")
        authorizationController.performRequests()
    }

    // Sign out
    func signOut() -> Result<Void, Error> {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            // Clear any retained delegates
            currentAppleSignInDelegate = nil
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
    
    // UPDATED: Now generates username for email signups
    private func createUserProfile(
        firebaseUser: FirebaseAuth.User,
        firstName: String,
        lastName: String
    ) async throws -> User {
        let displayName = "\(firstName) \(lastName)"
        
        // Generate a username from first name and user ID
        let baseUsername = firstName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let username = try await generateUniqueUsername(baseUsername: baseUsername, userId: firebaseUser.uid)
        
        let user = User(
            email: firebaseUser.email ?? "",
            displayName: displayName,
            firstName: firstName,
            lastName: lastName,
            username: username
        )
        
        // Use createUserWithUsername for atomic operation
        try await UserService.shared.createUserWithUsername(user, userId: firebaseUser.uid)
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
    
    private func handleAppleSignIn(
        firebaseUser: FirebaseAuth.User,
        appleAuthResult: AppleSignInAuthResult
    ) async throws -> User {
        print("🍎 Handling Apple Sign-In for user: \(firebaseUser.uid)")
        
        // First, try to get existing user profile
        do {
            let existingUser = try await UserService.shared.getUser(userId: firebaseUser.uid)
            print("🍎 Found existing user profile")
            return existingUser
        } catch {
            // User profile doesn't exist, create one
            print("🍎 Creating new user profile")
            return try await createUserProfileFromApple(firebaseUser: firebaseUser, appleAuthResult: appleAuthResult)
        }
    }
    
    // UPDATED: Now generates username for Google signups
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
        
        // Generate username from first name and ensure uniqueness
        let baseUsername = firstName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let username = try await generateUniqueUsername(baseUsername: baseUsername, userId: firebaseUser.uid)
        
        let user = User(
            email: email,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName,
            username: username,
            profileImageURL: googleUser?.profile?.imageURL(withDimension: 200)?.absoluteString
        )
        
        // Use createUserWithUsername for atomic operation
        try await UserService.shared.createUserWithUsername(user, userId: firebaseUser.uid)
        return user
    }
    
    // UPDATED: Now generates username for Apple signups
    private func createUserProfileFromApple(
        firebaseUser: FirebaseAuth.User,
        appleAuthResult: AppleSignInAuthResult
    ) async throws -> User {
        let email = firebaseUser.email ?? ""
        
        // Extract name from Apple Sign-In (only available on first sign-in)
        let firstName = appleAuthResult.firstName ?? "User"
        let lastName = appleAuthResult.lastName ?? ""
        let displayName = lastName.isEmpty ? firstName : "\(firstName) \(lastName)"
        
        print("🍎 Creating profile with firstName: '\(firstName)', lastName: '\(lastName)'")
        
        // Generate username from first name and ensure uniqueness
        let baseUsername = firstName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let username = try await generateUniqueUsername(baseUsername: baseUsername, userId: firebaseUser.uid)
        
        let user = User(
            email: email,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName,
            username: username
        )
        
        // Use createUserWithUsername for atomic operation
        try await UserService.shared.createUserWithUsername(user, userId: firebaseUser.uid)
        return user
    }
    
    // NEW: Generate unique username for social auth users
    private func generateUniqueUsername(baseUsername: String, userId: String) async throws -> String {
        // Clean the base username
        let cleanBase = baseUsername.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
        
        // Ensure it meets minimum requirements
        let validBase = cleanBase.isEmpty ? "user" : cleanBase
        
        // Try the base username first
        var candidate = validBase
        var attempts = 0
        let maxAttempts = 10
        
        while attempts < maxAttempts {
            // Validate the candidate
            if User.isValidUsername(candidate) {
                do {
                    let isAvailable = try await UserService.shared.checkUsernameAvailability(username: candidate)
                    if isAvailable {
                        return candidate
                    }
                } catch {
                    print("Error checking username availability: \(error)")
                }
            }
            
            // Generate next candidate
            attempts += 1
            if attempts == 1 {
                // Try with some numbers from the user ID
                let userIdSuffix = String(userId.suffix(4))
                candidate = validBase + userIdSuffix
            } else {
                // Try with random numbers
                let randomNumber = Int.random(in: 100...9999)
                candidate = validBase + String(randomNumber)
            }
        }
        
        // Fallback: use user prefix with part of userId
        let fallback = "user" + String(userId.prefix(8)).lowercased()
        print("⚠️ Using fallback username: \(fallback)")
        return fallback
    }
    
    // MARK: - Apple Sign-In Helpers
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - Apple Sign-In Models and Delegate

struct AppleSignInAuthResult {
    let identityToken: String
    let firstName: String?
    let lastName: String?
}

class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<AppleSignInAuthResult, Error>) -> Void
    
    init(completion: @escaping (Result<AppleSignInAuthResult, Error>) -> Void) {
        self.completion = completion
        super.init()
        print("🍎 AppleSignInDelegate created")
    }
    
    deinit {
        print("🍎 AppleSignInDelegate deallocated")
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("🍎 Apple Sign-In authorization completed successfully")
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                print("🍎 Failed to get identity token")
                completion(.failure(AuthError.noIDToken))
                return
            }
            
            let firstName = appleIDCredential.fullName?.givenName
            let lastName = appleIDCredential.fullName?.familyName
            
            print("🍎 Apple Sign-In success - firstName: '\(firstName ?? "nil")', lastName: '\(lastName ?? "nil")'")
            
            let result = AppleSignInAuthResult(
                identityToken: identityToken,
                firstName: firstName,
                lastName: lastName
            )
            
            completion(.success(result))
        } else {
            print("🍎 Failed to get Apple ID credential")
            completion(.failure(AuthError.noIDToken))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("🍎 Apple Sign-In authorization failed: \(error)")
        completion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("🍎 Warning: Could not find window for presentation anchor")
            return UIWindow()
        }
        return window
    }
}

// MARK: - Enhanced Custom Error Types
enum AuthError: LocalizedError {
    case userCreationFailed
    case noRootViewController
    case noIDToken
    case profileCreationFailed
    case emailAlreadyInUse
    case weakPassword
    case invalidEmail
    case networkError
    case userNotFound
    case wrongPassword
    case tooManyRequests
    case operationNotAllowed
    case userDisabled
    case requiresRecentLogin
    case unknown(String)
    
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
        case .emailAlreadyInUse:
            return "An account with this email already exists. Please sign in instead."
        case .weakPassword:
            return "Please choose a stronger password."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .networkError:
            return "Network connection error. Please check your internet and try again."
        case .userNotFound:
            return "No account found with this email address."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .tooManyRequests:
            return "Too many failed attempts. Please try again later."
        case .operationNotAllowed:
            return "This operation is not allowed. Please contact support."
        case .userDisabled:
            return "This account has been disabled. Please contact support."
        case .requiresRecentLogin:
            return "Please sign in again to complete this action."
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Firebase Error Mapping Helper
func mapFirebaseError(_ error: Error) -> AuthError {
    if let firebaseError = error as NSError? {
        switch firebaseError.code {
        case 17007: // FIRAuthErrorCodeEmailAlreadyInUse
            return .emailAlreadyInUse
        case 17026: // FIRAuthErrorCodeWeakPassword
            return .weakPassword
        case 17008: // FIRAuthErrorCodeInvalidEmail
            return .invalidEmail
        case 17011: // FIRAuthErrorCodeUserNotFound
            return .userNotFound
        case 17009: // FIRAuthErrorCodeWrongPassword
            return .wrongPassword
        case 17010: // FIRAuthErrorCodeTooManyRequests
            return .tooManyRequests
        case 17006: // FIRAuthErrorCodeOperationNotAllowed
            return .operationNotAllowed
        case 17005: // FIRAuthErrorCodeUserDisabled
            return .userDisabled
        case 17014: // FIRAuthErrorCodeRequiresRecentLogin
            return .requiresRecentLogin
        case 17020: // FIRAuthErrorCodeNetworkError
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
    return .unknown(error.localizedDescription)
}
