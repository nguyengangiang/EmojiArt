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
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let store = EmojiArtDocumentStore(directory: url)
        store.addDocument()
        return WindowGroup {
            EmojiArtDocumentChooser().environmentObject(store)
        }
    }
}
