//
//  SessionManager.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 20/10/25.
//

// SessionManager.swift
import Foundation
import SwiftUI
import Combine

final class SessionManager: ObservableObject {
    @Published var userId: String?
    @Published var isSignedIn = false
}
