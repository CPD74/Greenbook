//
//  ContentView.swift
//  Greenbook
//

import SwiftUI

struct CoursesView: View {
    @EnvironmentObject var authState: AuthenticationState
    @EnvironmentObject var courseService: CourseService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Popular this week (placeholder)
                SectionView(title: "Popular this week") {
                    PlaceholderSection()
                }
                
                // New from friends (placeholder)
                SectionView(title: "New from friends") {
                    PlaceholderSection()
                }
                
                // All courses
                SectionView(title: "All courses") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Use enumerated to create unique indices
                            ForEach(Array(courseService.courses.prefix(10).enumerated()), id: \.offset) { index, course in
                                NavigationLink(destination: CourseDetailView(course: course)) {
                                    CourseCardView(course: course, showDetails: false)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            NavigationLink(destination: CourseDirectoryView()) {
                                ViewAllCard()
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .task {
            await courseService.fetchAllCourses()
        }
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                Spacer()
            }
            
            content
        }
    }
}

struct PlaceholderSection: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 150, height: 100)
                        .overlay(
                            Text("Coming Soon")
                                .foregroundColor(.secondary)
                        )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Preview
struct CoursesView_Previews: PreviewProvider {
    static var previews: some View {
        CoursesView()
            .environmentObject({
                let authState = AuthenticationState()
                authState.currentUser = User(
                    email: "john.smith@example.com",
                    displayName: "John Smith",
                    firstName: "John",
                    lastName: "Smith",
                    username: "johnsmith_golf"
                )
                return authState
            }())
            .environmentObject(CourseService())
    }
}
