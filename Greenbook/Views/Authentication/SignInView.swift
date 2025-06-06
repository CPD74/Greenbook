//
//  SignInView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 3/25/25.
//

import SwiftUI
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices

// Sign In View
struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var keyboardHeight: CGFloat = 0
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authState: AuthenticationState
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        // Illustration
                        Image("GolfSignInIllustration")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 150)
                            .padding(.top, 40)
                        
                        Text("Sign In")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 16) {
                            // Google Sign-In Button
                            Button(action: googleSignIn) {
                                HStack {
                                    Image("GoogleIcon")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 25, height: 25)
                                    Text("Continue with Google")
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(8)
                            }
                            .disabled(isLoading)
                            
                            // Custom Apple Sign-In Button
                            Button(action: { handleCustomAppleSignIn() }) {
                                HStack {
                                    Image(systemName: "applelogo")
                                        .foregroundColor(.black)
                                        .font(.title3)
                                    Text("Continue with Apple")
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(8)
                            }
                            .disabled(isLoading)
                        }
                        .padding(.horizontal, 20)
                        
                        // OR divider
                        HStack {
                            VStack {
                                Divider()
                                    .background(Color.gray.opacity(0.5))
                            }
                            Text("or")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                            VStack {
                                Divider()
                                    .background(Color.gray.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        
                        // Email and Password Section
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.black)
                                
                                TextField("Enter your email", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.black)
                                
                                HStack {
                                    Group {
                                        if showPassword {
                                            TextField("••••••••", text: $password)
                                        } else {
                                            SecureField("••••••••", text: $password)
                                        }
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    
                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.gray)
                                            .font(.title3)
                                    }
                                    .padding(.leading, 8)
                                }
                                
                                HStack {
                                    Spacer()
                                    Button("Forgot Password?") {
                                        // Implement password reset
                                    }
                                    .font(.caption)
                                    .foregroundColor(.greenbookAuth)
                                }
                            }
                            
                            // Sign In Button
                            Button(action: signIn) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(email.isEmpty || password.isEmpty ? Color.gray.opacity(0.3) : Color.greenbookAuth)
                            .cornerRadius(8)
                            .disabled(email.isEmpty || password.isEmpty || isLoading)
                        }
                        .padding(.horizontal, 20)
                        
                        // Error message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 40)
                        
                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.gray)
                            NavigationLink("Sign Up", destination: SignUpView())
                                .foregroundColor(.greenbookAuth)
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                        .padding(.bottom, max(20, keyboardHeight > 0 ? 20 : 20))
                    }
                    .frame(minHeight: geometry.size.height)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                        let keyboardRectangle = keyboardFrame.cgRectValue
                        keyboardHeight = keyboardRectangle.height
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                    keyboardHeight = 0
                }
                .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Prevent split view on iPad
        .preferredColorScheme(.light) // Force light mode for this view
        .background(Color(.systemBackground))
    }
    
    // MARK: - Authentication Methods
    
    func signIn() {
        isLoading = true
        errorMessage = ""
        
        // Use the original signIn method that returns FirebaseAuth.User
        AuthManager.shared.signIn(email: email, password: password) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(_):
                    // Don't manually set authentication state
                    // AuthenticationState will automatically update via Firebase listener
                    // and load the user profile
                    print("✅ Sign in successful")
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    print("❌ Sign in failed: \(error)")
                }
            }
        }
    }

    func googleSignIn() {
        isLoading = true
        errorMessage = ""
        
        AuthManager.shared.signInWithGoogle { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let user):
                    // AuthenticationState will automatically update via Firebase listener
                    authState.updateCurrentUser(user)
                    print("✅ Google sign in successful: \(user.displayName)")
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    print("❌ Google sign in failed: \(error)")
                }
            }
        }
    }
    
    func handleCustomAppleSignIn() {
        print("🍎 Custom Apple sign-in button tapped")
        isLoading = true
        errorMessage = ""
        
        // Use AuthManager to handle the Apple Sign-In (it already has username generation for new users)
        AuthManager.shared.signInWithApple { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let user):
                    // AuthenticationState will automatically update via Firebase listener
                    self.authState.updateCurrentUser(user)
                    print("✅ Apple sign in successful: \(user.displayName)")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("❌ Apple sign in failed: \(error)")
                }
            }
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthenticationState())
        .preferredColorScheme(.light)
}
