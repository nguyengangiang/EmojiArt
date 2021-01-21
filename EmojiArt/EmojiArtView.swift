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
                        // emoji choosing palette
                        ForEach(EmojiArtDocument.palette.map { String($0)}, id: \.self) { emoji in
                            Text(emoji).font(Font.system(size: defaultEmojiSize))
                                .onDrag {
                                    return NSItemProvider(object: emoji as NSString)
                                }
                        }
                    }
                }.padding()
                // button to remove emojis shown on screen
                Button("Reset Emoji") {document.resetEmojis()}
            }

            GeometryReader { geometry in
                ZStack {
                    // background
                    Rectangle()
                        .foregroundColor(Color.white)
                        .overlay(
                        OptionalImage(image: document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .offset(panOffset)
                    )
                    .gesture(doubleTapToZoom(in: geometry.size))
                    
                    // emojis shown on screen
                    if !self.isLoading {
                        ForEach(self.document.emojis) { emoji in
                            if !document.chosenEmojis.contains(matching: emoji) {
                                EmojiView(emoji: emoji, isSelected: document.chosenEmojis.contains(matching: emoji), zoomScale: zoomScale)
                                    .font(animatableWithSize: fontSize(for: emoji))
                                    .position(self.position(for: emoji, in: geometry.size))
                                    .gesture(TapGesture(count: 1).onEnded {
                                        document.toggleMatching(emoji: emoji)
                                    }
                                    .exclusively(before: movingUnselectedGesture(emoji: emoji))
                                    )
                            } else {
                                EmojiView(emoji: emoji, isSelected: document.chosenEmojis.contains(matching: emoji), zoomScale: zoomScale)
                                    .font(animatableWithSize: fontSize(for: emoji))
                                    .position(self.position(for: emoji, in: geometry.size))
                                    .gesture(TapGesture(count: 1).onEnded {
                                        document.toggleMatching(emoji: emoji)
                                    }
                                    .exclusively(before: moveSelectionGesture())
                                    )
                            }
                        }
                    } else {
                        Image(systemName: "hourglass").imageScale(.large).spinning()
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
    
    private var isLoading: Bool {
        document.backgroundImage == nil && document.backgroundURL != nil
    }
    
    // MARK: - zoom constants
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
                // if no emoji is chosen then scale the whole document
                if document.chosenEmojis.isEmpty {
                    steadyStateZoomScale *= finalGestureScale
                } else {
                    // scale only chosen emojis
                    for emoji in document.chosenEmojis {
                        document.scaleEmoji(emoji, by: finalGestureScale)
                    }
                }
            }.updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
    }
    
    // MARK: - pan constants
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    private var panOffset: CGSize { (steadyStatePanOffset + gesturePanOffset) * zoomScale }
    @GestureState private var unchosenEmojiGesturePanOffset: CGSize = .zero
    @GestureState private var chosenEmojiGesturePanOffset: CGSize = .zero

    private var chosenEmojiPanOffset: CGSize { chosenEmojiGesturePanOffset * zoomScale }
    private var unchosenEmojiPanOffset: CGSize { unchosenEmojiGesturePanOffset * zoomScale }

    
    private func panGesture() -> some Gesture {
        DragGesture()
            // update panOffset by the amount of dragging
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + finalDragGestureValue.translation / zoomScale
                
            }.updating($gesturePanOffset) { latestGestureScale, gesturePanOffset, transaction in
                // following user gesture
                gesturePanOffset = latestGestureScale.translation / zoomScale
            }
    }
    
    // move selected emojis
    private func moveSelectionGesture() -> some Gesture {
        DragGesture()
            .onEnded { finalDragGestureValue in
                for emoji in document.chosenEmojis {
                    document.moveEmoji(emoji, by: finalDragGestureValue.translation / zoomScale)
                }
            }.updating($chosenEmojiGesturePanOffset) { latestGestureScale, chosenEmojiGesturePanOffset, transaction in
                chosenEmojiGesturePanOffset = latestGestureScale.translation / zoomScale
            }
    }
    
    private func movingUnselectedGesture(emoji: EmojiArt.Emoji) -> some Gesture {
        DragGesture()
            .updating($unchosenEmojiGesturePanOffset) {
                latestGestureScale, unchosenEmojiGesturePanOffset, transation in
                    unchosenEmojiGesturePanOffset = latestGestureScale.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                document.moveEmoji(emoji, by: finalDragGestureValue.translation / zoomScale)
            }
    }

    // position emojis by panOffset and zoomScale
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        let location = CGPoint(x: emoji.location.x * zoomScale + size.width / 2 + panOffset.width,
                           y: emoji.location.y * zoomScale + size.height / 2 + panOffset.height)
        return location
    }
    
    private func location(for emoji: EmojiArt.Emoji) -> CGPoint {
        if (document.chosenEmojis.contains(matching: emoji)) {
            return CGPoint(x: emoji.location.x + chosenEmojiPanOffset.width,
                               y: emoji.location.y + chosenEmojiPanOffset.height)
        }
        else {
            return CGPoint(x: emoji.location.x + unchosenEmojiPanOffset.width,
                               y: emoji.location.y + unchosenEmojiPanOffset.height)
        }
    }
    
    // calculate emoji's font size
    private func fontSize(for emoji: EmojiArt.Emoji) -> CGFloat {
        if document.chosenEmojis.contains(matching: emoji) {
            // if there are emojis chosen on screen
            // update font for chosen emojis only
            return gestureZoomScale * CGFloat(emoji.size) * zoomScale
        } else {
            // update font for every emoji on screen
            return zoomScale * CGFloat(emoji.size)
        }
    }
    
    // import image from the internet and set as background
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            print("dropped: \(url)")
            //document.setBackgroundURL(url)
            document.backgroundURL = url
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: defaultEmojiSize)
            }
        }
        return found
    }
}

// View for each emoji on screen
struct EmojiView: View {
    var emoji: EmojiArt.Emoji
    var isSelected: Bool
    var zoomScale: CGFloat
    
    var body: some View {
        ZStack {
            Text(emoji.text).shadow(color: .orange, radius: isSelected ? defaultEmojiSize : 0)
        }
    }
}

private let defaultEmojiSize: CGFloat = 40
