//
//  ListsView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 6/3/25.
//

import SwiftUI

struct ListsView: View {
    @EnvironmentObject var authState: AuthenticationState
    @State private var courseLists: [CourseList] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading lists...")
                    .foregroundColor(.gray)
            } else if courseLists.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No lists yet")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Discover curated course lists from the community like 'Best Championship Courses' or 'Hidden Gems'!")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Future: List of course lists
                List {
                    ForEach(Array(courseLists.enumerated()), id: \.offset) { index, list in
                        ListCardView(courseList: list)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear {
            loadCourseLists()
        }
    }
    
    private func loadCourseLists() {
        // TODO: Implement when course list functionality is built
        isLoading = true
        
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            // courseLists will be populated from Firebase when implemented
        }
    }
}

// MARK: - Placeholder Models
struct CourseList {
    let id: String
    let title: String
    let description: String
    let creatorId: String
    let creatorName: String
    let courseIds: [String]
    let courseCount: Int
    let isPublic: Bool
    let createdAt: Date
    let updatedAt: Date
}

struct ListCardView: View {
    let courseList: CourseList
    
    var body: some View {
        // Placeholder for future list card component
        VStack(alignment: .leading, spacing: 8) {
            Text(courseList.title)
                .font(.headline)
            Text(courseList.description)
                .font(.body)
                .foregroundColor(.secondary)
            Text("\(courseList.courseCount) courses")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

// MARK: - Preview
struct ListsView_Previews: PreviewProvider {
    static var previews: some View {
        ListsView()
            .environmentObject(AuthenticationState())
    }
}
