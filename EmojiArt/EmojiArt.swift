//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Giang Nguyenn on 1/10/21.
//

import Foundation

struct EmojiArt: Codable {
    var backgroundURL: URL?
    var emojis = [Emoji]()
    
    // struct representation of an emoji
    struct Emoji: Identifiable, Codable, Hashable {
        let text: String
        var x: Int
        var y: Int
        var size: Int
        var id: Int
        
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
        
    }
    private var uniqueEmojiId: Int = 0
    
    // encode each emojiArt as json
    var json: Data? {
        try? JSONEncoder().encode(self)
    }
    
    // initialized emojiArt by its json
    init?(json: Data?) {
        if json != nil, let newEmojiArt = try? JSONDecoder().decode(EmojiArt.self, from: json!) {
            self = newEmojiArt
        } else {
            return nil
        }
    }
    
    // empty initialization
    init() {}
    
    // add emojis on screen
    mutating func addEmoji(_ text: String, x: Int, y: Int, size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: x, y: y, size: size, id: uniqueEmojiId))
    }
    
    // remove all emojis on screen
    mutating func resetEmojis() {
        emojis.removeAll()
    }
}
