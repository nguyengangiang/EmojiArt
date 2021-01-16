//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by Giang Nguyenn on 1/16/21.
//

import SwiftUI

struct OptionalImage: View {
    var image: UIImage?
    var body: some View {
        Group {
            if image != nil {
                Image(uiImage: image!)
            }
        }
    }
}
