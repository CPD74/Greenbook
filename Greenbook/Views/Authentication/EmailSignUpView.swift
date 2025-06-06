//
//  EmailSignUpView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 6/5/25.
//

import SwiftUI
import FirebaseAuth

struct EmailSignUpView: View {
    let email: String
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    // Username validation states
    @State private var isCheckingUsername = false
    @State private var usernameAvailable: Bool? = nil
    @State private var usernameError: String? = nil
    @State private var usernameCheckTask: Task<Void, Never>? = nil
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authState: AuthenticationState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with back button
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.black)
                                .font(.title2)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Illustration (smaller version)
                    Image("GolfSignUpIllustration")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 120)
                        .padding(.top, 20)
                    
                    Text("Sign Up")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        // First Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            
                            TextField("Bryson", text: $firstName)
                                .autocapitalization(.words)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Last Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            
                            TextField("DeChambeau", text: $lastName)
                                .autocapitalization(.words)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Username Field (NEW)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            
                            HStack {
                                TextField("bryson_golf", text: $username)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(usernameBorderColor, lineWidth: 1)
                                    )
                                    .onChange(of: username) { _, newValue in
                                        handleUsernameChange(newValue)
                                    }
                                
                                // Username status indicator
                                Group {
                                    if isCheckingUsername {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else if let available = usernameAvailable {
                                        Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(available ? .green : .red)
                                            .font(.title3)
                                    }
                                }
                                .frame(width: 24, height: 24)
                                .padding(.leading, 8)
                            }
                            
                            // Username feedback message
                            if let error = usernameError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else if let available = usernameAvailable, available {
                                Text("Username is available")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            // Username requirements
                            if username.isEmpty {
                                Text("3-20 characters, letters, numbers, underscores, and hyphens only")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Email Field (pre-filled and disabled)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            
                            TextField("", text: .constant(email))
                                .disabled(true)
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .foregroundColor(.gray)
                        }
                        
                        // Password Field
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
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            
                            HStack {
                                Group {
                                    if showConfirmPassword {
                                        TextField("••••••••", text: $confirmPassword)
                                    } else {
                                        SecureField("••••••••", text: $confirmPassword)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(passwordsMatch ? Color.gray.opacity(0.3) : Color.red.opacity(0.5), lineWidth: 1)
                                )
                                
                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                        .font(.title3)
                                }
                                .padding(.leading, 8)
                            }
                            
                            // Password match indicator
                            if !confirmPassword.isEmpty && !passwordsMatch {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Password requirements
                        if !password.isEmpty && password.count < 6 {
                            Text("Password must be at least 6 characters")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        // Error message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.callout)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Sign Up Button
                    Button(action: signUp) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign up")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isFormValid ? Color.greenbookAuth : Color.gray.opacity(0.3))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    .disabled(!isFormValid || isLoading)
                    
                    Spacer(minLength: 20)
                    
                    // Terms and Privacy
                    Text("By continuing, you are agreeing to our Terms of Service and Privacy Policy.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Sign In Link (NEW - added from SignUpView pattern)
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.gray)
                        NavigationLink("Sign In", destination: SignInView())
                            .foregroundColor(.greenbookAuth)
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Prevent split view on iPad
        .preferredColorScheme(.light) // Force light mode for this view
        .background(Color(.systemBackground))
        .onDisappear {
            // Cancel any pending username check when view disappears
            usernameCheckTask?.cancel()
        }
    }
    
    // MARK: - Computed Properties
    
    private var passwordsMatch: Bool {
        return password == confirmPassword
    }
    
    private var isFormValid: Bool {
        return !firstName.isEmpty &&
               !lastName.isEmpty &&
               !username.isEmpty &&
               usernameAvailable == true &&
               usernameError == nil &&
               !password.isEmpty &&
               password.count >= 6 &&
               passwordsMatch
    }
    
    private var usernameBorderColor: Color {
        if username.isEmpty {
            return Color.gray.opacity(0.3)
        } else if isCheckingUsername {
            return Color.blue.opacity(0.5)
        } else if let available = usernameAvailable {
            return available ? Color.green.opacity(0.5) : Color.red.opacity(0.5)
        } else if usernameError != nil {
            return Color.red.opacity(0.5)
        }
        return Color.gray.opacity(0.3)
    }
    
    // MARK: - Username Methods
    
    private func handleUsernameChange(_ newValue: String) {
        // Cancel any existing check
        usernameCheckTask?.cancel()
        
        // Reset states
        usernameAvailable = nil
        usernameError = nil
        isCheckingUsername = false
        
        // Clean the username (remove spaces, convert to lowercase for checking)
        let cleanedUsername = newValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Don't check if empty
        guard !cleanedUsername.isEmpty else {
            return
        }
        
        // Validate format first
        let validationError = User.getUsernameValidationError(cleanedUsername)
        if let error = validationError {
            usernameError = error
            return
        }
        
        // Start checking availability after a short delay
        isCheckingUsername = true
        
        usernameCheckTask = Task {
            do {
                // Add a small delay to prevent too many API calls
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Check if task was cancelled
                if Task.isCancelled {
                    return
                }
                
                let available = try await UserService.shared.checkUsernameAvailability(username: cleanedUsername)
                
                await MainActor.run {
                    if !Task.isCancelled {
                        isCheckingUsername = false
                        usernameAvailable = available
                        if !available {
                            usernameError = "Username is already taken"
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    if !Task.isCancelled {
                        isCheckingUsername = false
                        usernameError = "Unable to check username availability"
                    }
                }
                print("❌ Error checking username availability: \(error)")
            }
        }
    }
    
    // MARK: - Methods
    
    func signUp() {
        isLoading = true
        errorMessage = ""
        
        // Final validation before submission
        guard isFormValid else {
            errorMessage = "Please fill out all fields correctly"
            isLoading = false
            return
        }
        
        // Cancel any pending username check
        usernameCheckTask?.cancel()
        
        // Create User object with username
        let displayName = "\(firstName) \(lastName)"
        let user = User(
            email: email,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName,
            username: username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        // Create Firebase Auth account first
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = self.getFormattedError(error)
                    print("❌ Firebase Auth creation failed: \(error)")
                }
                return
            }
            
            guard let firebaseUser = authResult?.user else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to create account"
                }
                return
            }
            
            // Now create the user profile with username
            Task {
                do {
                    try await UserService.shared.createUserWithUsername(user, userId: firebaseUser.uid)
                    
                    await MainActor.run {
                        self.isLoading = false
                        // AuthenticationState will automatically update via Firebase listener
                        self.authState.updateCurrentUser(user)
                        print("✅ User created successfully with username: \(user.username)")
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    
                } catch {
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = "Failed to create user profile: \(error.localizedDescription)"
                        print("❌ User profile creation failed: \(error)")
                    }
                }
            }
        }
    }
    
    private func getFormattedError(_ error: Error) -> String {
        if let authError = error as? AuthError {
            switch authError {
            case .emailAlreadyInUse:
                return "An account with this email already exists. Please sign in instead."
            case .weakPassword:
                return "Please choose a stronger password."
            case .invalidEmail:
                return "Please enter a valid email address."
            case .networkError:
                return "Network connection error. Please check your internet and try again."
            default:
                return "An error occurred. Please try again."
            }
        } else if let firebaseError = error as NSError? {
            switch firebaseError.code {
            case 17007: // FIRAuthErrorCodeEmailAlreadyInUse
                return "An account with this email already exists. Please sign in instead."
            case 17026: // FIRAuthErrorCodeWeakPassword
                return "Please choose a stronger password."
            case 17008: // FIRAuthErrorCodeInvalidEmail
                return "Please enter a valid email address."
            default:
                return "An error occurred. Please try again."
            }
        }
        return error.localizedDescription
    }
}

#Preview {
    EmailSignUpView(email: "charlie@example.com")
        .environmentObject(AuthenticationState())
        .preferredColorScheme(.light)
}
