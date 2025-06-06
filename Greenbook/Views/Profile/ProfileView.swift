//
//  ProfileView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 6/2/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authState: AuthenticationState
    @StateObject private var courseService = CourseService()
    @State private var isEditing = false
    @State private var editedUser: User?
    @State private var showingHomeCourseSelection = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Username validation state
    @State private var usernameValidationState: UsernameValidationState = .idle
    @State private var usernameValidationMessage: String = ""
    @State private var usernameCheckTask: Task<Void, Never>?
    
    var body: some View {
        // Removed NavigationView - parent ProfileTabView provides navigation
        ScrollView {
            VStack(spacing: 24) {
                if let user = authState.currentUser {
                    // Profile Header
                    profileHeader(user: isEditing ? (editedUser ?? user) : user)
                    
                    // Profile Information
                    profileInformation(user: isEditing ? (editedUser ?? user) : user)
                    
                    // Action Buttons
                    actionButtons
                    
                } else {
                    // Loading or No User State
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading profile...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if authState.currentUser != nil {
                    Button(isEditing ? "Done" : "Edit") {
                        if isEditing {
                            saveProfile()
                        } else {
                            startEditing()
                        }
                    }
                    // Edge Case: Disable button during various states
                    .disabled(isEditing && (!canSaveProfile || isLoading))
                    .opacity((isEditing && (!canSaveProfile || isLoading)) ? 0.6 : 1.0)
                }
            }
        }
        .sheet(isPresented: $showingHomeCourseSelection) {
            homeCourseSelectionSheet
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Username Validation State Enum
    enum UsernameValidationState {
        case idle
        case checking
        case valid
        case invalid
        case taken
        case unchanged
    }
    
    // MARK: - Profile Header (Updated with Username Display and Editing)
    private func profileHeader(user: User) -> some View {
        VStack(spacing: 16) {
            // Profile Image / Initials
            UserInitialsView(user: user, size: 120)
            
            // User Name and Username
            VStack(spacing: 4) {
                if isEditing {
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            TextField("First Name", text: Binding(
                                get: { editedUser?.firstName ?? user.firstName },
                                set: { updateEditedUser(\.firstName, value: $0) }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Last Name", text: Binding(
                                get: { editedUser?.lastName ?? user.lastName },
                                set: { updateEditedUser(\.lastName, value: $0) }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        TextField("Display Name", text: Binding(
                            get: { editedUser?.displayName ?? user.displayName },
                            set: { updateEditedUser(\.displayName, value: $0) }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        // Username Field with Validation
                        usernameEditingField(currentUser: user)
                    }
                } else {
                    // Display Name
                    Text(user.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    // Username Handle
                    Text(user.displayHandle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    // MARK: - Enhanced Username Text Field with Input Restrictions
    private func usernameEditingField(currentUser: User) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TextField("Username", text: Binding(
                    get: { editedUser?.username ?? currentUser.username },
                    set: { newUsername in
                        // Edge Case 1: Limit input length to prevent UI issues
                        let limitedUsername = String(newUsername.prefix(20))
                        
                        // Edge Case 2: Filter out invalid characters as user types
                        let filteredUsername = limitedUsername.filter { char in
                            char.isLetter || char.isNumber || char == "_" || char == "-"
                        }
                        
                        updateEditedUser(\.username, value: filteredUsername)
                        validateUsername(filteredUsername, currentUsername: currentUser.username)
                    }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .autocorrectionDisabled()
                // Edge Case 3: Disable spell check and suggestions
                .textContentType(.username)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(usernameValidationBorderColor, lineWidth: 1)
                )
                
                // Validation Status Icon
                Group {
                    switch usernameValidationState {
                    case .checking:
                        ProgressView()
                            .scaleEffect(0.8)
                    case .valid:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    case .invalid, .taken:
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    case .unchanged:
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.orange)
                    case .idle:
                        EmptyView()
                    }
                }
                .frame(width: 20, height: 20)
            }
            
            // Validation Message with Animation
            if !usernameValidationMessage.isEmpty {
                Text(usernameValidationMessage)
                    .font(.caption)
                    .foregroundColor(usernameValidationMessageColor)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.easeInOut(duration: 0.2), value: usernameValidationMessage)
            }
            
            // Username Format Helper
            Text("3-20 characters, letters, numbers, underscore, and hyphen only")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Username Validation Computed Properties
    private var usernameValidationBorderColor: Color {
        switch usernameValidationState {
        case .valid:
            return .green
        case .invalid, .taken:
            return .red
        case .unchanged:
            return .orange
        case .checking, .idle:
            return Color(.systemGray4)
        }
    }
    
    private var usernameValidationMessageColor: Color {
        switch usernameValidationState {
        case .valid, .unchanged:
            return .green
        case .invalid, .taken:
            return .red
        case .checking, .idle:
            return .secondary
        }
    }
    
    // MARK: - Profile Information
    private func profileInformation(user: User) -> some View {
        VStack(spacing: 16) {
            // Bio Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Bio")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if isEditing {
                    TextField("Tell us about yourself...", text: Binding(
                        get: { editedUser?.bio ?? user.bio ?? "" },
                        set: { updateEditedUser(\.bio, value: $0.isEmpty ? nil : $0) }
                    ), axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                } else {
                    Text(user.bio ?? "No bio yet")
                        .foregroundColor(user.bio == nil ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Home Course Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Home Course")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if isEditing {
                    Button(action: { showingHomeCourseSelection = true }) {
                        HStack {
                            Text(editedUser?.homeCourseName ?? user.homeCourseName ?? "Select home course")
                                .foregroundColor(user.homeCourseName == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                } else {
                    Text(user.homeCourseName ?? "No home course set")
                        .foregroundColor(user.homeCourseName == nil ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Email (Read-only)
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(user.email)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 16) {
            if isEditing {
                Button("Cancel") {
                    cancelEditing()
                }
                .foregroundColor(.red)
            } else {
                Button("Sign Out") {
                    signOut()
                }
                .foregroundColor(.red)
            }
        }
        .padding(.top)
    }
    
    // MARK: - Home Course Selection Sheet
    private var homeCourseSelectionSheet: some View {
        NavigationView {
            List {
                ForEach(Array(courseService.courses.enumerated()), id: \.offset) { index, course in
                    Button(action: {
                        selectHomeCourse(course)
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(course.name)
                                    .foregroundColor(.primary)
                                Text("\(course.city), \(course.state)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if course.id == (editedUser?.homeCourseId ?? authState.currentUser?.homeCourseId) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Home Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingHomeCourseSelection = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        clearHomeCourse()
                    }
                }
            }
            .onAppear {
                Task {
                    await courseService.fetchAllCourses()
                }
            }
        }
    }
    
    // MARK: - Enhanced Username Validation with Edge Case Handling
    private func validateUsername(_ username: String, currentUsername: String) {
        // Cancel any existing validation task
        usernameCheckTask?.cancel()
        
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Edge Case 1: Empty username - prevent user from clearing it
        if trimmedUsername.isEmpty {
            usernameValidationState = .invalid
            usernameValidationMessage = "Username cannot be empty"
            return
        }
        
        // Edge Case 2: Check if username is unchanged (case-insensitive)
        if trimmedUsername.lowercased() == currentUsername.lowercased() {
            usernameValidationState = .unchanged
            usernameValidationMessage = "Current username"
            return
        }
        
        // Edge Case 3: Immediate format validation before async check
        if let validationError = User.getUsernameValidationError(trimmedUsername) {
            usernameValidationState = .invalid
            usernameValidationMessage = validationError
            return
        }
        
        // Start availability check with debouncing
        usernameValidationState = .checking
        usernameValidationMessage = "Checking availability..."
        
        usernameCheckTask = Task {
            // Edge Case 4: Debouncing to avoid excessive API calls
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Edge Case 5: Check if task was cancelled (user kept typing)
            guard !Task.isCancelled else {
                print("🔄 Username validation cancelled - user kept typing")
                return
            }
            
            do {
                let isAvailable = try await UserService.shared.checkUsernameAvailability(username: trimmedUsername)
                
                await MainActor.run {
                    // Edge Case 6: Double-check task wasn't cancelled during async operation
                    guard !Task.isCancelled else {
                        print("🔄 Username validation cancelled during async check")
                        return
                    }
                    
                    if isAvailable {
                        self.usernameValidationState = .valid
                        self.usernameValidationMessage = "Username is available!"
                    } else {
                        self.usernameValidationState = .taken
                        self.usernameValidationMessage = "Username is already taken"
                    }
                }
            } catch {
                await MainActor.run {
                    // Edge Case 7: Network/API error handling
                    guard !Task.isCancelled else { return }
                    
                    print("❌ Username validation error: \(error)")
                    
                    // Check for specific error types and provide helpful messages
                    if let userServiceError = error as? UserServiceError {
                        switch userServiceError {
                        case .usernameCheckFailed:
                            self.usernameValidationState = .invalid
                            self.usernameValidationMessage = "Network error - please try again"
                        default:
                            self.usernameValidationState = .invalid
                            self.usernameValidationMessage = "Error checking availability"
                        }
                    } else {
                        // Generic network error
                        self.usernameValidationState = .invalid
                        self.usernameValidationMessage = "Network error - please check your connection"
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Method to Check if Profile Can Be Saved
    private var canSaveProfile: Bool {
        // Can save if username validation is valid or unchanged
        switch usernameValidationState {
        case .valid, .unchanged:
            return true
        case .checking, .invalid, .taken, .idle:
            return false
        }
    }
    
    // MARK: - Helper Methods
    private func startEditing() {
        editedUser = authState.currentUser
        isEditing = true
        // Reset username validation state when starting to edit
        usernameValidationState = .idle
        usernameValidationMessage = ""
    }
    
    // MARK: - Enhanced Cancel Editing with Cleanup
    private func cancelEditing() {
        // Edge Case 1: Cancel any pending username validation
        usernameCheckTask?.cancel()
        
        // Edge Case 2: Reset all editing state
        editedUser = nil
        isEditing = false
        
        // Edge Case 3: Clean up username validation state
        usernameValidationState = .idle
        usernameValidationMessage = ""
        
        // Edge Case 4: Clear any error messages
        errorMessage = nil
        
        print("🔄 Editing cancelled and state cleaned up")
    }
    
    private func updateEditedUser<T>(_ keyPath: WritableKeyPath<User, T>, value: T) {
        if editedUser == nil {
            editedUser = authState.currentUser
        }
        editedUser?[keyPath: keyPath] = value
    }
    
    private func selectHomeCourse(_ course: Course) {
        updateEditedUser(\.homeCourseId, value: course.id)
        updateEditedUser(\.homeCourseName, value: course.name)
        showingHomeCourseSelection = false
    }
    
    private func clearHomeCourse() {
        updateEditedUser(\.homeCourseId, value: nil)
        updateEditedUser(\.homeCourseName, value: nil)
        showingHomeCourseSelection = false
    }
    
    // MARK: - Enhanced Profile Save Logic with Edge Cases
    private func saveProfile() {
        guard let editedUser = editedUser else {
            // Edge Case 1: No edited user data
            print("⚠️ No edited user data to save")
            isEditing = false
            return
        }
        
        guard let currentUser = authState.currentUser else {
            // Edge Case 2: Current user disappeared during editing
            errorMessage = "User session expired. Please sign in again."
            cancelEditing()
            return
        }
        
        guard let userId = currentUser.id else {
            // Edge Case 3: Missing user ID
            errorMessage = "Invalid user session. Please sign in again."
            cancelEditing()
            return
        }
        
        // Edge Case 4: Check if we can save (username validation passed)
        guard canSaveProfile else {
            switch usernameValidationState {
            case .checking:
                errorMessage = "Please wait for username validation to complete"
            case .invalid:
                errorMessage = "Please fix the username format errors before saving"
            case .taken:
                errorMessage = "Please choose a different username - this one is taken"
            case .idle:
                errorMessage = "Username validation pending - please wait"
            case .valid, .unchanged:
                errorMessage = "Unexpected validation state - please try again"
            }
            return
        }
        
        // Edge Case 5: Prevent double-saving
        guard !isLoading else {
            print("⚠️ Save already in progress, ignoring duplicate request")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Edge Case 6: Validate username one more time before saving
                let trimmedUsername = editedUser.username.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Ensure username is still valid
                guard User.isValidUsername(trimmedUsername) else {
                    await MainActor.run {
                        self.errorMessage = "Username validation failed. Please check the format."
                        self.isLoading = false
                    }
                    return
                }
                
                // Check if username changed and needs special handling
                let usernameChanged = trimmedUsername.lowercased() != currentUser.username.lowercased()
                
                if usernameChanged {
                    // Edge Case 7: Username change requires atomic operations
                    print("🔄 Username changed, using atomic update process")
                    
                    // Double-check availability one more time before committing
                    let isStillAvailable = try await UserService.shared.checkUsernameAvailability(username: trimmedUsername)
                    guard isStillAvailable else {
                        await MainActor.run {
                            self.errorMessage = "Username was taken by another user. Please choose a different one."
                            self.usernameValidationState = .taken
                            self.usernameValidationMessage = "Username is already taken"
                            self.isLoading = false
                        }
                        return
                    }
                    
                    // Use UserService to update username (handles atomic operations)
                    try await UserService.shared.updateUsername(
                        newUsername: trimmedUsername,
                        userId: userId
                    )
                    
                    // Then update the rest of the profile
                    var updatedUser = editedUser.withUpdatedTimestamp()
                    updatedUser.username = trimmedUsername // Ensure normalized username
                    try await UserService.shared.updateUser(updatedUser)
                    
                    await MainActor.run {
                        authState.updateCurrentUser(updatedUser)
                    }
                    
                    print("✅ Username and profile updated successfully")
                    
                } else {
                    // Edge Case 8: Regular profile update without username change
                    print("🔄 Username unchanged, using regular profile update")
                    
                    try await UserService.shared.updateUser(editedUser)
                    
                    await MainActor.run {
                        authState.updateCurrentUser(editedUser.withUpdatedTimestamp())
                    }
                    
                    print("✅ Profile updated successfully")
                }
                
                // Edge Case 9: Clean up all state after successful save
                await MainActor.run {
                    self.editedUser = nil
                    self.isEditing = false
                    self.isLoading = false
                    self.usernameValidationState = .idle
                    self.usernameValidationMessage = ""
                    self.usernameCheckTask?.cancel()
                    
                    print("✅ Profile save completed successfully")
                }
                
            } catch {
                // Edge Case 10: Comprehensive error handling
                await MainActor.run {
                    self.isLoading = false
                    
                    print("❌ Profile save failed: \(error)")
                    
                    // Provide specific error messages based on error type
                    if let userServiceError = error as? UserServiceError {
                        switch userServiceError {
                        case .usernameTaken:
                            self.errorMessage = "Username was taken by another user. Please choose a different one."
                            self.usernameValidationState = .taken
                            self.usernameValidationMessage = "Username is already taken"
                        case .invalidUsername:
                            self.errorMessage = "Username format is invalid. Please check the requirements."
                            self.usernameValidationState = .invalid
                        case .usernameUpdateFailed, .updateFailed:
                            self.errorMessage = "Failed to save changes. Please check your connection and try again."
                        default:
                            self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                        }
                    } else {
                        // Generic error
                        self.errorMessage = "Failed to save profile. Please check your connection and try again."
                    }
                }
            }
        }
    }
    
    private func signOut() {
        let result = AuthManager.shared.signOut()
        if case .failure(let error) = result {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
}
