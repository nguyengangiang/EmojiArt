//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Giang Nguyenn on 1/10/21.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    static var palette: String = "🙄💀😳"
    @Published var chosenEmojis = Set<EmojiArt.Emoji>()
    private var emojiArt = EmojiArt() {
        willSet {
            objectWillChange.send()
        }
        didSet {
            print("json: \(emojiArt.json?.utf8 ?? "nil")")
            // save the document into UserDefaults
            UserDefaults.standard.setValue(emojiArt.json, forKey: EmojiArtDocument.untitled)
        }
    }
    private static let untitled = "EmojiArtDocument.Untitled"
    
    var backgroundURL: URL? {
        get {
            emojiArt.backgroundURL
        } set {
            emojiArt.backgroundURL = newValue
            fetchBackgroundImageData()
        }
    }

    // initialize document from json and update its background
    init() {
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArt()
        fetchBackgroundImageData()
    }
    
    @Published private(set) var backgroundImage: UIImage?
    var emojis: [EmojiArt.Emoji] {emojiArt.emojis}
    
    //MARK: Intents
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }
    
//    func setBackgroundURL(_ url: URL?) {
//        emojiArt.backgroundURL = url?.imageURL
//        fetchBackgroundImageData()
//    }
    
    func toggleMatching(emoji: EmojiArt.Emoji) {
        if chosenEmojis.contains(matching: emoji) {
            chosenEmojis.remove(at: chosenEmojis.firstIndex(matching: emoji)!)
        } else {
            chosenEmojis.insert(emoji)
        }
    }
    
    func resetEmojis() {
        chosenEmojis.removeAll()
        emojiArt.resetEmojis()
    }
    
    func deselectAllEmojis() {
        chosenEmojis.removeAll()
    }
    
    func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = self.emojiArt.backgroundURL {
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        if url == self.emojiArt.backgroundURL {
                            self.backgroundImage = UIImage(data: imageData)
                        }
                    }
                }
            }
        }
    }
}

extension EmojiArt.Emoji {
    var fontSize: CGFloat {
        CGFloat(self.size)
    }
    
    var location: CGPoint {
        CGPoint(x: CGFloat(self.x), y: CGFloat(self.y))
    }
}
