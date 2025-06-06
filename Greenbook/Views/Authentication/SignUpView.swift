//
//  SignUpView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 3/25/25.
//

import SwiftUI
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices

// Sign Up View
struct SignUpView: View {
    @State private var email = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showEmailSignUp = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var appleSignInDelegate: CustomAppleSignInDelegate?
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authState: AuthenticationState
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        // Illustration
                        Image("GolfSignUpIllustration")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 150)
                            .padding(.top, 40)
                        
                        Text("Create an Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 16) {
                            // Google Sign-Up Button
                            Button(action: googleSignUp) {
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
                            
                            // Custom Apple Sign-Up Button
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
                        
                        // Email Section
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
                            
                            // Sign Up with Email Button
                            Button(action: proceedWithEmail) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Sign Up")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(email.isEmpty ? Color.gray.opacity(0.3) : Color.greenbookAuth)
                            .cornerRadius(8)
                            .disabled(email.isEmpty || isLoading)
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
                        
                        // Sign In Link
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.gray)
                            NavigationLink("Sign In", destination: SignInView())
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
        .background(Color(.systemBackground)) // Ensure proper background color
        .fullScreenCover(isPresented: $showEmailSignUp, onDismiss: {
            // Reset email field when returning from EmailSignUpView
            // (in case user wants to try a different email)
            // email = "" // Uncomment if you want to clear the email field
        }) {
            EmailSignUpView(email: email)
                .environmentObject(authState)
        }
    }
    
    func proceedWithEmail() {
        print("📧 proceedWithEmail() called with email: '\(email)'")
        
        // Validate email format
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            print("❌ Email validation failed: '\(email)'")
            return
        }
        
        print("✅ Email validation passed, showing EmailSignUpView")
        errorMessage = ""
        showEmailSignUp = true
    }
    
    func isValidEmail(_ email: String) -> Bool {
        guard !email.isEmpty else {
            print("❌ Email is empty")
            return false
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        let isValid = emailPredicate.evaluate(with: email)
        print("📧 Email '\(email)' validation result: \(isValid)")
        return isValid
    }

    func handleCustomAppleSignIn() {
        print("🍎 Custom Apple button tapped")
        isLoading = true
        errorMessage = ""
        
        // Use AuthManager to handle the Apple Sign-In (it already has username generation)
        AuthManager.shared.signInWithApple { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let user):
                    // AuthenticationState will automatically update via Firebase listener
                    self.authState.updateCurrentUser(user)
                    print("✅ Apple sign up successful: \(user.displayName)")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("❌ Apple sign up failed: \(error)")
                }
            }
        }
    }
    
    func googleSignUp() {
        isLoading = true
        errorMessage = ""
        
        AuthManager.shared.signInWithGoogle { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let user):
                    // AuthenticationState will automatically update via Firebase listener
                    authState.updateCurrentUser(user)
                    print("✅ Google sign up successful: \(user.displayName)")
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    print("❌ Google sign up failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Custom Apple Sign-In Delegate (Not needed anymore but keeping for reference)
class CustomAppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<ASAuthorization, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthenticationState())
        .preferredColorScheme(.light)
}
