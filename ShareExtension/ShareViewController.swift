//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Edward Suwandi on 30/10/25.
//

import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
        // Save shared data
        if let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem {
            for attachment in extensionItem.attachments ?? [] {
                if attachment.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, error in
                        if let text = item as? String {
                            self.saveToApp(text: text)
                            self.openMainApp()
                        }
                    }
                } else if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
                        if let url = item as? URL {
                            self.saveToApp(imageURL: url)
                            self.openMainApp()
                        } else if let image = item as? UIImage {
                            if let data = image.pngData() {
                                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("shared.png")
                                try? data.write(to: tempURL)
                                self.saveToApp(imageURL: tempURL)
                                self.openMainApp()
                            }
                        }
                    }
                }
            }
        }

        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func saveToApp(text: String? = nil, imageURL: URL? = nil) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.macroa2.identifier")
        sharedDefaults?.set(text, forKey: "sharedText")
        sharedDefaults?.set(imageURL?.absoluteString, forKey: "sharedImage")
        sharedDefaults?.synchronize()
    }

    private func openMainApp() {
        // Open your main app via custom URL scheme
        if let url = URL(string: "macroa2://share") {
            var responder: UIResponder? = self
            while responder != nil {
                if let app = responder as? UIApplication {
                    app.open(url, options: [:], completionHandler: nil)
                    break
                }
                responder = responder?.next
            }
        }
    }
}
