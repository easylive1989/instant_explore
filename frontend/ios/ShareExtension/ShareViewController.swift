import UIKit
import Social
import UniformTypeIdentifiers

/// Share Extension entry point.
///
/// Auto-processes the incoming URL / text in `viewDidAppear` — there
/// is no compose UI, because our flow is "save the shared location";
/// the user doesn't need to write anything.
///
/// Writes the payload into App Group UserDefaults in the exact format
/// that the `receive_sharing_intent` Flutter plugin expects:
/// - key: `"ShareKey"`
/// - value: `Data` (UTF-8 JSON) of `[SharedMediaFile]`
///
/// Then opens the host app with the
/// `ShareMedia-{hostAppBundleIdentifier}://share` URL, which the
/// plugin listens for to flush the pending media into
/// `getMediaStream()`.
///
/// Implemented without `import receive_sharing_intent` because that
/// module transitively requires `Flutter.framework`, which App
/// Extensions cannot link against.
class ShareViewController: SLComposeServiceViewController {
    private static let userDefaultsKey = "ShareKey"
    private static let schemePrefix = "ShareMedia"
    private static let appGroupIdInfoKey = "AppGroupId"

    private var sharedMedia: [SharedMediaFile] = []
    private var hostAppBundleIdentifier = ""
    private var appGroupId = ""

    override func isContentValid() -> Bool { return true }

    override func configurationItems() -> [Any]! { return [] }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadIds()
        // Hide the default compose chrome so the user sees nothing
        // between tapping "Contexture" and the host app opening.
        view.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let content = extensionContext?.inputItems.first
                as? NSExtensionItem,
              let attachments = content.attachments, !attachments.isEmpty
        else {
            completeRequest()
            return
        }

        let group = DispatchGroup()
        for (index, provider) in attachments.enumerated() {
            if provider.hasItemConformingToTypeIdentifier(
                UTType.url.identifier
            ) {
                group.enter()
                provider.loadItem(
                    forTypeIdentifier: UTType.url.identifier,
                    options: nil
                ) { [weak self] data, _ in
                    if let url = data as? URL {
                        self?.appendLiteral(url.absoluteString,
                                            type: .url,
                                            index: index)
                    }
                    group.leave()
                }
            } else if provider.hasItemConformingToTypeIdentifier(
                UTType.plainText.identifier
            ) {
                group.enter()
                provider.loadItem(
                    forTypeIdentifier: UTType.plainText.identifier,
                    options: nil
                ) { [weak self] data, _ in
                    if let text = data as? String {
                        self?.appendLiteral(text,
                                            type: .text,
                                            index: index)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.saveAndRedirect()
        }
    }

    override func didSelectPost() {
        // Not expected to reach here since viewDidAppear auto-submits,
        // but provide a sensible fallback.
        saveAndRedirect()
    }

    // MARK: - Private

    private func appendLiteral(
        _ value: String, type: SharedMediaType, index: Int
    ) {
        sharedMedia.append(
            SharedMediaFile(
                path: value,
                mimeType: type == .text ? "text/plain" : nil,
                type: type
            )
        )
    }

    private func saveAndRedirect() {
        guard !sharedMedia.isEmpty else {
            completeRequest()
            return
        }

        if let defaults = UserDefaults(suiteName: appGroupId),
           let data = try? JSONEncoder().encode(sharedMedia) {
            defaults.set(data, forKey: Self.userDefaultsKey)
            defaults.synchronize()
        }

        let urlString =
            "\(Self.schemePrefix)-\(hostAppBundleIdentifier)://share"
        if let url = URL(string: urlString) {
            openURL(url)
        }
        completeRequest()
    }

    /// Walks the responder chain looking for a UIApplication that can
    /// open a URL. Needed because App Extensions cannot access
    /// `UIApplication.shared`.
    private func openURL(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = responder?.next
        }
        // Fallback for older iOS versions.
        let selector = sel_registerName("openURL:")
        responder = self
        while responder != nil {
            if responder?.responds(to: selector) == true {
                _ = responder?.perform(selector, with: url)
                return
            }
            responder = responder?.next
        }
    }

    private func completeRequest() {
        extensionContext?.completeRequest(
            returningItems: [], completionHandler: nil
        )
    }

    /// Derives the host-app bundle id and app-group id from the
    /// extension's bundle id and Info.plist.
    private func loadIds() {
        let extensionBundleId = Bundle.main.bundleIdentifier ?? ""
        if let dotIndex = extensionBundleId.lastIndex(of: ".") {
            hostAppBundleIdentifier =
                String(extensionBundleId[..<dotIndex])
        } else {
            hostAppBundleIdentifier = extensionBundleId
        }
        let custom = Bundle.main.object(
            forInfoDictionaryKey: Self.appGroupIdInfoKey
        ) as? String
        appGroupId = custom ?? "group.\(hostAppBundleIdentifier)"
    }
}

/// Must stay wire-compatible with the `SharedMediaFile` struct that
/// `receive_sharing_intent` deserialises on the Flutter side.
private class SharedMediaFile: Codable {
    let path: String
    let mimeType: String?
    let thumbnail: String?
    let duration: Double?
    let message: String?
    let type: SharedMediaType

    init(
        path: String,
        mimeType: String? = nil,
        thumbnail: String? = nil,
        duration: Double? = nil,
        message: String? = nil,
        type: SharedMediaType
    ) {
        self.path = path
        self.mimeType = mimeType
        self.thumbnail = thumbnail
        self.duration = duration
        self.message = message
        self.type = type
    }
}

private enum SharedMediaType: String, Codable {
    case image
    case video
    case text
    case file
    case url
}
