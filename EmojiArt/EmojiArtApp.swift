//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Giang Nguyenn on 1/10/21.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    var body: some Scene {
        WindowGroup {
            EmojiArtView(document: EmojiArtDocument())
        }
    }
}
