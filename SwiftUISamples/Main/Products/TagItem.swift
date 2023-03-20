//
//  TagItem.swift
//  LifeMart
//
//  Created by Andrey on 11.03.2022.
//

import SwiftUI

struct TagItem: View {
    
    var tag: TagModel
    var tagTapAction: () -> Void
    
    var body: some View {
        Text(verbatim: tag.categoryName)
            .foregroundColor(tag.selected ? .appWhite : .appGrey)
            .font(.appText)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(tag.selected ? Color.appGreen.cornerRadius(5) : Color.appGhostWhite.cornerRadius(5))
            .shadow(color: tag.selected ? Color.appGreen.opacity(0.35) : .clear, radius: 8, x: 0, y: 4)
            .onTapGesture {
                print("tag = \(tag)")
                tagTapAction()
            }
    }
}

#if DEBUG
struct TagItem_Previews: PreviewProvider {
    static var previews: some View {
        TagItem(tag: TagModel(categoryId: 123, categoryName: "Готовые"), tagTapAction: {})
    }
}
#endif
