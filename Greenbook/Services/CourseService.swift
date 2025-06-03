//
//  CourseService.swift
//  Greenbook
//
//  Created by Charlie Daniel on 5/22/25.
//

import Foundation
import FirebaseFirestore

class CourseService: ObservableObject {
    private let db = Firestore.firestore()
    private let collectionName = "courses"
    
    // Published properties for SwiftUI to observe
    @Published var courses: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Fetch all courses
    func fetchAllCourses() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        print("🔍 Starting to fetch courses from collection: \(collectionName)")
        
        do {
            let snapshot = try await db.collection(collectionName).getDocuments()
            print("📊 Found \(snapshot.documents.count) documents in Firebase")
            
            let fetchedCourses = snapshot.documents.compactMap { document -> Course? in
                //print("📄 Document ID: \(document.documentID)")
                //print("📄 Document data: \(document.data())")
                
                do {
                    let course = try document.data(as: Course.self)
                    //print("✅ Successfully decoded course: \(course.name)")
                    return course
                } catch {
                    print("❌ Failed to decode document \(document.documentID): \(error)")
                    return nil
                }
            }
            
            print("🎯 Successfully decoded \(fetchedCourses.count) courses")
            
            await MainActor.run {
                self.courses = fetchedCourses
                self.isLoading = false
            }
        } catch {
            print("💥 Fetch error: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to fetch courses: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Search courses by name or city
    func searchCourses(query: String) async {
        guard !query.isEmpty else {
            await fetchAllCourses()
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Note: Firestore has limited text search. This searches for courses where name starts with the query
            let snapshot = try await db.collection(collectionName)
                .whereField("name", isGreaterThanOrEqualTo: query)
                .whereField("name", isLessThan: query + "\u{f8ff}")
                .getDocuments()
            
            let searchResults = snapshot.documents.compactMap { document -> Course? in
                try? document.data(as: Course.self)
            }
            
            await MainActor.run {
                self.courses = searchResults
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Search failed: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Filter courses by country
    func fetchCoursesByCountry(_ country: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let snapshot = try await db.collection(collectionName)
                .whereField("country", isEqualTo: country)
                .getDocuments()
            
            let filteredCourses = snapshot.documents.compactMap { document -> Course? in
                try? document.data(as: Course.self)
            }
            
            await MainActor.run {
                self.courses = filteredCourses
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to filter courses: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Get a specific course by ID
    func getCourse(id: String) async -> Course? {
        do {
            let document = try await db.collection(collectionName).document(id).getDocument()
            return try document.data(as: Course.self)
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch course: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    // MARK: - Add a new course (for future user-added courses)
    func addCourse(_ course: Course) async -> Bool {
        do {
            var newCourse = course
            newCourse.isOriginalData = false // Mark as user-added
            
            try db.collection(collectionName).addDocument(from: newCourse)
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to add course: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Clear error message
    func clearError() {
        errorMessage = nil
    }
}
