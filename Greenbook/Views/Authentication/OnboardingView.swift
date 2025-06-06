//
//  OnboardingView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 3/25/25.
//

import SwiftUI
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift

// Onboarding/Welcome View
struct OnboardingView: View {
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Background Image - covers full screen including safe areas
                    Image("GreenBookLandscape")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .ignoresSafeArea(.all)
                    
                    // Semi-transparent overlay to improve text readability
                    Color.black.opacity(0.6)
                        .ignoresSafeArea(.all)
                    
                    // Content laid over the image
                    VStack(spacing: 0) {
                        // Title section - bigger text, closer to top
                        VStack(spacing: 12) {
                            // Split color title
                            HStack(spacing: 0) {
                                Text("GREEN")
                                    .font(.system(size: 48, weight: .bold, design: .default))
                                    .foregroundColor(.greenbookAuth)
                                    .shadow(color: .black, radius: 2, x: 1, y: 1) // Add shadow
                                Text("BOOK")
                                    .font(.system(size: 48, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                            }
                            .multilineTextAlignment(.center)
                            
                            Text("YOUR LIFE IN GOLF")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 30)
                        .frame(maxWidth: .infinity)
                        
                        Spacer(minLength: 100)
                        
                        // Buttons section - always stays above safe area
                        VStack(spacing: 16) {
                            NavigationLink(destination: SignUpView()) {
                                Text("Join Greenbook")
                                    .font(.system(size: 20, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.greenbookAuth)
                                    .foregroundColor(.white)
                                    .cornerRadius(60)
                            }
                            
                            NavigationLink(destination: SignInView()) {
                                Text("Sign in")
                                    .font(.system(size: 20, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .foregroundColor(.greenbookAuth)
                                    .cornerRadius(60)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 50)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.light) // Force the entire authentication navigation stack to light mode
    }
}

#Preview {
    OnboardingView()
        .preferredColorScheme(.light)
}
