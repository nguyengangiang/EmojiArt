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
                }
            }
        }.padding()
        Rectangle().foregroundColor(.white).overlay(
            Group {
                if self.document.backgroundImage != nil {
                    Image(uiImage: self.document.backgroundImage!)
                }
            }
        )
            .ignoresSafeArea(edges: [/*@START_MENU_TOKEN@*/.bottom/*@END_MENU_TOKEN@*/, .horizontal])
            .onDrop(of: ["public.image"], isTargeted: nil) { providers, location in
                return self.drop(providers: providers)
            }
    }
    
    private func drop(providers: [NSItemProvider]) -> Bool {
        let found = providers.loadFirstObject(ofType: URL.self) { url in
            print("dropped: \(url)")
            self.document.setBackgroundURL(url)
        }
        return found
    }
    
    private let defaultEmojiSize: CGFloat = 40

}
