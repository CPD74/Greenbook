//
//  MyReviewsView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 6/3/25.
//

import SwiftUI

struct MyReviewsView: View {
    @EnvironmentObject var authState: AuthenticationState
    @State private var userReviews: [UserCourseReview] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading your reviews...")
                    .foregroundColor(.gray)
            } else if userReviews.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "star.bubble")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No reviews written yet")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Share your experiences! Write reviews for courses you've played to help other golfers discover great places to play.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Future: List of user's course reviews
                List {
                    ForEach(Array(userReviews.enumerated()), id: \.offset) { index, review in
                        UserReviewCardView(review: review)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear {
            loadUserReviews()
        }
    }
    
    private func loadUserReviews() {
        // TODO: Implement when user review functionality is built
        isLoading = true
        
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            // userReviews will be populated from Firebase when implemented
        }
    }
}

// MARK: - Placeholder Models
struct UserCourseReview {
    let id: String
    let courseId: String
    let courseName: String
    let userId: String
    let rating: Int // 1-5 stars
    let reviewText: String
    let pros: [String]
    let cons: [String]
    let playedDate: Date?
    let courseCondition: String? // "Excellent", "Good", "Fair", "Poor"
    let difficulty: Int? // 1-5 scale
    let wouldPlayAgain: Bool
    let createdAt: Date
    let updatedAt: Date
}

struct UserReviewCardView: View {
    let review: UserCourseReview
    
    var body: some View {
        // Placeholder for future user review card component
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(review.courseName)
                    .font(.headline)
                Spacer()
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= review.rating ? "star.fill" : "star")
                            .foregroundColor(star <= review.rating ? .yellow : .gray)
                            .font(.caption)
                    }
                }
            }
            
            Text(review.reviewText)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                if let playedDate = review.playedDate {
                    Text("Played \(playedDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                if review.wouldPlayAgain {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Would play again")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Preview
struct MyReviewsView_Previews: PreviewProvider {
    static var previews: some View {
        MyReviewsView()
            .environmentObject(AuthenticationState())
    }
}
