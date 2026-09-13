#!/usr/bin/env swift
// 生成社交分享预览图 assets/og-image.png（1200×630）。
// 用法：在仓库根目录执行 `swift tools/render-og-image.swift`。
// 风格沿用官网：羊皮纸底、墨色描边、硬阴影和四块时间积木。

import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconURL = root.appendingPathComponent("assets/tilely-icon.png")
let outputURL = root.appendingPathComponent("assets/og-image.png")

guard let icon = NSImage(contentsOf: iconURL) else {
    fatalError("Missing icon at \(iconURL.path)")
}

func rgb(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

let paper = rgb(0xF8F1D9)
let ink = rgb(0x1D3447)
let muted = rgb(0x53666F)
let yellow = rgb(0xFFD84D)
let blue = rgb(0x1768B6)
let coral = rgb(0xB53B2A)
let mint = rgb(0x168461)

let canvas = NSSize(width: 1200, height: 630)

func draw(_ text: String, at origin: NSPoint, size: CGFloat, weight: NSFont.Weight, color: NSColor, kern: CGFloat = 0) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .kern: kern
    ]
    (text as NSString).draw(at: origin, withAttributes: attributes)
}

func hardCard(_ rect: NSRect, radius: CGFloat, fill: NSColor, stroke: NSColor = ink, lineWidth: CGFloat = 3, shadow: CGFloat = 6) {
    let shadowPath = NSBezierPath(roundedRect: rect.offsetBy(dx: 0, dy: shadow), xRadius: radius, yRadius: radius)
    ink.withAlphaComponent(0.2).setFill()
    shadowPath.fill()
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
    stroke.setStroke()
    path.lineWidth = lineWidth
    path.stroke()
}

struct Tile {
    let emoji: String
    let name: String
    let duration: String
    let fill: NSColor
    let text: NSColor
}

let tiles: [Tile] = [
    Tile(emoji: "📚", name: "阅读", duration: "45 分钟", fill: blue, text: .white),
    Tile(emoji: "💻", name: "项目工作", duration: "1 小时 20 分", fill: coral, text: .white),
    Tile(emoji: "🏃", name: "运动", duration: "30 分钟", fill: mint, text: .white),
    Tile(emoji: "☕️", name: "休息", duration: "10 分钟", fill: yellow, text: ink)
]

let image = NSImage(size: canvas, flipped: true) { bounds in
    NSGraphicsContext.current?.imageInterpolation = .high

    paper.setFill()
    bounds.fill()

    // 底纹：和官网 body::before 一样的细点阵。
    ink.withAlphaComponent(0.09).setFill()
    var y: CGFloat = 6
    while y < canvas.height {
        var x: CGFloat = 6
        while x < canvas.width {
            NSBezierPath(ovalIn: NSRect(x: x, y: y, width: 1.6, height: 1.6)).fill()
            x += 12
        }
        y += 12
    }

    // 左侧：图标、名字、口号。
    let iconRect = NSRect(x: 84, y: 84, width: 150, height: 150)
    let iconShadow = NSBezierPath(roundedRect: iconRect.offsetBy(dx: 0, dy: 7), xRadius: 36, yRadius: 36)
    ink.withAlphaComponent(0.2).setFill()
    iconShadow.fill()
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: iconRect, xRadius: 36, yRadius: 36).addClip()
    icon.draw(in: iconRect, from: NSRect(origin: .zero, size: icon.size), operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
    NSGraphicsContext.restoreGraphicsState()

    draw("PLAN · FOCUS · REVIEW", at: NSPoint(x: 86, y: 262), size: 17, weight: .heavy, color: coral, kern: 4)
    draw("一块时光 Tilely", at: NSPoint(x: 82, y: 292), size: 74, weight: .heavy, color: ink, kern: -1.5)
    draw("把今天，一块块装进口袋。", at: NSPoint(x: 86, y: 392), size: 38, weight: .bold, color: blue)
    draw("低负担的时间计划、活动计时与每日复盘", at: NSPoint(x: 86, y: 452), size: 24, weight: .semibold, color: muted)

    let pillRect = NSRect(x: 86, y: 508, width: 470, height: 46)
    hardCard(pillRect, radius: 23, fill: yellow, lineWidth: 2, shadow: 4)
    draw("现已登陆 App Store · iPhone / iPad / Apple Watch", at: NSPoint(x: 108, y: 519), size: 19, weight: .heavy, color: ink)

    // 右侧：一张卡里四块时间积木。
    let card = NSRect(x: 700, y: 66, width: 424, height: 498)
    hardCard(card, radius: 40, fill: rgb(0xFFFDF5, alpha: 0.9), shadow: 10)
    draw("今天", at: NSPoint(x: 730, y: 92), size: 26, weight: .heavy, color: ink)
    let dateRect = NSRect(x: 1000, y: 92, width: 96, height: 34)
    let datePath = NSBezierPath(roundedRect: dateRect, xRadius: 17, yRadius: 17)
    yellow.setFill()
    datePath.fill()
    draw("9 月 13 日", at: NSPoint(x: 1013, y: 99), size: 16, weight: .heavy, color: ink)

    let tileSize = NSSize(width: 178, height: 176)
    let gap: CGFloat = 16
    for (index, tile) in tiles.enumerated() {
        let column = CGFloat(index % 2)
        let row = CGFloat(index / 2)
        let rect = NSRect(
            x: card.minX + 30 + column * (tileSize.width + gap),
            y: card.minY + 84 + row * (tileSize.height + gap),
            width: tileSize.width,
            height: tileSize.height
        )
        hardCard(rect, radius: 26, fill: tile.fill, lineWidth: 2.5, shadow: 5)

        let badge = NSRect(x: rect.minX + 18, y: rect.minY + 18, width: 52, height: 52)
        NSColor(calibratedWhite: 1, alpha: 0.88).setFill()
        NSBezierPath(roundedRect: badge, xRadius: 15, yRadius: 15).fill()
        draw(tile.emoji, at: NSPoint(x: badge.minX + 9, y: badge.minY + 8), size: 30, weight: .regular, color: ink)

        draw(tile.name, at: NSPoint(x: rect.minX + 18, y: rect.maxY - 70), size: 24, weight: .heavy, color: tile.text)
        draw(tile.duration, at: NSPoint(x: rect.minX + 18, y: rect.maxY - 40), size: 17, weight: .bold, color: tile.text.withAlphaComponent(0.85))
    }

    return true
}

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fatalError("Could not encode og-image.png")
}

try png.write(to: outputURL, options: .atomic)
print("\(outputURL.path) \(bitmap.pixelsWide)x\(bitmap.pixelsHigh)")
