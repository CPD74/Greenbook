//
//  WantToPlayView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 6/3/25.
//

import SwiftUI

struct WantToPlayView: View {
    @EnvironmentObject var authState: AuthenticationState
    @State private var wantToPlayCourses: [WantToPlayCourse] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading your wishlist...")
                    .foregroundColor(.gray)
            } else if wantToPlayCourses.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "heart")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No courses on your wishlist")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Discover amazing courses and add them to your wishlist! Keep track of dream destinations and courses you want to experience.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Future: List of courses user wants to play
                List {
                    ForEach(Array(wantToPlayCourses.enumerated()), id: \.offset) { index, course in
                        WantToPlayCardView(wantToPlayCourse: course)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear {
            loadWantToPlayCourses()
        }
    }
    
    private func loadWantToPlayCourses() {
        // TODO: Implement when want-to-play functionality is built
        isLoading = true
        
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            // wantToPlayCourses will be populated from Firebase when implemented
        }
    }
}

// MARK: - Placeholder Models
struct WantToPlayCourse {
    let id: String
    let courseId: String
    let courseName: String
    let courseCity: String
    let courseState: String
    let courseCountry: String
    let userId: String
    let priority: WantToPlayPriority
    let notes: String?
    let addedDate: Date
    let targetDate: Date? // When they hope to play
}

enum WantToPlayPriority: String, CaseIterable {
    case low = "Someday"
    case medium = "This Year"
    case high = "ASAP"
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct WantToPlayCardView: View {
    let wantToPlayCourse: WantToPlayCourse
    
    var body: some View {
        // Placeholder for future want-to-play card component
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(wantToPlayCourse.courseName)
                    .font(.headline)
                Spacer()
                Text(wantToPlayCourse.priority.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(wantToPlayCourse.priority.color.opacity(0.2))
                    .foregroundColor(wantToPlayCourse.priority.color)
                    .cornerRadius(4)
            }
            
            Text("\(wantToPlayCourse.courseCity), \(wantToPlayCourse.courseState)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let notes = wantToPlayCourse.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Text("Added \(wantToPlayCourse.addedDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if let targetDate = wantToPlayCourse.targetDate {
                    Text("Target: \(targetDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
    }
}

// MARK: - Preview
struct WantToPlayView_Previews: PreviewProvider {
    static var previews: some View {
        WantToPlayView()
            .environmentObject(AuthenticationState())
    }
}
