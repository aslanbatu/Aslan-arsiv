import UIKit

/// PDF oluşturmayı mümkün olduğunca yüksek çözünürlükte tutar.
/// Sayfa boyutu, görüntünün piksel boyutundan hesaplanır; gereksiz 595x842'e küçültme yapılmaz.
enum PDFBuilder {
    static func pdfData(images: [UIImage]) -> Data? {
        guard !images.isEmpty else { return nil }
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        return renderer.pdfData { context in
            for image in images {
                let size = pageSize(for: image)
                context.beginPage(withBounds: CGRect(origin: .zero, size: size))
                UIColor.white.setFill(); UIRectFill(CGRect(origin: .zero, size: size))
                drawHighQuality(image, in: CGRect(origin: .zero, size: size))
            }
        }
    }

    private static func pageSize(for image: UIImage) -> CGSize {
        // Yaklaşık 180 DPI: yüksek okunabilirlik + makul PDF boyutu.
        let pixels = image.cgImage.map { CGSize(width: $0.width, height: $0.height) } ?? CGSize(width: 1600, height: 2200)
        let scale: CGFloat = 72.0 / 180.0
        return CGSize(width: max(72, pixels.width * scale), height: max(72, pixels.height * scale))
    }

    private static func drawHighQuality(_ image: UIImage, in rect: CGRect) {
        let source = image.size
        let aspect = source.width / max(source.height, 1)
        let targetAspect = rect.width / max(rect.height, 1)
        var drawRect = rect
        if aspect > targetAspect {
            let h = rect.width / aspect
            drawRect.origin.y = (rect.height - h) / 2
            drawRect.size.height = h
        } else {
            let w = rect.height * aspect
            drawRect.origin.x = (rect.width - w) / 2
            drawRect.size.width = w
        }
        image.draw(in: drawRect, blendMode: .normal, alpha: 1)
    }
}
