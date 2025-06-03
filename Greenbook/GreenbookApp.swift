//
//  GreenbookApp.swift
//  Greenbook
//
//  Created by Charlie Daniel on 3/24/25.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Ensure Google Sign-In is initialized properly
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            fatalError("❌ ERROR: Missing Google Client ID")
        }

        let googleSignInConfig = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = googleSignInConfig

        return true
    }
}

@main
struct GreenbookApp: App {
    // Register AppDelegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Authentication state
    @StateObject private var authState = AuthenticationState()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authState.isLoading {
                    // Show loading screen while checking authentication state
                    LoadingView()
                } else if authState.isAuthenticated {
                    // User is signed in - show main app with tab navigation
                    MainTabView()
                } else {
                    // User is not signed in - show onboarding
                    AuthenticationFlow()
                }
            }
            .environmentObject(authState)
            .preferredColorScheme(.dark) // Force dark mode for entire app
        }
    }
}

// MARK: - Authentication Flow
struct AuthenticationFlow: View {
    var body: some View {
        NavigationView {
            OnboardingView()
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.golf")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Greenbook")
                .font(.title)
                .fontWeight(.bold)
            
            ProgressView()
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview Provider
#Preview("Authenticated") {
    MainTabView()
        .environmentObject({
            let authState = AuthenticationState()
            authState.isAuthenticated = true
            authState.currentUser = User(
                email: "john.smith@example.com",
                displayName: "John Smith",
                firstName: "John",
                lastName: "Smith"
            )
            return authState
        }())
}

#Preview("Not Authenticated") {
    AuthenticationFlow()
        .environmentObject(AuthenticationState())
}

#Preview("Loading") {
    LoadingView()
}
