//
//  ProfileTabView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 6/3/25.
//

import SwiftUI

struct ProfileTabView: View {
    @EnvironmentObject var authState: AuthenticationState
    @State private var selectedSegment = 0
    
    private let segments = ["Profile", "My Lists", "My Reviews", "Want to Play"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control Navigation
                Picker("Profile Sections", selection: $selectedSegment) {
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
                        ProfileView()
                            .environmentObject(authState)
                    case 1:
                        MyListsView()
                            .environmentObject(authState)
                    case 2:
                        MyReviewsView()
                            .environmentObject(authState)
                    case 3:
                        WantToPlayView()
                            .environmentObject(authState)
                    default:
                        ProfileView()
                            .environmentObject(authState)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Profile")
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
struct ProfileTabView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileTabView()
            .environmentObject(AuthenticationState())
    }
}
