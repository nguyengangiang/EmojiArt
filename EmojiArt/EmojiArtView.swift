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
        Rectangle().foregroundColor(.green).ignoresSafeArea(edges: [/*@START_MENU_TOKEN@*/.bottom/*@END_MENU_TOKEN@*/, .horizontal])
        
    }
    
    let defaultEmojiSize: CGFloat = 40
}
