import Cocoa

// MARK: - 猫アイコン読み込み（表情ベースのカスタム画像があればそれを使い、無ければ液面メーター型にフォールバック）

private let customImageFileNames: [CatStage: String] = [
    .slim: "cat_slim",
    .normal: "cat_normal",
    .chubby: "cat_chubby",
    .plump: "cat_plump",
    .stuffed: "cat_stuffed",
]

private var customImageCache: [CatStage: NSImage] = [:]

// 画像内の実際の絵柄（アルファが乗っている範囲）だけを検出する。
// 元画像に余白があると、メニューバーでは実際より小さく見えてしまうため。
private func alphaBoundingBox(of cg: CGImage) -> CGRect {
    let w = cg.width, h = cg.height
    guard let ctx = CGContext(
        data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return CGRect(x: 0, y: 0, width: w, height: h) }
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
    guard let ptr = ctx.data?.bindMemory(to: UInt8.self, capacity: w * h * 4) else {
        return CGRect(x: 0, y: 0, width: w, height: h)
    }
    // このバッファは行0が画像の下端（CGコンテキストは左下原点）
    var minX = w, maxX = -1, minYBottomUp = h, maxYBottomUp = -1
    for row in 0..<h {
        for col in 0..<w {
            if ptr[(row * w + col) * 4 + 3] > 10 {
                if col < minX { minX = col }
                if col > maxX { maxX = col }
                if row < minYBottomUp { minYBottomUp = row }
                if row > maxYBottomUp { maxYBottomUp = row }
            }
        }
    }
    guard maxX >= minX, maxYBottomUp >= minYBottomUp else { return CGRect(x: 0, y: 0, width: w, height: h) }
    // CGImage.cropping(to:) は左上原点なのでYを変換する
    let topLeftY = h - 1 - maxYBottomUp
    return CGRect(x: minX, y: topLeftY, width: maxX - minX + 1, height: maxYBottomUp - minYBottomUp + 1)
}

// PNGの余白をトリミングし、メニューバー用のポイントサイズ角（2xビットマップ）に確実に焼き直す。
// NSImage.size の上書きだけだと表示側で元のピクセルサイズが優先されはみ出すことがあるため、
// ここで明示的にビットマップとして再描画してからサイズを付与する。
private func fitToMenuBarSize(pngURL: URL, pointSize: Int = 22, pixelScale: Int = 2) -> NSImage? {
    guard let data = try? Data(contentsOf: pngURL),
          let srcRep = NSBitmapImageRep(data: data),
          var srcCG = srcRep.cgImage else { return nil }

    let bbox = alphaBoundingBox(of: srcCG)
    if let cropped = srcCG.cropping(to: bbox) {
        srcCG = cropped
    }

    let pixels = pointSize * pixelScale
    guard let ctx = CGContext(
        data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    ctx.interpolationQuality = .high
    // トリミング後の絵柄をアスペクト比を保ったまま正方形いっぱいに配置する
    let srcSize = CGSize(width: srcCG.width, height: srcCG.height)
    let fitScale = min(CGFloat(pixels) / srcSize.width, CGFloat(pixels) / srcSize.height)
    let drawWidth = srcSize.width * fitScale
    let drawHeight = srcSize.height * fitScale
    let drawRect = CGRect(
        x: (CGFloat(pixels) - drawWidth) / 2,
        y: (CGFloat(pixels) - drawHeight) / 2,
        width: drawWidth,
        height: drawHeight
    )
    ctx.draw(srcCG, in: drawRect)

    guard let outCG = ctx.makeImage() else { return nil }
    let image = NSImage(cgImage: outCG, size: NSSize(width: pointSize, height: pointSize))
    image.isTemplate = false
    return image
}

func loadCatImage(stage: CatStage, isDarkMenuBar: Bool) -> NSImage {
    if let cached = customImageCache[stage] {
        return cached
    }
    if let name = customImageFileNames[stage],
       let url = Bundle.module.url(forResource: name, withExtension: "png"),
       let fitted = fitToMenuBarSize(pngURL: url) {
        customImageCache[stage] = fitted
        return fitted
    }
    return catImage(stage: stage, isDarkMenuBar: isDarkMenuBar)
}
