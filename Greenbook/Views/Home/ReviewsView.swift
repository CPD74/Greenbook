//
//  ReviewsView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 6/3/25.
//

import SwiftUI

struct ReviewsView: View {
    @EnvironmentObject var authState: AuthenticationState
    @State private var reviews: [CourseReview] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading reviews...")
                    .foregroundColor(.gray)
            } else if reviews.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "star.bubble")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No reviews yet")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Discover course reviews from the community and share your own experiences!")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Future: List of course reviews
                List {
                    ForEach(Array(reviews.enumerated()), id: \.offset) { index, review in
                        ReviewCardView(review: review)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear {
            loadReviews()
        }
    }
    
    private func loadReviews() {
        // TODO: Implement when review functionality is built
        isLoading = true
        
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            // reviews will be populated from Firebase when implemented
        }
    }
}

// MARK: - Placeholder Models
struct CourseReview {
    let id: String
    let courseId: String
    let courseName: String
    let userId: String
    let userName: String
    let rating: Int
    let reviewText: String
    let createdAt: Date
}

struct ReviewCardView: View {
    let review: CourseReview
    
    var body: some View {
        // Placeholder for future review card component
        VStack(alignment: .leading, spacing: 8) {
            Text(review.courseName)
                .font(.headline)
            Text(review.reviewText)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Preview
struct ReviewsView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewsView()
            .environmentObject(AuthenticationState())
    }
}
