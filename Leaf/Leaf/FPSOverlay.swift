//
//  FPSOverlay.swift
//  Leaf
//
//  Created by Neeraj Kumar on 24/01/26.
//

import AppKit
import QuartzCore
import SwiftUI

#if DEBUG
final class FPSCounter: ObservableObject {
    @Published private(set) var fps: Int = 0
    @Published private(set) var frameTimeMs: Int = 0

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0

    init() {
        start()
    }

    deinit {
        stop()
    }

    private func start() {
        guard displayLink == nil else { return }
        if let link = NSScreen.main?.displayLink(target: self, selector: #selector(step)) {
            link.add(to: .main, forMode: .common)
            displayLink = link
        }
    }

    private func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func step(_ link: CADisplayLink) {
        let timestamp = link.timestamp
        if lastTimestamp == 0 {
            lastTimestamp = timestamp
            return
        }

        let delta = timestamp - lastTimestamp
        lastTimestamp = timestamp
        guard delta > 0 else { return }

        let currentFPS = Int(round(1.0 / delta))
        let currentFrameMs = Int(round(delta * 1000))

        if Thread.isMainThread {
            fps = currentFPS
            frameTimeMs = currentFrameMs
        } else {
            DispatchQueue.main.async {
                self.fps = currentFPS
                self.frameTimeMs = currentFrameMs
            }
        }
    }
}

struct FPSOverlay: View {
    @StateObject private var counter = FPSCounter()

    var body: some View {
        Text("\(counter.fps) FPS  \(counter.frameTimeMs)ms")
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.45))
            )
            .allowsHitTesting(false)
    }
}
#endif
