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

// Sign In View
struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authState: AuthenticationState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Back button
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Illustration
                Image("GolfSignInIllustration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                
                Text("Sign In")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextField("john.smith@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    Text("Password")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                    
                    HStack {
                        SecureField("••••••••", text: $password)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        Button(action: {}) {
                            Image(systemName: "eye")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 10)
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            // Implement password reset
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                
                Button(action: signIn) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign in")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(60)
                .padding(.horizontal)
                .disabled(isLoading)
                
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.gray)
                    NavigationLink("Sign Up", destination: SignUpView())
                        .foregroundColor(.green)
                }
                .padding(.top, 5)
                
                // Google Sign-In Button
                GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .light, style: .standard, state: .normal)) {
                    googleSignIn()
                }
                .padding()
                .frame(height: 50)
            }
            .navigationBarHidden(true)
        }
    }
    
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
}

#Preview {
    SignInView()
        .environmentObject(AuthenticationState())
}
