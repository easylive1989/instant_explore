import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {

    private let appGroupId = "group.com.paulchwu.instantexplore"
    private let sharedKey = "ShareKey"

    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
        guard let extensionItem = extensionContext?.inputItems.first
                as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            completeRequest()
            return
        }

        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(
                UTType.url.identifier
            ) {
                provider.loadItem(
                    forTypeIdentifier: UTType.url.identifier,
                    options: nil
                ) { [weak self] data, _ in
                    if let url = data as? URL {
                        self?.save(url.absoluteString)
                    }
                    self?.completeRequest()
                }
                return
            }

            if provider.hasItemConformingToTypeIdentifier(
                UTType.plainText.identifier
            ) {
                provider.loadItem(
                    forTypeIdentifier: UTType.plainText.identifier,
                    options: nil
                ) { [weak self] data, _ in
                    if let text = data as? String {
                        self?.save(text)
                    }
                    self?.completeRequest()
                }
                return
            }
        }

        completeRequest()
    }

    override func configurationItems()
        -> [Any]! {
        return []
    }

    /// 將分享的文字存到 App Group UserDefaults，
    /// 主 App 透過 receive_sharing_intent 讀取。
    private func save(_ text: String) {
        let userDefaults = UserDefaults(
            suiteName: appGroupId
        )
        userDefaults?.set(text, forKey: sharedKey)
        userDefaults?.synchronize()
    }

    private func completeRequest() {
        extensionContext?.completeRequest(
            returningItems: [],
            completionHandler: nil
        )
    }
}
