//
//  HomeView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 6/3/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authState: AuthenticationState
    @EnvironmentObject var courseService: CourseService
    @State private var selectedSegment = 0
    
    private let segments = ["Courses", "Reviews", "Lists", "Journal"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control Navigation
                Picker("Home Sections", selection: $selectedSegment) {
                    ForEach(0..<segments.count, id: \.self) { index in
                        Text(segments[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Content based on selected segment
                Group {
                    switch selectedSegment {
                    case 0:
                        CoursesView()
                            .environmentObject(authState)
                            .environmentObject(courseService)
                    case 1:
                        ReviewsView()
                            .environmentObject(authState)
                    case 2:
                        ListsView()
                            .environmentObject(authState)
                    case 3:
                        JournalView()
                            .environmentObject(authState)
                    default:
                        CoursesView()
                            .environmentObject(authState)
                            .environmentObject(courseService)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Greenbook")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
        .accentColor(.green) // This will make the segmented control use dark green
        .onAppear {
            // Customize segmented control appearance
            UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.systemGreen
            UISegmentedControl.appearance().setTitleTextAttributes([
                .foregroundColor: UIColor.black
            ], for: .selected)
            UISegmentedControl.appearance().setTitleTextAttributes([
                .foregroundColor: UIColor.systemGray
            ], for: .normal)
        }
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthenticationState())
            .environmentObject(CourseService())
    }
}
