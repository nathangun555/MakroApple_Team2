//
//  CustomUnsavedAlertComponent.swift
//  MakroApple_Team2
//

import SwiftUI

struct CustomUnsavedAlertComponent: View {
    var title: String
    var message: String
    var cancelTitle: String
    var confirmTitle: String
    var onCancel: () -> Void
    var onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            // ✅ Full screen backdrop - blocks everything
            Color.black.opacity(0.45)
                .frame(maxWidth: .infinity, maxHeight: .infinity)  // Cover entire screen
                .ignoresSafeArea()  // Cover safe areas too
                .contentShape(Rectangle())  // Make entire area tappable
                .onTapGesture { onCancel() }
            
            // Alert card
            VStack(spacing: 20) {
                Image(systemName: "gear.badge.xmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color.primaryButton)
                    .padding(.top, 8)
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primaryButton)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                
                HStack(spacing: 16) {
                    Button(action: onCancel) {
                        Text(cancelTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray3))
                            .clipShape(Capsule())
                    }
                    
                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(uiColor: .systemBackground))  // Adaptive to light/dark mode
            )
            .padding(.horizontal, 40)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)  // ✅ CRITICAL: Full screen coverage
    }
}

//
//  CustomDeleteAlertComponent.swift
//  MakroApple_Team2
//

//
//struct CustomDeleteAlertComponent: View {
//    let title: String
//    let message: String
//    let cancelTitle: String
//    let confirmTitle: String
//    let onCancel: () -> Void
//    let onConfirm: () -> Void
//
//    var body: some View {
//        ZStack {
//            // ✅ Full screen backdrop
//            Color.black.opacity(0.45)
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .ignoresSafeArea()
//                .contentShape(Rectangle())
//                .onTapGesture { onCancel() }
//
//            // Alert card
//            VStack(spacing: 20) {
//                Image(systemName: "trash.fill")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 50, height: 50)
//                    .foregroundColor(.primaryButton)
//                    .padding(.top, 8)
//
//                Text(title)
//                    .font(.system(size: 20, weight: .semibold))
//                    .foregroundColor(.primaryButton)
//                    .multilineTextAlignment(.center)
//
//                Text(message)
//                    .font(.system(size: 15))
//                    .foregroundColor(.black)
//                    .multilineTextAlignment(.center)
//                    .padding(.horizontal)
//                    .padding(.bottom, 6)
//
//                HStack(spacing: 16) {
//                    Button(action: onCancel) {
//                        Text(cancelTitle)
//                            .fontWeight(.semibold)
//                            .foregroundColor(.white.opacity(0.9))
//                            .frame(maxWidth: .infinity)
//                            .padding(.vertical, 12)
//                            .background(Color(.systemGray3))
//                            .clipShape(Capsule())
//                    }
//
//                    Button(action: onConfirm) {
//                        Text(confirmTitle)
//                            .fontWeight(.semibold)
//                            .foregroundColor(.white)
//                            .frame(maxWidth: .infinity)
//                            .padding(.vertical, 12)
//                            .background(Color.primaryButton)
//                            .clipShape(Capsule())
//                    }
//                }
//                .padding(.horizontal, 8)
//            }
//            .padding(.vertical, 24)
//            .padding(.horizontal, 20)
//            .background(
//                RoundedRectangle(cornerRadius: 20)
//                    .fill(Color(uiColor: .systemBackground))
//            )
//            .padding(.horizontal, 40)
//            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//}

struct CustomDeleteAlertComponent: View {
    let title: String
    let message: String
    let cancelTitle: String
    let confirmTitle: String
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            // ✅ Full screen backdrop - extend to all edges including safe area
            Color.black.opacity(0.45)
                .ignoresSafeArea(.all)  // ← UBAH: Dari .ignoresSafeArea() jadi .ignoresSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { onCancel() }
            
            // Alert card
            VStack(spacing: 20) {
                Image(systemName: "trash.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.primaryButton)
                    .padding(.top, 8)
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primaryButton)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                
                HStack(spacing: 16) {
                    Button(action: onCancel) {
                        Text(cancelTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray3))
                            .clipShape(Capsule())
                    }
                    
                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.primaryButton)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(uiColor: .systemBackground))
            )
            .padding(.horizontal, 40)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        }
    }
}


// MARK: - Custom Alert (unsaved)
struct CustomUnsavedAlert: View {
    var title: String
    var message: String
    var cancelTitle: String
    var confirmTitle: String
    var onCancel: () -> Void
    var onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }
            
            VStack(spacing: 20) {
                Image(systemName: "gear.badge.xmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color.primaryButton)
                    .padding(.top, 8)
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                
                HStack(spacing: 16) {
                    Button(action: onCancel) {
                        Text(cancelTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray3))
                            .clipShape(Capsule())
                    }
                    
                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.primaryButton)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 40)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        }
        .transition(.opacity .combined(with: .scale))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: UUID())
    }
}
