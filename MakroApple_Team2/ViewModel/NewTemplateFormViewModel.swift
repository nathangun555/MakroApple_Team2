//
//  NewTemplateFormViewModel.swift
//  MakroApple_Team2
//
//  Created by Alfred Hans Witono on 22/10/25.
//

import SwiftUI
import Foundation
import Observation

@Observable
class NewTemplateViewModel {
    var userRecord: UserRecord?
    var errorMessage: String?
    var isLoading: Bool = false
    var didSave: Bool = false
    
    private(set) var userId: String?
    
    func configure(userId: String?) {
        self.userId = userId
    }
    
    func saveTemplate(templateString: String) async {
        guard let userId, let uuid = UUID(uuidString: userId) else {
            errorMessage = "User belum login atau UID tidak valid."
            return
        }
        
        isLoading = true
        errorMessage = nil
        didSave = false
        defer { isLoading = false }
        
        do {
            let updatedRecord = try await SupabaseManager.shared.upsertFormTemplate(
                id: uuid,
                formTemplate: templateString
            )
            self.userRecord = updatedRecord
            self.errorMessage = nil
            self.didSave = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
