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
        VStack {
            HStack {
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
                Button("Reset") {document.resetEmojis()}
            }

            GeometryReader { geometry in
                ZStack {
                    Rectangle().overlay(
                        OptionalImage(image: document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .offset(panOffset)
                    )
                    .gesture(doubleTapToZoom(in: geometry.size))
                    
                    ForEach(self.document.emojis) { emoji in
                        EmojiView(emoji: emoji, isSelected: document.chosenEmojis.contains(matching: emoji), zoomScale: zoomScale)
                            .onTapGesture {
                                document.toggleMatching(emoji: emoji)
                            }
                            .font(animatableWithSize: fontSize(for: emoji))
                            .position(self.position(for: emoji, in: geometry.size))
                            .gesture(moveSelectionGesture())
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
                .gesture(panGesture())
                .gesture(zoomGesture())
            }

        }
    }
    
    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    private var zoomScale: CGFloat { document.chosenEmojis.isEmpty ? steadyStateZoomScale * gestureZoomScale : steadyStateZoomScale }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded { _ in withAnimation(.linear) {
            zoomToFit(self.document.backgroundImage, in: size)
                }
            }
            .exclusively(before: TapGesture(count: 1).onEnded {
                document.deselectAllEmojis()
            })
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
                if document.chosenEmojis.isEmpty {
                    steadyStateZoomScale *= finalGestureScale
                } else {
                    for emoji in document.chosenEmojis {
                        document.scaleEmoji(emoji, by: finalGestureScale)
                    }
                }
                print("final scale: \(finalGestureScale)")
            }.updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
    }
    
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    private var panOffset: CGSize { (steadyStatePanOffset + gesturePanOffset) * zoomScale }
    
    @GestureState private var emojiGesturePanOffset: CGSize = .zero
    private var emojiPanOffset: CGSize { emojiGesturePanOffset * zoomScale }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + finalDragGestureValue.translation / zoomScale
                
            }.updating($gesturePanOffset) { latestGestureScale, gesturePanOffset, transaction in
                gesturePanOffset = latestGestureScale.translation / zoomScale
            }
    }
    
    private func moveSelectionGesture() -> some Gesture {
        DragGesture()
            .onEnded { finalDragGestureValue in
                for emoji in document.chosenEmojis {
                    document.moveEmoji(emoji, by: finalDragGestureValue.translation / zoomScale)
                }
            }.updating($emojiGesturePanOffset) { latestGestureScale, emojiGesturePanOffset, transaction in
                emojiGesturePanOffset = latestGestureScale.translation / zoomScale
            }
    }
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = CGPoint(x: emoji.location.x * zoomScale + size.width / 2 + panOffset.width,
                           y: emoji.location.y * zoomScale + size.height / 2 + panOffset.height)
        if (document.chosenEmojis.contains(matching: emoji)) {
            location = CGPoint(x: location.x + emojiPanOffset.width,
                               y: location.y + emojiPanOffset.height)
        }
        return location
    }
    
    private func fontSize(for emoji: EmojiArt.Emoji) -> CGFloat {
        if document.chosenEmojis.contains(matching: emoji) {
            return gestureZoomScale * CGFloat(emoji.size) * zoomScale
        } else {
            return zoomScale * CGFloat(emoji.size)
        }
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
}

struct EmojiView: View {
    var emoji: EmojiArt.Emoji
    var isSelected: Bool
    var zoomScale: CGFloat
    
    var body: some View {
        ZStack {
            Text(emoji.text).shadow(color: .red, radius: isSelected ? CGFloat(emoji.size) * zoomScale : 0)
        }
    }
}

private let defaultEmojiSize: CGFloat = 40
