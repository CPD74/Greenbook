//
//  MainTabView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 6/3/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authState: AuthenticationState
    @StateObject private var courseService = CourseService()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Home
            HomeView()
                .environmentObject(authState)
                .environmentObject(courseService)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0)
            
            // Tab 2: Explore
            NavigationView {
                CourseDirectoryView()
                    .environmentObject(courseService)
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Explore")
            }
            .tag(1)
            
            // Tab 3: Playlist
            NavigationView {
                PlaylistView()
                    .environmentObject(authState)
            }
            .tabItem {
                Image(systemName: "checkmark.rectangle.stack")
                Text("Playlist")
            }
            .tag(2)
            
            // Tab 4: Profile
            ProfileTabView()
                .environmentObject(authState)
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(3)
        }
        .preferredColorScheme(.dark)
        .accentColor(.green) // This will make selected tabs dark green
        .onAppear {
            // Ensure we always start on Home tab
            selectedTab = 0
            
            // Customize tab bar appearance for dark theme
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            // Selected tab styling (dark green)
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemGreen
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.systemGreen
            ]
            
            // Unselected tab styling (grey)
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.systemGray
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthenticationState())
    }
}
