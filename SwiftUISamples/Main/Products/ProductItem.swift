//
//  ProductItem.swift
//  LifeMart
//
//  Created by Andrey on 05.04.2022.
//

import SwiftUI
import SDWebImageSwiftUI
import Longinus
//import LonginusSwiftUI

struct ProductItem: View {
    
    var product: Product
    var width: CGFloat
    var addAction: () -> Void
    var removeAction: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
//                WebImage(url: URL(string: product.photo ?? ""))
//                    .resizable()
//                    .placeholder(Image("icon_product_placeholder_big"))
                LGImage(source: URL(string: product.photo ?? ""), placeholder: {
                    Image("icon_product_placeholder_big")
                })
                    .resizable()
                    .cancelOnDisappear(true)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width - 8, height: width - 8, alignment: .center)
                    .cornerRadius(width/2)
                
                productWeight
                
                productName
            }
            
            ratingView
                .isHidden(product.avgScore == nil)
            productPrice
            
        }
    }
    
    var productWeight: some View {
        Text(product.info?.weight ?? "")
            .foregroundColor(.appLightGrey)
            .font(.appSmallText)
            .frame(height: 14, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
    }
    
    var productName: some View {
        Text(product.name ?? "")
            .foregroundColor(.appDarkGrey)
            .font(.appText)
            .frame(height: 46, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    
    var ratingView: some View {
        HStack {
            Text(product.avgScoreStr)
                .foregroundColor(.white)
                .font(.appRating)
                .frame(width: 32, height: 32)
                .background(Color.appPhthaloGreen)
                .cornerRadius(32/2)
                .padding(.trailing, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    
    var productPrice: some View {
        ZStack {
            Button {
                //if !(product.hasModifiers ?? true) {
                    addAction()
                //}
            } label: {
                VStack {
                    if product.quantity ?? 0 > 0 {
                        Text(product.dimensionStr(quantity: product.quantity ?? 0))
                            .foregroundColor(.appWhite)
                            .font(.appFont(size: 14, weight: .bold))
                        Text(product.priceStr(quantity: product.quantity ?? 0))
                            .foregroundColor(.appWhite)
                            .font(.appFont(size: 12, weight: .regular))
                    } else {
                        Image("product_order")
                            .aspectRatio(contentMode: .fit)
                            .padding(.top, 5)
                        
                        Text(product.priceStr)
                            .foregroundColor(.white)
                            .font(.appRating)
                            .padding(.top, -5)
                    }
                }
                .frame(width: 64, height: 64)
                .background(Color.appGreen)
                .cornerRadius(64/2)
                .disabled(product.hasModifiers ?? true)
            }           
            
            if ((product.quantity ?? 0 > 0) && !(product.hasModifiers ?? true)) {
                plusButton
                removeButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.bottom, 67)
    }
    
    var plusButton: some View {
        Button(action: {
            addAction()
        }) {
            Image("icon_plus_small")
                .frame(width: 27, height: 27)
        }
        .offset(y: -32 - 5 - 13)
    }
    
    var removeButton: some View {
        Button(action: {
            removeAction()
        }) {
            if product.quantity == 1 {
                Image("icon_trash_small")
                    .frame(width: 27, height: 27)
            } else {
                Image("icon_minus_small")
                    .frame(width: 27, height: 27)
            }
        }
        .offset(x: -32 - 5 - 13)
    }
    
}
//struct ProductItem: View {
//    
//    var product: Product
//    var width: CGFloat
//    
//    init(product: Product, width: CGFloat) {
//        self.product = product
//        self.width = width
//    }
//        
//    var body: some View {
//        ZStack {
//            productImage
//                .frame(width: width, height: height, alignment: .topLeading)
//
//            VStack(alignment: .leading, spacing: 0) {
//
//                productWeight
//
//                productName
//            }
//            .frame(width: width, height: height, alignment: .bottomLeading)
//
//            ratingView
//
//            productPrice
//        }
//        .frame(width: width, height: height)
//
//    }
//}
//
//extension ProductItem {
//    
//    var height: CGFloat {
//        return width - 8 + 14 + 46
//    }
//        
//    var productImage: some View {
//        LGImage(source: URL(string: product.photo ?? ""), placeholder: {
//            Image("image_placeholder") })
//            .resizable()
//            .cancelOnDisappear(true)
//            .aspectRatio(contentMode: .fill)
//            .frame(width: width - 8, height: width - 8, alignment: .center)
//            .clipShape(Circle())
////        WebImage (url: URL(string: product.photo ?? ""))
////            .renderingMode(.original)
////            .resizable()
////            .placeholder(Image("icon_product_placeholder_big"))
////            .padding(0)
////            .aspectRatio(contentMode: .fill)
////            .frame(width: width - 8, height: width - 8, alignment: .leading)
////            .clipShape(Circle())
//    }
//        
//    var productPrice: some View {
//        HStack {
//            VStack {
//                Image("product_order")
//                    .aspectRatio(contentMode: .fit)
//                    .padding(.top, 5)
//                
//                Text(product.priceStr)
//                    .foregroundColor(.white)
//                    .font(.appRating)
//                    .padding(.top, -5)
//            }
//            .frame(width: 64, height: 64)
//            .background(Color.appGreen)
//            .clipShape(Circle())
//            
//            .padding(.bottom, 50)
//        }
//        .frame(width: width, height: height, alignment: .bottomTrailing)
//    }
//        
//    var productWeight: some View {
//        Text(product.info?.weight ?? "")
//            .foregroundColor(.appLightGrey)
//            .font(.appSmallText)
//            .frame(width: width, height: 14, alignment: .leading)
//            .padding(.top, 0)
//            .padding(.bottom, 0)
//            //.offset(y: -1)
//    }
//    
//    var productName: some View {
//        Text(product.name ?? "")
//            .foregroundColor(.appDarkGrey)
//            .font(.appText)
//            .frame(width: width, height: 46, alignment: .leading)
//            .padding(.top, 0)
//    }
//    
//    var favoriteButton: some View {
//        VStack(alignment: .leading) {
//            Button(action: {
//                
//            }) {
//                Image("Icon_favorite_default")
//            }
//            .padding(.top, 2)
//        }
//        .frame(
//            maxWidth: .infinity,
//            maxHeight: .infinity,
//            alignment: .topLeading
//        )
//    }
//    
//    var ratingView: some View {
//        HStack {
//            Text(product.avgScoreStr)
//                .foregroundColor(.white)
//                .font(.appRating)
//                .frame(width: 32, height: 32)
//                .background(Color.appPhthaloGreen)
//                .clipShape(Circle())
//                .padding(.trailing, 14)
//        }
//        .frame(width: width, height: height, alignment: .topTrailing)
//    }
//}

#if DEBUG
struct ProductItem_Previews: PreviewProvider {
    static var previews: some View {
        let product = Parser.shared.catalog()!.products!.first!
        return ProductItem(product: product, width: 100, addAction: {}, removeAction: {})
    }
}
#endif
