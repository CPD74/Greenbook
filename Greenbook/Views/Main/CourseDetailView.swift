//
//  CourseDetailView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 5/22/25.
//

import SwiftUI

struct CourseDetailView: View {
    let course: Course
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Course Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(course.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("\(course.city), \(course.country)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Course Details
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    DetailCard(title: "Holes", value: "\(course.holes)")
                    DetailCard(title: "Access", value: course.access)
                    DetailCard(title: "Designer", value: course.designer.isEmpty ? "Unknown" : course.designer)
                    if let established = course.established {
                        DetailCard(title: "Established", value: "\(established)")
                    }
                }
                
                if !course.description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(course.description)
                            .font(.body)
                    }
                }
                
                if !course.website.isEmpty {
                    Link("Visit Website", destination: URL(string: course.website) ?? URL(string: "https://google.com")!)
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .navigationTitle("Course Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
