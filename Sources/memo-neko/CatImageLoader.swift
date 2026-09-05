import Cocoa

// MARK: - 猫アイコン読み込み（表情ベースのカスタム画像があればそれを使い、無ければ液面メーター型にフォールバック）

private struct CacheKey: Hashable {
    let breed: CatBreed
    let stage: CatStage
}

private var customImageCache: [CacheKey: NSImage] = [:]

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
private func fitToMenuBarSize(pngURL: URL, overscan: CGFloat, pointSize: Int = 22, pixelScale: Int = 2) -> NSImage? {
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
    // トリミング後の絵柄をアスペクト比を保ったまま正方形いっぱいに配置する。
    // overscanは呼び出し元が猫種ごとに指定する（余白の少ない新画像には1.0を渡し、
    // 余白が多い旧画像だけ拡大して大きく見せる）。
    let srcSize = CGSize(width: srcCG.width, height: srcCG.height)
    let fitScale = min(CGFloat(pixels) / srcSize.width, CGFloat(pixels) / srcSize.height) * overscan
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

// MARK: - カスタム画像（ユーザーがアップロードしたもの）の保存先
// アプリバンドル内には書き込めないので、Application Support配下に保存する。

func customImagesDirectory() throws -> URL {
    let base = try FileManager.default.url(
        for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    )
    let dir = base.appendingPathComponent("MemoriNeko/CustomCat", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

private func customImageURL(for stage: CatStage) -> URL? {
    try? customImagesDirectory().appendingPathComponent("\(stage.fileSuffix).png")
}

// 新しいカスタム画像を保存した後に呼び、古いキャッシュを捨てて再読み込みさせる。
func clearCustomImageCache() {
    customImageCache = customImageCache.filter { $0.key.breed != .custom }
}

func loadCatImage(breed: CatBreed, stage: CatStage, isDarkMenuBar: Bool) -> NSImage {
    let key = CacheKey(breed: breed, stage: stage)
    if let cached = customImageCache[key] {
        return cached
    }

    let url: URL?
    if breed == .custom {
        url = customImageURL(for: stage)
    } else {
        url = Bundle.module.url(forResource: "\(breed.fileNamePrefix)_\(stage.fileSuffix)", withExtension: "png")
    }

    if let url, FileManager.default.fileExists(atPath: url.path),
       let fitted = fitToMenuBarSize(pngURL: url, overscan: breed.overscan) {
        customImageCache[key] = fitted
        return fitted
    }
    return catImage(stage: stage, isDarkMenuBar: isDarkMenuBar)
}
