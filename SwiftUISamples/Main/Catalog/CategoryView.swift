//
//  CategoryView.swift
//  LifeMart
//
//  Created by Andrey on 15.03.2022.
//

import SwiftUI
import SDWebImageSwiftUI

struct CategoryView: View {
    
    enum CategoryImagePosition {
        case left, right
    }
    
    let category: ProductCategory
    let imagePosition: CategoryImagePosition
    
    var body: some View {
        
        ZStack {
            
            Text("")
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .background(Color.appGreen)
                .cornerRadius(5)
                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 0)

            HStack(spacing: 0) {
                if imagePosition == CategoryImagePosition.left {
                    WebImage (url: URL(string: category.photo ?? ""))
                        .imageModifier(height: 125, width: 125)
                    
                    Spacer()
                }
                
                
                VStack(alignment: .leading) {
                    Text(category.title ?? "")
                        .font(.appCategoryTitle)
                        .foregroundColor(.appWhite)
                    
                    Text(category.description ?? "")
                        .lineSpacing(0.9)
                        .font(.appCategoryDescription)
                        .foregroundColor(.appWhite)
                }
                //.frame(height: 100)
                
                Spacer()
                
                if imagePosition == CategoryImagePosition.right {
                    WebImage (url: URL(string: category.photo ?? ""))
                        .imageModifier(height: 125, width: 125)
                }
                
                Image("icon_arrow_forward")

            }
            .padding(.horizontal, 21)
            .frame(height: 100)
        }
    }
}
