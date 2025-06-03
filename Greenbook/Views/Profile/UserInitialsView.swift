//
//  UserInitialsView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 6/2/25.
//

import SwiftUI

struct UserInitialsView: View {
    let user: User?
    let size: CGFloat
    
    // Default initializer with standard size
    init(user: User?, size: CGFloat = 40) {
        self.user = user
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.green)
                .frame(width: size, height: size)
            
            // Profile image or initials
            Group {
                if let profileImageURL = user?.profileImageURL,
                   let url = URL(string: profileImageURL) {
                    // Show profile image if available
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                    } placeholder: {
                        // Show initials while loading image
                        initialsText
                    }
                } else {
                    // Show initials when no profile image
                    initialsText
                }
            }
        }
        .frame(width: size, height: size)
    }
    
    private var initialsText: some View {
        Text(user?.initials ?? "?")
            .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
    }
}

// MARK: - Preview Provider
struct UserInitialsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Preview with user
            UserInitialsView(
                user: User(
                    email: "john.smith@example.com",
                    displayName: "John Smith",
                    firstName: "John",
                    lastName: "Smith"
                ),
                size: 40
            )
            
            // Preview with user who has profile image
            UserInitialsView(
                user: User(
                    email: "jane.doe@example.com",
                    displayName: "Jane Doe",
                    firstName: "Jane",
                    lastName: "Doe",
                    profileImageURL: "https://example.com/profile.jpg"
                ),
                size: 40
            )
            
            // Preview with no user
            UserInitialsView(user: nil, size: 40)
            
            // Preview with different sizes
            HStack(spacing: 10) {
                UserInitialsView(
                    user: User(
                        email: "test@example.com",
                        displayName: "Test User",
                        firstName: "Test",
                        lastName: "User"
                    ),
                    size: 30
                )
                
                UserInitialsView(
                    user: User(
                        email: "test@example.com",
                        displayName: "Test User",
                        firstName: "Test",
                        lastName: "User"
                    ),
                    size: 50
                )
                
                UserInitialsView(
                    user: User(
                        email: "test@example.com",
                        displayName: "Test User",
                        firstName: "Test",
                        lastName: "User"
                    ),
                    size: 70
                )
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
