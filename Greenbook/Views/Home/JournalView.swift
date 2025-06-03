//
//  JournalView.swift
//  Greenbook
//
//  Created by Charlie Daniel on 6/3/25.
//

import SwiftUI

struct JournalView: View {
    @EnvironmentObject var authState: AuthenticationState
    @State private var journalEntries: [JournalEntry] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading journal entries...")
                    .foregroundColor(.gray)
            } else if journalEntries.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No journal entries yet")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Keep track of your golf experiences, memorable shots, and course conditions in your personal journal!")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Future: List of journal entries
                List {
                    ForEach(Array(journalEntries.enumerated()), id: \.offset) { index, entry in
                        JournalEntryCardView(entry: entry)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear {
            loadJournalEntries()
        }
    }
    
    private func loadJournalEntries() {
        // TODO: Implement when journal functionality is built
        isLoading = true
        
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            // journalEntries will be populated from Firebase when implemented
        }
    }
}

// MARK: - Placeholder Models
struct JournalEntry {
    let id: String
    let userId: String
    let courseId: String?
    let courseName: String?
    let title: String
    let content: String
    let date: Date
    let weather: String?
    let score: Int?
    let photos: [String] // Photo URLs
    let createdAt: Date
    let updatedAt: Date
}

struct JournalEntryCardView: View {
    let entry: JournalEntry
    
    var body: some View {
        // Placeholder for future journal entry card component
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.title)
                    .font(.headline)
                Spacer()
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if let courseName = entry.courseName {
                Text("at \(courseName)")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            Text(entry.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding()
    }
}

// MARK: - Preview
struct JournalView_Previews: PreviewProvider {
    static var previews: some View {
        JournalView()
            .environmentObject(AuthenticationState())
    }
}
