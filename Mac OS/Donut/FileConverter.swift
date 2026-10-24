import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum OutputFormat: CaseIterable, Hashable, Identifiable {
    case jpg
    case png
    case webp
    case heic
    case tiff
    case pdf

    var id: Self { self }

    var displayName: String {
        switch self {
        case .jpg: return "JPG"
        case .png: return "PNG"
        case .webp: return "WEBP"
        case .heic: return "HEIC"
        case .tiff: return "TIFF"
        case .pdf: return "PDF"
        }
    }

    var fileExtension: String {
        switch self {
        case .jpg: return "jpg"
        case .png: return "png"
        case .webp: return "webp"
        case .heic: return "heic"
        case .tiff: return "tiff"
        case .pdf: return "pdf"
        }
    }

    var contentType: UTType {
        switch self {
        case .jpg: return .jpeg
        case .png: return .png
        case .webp: return .webP
        case .heic: return .heic
        case .tiff: return .tiff
        case .pdf: return .pdf
        }
    }

    var symbolName: String {
        switch self {
        case .jpg: return "photo"
        case .png: return "photo.fill"
        case .webp: return "square.stack.3d.forward.dottedline"
        case .heic: return "camera"
        case .tiff: return "doc.richtext"
        case .pdf: return "doc.text"
        }
    }
}

enum FileConverterError: LocalizedError {
    case unsupportedInput
    case unableToReadSource
    case unableToCreateImage
    case encoderUnavailable(OutputFormat)
    case unableToCreateDestination
    case conversionFailed

    var errorDescription: String? {
        switch self {
        case .unsupportedInput:
            return "The selected file is not a supported image or document."
        case .unableToReadSource:
            return "The source file could not be read."
        case .unableToCreateImage:
            return "The source file does not contain a readable image."
        case .encoderUnavailable(let format):
            return "\(format.displayName) encoding is not available on this Mac."
        case .unableToCreateDestination:
            return "The destination file could not be created."
        case .conversionFailed:
            return "The conversion did not complete successfully."
        }
    }
}

struct FileConverter {
    func convert(sourceURL: URL, to format: OutputFormat) throws -> URL {
        guard sourceURL.isFileURL else {
            throw FileConverterError.unsupportedInput
        }

        let destinationURL = try makeDestinationURL(
            sourceURL: sourceURL,
            format: format
        )
        let sourceExtension = sourceURL.pathExtension.lowercased()

        if sourceExtension == format.fileExtension {
            do {
                try FileManager.default.copyItem(
                    at: sourceURL,
                    to: destinationURL
                )
                return destinationURL
            } catch {
                throw FileConverterError.unableToCreateDestination
            }
        }

        let image: CGImage
        let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil)

        if let source,
           let imageSource = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            image = imageSource
        } else if sourceURL.pathExtension.lowercased() == "pdf" {
            guard let document = CGPDFDocument(sourceURL as CFURL),
                  let page = document.page(at: 1),
                  let rendered = renderPDFPage(page) else {
                throw FileConverterError.unableToCreateImage
            }
            image = rendered
        } else {
            throw FileConverterError.unableToReadSource
        }

        if format == .pdf {
            try writePDF(image: image, to: destinationURL)
            return destinationURL
        }

        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            format.contentType.identifier as CFString,
            1,
            nil
        ) else {
            throw FileConverterError.encoderUnavailable(format)
        }

        var properties: [CFString: Any] = sourceProperties(
            from: source
        )
        if format == .jpg || format == .webp || format == .heic {
            properties[kCGImageDestinationLossyCompressionQuality] = 1.0
        }
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            try? FileManager.default.removeItem(at: destinationURL)
            throw FileConverterError.conversionFailed
        }

        return destinationURL
    }

    private func sourceProperties(
        from source: CGImageSource?
    ) -> [CFString: Any] {
        guard let source,
              let properties = CGImageSourceCopyPropertiesAtIndex(
                source,
                0,
                nil
              ) as? [CFString: Any] else {
            return [:]
        }

        var preserved = properties
        preserved.removeValue(forKey: kCGImagePropertyTIFFDictionary)
        preserved.removeValue(forKey: kCGImagePropertyPNGDictionary)
        preserved.removeValue(forKey: kCGImagePropertyJFIFDictionary)
        preserved.removeValue(forKey: kCGImagePropertyHEIFDictionary)
        preserved.removeValue(forKey: kCGImagePropertyOrientation)
        return preserved
    }

    private func renderPDFPage(_ page: CGPDFPage) -> CGImage? {
        let pageRect = page.getBoxRect(.cropBox)
        guard pageRect.width > 0, pageRect.height > 0 else {
            return nil
        }

        let scale = min(300.0 / 72.0, 12000.0 / max(
            pageRect.width,
            pageRect.height
        ))
        let width = max(1, Int((pageRect.width * scale).rounded()))
        let height = max(1, Int((pageRect.height * scale).rounded()))
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
              ) else {
            return nil
        }

        let drawRect = CGRect(x: 0, y: 0, width: width, height: height)
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(drawRect)
        context.concatenate(
            page.getDrawingTransform(
                .cropBox,
                rect: drawRect,
                rotate: 0,
                preserveAspectRatio: true
            )
        )
        context.drawPDFPage(page)
        return context.makeImage()
    }

    private func writePDF(image: CGImage, to url: URL) throws {
        var mediaBox = CGRect(
            x: 0,
            y: 0,
            width: image.width,
            height: image.height
        )

        guard let context = CGContext(
            url as CFURL,
            mediaBox: &mediaBox,
            nil
        ) else {
            throw FileConverterError.unableToCreateDestination
        }

        context.beginPDFPage([:])
        context.draw(
            image,
            in: mediaBox
        )
        context.endPDFPage()
        context.closePDF()

        guard FileManager.default.fileExists(atPath: url.path),
              let attributes = try? FileManager.default.attributesOfItem(
                atPath: url.path
              ),
              let fileSize = attributes[.size] as? NSNumber,
              fileSize.intValue > 0 else {
            try? FileManager.default.removeItem(at: url)
            throw FileConverterError.conversionFailed
        }
    }

    private func makeDestinationURL(
        sourceURL: URL,
        format: OutputFormat
    ) throws -> URL {
        let fileManager = FileManager.default
        let directory = sourceURL.deletingLastPathComponent()
        let originalBaseName = sourceURL.deletingPathExtension().lastPathComponent
        let sourceExtension = sourceURL.pathExtension.lowercased()
        let baseName = sourceExtension == format.fileExtension
            ? "\(originalBaseName)_converted"
            : originalBaseName

        var candidate = directory
            .appendingPathComponent(baseName)
            .appendingPathExtension(format.fileExtension)

        var suffix = 2
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = directory
                .appendingPathComponent("\(baseName)_\(suffix)")
                .appendingPathExtension(format.fileExtension)
            suffix += 1
        }

        return candidate
    }
}
