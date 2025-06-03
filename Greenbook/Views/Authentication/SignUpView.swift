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

// Sign Up View
struct SignUpView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
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
                Image("GolfSignUpIllustration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                
                Text("Sign Up")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 10) {
                    // First Name Field
                    Text("First Name")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextField("John", text: $firstName)
                        .autocapitalization(.words)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    // Last Name Field
                    Text("Last Name")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                    
                    TextField("Smith", text: $lastName)
                        .autocapitalization(.words)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    // Email Field
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                    
                    TextField("john.smith@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    // Password Field
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
                    
                    // Confirm Password Field
                    Text("Confirm Password")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                    
                    SecureField("••••••••", text: $confirmPassword)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 5)
                    }
                }
                .padding()
                
                Button(action: signUp) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign up")
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
                    Text("Already have an account?")
                        .foregroundColor(.gray)
                    NavigationLink("Sign In", destination: SignInView())
                        .foregroundColor(.green)
                }
                .padding(.top, 5)
                
                HStack {
                    Spacer()
                    GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .light, style: .standard, state: .normal)) {
                        googleSignUp()
                    }
                    .frame(width: 200, height: 50)
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    func signUp() {
        isLoading = true
        errorMessage = ""
        
        // Validation
        guard !firstName.isEmpty else {
            errorMessage = "First name cannot be empty"
            isLoading = false
            return
        }
        
        guard !lastName.isEmpty else {
            errorMessage = "Last name cannot be empty"
            isLoading = false
            return
        }
        
        guard !email.isEmpty else {
            errorMessage = "Email cannot be empty"
            isLoading = false
            return
        }
        
        guard !password.isEmpty, password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            isLoading = false
            return
        }
        
        // Call updated AuthManager method
        AuthManager.shared.signUp(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let user):
                    // AuthenticationState will automatically update via Firebase listener
                    // Update the current user in auth state
                    authState.updateCurrentUser(user)
                    print("✅ User created successfully: \(user.displayName)")
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    print("❌ Sign up failed: \(error)")
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

#Preview {
    SignUpView()
        .environmentObject(AuthenticationState())
}
