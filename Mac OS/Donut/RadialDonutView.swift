import AppKit
import Combine
import SwiftUI
import UniformTypeIdentifiers

final class RadialHUDModel: ObservableObject {
    enum Status: Equatable {
        case idle
        case working(OutputFormat)
        case done(converted: Int, failed: Int, format: OutputFormat)
        case failed(String)
    }

    @Published var status: Status = .idle
    @Published var fileCount = 0
    var onDrop: ((OutputFormat, [URL]) -> Void)?
}

extension OutputFormat {
    var tint: Color {
        switch self {
        case .jpg: return .orange
        case .png: return .blue
        case .webp: return .green
        case .heic: return .pink
        case .tiff: return .purple
        case .pdf: return .red
        }
    }
}

struct DonutSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var innerRadius: CGFloat
    var outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        path.closeSubpath()
        return path
    }
}

struct RadialDonutView: View {
    static let panelSize: CGFloat = 360
    static let outerRadius: CGFloat = 158
    static let innerRadius: CGFloat = 68
    private static let gapDegrees: Double = 3

    @ObservedObject var model: RadialHUDModel
    @State private var hovered: OutputFormat?

    private let formats = OutputFormat.allCases
    private var sliceDegrees: Double {
        360 / Double(formats.count)
    }

    var body: some View {
        ZStack {
            ForEach(Array(formats.enumerated()), id: \.element) { index, format in
                slice(at: index, format: format)
            }

            Circle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                }
                .frame(
                    width: Self.innerRadius * 2 - 18,
                    height: Self.innerRadius * 2 - 18
                )
                .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
                .overlay {
                    hubContent
                        .padding(8)
                        .frame(
                            width: Self.innerRadius * 2 - 18,
                            height: Self.innerRadius * 2 - 18
                        )
                }
                .allowsHitTesting(false)
        }
        .frame(width: Self.panelSize, height: Self.panelSize)
    }

    private func slice(at index: Int, format: OutputFormat) -> some View {
        let centerDegrees = -90 + sliceDegrees * Double(index)
        let shape = DonutSlice(
            startAngle: .degrees(
                centerDegrees - sliceDegrees / 2 + Self.gapDegrees / 2
            ),
            endAngle: .degrees(
                centerDegrees + sliceDegrees / 2 - Self.gapDegrees / 2
            ),
            innerRadius: Self.innerRadius,
            outerRadius: Self.outerRadius
        )
        let isHovered = hovered == format
        let radians = centerDegrees * .pi / 180
        let midRadius = (Self.innerRadius + Self.outerRadius) / 2

        return ZStack {
            shape.fill(.ultraThinMaterial)
            shape.fill(format.tint.opacity(isHovered ? 0.55 : 0.10))
            shape.stroke(
                Color.white.opacity(isHovered ? 0.6 : 0.2),
                lineWidth: 1
            )

            VStack(spacing: 3) {
                Image(systemName: format.symbolName)
                    .font(.system(size: 17, weight: .semibold))
                Text(format.displayName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(isHovered ? Color.white : Color.primary)
            .scaleEffect(isHovered ? 1.12 : 1)
            .offset(
                x: CGFloat(cos(radians)) * midRadius,
                y: CGFloat(sin(radians)) * midRadius
            )
            .allowsHitTesting(false)
        }
        .contentShape(shape)
        .shadow(
            color: .black.opacity(isHovered ? 0.3 : 0.16),
            radius: isHovered ? 10 : 5,
            y: 3
        )
        .scaleEffect(isHovered ? 1.05 : 1)
        .zIndex(isHovered ? 1 : 0)
        .animation(
            .spring(response: 0.2, dampingFraction: 0.76),
            value: isHovered
        )
        .onDrop(
            of: [UTType.fileURL],
            isTargeted: targetBinding(for: format)
        ) { providers in
            handleDrop(providers, format: format)
        }
    }

    @ViewBuilder
    private var hubContent: some View {
        switch model.status {
        case .idle:
            if let hovered {
                VStack(spacing: 2) {
                    Text("Convert to")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(hovered.displayName)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(hovered.tint)
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(model.fileCount > 1
                         ? "\(model.fileCount) files"
                         : "Drop on a format")
                        .font(.system(size: 10, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }
        case .working:
            VStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Converting…")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        case .done(let converted, let failed, let format):
            VStack(spacing: 4) {
                Image(
                    systemName: failed == 0
                        ? "checkmark.circle.fill"
                        : "exclamationmark.circle.fill"
                )
                .font(.system(size: 26))
                .foregroundStyle(failed == 0 ? .green : .orange)
                Text(failed == 0
                     ? (converted == 1
                        ? "Saved \(format.displayName)"
                        : "\(converted) → \(format.displayName)")
                     : "\(converted) saved · \(failed) failed")
                    .font(.system(size: 10, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        case .failed(let message):
            VStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.system(size: 9, weight: .medium))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func targetBinding(for format: OutputFormat) -> Binding<Bool> {
        Binding(
            get: { hovered == format },
            set: { isTargeted in
                if isTargeted {
                    hovered = format
                } else if hovered == format {
                    hovered = nil
                }
            }
        )
    }

    private func handleDrop(
        _ providers: [NSItemProvider],
        format: OutputFormat
    ) -> Bool {
        guard case .idle = model.status else { return false }

        let fileProviders = providers.filter {
            $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }
        guard !fileProviders.isEmpty else { return false }

        model.status = .working(format)
        let group = DispatchGroup()
        let lock = NSLock()
        var urls: [URL] = []

        for provider in fileProviders {
            group.enter()
            provider.loadItem(
                forTypeIdentifier: UTType.fileURL.identifier,
                options: nil
            ) { item, _ in
                defer { group.leave() }
                let resolvedURL: URL?
                if let item = item as? URL {
                    resolvedURL = item
                } else if let item = item as? NSURL {
                    resolvedURL = item as URL
                } else if let data = item as? Data {
                    resolvedURL = URL(dataRepresentation: data, relativeTo: nil)
                } else {
                    resolvedURL = nil
                }

                guard let resolvedURL, resolvedURL.isFileURL else { return }
                lock.lock()
                urls.append(resolvedURL)
                lock.unlock()
            }
        }

        group.notify(queue: .main) {
            model.fileCount = urls.count
            model.onDrop?(format, urls)
        }
        return true
    }
}
