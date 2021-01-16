//
//  EmojiArtView.swift
//  EmojiArt
//
//  Created by Giang Nguyenn on 1/10/21.
//

import SwiftUI

struct EmojiArtView: View {
    @ObservedObject var  document: EmojiArtDocument
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(EmojiArtDocument.palette.map { String($0)}, id: \.self) { emoji in
                    Text(emoji).font(Font.system(size: defaultEmojiSize))
                        .onDrag {
                            return NSItemProvider(object: emoji as NSString)
                        }
                }
            }
        }.padding()

        GeometryReader { geometry in
            ZStack {
                Rectangle().foregroundColor(.white).overlay(
                    OptionalImage(image: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .offset(panOffset)
                )
                .gesture(doubleTapToZoom(in: geometry.size))
                ForEach(self.document.emojis) { emoji in
                    Text(emoji.text)
                        .font(animatableWithSize: zoomScale * defaultEmojiSize)
                        .position(self.position(for: emoji, in: geometry.size))
                }
            }
            .clipped()
            .ignoresSafeArea(edges: [/*@START_MENU_TOKEN@*/.bottom/*@END_MENU_TOKEN@*/, .horizontal])
            .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                var location = geometry.convert(location, from: .global)
                location = CGPoint(x: location.x - geometry.size.width / 2,
                                   y: location.y - geometry.size.height / 2)
                location = CGPoint(x: location.x - panOffset.width,
                                   y: location.y - panOffset.height)
                location = location / zoomScale
                return self.drop(providers: providers, at: location)
            }
            .gesture(zoomGesture())
            .gesture(panGesture())
        }
    }
    
    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    private var zoomScale: CGFloat { steadyStateZoomScale * gestureZoomScale }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded { withAnimation(.linear) {
                zoomToFit(self.document.backgroundImage, in: size)
            }
        }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        steadyStatePanOffset = .zero
        if let image = image, image.size.width > 0, image.size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .onEnded { finalGestureScale in
                steadyStateZoomScale *= finalGestureScale
            }.updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transition in
                gestureZoomScale = latestGestureScale
            }
    }
    
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    private var panOffset: CGSize { (steadyStatePanOffset + gesturePanOffset) * zoomScale }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + finalDragGestureValue.translation / zoomScale
            }.updating($gesturePanOffset) { latestGestureScale, gesturePanOffset, transition in
                gesturePanOffset = latestGestureScale.translation / zoomScale
            }
    }
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: emoji.location.x * zoomScale + size.width / 2 + panOffset.width,
                           y: emoji.location.y * zoomScale + size.height / 2 + panOffset.height)
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            print("dropped: \(url)")
            self.document.setBackgroundURL(url)
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: defaultEmojiSize)
            }
        }
        return found
    }
    
    private let defaultEmojiSize: CGFloat = 40
}
