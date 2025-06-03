//
//  CourseCardView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 5/22/25.
//

import SwiftUI

struct CourseCardView: View {
    let course: Course
    let showDetails: Bool // true for directory, false for home page
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.name)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            if showDetails {
                Text("\(course.city), \(course.country)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("\(course.holes) holes")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .frame(width: showDetails ? nil : 150, height: showDetails ? 80 : 100)
        .background(Color.green)
        .cornerRadius(12)
    }
}

struct ViewAllCard: View {
    var body: some View {
        VStack {
            Spacer()
            Text("View All")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
        }
        .padding()
        .frame(width: 150, height: 100)
        .background(Color.green.opacity(0.7))
        .cornerRadius(12)
    }
}
