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
    
    // MARK: - Profile Header
    private func profileHeader(user: User) -> some View {
        VStack(spacing: 16) {
            // Profile Image / Initials
            UserInitialsView(user: user, size: 120)
            
            // User Name
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
                }
            } else {
                Text(user.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
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
    
    // MARK: - Helper Methods
    private func startEditing() {
        editedUser = authState.currentUser
        isEditing = true
    }
    
    private func cancelEditing() {
        editedUser = nil
        isEditing = false
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
    
    private func saveProfile() {
        guard let editedUser = editedUser else {
            isEditing = false
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Update the user profile using UserService
                try await UserService.shared.updateUser(editedUser)
                
                await MainActor.run {
                    authState.updateCurrentUser(editedUser.withUpdatedTimestamp())
                    self.editedUser = nil
                    self.isEditing = false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    self.isLoading = false
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

// MARK: - Preview Provider
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject({
                let authState = AuthenticationState()
                authState.currentUser = User(
                    email: "john.smith@example.com",
                    displayName: "John Smith",
                    firstName: "John",
                    lastName: "Smith",
                    bio: "Golf enthusiast and weekend warrior",
                    homeCourseName: "Pebble Beach Golf Links"
                )
                return authState
            }())
    }
}
