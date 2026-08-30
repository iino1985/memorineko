import Cocoa

// MARK: - 猫アイコン描画（液面メーター型）
// 輪郭（耳・顔・ひげ）は固定。顔の内側をメモリ使用率の高さまで塗りつぶし、
// 目の記号（●/﹀/×）で二重に段階を示す。危険域のみ色をつけ、それ以外はtemplate画像。

private func punchEye(ctx: CGContext, center: CGPoint, radius: CGFloat, style: EyeStyle, lineWidth: CGFloat) {
    ctx.setLineWidth(lineWidth)
    ctx.setLineCap(.round)
    switch style {
    case .dot:
        ctx.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        ctx.fillPath()
    case .squint:
        ctx.beginPath()
        ctx.move(to: CGPoint(x: center.x - radius, y: center.y + radius * 0.2))
        ctx.addQuadCurve(to: CGPoint(x: center.x + radius, y: center.y + radius * 0.2), control: CGPoint(x: center.x, y: center.y - radius * 0.9))
        ctx.strokePath()
    case .cross:
        ctx.beginPath()
        ctx.move(to: CGPoint(x: center.x - radius, y: center.y - radius))
        ctx.addLine(to: CGPoint(x: center.x + radius, y: center.y + radius))
        ctx.strokePath()
        ctx.beginPath()
        ctx.move(to: CGPoint(x: center.x - radius, y: center.y + radius))
        ctx.addLine(to: CGPoint(x: center.x + radius, y: center.y - radius))
        ctx.strokePath()
    }
}

func catImage(stage: CatStage, isDarkMenuBar: Bool, gridSize: Int = 18, superSample: Int = 8) -> NSImage {
    let hiRes = gridSize * superSample
    let hiSize = CGFloat(hiRes)

    guard let ctx = CGContext(
        data: nil, width: hiRes, height: hiRes, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return NSImage(size: NSSize(width: gridSize, height: gridSize)) }

    ctx.setShouldAntialias(true)
    ctx.setAllowsAntialiasing(true)

    let useTemplate = !stage.isDangerColor
    // templateはシステムが自動反転するので常に黒で描く。色つき段階はライト/ダーク両対応の輪郭色を自前で選ぶ。
    let outlineColor: CGColor = useTemplate ? NSColor.black.cgColor : (isDarkMenuBar ? NSColor.white.cgColor : NSColor.black.cgColor)
    let fillColor: CGColor = useTemplate ? NSColor.black.cgColor : stage.dangerColor.cgColor

    let center = CGPoint(x: hiSize / 2, y: hiSize * 0.46)
    let radius = hiSize * 0.30
    let headRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    let headPath = CGPath(ellipseIn: headRect, transform: nil)

    let lineWidth = hiSize * 0.05
    ctx.setLineWidth(lineWidth)
    ctx.setStrokeColor(outlineColor)
    ctx.setFillColor(outlineColor)

    // 耳（輪郭のみ、固定形状）
    let earBaseHalf = hiSize * 0.13
    let earHeight = hiSize * 0.20
    let earSpread = radius * 0.62
    let earBaseY = center.y + radius * 0.62

    for side: CGFloat in [-1, 1] {
        ctx.beginPath()
        ctx.move(to: CGPoint(x: center.x + side * (earSpread - earBaseHalf), y: earBaseY))
        ctx.addLine(to: CGPoint(x: center.x + side * earSpread, y: earBaseY + earHeight))
        ctx.addLine(to: CGPoint(x: center.x + side * (earSpread + earBaseHalf), y: earBaseY))
        ctx.closePath()
        ctx.strokePath()
    }

    // ひげ
    let whiskerY = center.y - radius * 0.05
    let whiskerLen = hiSize * 0.16
    for dy: CGFloat in [-1, 0, 1] {
        for side: CGFloat in [-1, 1] {
            ctx.beginPath()
            ctx.move(to: CGPoint(x: center.x + side * radius * 0.92, y: whiskerY + dy * hiSize * 0.05))
            ctx.addLine(to: CGPoint(x: center.x + side * (radius * 0.92 + whiskerLen), y: whiskerY + dy * hiSize * 0.06))
            ctx.strokePath()
        }
    }

    // 顔の塗り（メモリ使用率の高さまで、顔の内側にクリップ）
    let fillTopY = headRect.minY + headRect.height * stage.fillFraction
    ctx.saveGState()
    ctx.addPath(headPath)
    ctx.clip()
    ctx.setFillColor(fillColor)
    ctx.fill(CGRect(x: headRect.minX, y: headRect.minY, width: headRect.width, height: fillTopY - headRect.minY))
    ctx.restoreGState()

    // 顔の輪郭を塗りの上から描き直してエッジをくっきりさせる
    ctx.setStrokeColor(outlineColor)
    ctx.addPath(headPath)
    ctx.strokePath()

    // 目（塗りの有無に関わらず常に見えるよう、輪郭色で不透明に描く）
    let eyeRadius = hiSize * 0.045
    let eyeY = center.y + radius * 0.15
    let eyeSpread = radius * 0.42
    ctx.setFillColor(outlineColor)
    ctx.setStrokeColor(outlineColor)
    punchEye(ctx: ctx, center: CGPoint(x: center.x - eyeSpread, y: eyeY), radius: eyeRadius, style: stage.eyeStyle, lineWidth: lineWidth * 0.7)
    punchEye(ctx: ctx, center: CGPoint(x: center.x + eyeSpread, y: eyeY), radius: eyeRadius, style: stage.eyeStyle, lineWidth: lineWidth * 0.7)

    guard let hiImage = ctx.makeImage() else { return NSImage(size: NSSize(width: gridSize, height: gridSize)) }

    // Retinaでも滲まないよう@2xピクセルへスムーズにダウンサンプル
    let pixelScale = 2
    let finalRes = gridSize * pixelScale
    guard let finalCtx = CGContext(
        data: nil, width: finalRes, height: finalRes, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return NSImage(size: NSSize(width: gridSize, height: gridSize)) }
    finalCtx.interpolationQuality = .high
    let inset = CGFloat(finalRes) * 0.06
    finalCtx.draw(hiImage, in: CGRect(x: inset, y: inset, width: CGFloat(finalRes) - inset * 2, height: CGFloat(finalRes) - inset * 2))

    guard let finalImage = finalCtx.makeImage() else { return NSImage(size: NSSize(width: gridSize, height: gridSize)) }
    let image = NSImage(cgImage: finalImage, size: NSSize(width: gridSize, height: gridSize))
    image.isTemplate = useTemplate
    return image
}
