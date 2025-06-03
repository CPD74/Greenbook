//
//  MyListsView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 6/3/25.
//

import SwiftUI

struct MyListsView: View {
    @EnvironmentObject var authState: AuthenticationState
    @State private var userLists: [UserCourseList] = []
    @State private var isLoading = false
    @State private var showingCreateList = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading your lists...")
                    .foregroundColor(.gray)
            } else if userLists.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No lists created yet")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Create custom lists like 'Bucket List Courses', 'Weekend Getaways', or 'Courses Near Home'!")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Button(action: {
                        showingCreateList = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Create Your First List")
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Future: List of user's course lists
                List {
                    ForEach(Array(userLists.enumerated()), id: \.offset) { index, list in
                        UserListCardView(courseList: list)
                    }
                }
                .listStyle(PlainListStyle())
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingCreateList = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateList) {
            CreateListView()
                .environmentObject(authState)
        }
        .onAppear {
            loadUserLists()
        }
    }
    
    private func loadUserLists() {
        // TODO: Implement when user list functionality is built
        isLoading = true
        
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            // userLists will be populated from Firebase when implemented
        }
    }
}

// MARK: - Placeholder Models
struct UserCourseList {
    let id: String
    let title: String
    let description: String
    let userId: String
    let courseIds: [String]
    let courseCount: Int
    let isPublic: Bool
    let createdAt: Date
    let updatedAt: Date
}

struct UserListCardView: View {
    let courseList: UserCourseList
    
    var body: some View {
        // Placeholder for future user list card component
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(courseList.title)
                    .font(.headline)
                Spacer()
                if courseList.isPublic {
                    Image(systemName: "globe")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            Text(courseList.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text("\(courseList.courseCount) courses")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct CreateListView: View {
    @EnvironmentObject var authState: AuthenticationState
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Create List functionality coming soon!")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding()
                Spacer()
            }
            .navigationTitle("Create List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct MyListsView_Previews: PreviewProvider {
    static var previews: some View {
        MyListsView()
            .environmentObject(AuthenticationState())
    }
}
