//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Edward Suwandi on 30/10/25.
//


import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    private var hostingController: UIHostingController<ShareContentView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwiftUIView()
        handleIncomingData()
    }
    
    private func setupSwiftUIView() {
        let swiftUIView = ShareContentView()
        let host = UIHostingController(rootView: swiftUIView)
        
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        host.didMove(toParent: self)
        self.hostingController = host
    }
    
    
    private func handleIncomingData() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else { return }
        
        var allImageData: [Data] = []
        var sharedText: String? = nil
        let groupDefaults = UserDefaults(suiteName: "group.com.please.shared")
        
        groupDefaults?.removeObject(forKey: "sharedText")
           groupDefaults?.removeObject(forKey: "sharedImagesData")
           groupDefaults?.synchronize()
        
        let dispatchGroup = DispatchGroup()
        
        
        for provider in extensionItem.attachments ?? [] {
            
            // Handle Text
            if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                dispatchGroup.enter()
                provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (item: NSSecureCoding?, error: Error?) in
                    if let text = item as? String {
                        sharedText = text
                        print("📩 Received text: \(text)")
                    }
                    dispatchGroup.leave()
                }
            }
            
            else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier), allImageData.count < 3{
                dispatchGroup.enter()
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { (item: NSSecureCoding?, error: Error?) in
                    if let url = item as? URL, let data = try? Data(contentsOf : url) {
                        allImageData.append(data)
                        print("RECEIVED IMAGE URL : \(url)")
                    }
                    else if let image = item as? UIImage, let data = image.pngData() {
                        allImageData.append(data)
                        print("RECEIVED IMAGE DIRECTLY")
                    }
                    else {
                        print("UNSUPPORTED IMAGE TYPE")
                    }
                    
                    dispatchGroup.leave()
                }
                
            }
            
        }
        
        // After all items are loaded
        dispatchGroup.notify(queue: .main) {
            if let text = sharedText {
                groupDefaults?.set(text, forKey: "sharedText")
                print("✅ Saved text to App Group: \(text)")
            }
            
            if !allImageData.isEmpty {
                groupDefaults?.set(allImageData, forKey: "sharedImagesData")
                print("✅ Saved \(allImageData.count) images to App Group")
            }
            
            groupDefaults?.synchronize()
            self.openMainApp()
        }
        
        
    }
    
    private func openMainApp() {
        guard let url = URL(string: "makroa2://fromwhatsapp") else {
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url)
                print("🚀 MAIN APP OPENED SUCCESSFULLY")
                break
            }
            responder = responder?.next
        }
    }
}
    
    
    
    



