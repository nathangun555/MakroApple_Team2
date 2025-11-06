//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Edward Suwandi on 30/10/25.
//

//
//  ShareViewController.swift
//  ShareExtension
//

//
//  ShareViewController.swift
//  ShareToMyAppExtension
//
//  Created by Edward Suwandi on 05/11/25.
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

//    private func handleIncomingData() {
//        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else { return }
//
//        for provider in extensionItem.attachments ?? [] {
//            if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
//                provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, error in
//                    if let text = item as? String {
//                        print("📩 Received text from WhatsApp: \(text)")
//
//                        // ✅ Save to shared UserDefaults (App Group)
//                        if let defaults = UserDefaults(suiteName: "group.com.edward.makroa2.shared") {
//                            defaults.set(text, forKey: "sharedText")
//                            defaults.synchronize()
//                        } else {
//                            print("❌ Failed to access shared defaults")
//                        }
//
//                        // ✅ Tell the system we're done
//                        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
//
//                        // ✅ Ask the system to open the main app (via URL scheme)
//                        self.openMainApp()
//                    }
//                }
//                return
//            }
//        }
//    }
    
    private func handleIncomingData() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else { return }

        for provider in extensionItem.attachments ?? [] {
            if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, error in
                    if let text = item as? String {
                        print("📩 Received text: \(text)")

                        // Save to App Group
                        if let defaults = UserDefaults(suiteName: "group.com.please.shared") {
                            print("USER DEFAULT SET \(text)")
                            defaults.set(text, forKey: "sharedText")
                            defaults.synchronize()
                        }

                        // Open the main app first
                        if let url = URL(string: "makroa2://fromwhatsapp") {
                            var responder: UIResponder? = self
                            
                            while responder != nil {
                                if let application = responder as? UIApplication {
                                    application.open(url)
                                    print("MAIN APP OPENED")
                                    break
                                } else {
                                    print("❌ Failed to open main app")
                                }
                                responder = responder?.next
                            }
                        } else {
                            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                        }
                    }
                }
                return
            }
        }
    }


    
    private func openMainApp() {
        guard let url = URL(string: "makroa2://fromwhatsapp") else { return }

        // ✅ This is the official API for opening your main app from a Share Extension
        extensionContext?.open(url, completionHandler: { success in
            if success {
                print("✅ Successfully opened main app.")
            } else {
                print("❌ Failed to open main app.")
            }
        })
    }


}


