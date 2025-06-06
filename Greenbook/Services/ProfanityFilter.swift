//
//  ProfanityFilter.swift
//  Greenbook
//
//  Created by Charlie Daniel on 6/6/25.
//

import Foundation

class ProfanityFilter {
    static let shared = ProfanityFilter()
    
    private var profanityWords: Set<String> = []
    
    private init() {
        loadProfanityWords()
    }
    
    private func loadProfanityWords() {
        guard let path = Bundle.main.path(forResource: "ProfanityWords", ofType: "txt"),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("⚠️ Could not load profanity words file")
            return
        }
        
        // Split by newlines and clean up the words
        profanityWords = Set(content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty })
        
        print("✅ Loaded \(profanityWords.count) profanity words")
    }
    
    /// Checks if a username contains profanity
    func containsProfanity(_ text: String) -> Bool {
        let normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if the entire username is a profane word
        if profanityWords.contains(normalizedText) {
            return true
        }
        
        // Check if username contains profane words as substrings
        for word in profanityWords {
            if normalizedText.contains(word) && word.count >= 4 { // Only check longer words to avoid false positives
                return true
            }
        }
        
        return false
    }
    
    /// Gets a user-friendly error message for profanity
    func getProfanityErrorMessage() -> String {
        return "Username contains inappropriate content. Please choose a different username."
    }
}
