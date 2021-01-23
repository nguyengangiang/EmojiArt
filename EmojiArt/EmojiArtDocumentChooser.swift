//
//  EmojiArtDocumentChooser.swift
//  EmojiArt
//
//  Created by Giang Nguyenn on 1/22/21.
//

import SwiftUI

struct EmojiArtDocumentChooser: View {
    @EnvironmentObject var store: EmojiArtDocumentStore
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.documents) { document in
                    NavigationLink(destination: EmojiArtDocumentView(document: document)                        .navigationBarTitle(store.name(for: document)))
                        { Text(self.store.name(for: document)) }
                }
            }
            .navigationTitle(store.name)
            .navigationBarItems(leading: Button(action: {store.addDocument()},
                                                label: {Image(systemName: "plus").imageScale(.large)}))
        }
    }
}

struct EmojiArtDocumentChooser_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentChooser()
    }
}
