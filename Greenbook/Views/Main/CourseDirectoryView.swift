//
//  CourseDirectoryView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 5/22/25.
//

import SwiftUI

struct CourseDirectoryView: View {
    @EnvironmentObject var courseService: CourseService // Changed from @StateObject to @EnvironmentObject
    @State private var searchText = ""
    @State private var selectedHoles = "All"
    @State private var selectedAccess = "All"
    
    // Filter options
    private let holeOptions = ["All", "9", "18", "27"]
    private let accessOptions = ["All", "Public", "Private"]
    
    private var filteredCourses: [Course] {
        var filtered = courseService.courses
        
        if !searchText.isEmpty {
            filtered = filtered.filter { course in
                course.name.localizedCaseInsensitiveContains(searchText) ||
                course.city.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if selectedHoles != "All" {
            filtered = filtered.filter { "\($0.holes)" == selectedHoles }
        }
        
        if selectedAccess != "All" {
            filtered = filtered.filter { $0.access == selectedAccess }
        }
        
        return filtered
    }
    
    var body: some View {
        // Removed NavigationView - parent MainTabView provides navigation
        VStack(spacing: 0) {
            // Search Bar
            SearchBar(text: $searchText)
            
            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterPicker(title: "Holes", selection: $selectedHoles, options: holeOptions)
                    FilterPicker(title: "Access", selection: $selectedAccess, options: accessOptions)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Course List
            if courseService.isLoading {
                Spacer()
                ProgressView("Loading courses...")
                Spacer()
            } else if filteredCourses.isEmpty {
                Spacer()
                Text("No courses found")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(Array(filteredCourses.enumerated()), id: \.offset) { index, course in
                        NavigationLink(destination: CourseDetailView(course: course)) {
                            CourseRowView(course: course)
                        }
                        .listRowSeparator(.visible)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await courseService.fetchAllCourses()
        }
    }
}

struct CourseRowView: View {
    let course: Course
    
    var body: some View {
        HStack(spacing: 16) {
            // Placeholder image rectangle
            Rectangle()
                .fill(Color(red: 0.96, green: 0.94, blue: 0.87)) // Beige color
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            
            // Course information
            VStack(alignment: .leading, spacing: 4) {
                // Course name (bold and prominent)
                Text(course.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                // City, State | X holes
                Text("\(course.city), \(course.state) | \(course.holes) holes")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Spacer()
            
            // Chevron for navigation
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 60)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search courses...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct FilterPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    selection = option
                }
            }
        } label: {
            HStack {
                Text(selection == "All" ? title : selection)
                Image(systemName: "chevron.down")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
    }
}

#Preview {
    CourseDirectoryView()
        .environmentObject(CourseService())
}
