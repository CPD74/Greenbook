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
