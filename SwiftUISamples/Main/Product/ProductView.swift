//
//  ProductView.swift
//  LifeMart
//
//  Created by Andrey on 05.03.2022.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProductView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @ObservedObject var model: ProductViewModel
    
    private let photoHeight: CGFloat = 300
    
    init(viewModel: ProductViewModel) {
        self.model = viewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                
                WebImage(url: URL(string: model.product?.photo ?? ""))
                    .resizable()
                    .placeholder(Image("icon_product_placeholder"))
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: photoHeight)
                    .clipped()
                
                nameView
                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Group() {
                            Spacer()
                                .frame(height: 10)
                            if model.showNutrients {
                                nutrientView
                            }

                            if model.showModifiers {
                                modifiersView
                            }

                            if model.showConsist {
                                consistView
                            }

                            if model.showDescription {
                                descriptionView
                            }

                            if model.showScore {
                                scoresView
                            }
                        }
                        .padding(.horizontal, 16)

                        Spacer()
                    }
                }
//                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .onChange(of: model.dismissView) { value in
                if value {
                    back()
                }
            }
            .errorView(errorMessage: $model.errorMessage)
            
            addProductView
            
            
            if model.loading { LoadingView() }
        }
        }

    }
}

extension ProductView {
    
    var addProductView: some View {
        Group {
            priceButton
            if model.quantity > 0 && model.enableAddProductAction() {
                removeButton
                plusButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    
    var priceButton: some View {
        Button(action: {
            if model.enableAddProductAction() {
                if model.quantity == 0 {
                    if model.showModifiers {
                        model.checkValidModifiersAndAddToCart()
                    } else {
                        model.changeProductInCart(changeProductAction: .add)
                    }
                }
            }
        }) {
            if model.quantity == 0 {
                VStack(spacing: 6) {
                    Image("product_order_big")
                        .padding(.top, 8)
                    //Text(model.price?.clean.addCurrency ?? "")
                    Text(model.priceStr())
                        .foregroundColor(.appWhite)
                        .font(.appBoldPriceText)
                }
            } else {
                VStack(spacing: 6) {
                    //Text("\(model.quantity.clean) шт.")
                    Text(model.quantityStr())
                        .foregroundColor(.appWhite)
                        .font(.appFont(size: 20, weight: .bold))
                    //Text("по  \(model.price?.clean.addCurrency ?? "")")
                    Text(model.priceStr())
                        .foregroundColor(.appWhite)
                        .font(.appFont(size: 14, weight: .regular))
                }
            }
        }
        .frame(width: 110, height: 110)
        .background(Color.appGreen)
        .clipShape(Circle())
        .offset(x: 20.0, y: photoHeight - 80.0)
        .disabled(model.quantity > 0)
    }
    
    var plusButton: some View {
        Button(action: {
            model.changeProductInCart(changeProductAction: .add)
        }) {
            Image("icon_plus")
        }
        .offset(x: -42.0, y: photoHeight - 128.0)
    }
    
    var removeButton: some View {
        Button(action: {
            model.changeProductInCart(changeProductAction: .remove)
        }) {
            if model.quantity == 1 {
                Image("icon_trash")
            } else {
                Image("icon_minus")
            }
        }
        .offset(x: -102.0, y: photoHeight - 44.0)
    }
        
//    var orderWithModifiersButton: some View {
//        Button(action: {
//
//        }) {
//            VStack(spacing: 6) {
//                Image("product_order_big")
//                    .padding(.top, 8)
//                Text(model.product?.priceStr ?? "")
//                    .foregroundColor(.appWhite)
//                    .font(.appBoldPriceText)
//            }
//        }
//        .frame(width: 110, height: 110)
//        .background(Color.appGreen)
//        .clipShape(Circle())
//        .offset(x: 20.0, y: photoHeight - 80.0)
//    }
    
    var photoView: some View {
//        //GeometryReader { geometry in
////            WebImage(url: URL(string: model.product?.photo ?? ""))
////                .resizable()
////                .placeholder(Image("Illustration"))
////                //.scaledToFit()
////                .aspectRatio(contentMode: .fill)
////                .frame(width: geometry.size.width, height: photoHeight, alignment: .top)
////                //.aspectRatio(contentMode: .fill)
////                .clipped()
//
//            WebImage(url: URL(string: model.product?.photo ?? ""))
//            .resizable()
//            .aspectRatio(contentMode: .fit)
//
//                .frame(height: photoHeight)
//                .clipped()
//            //Image("Illustration")
//        //}
        
        WebImage(url: URL(string: model.product?.photo ?? ""))
            .resizable()
            .placeholder(Image("icon_product_placeholder"))
            .aspectRatio(contentMode: .fit)
            .frame(height: photoHeight)
            .clipped()
    }
    
    var nameView: some View {
        Group {
            Text(model.product?.name ?? "")
                .foregroundColor(Color.appDarkGrey.opacity(0.7))
                .font(.appTitleBoldText)
                .frame(height: 14)
                .padding(.trailing, 90)
                .padding(.top, 14)
            
            HStack {
                Text(model.product?.info?.weight ?? "")
                    .foregroundColor(Color.appDarkGrey.opacity(0.7))
                    .font(.appText)
            }
            .frame(height: 14)
            .padding(.top, 8)
            .padding(.bottom, 19)
        }
        .padding(.horizontal, 16)
    }
    var nutrientView: some View {
        HStack(alignment: .center, spacing: 0) {
            NutrientItem(name: "", value: model.product?.info?.weight ?? "")
            NutrientItem(name: "ккал", value: model.product?.info?.calories100 ?? "")
            NutrientItem(name: "белки", value: model.product?.info?.proteins100 ?? "")
            NutrientItem(name: "жиры", value: model.product?.info?.fats100 ?? "")
            NutrientItem(name: "углеводы", value: model.product?.info?.carbohydrates100 ?? "")
        }
        .frame(height: 35)
        .padding(.top, 15)
        .padding(.bottom, 24)
    }
    
    var modifiersView: some View {
        ForEach(model.modifierGroupModels, id: \.self) { modifierGroupM in
            Text("\(modifierGroupM.title)")
                .foregroundColor(Color.appDarkGrey.opacity(0.7))
                .font(.appBoldText)
                .padding(.bottom, 14)
            FlexibleView(data: modifierGroupM.modifiers, spacing: 8, alignment: .leading) { modifierM in
                ModifierItem(modifierM: modifierM) {
                    if model.enableAddProductAction() {
                        model.select(modifierModel: modifierM, modifierGroupModel: modifierGroupM)
                    }
                }
            }
            .padding(.bottom, 22)
        }
    }
        
    var consistView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Состав")
                .foregroundColor(Color.appDarkGrey.opacity(0.7))
                .font(.appTitleBoldText)
                .frame(height: 14)
                .padding(.bottom, 8)
            
            Text(model.product?.consist ?? "")
                .foregroundColor(.appGrey)
                .font(.appText)
                .padding(.bottom, 24)
        }
    }
    
    var descriptionView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Описание")
                .foregroundColor(Color.appDarkGrey.opacity(0.7))
                .font(.appTitleBoldText)
                .frame(height: 14)
                .padding(.bottom, 8)
            
            Text(model.product?.description ?? "")
                .foregroundColor(.appGrey)
                .font(.appText)
                .padding(.bottom, 24)
        }
    }
    
    var scoresView: some View {
        VStack(alignment: .leading, spacing: 0) {
            let count = model.product?.scoresCount ?? 0
            let strings = ["\(count) голоса", "\(count) голосов", "\(count) голосов"]
            let pluralString = String.makePluralSensitive(for: count, strings: strings)
            Text("Оценка \(model.product?.avgScoreStr ?? "0.0") на основании \(pluralString)")
                .foregroundColor(Color.appDarkGrey.opacity(0.7))
                .font(.appTitleBoldText)
                .frame(height: 14)
                .padding(.bottom, 11)
            
            VStack(spacing: 5) {
                VoteProgress(imageName: "icon_smile_green", color: .appGreen, progress: model.progress(type: .green))
                VoteProgress(imageName: "icon_smile_yel", color: .appMikadoYellow, progress: model.progress(type: .yellow))
                VoteProgress(imageName: "icon_smile_red", color: .appPink, progress: model.progress(type: .red))
            }
        }
    }
}

extension ProductView {
    func back() {
        print("back")
        self.presentationMode.wrappedValue.dismiss()
        LifeMartApp.dependencyProvider.container.resetObjectScope(.modalView)
    }
}

#if DEBUG
struct ProductView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
    }
    
    struct PreviewWrapper: View {
        
        //@State(initialValue: Parser.shared.product()) var product: Product?
        
        var body: some View {
            //ProductView(viewModel: ProductViewModel(product: $product))
            LifeMartApp.dependencyProvider.assembler.resolver.resolve(ProductView.self, arguments: Parser.shared.product(), SourceScreen.catalog, 4685)!
        }
      }
}
#endif
