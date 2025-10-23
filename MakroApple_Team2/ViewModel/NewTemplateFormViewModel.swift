//
//  NewTemplateFormViewModel.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 22/10/25.
//

import SwiftUI
import Foundation
import Combine
import Observation

@Observable
class NewTemplateViewModel {
    var userRecord: UserRecord?
    var errorMessage: String?
    var isLoading: Bool = false
    var didSave: Bool = false
    
    func saveTemplate(userId: UUID, templateString: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let updatedRecord = try await SupabaseManager.shared.upsertFormTemplate(id: userId, formTemplate: templateString)
            DispatchQueue.main.async {
                self.userRecord = updatedRecord
                self.errorMessage = nil
                self.didSave = true
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
