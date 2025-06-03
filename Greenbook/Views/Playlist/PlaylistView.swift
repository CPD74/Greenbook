//
//  PlaylistView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 6/3/25.
//

import SwiftUI

struct PlaylistView: View {
    @EnvironmentObject var authState: AuthenticationState
    @State private var playedCourses: [Course] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading your courses...")
                        .foregroundColor(.gray)
                } else if playedCourses.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.rectangle.stack")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No courses played yet")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Start exploring courses and mark the ones you've played to build your playlist!")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Future: List of played courses
                    List {
                        ForEach(Array(playedCourses.enumerated()), id: \.offset) { index, course in
                            CourseCardView(course: course, showDetails: true)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Playlist")
            .preferredColorScheme(.dark)
        }
        .onAppear {
            loadPlayedCourses()
        }
    }
    
    private func loadPlayedCourses() {
        // TODO: Implement when course interaction functionality is built
        // For now, this is a placeholder
        isLoading = true
        
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            // playedCourses will be populated from Firebase when implemented
        }
    }
}

// MARK: - Preview
struct PlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistView()
            .environmentObject(AuthenticationState())
    }
}
