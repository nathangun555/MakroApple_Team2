//
//  MakroApple_Team2App.swift
//  MakroApple_Team2
//
//  Created by Nathan Gunawan on 06/10/25.
//

import SwiftUI
import Combine

@main
struct MakroApple_Team2App: App {
    @StateObject var session = SessionManager()
    @StateObject var deleteBus = DeleteOverlayBus()
    @State private var selectedTab: Int = 0
    @State private var sharedText: String = ""
    @State private var sharedImages: [UIImage] = []
    @State private var hasNewObject = false
    @StateObject var unsavedBus = UnsavedOverlayBus()
    
    @State private var isDismissed: Bool = false

    let notifDelegate = NotificationDelegate()
        
    init() {
        UNUserNotificationCenter.current().delegate = notifDelegate
        NotificationManager.shared.requestPermission()
    }
    
    @State private var path : NavigationPath = .init()
    var body: some Scene {
        WindowGroup {
            //            InvoicePreviewView(orderId: "97b3757c-a90b-4868-8b97-0fbe9be71955", isDismissed: $isDismissed)
            //                .environmentObject(session)
            //            InvoiceContentView(viewModel: InvoicePreviewViewModel())
            //            HeaderSectionView(
            //                businessLogoUrl: "https://ynxrqdbpovgmhhoobfjt.supabase.co/storage/v1/object/public/MakroAppleTeam2_Bucket/business-logos/3A0A83FE-2480-42F5-82AE-D2A419AAFF89.jpg",
            //                businessName: "Toko Subur",
            //                businessAddress: "Ngagel Jaya",
            //                businessPhone: "62812345678",
            //                businessEmail: "bejo@gmail.com",
            //                invoiceNumber: "1234"
            //            )
            
            MainTabView(selectedTab: $selectedTab, sharedText: $sharedText,hasNewObject: $hasNewObject, sharedImages : $sharedImages)
                .environmentObject(session)
                .environmentObject(deleteBus)
                .environmentObject(unsavedBus)
                .onOpenURL { url in
                    if url.host == "fromwhatsapp" {
                        if let defaults = UserDefaults(suiteName: "group.com.please.shared") {
                            
                            // Ambil shared text
                            if let text = defaults.string(forKey: "sharedText") {
                                sharedText = text
                                hasNewObject = true
                                print("📩 SHARED TEXT: \(text)")
                                // 🧹 Hapus setelah digunakan
                                defaults.removeObject(forKey: "sharedText")
                            }
                            
                            // Ambil shared images
                            if let imageDataArray = defaults.array(forKey: "sharedImagesData") as? [Data] {
                                sharedImages = imageDataArray.compactMap { UIImage(data: $0) }
                                hasNewObject = true
                                print("🖼️ LOADED \(sharedImages.count) SHARED IMAGES")
                                // 🧹 Hapus setelah digunakan
                                defaults.removeObject(forKey: "sharedImagesData")
                            }
                            
                            defaults.synchronize()
                        }
                    }
                }
            
                .onOpenURL { url in
                    if url.host == "fromwhatsapp" {
                        if let defaults = UserDefaults(suiteName: "group.com.please.shared2") {
                            
                            if let text = defaults.string(forKey: "sharedText") {
                                sharedText = text
                                hasNewObject = true
                                print("SHARED TEXT : \(text)")
                            }
                            
                            if let image = defaults.array(forKey: "sharedImagesData") as? [Data] {
                                sharedImages = image.compactMap { UIImage(data: $0) }
                                hasNewObject = true
                                print("LOADED \(sharedImages.count) shared images")
                            }
                            defaults.synchronize()
                        }
                    }
                }
                .onAppear {
                    NotificationManager.shared.scheduleDailyNotifications() // ⬅️ keep existing schedule
                }
            
            
        }
        
    }
}
