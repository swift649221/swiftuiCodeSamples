//
//  CatalogView.swift
//  LifeMart
//
//  Created by Andrey on 01.03.2022.
//

import SwiftUI
import Combine
import SDWebImageSwiftUI

struct CatalogView: View {
    
    @ObservedObject var model: CatalogViewModel
    
    @State private var showPromoPageBanners = false
    
        
    init(viewModel: CatalogViewModel) {
        self.model = viewModel
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                NavigationView {
                    ZStack {
                        bgImage
                        
                        VStack(spacing: 0) {
                            
                            addressView
                            
                            ScrollView(.vertical, showsIndicators: false) {
                                
                                VStack(spacing: 0) {
                                    
                                    PullToRefreshView {
                                        print("refreshing")
                                        model.downloadCart()
                                        model.downloadCatalog()
                                    }
                                    .background(Color.blue)
                                    
                                    promoPagesView
                                        .padding(.bottom, 43)
                                    
                                    VStack(spacing: 30) {
                                        ForEach(model.categories.indices, id: \.self) { index in
                                            let category = model.categories[index]
                                            //NavigationLink(destination: productsView(selectedCategory: category)) {
                                                CategoryView(category: category, imagePosition: (index % 2 == 0) ? .left : .right)
                                                .onTapGesture {
                                                    self.model.selectedParentCategory = category
                                                    self.model.selectedCategory = nil
                                                    self.model.showProducts = true
                                                }
                                            //}
                                        }
                                        
                                        if model.isLoggedIn {
                                            FavoriteCategoryView {
                                                self.model.showMyPurchases = true
                                            }
                                            .padding(.bottom, 34)
                                        }
                                        
                                        NavigationLink(destination: productsView(), isActive: self.$model.showProducts) {}
                                        NavigationLink(destination: myPurchasesView(), isActive: self.$model.showMyPurchases) {}

                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 30)
                                }
                               
                            }
                        }
                    }
                    .navigationBarHidden(true)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                    .padding(.top, 0)
                    .background(Color.appMidnightGreen)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .errorView(errorMessage: $model.errorMessage)
                
                
                if model.loading { LoadingView() }
            }
            .statusBar(hidden: false)
        }
        .navigationBarHidden(true)
        .background(
            EmptyView().fullScreenCover(isPresented: $showPromoPageBanners, onDismiss: {
                
            }, content: {
                if let promoPage = model.selectedPromoPage {
                    bannersList(promoPage: promoPage)
                }
            })
        )
        .onReceive(.deliveryChanged) { _ in
            print("deliveryChanged")
            model.downloadCatalog()
        }
        .onReceive(.cartSent) { _ in
            print("CatalogView_cartSent")
            model.downloadCart()
        }
        .onReceive(.showCategory) { obj in
            if let userInfo = obj.userInfo, let categoryId = userInfo["categoryId"] as? Int {
                print("OPEN CATEGORY \(categoryId)")
                model.receiveShowCategory(categoryId: categoryId)
            }
        }
    }
}

extension CatalogView {
    
    var bgImage: some View {
        Image("Illustration")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding()
    }
    
    var addressView: some View {
        HStack(spacing: 0) {
            Image("icon_leaves")
                .padding(.leading, 17)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(model.deliveryTitle())
                    .foregroundColor(.appGrey)
                    .font(.appFont(size: 12, weight: .bold))
                    .offset(y: 2.0)
                
                Text(model.deliveryAddressTitle())
                    .foregroundColor(.appDarkGrey)
                    .font(.appFont(size: 18, weight: .bold))
                    .offset(y: -2.0)
            }
            .padding(.leading, 14)
            
            Spacer()
            
            NavigationLink(destination: deliveryView(), isActive: $model.showDeliveryAddress) {
                Button {
                    model.showDeliveryAddress = true
                } label: {
                    Image("icon_edit_blackincircle")
                        .padding(.trailing, 8)
                }
            }
            
        }.frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 50)
        .background(Color.white)
    }
    
    var promoPagesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 10) {
                ForEach(model.promoPages, id: \.self) { promoPage in
                    Button(action: {
                        model.selectedPromoPage = promoPage
                        showPromoPageBanners = true
                    }, label: {
                        ZStack {
                            WebImage(url: URL(string: promoPage.imageUrl ?? ""))
                                .circleImageModifier(height: 80, width: 80)
                            Text(promoPage.title ?? "")
                                .foregroundColor(.appWhite)
                                .font(.appFont(size: 12, weight: .bold))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal, 2)
                        }
                        .frame(width: 80, height: 80, alignment: .center)
                    })
                }
            }
            .padding(.horizontal, 16)
        }

        .padding(.top, 20)
        .padding(.bottom, 20)
        .background(Color.white)
    }
}

extension CatalogView {
    func productsView() -> some View {
        LazyView(model.catalogRouter.productsView(parentCategory: model.selectedParentCategory, category: model.selectedCategory))
    }
    
    func myPurchasesView() -> some View {
        LazyView(model.mainRouter.myPurchasesView())
    }
    
    func bannersList(promoPage: PromoPage) -> some View {
        LazyView(model.mainRouter.bannersListView(promoPage: promoPage, banners: nil))
    }
    
    func deliveryView() -> some View {
        LazyView(model.deliveryRouter.deliveryMethodView(presentationState: .stack))
    }
}

struct CatalogView_Previews: PreviewProvider {
    static var previews: some View {
        LifeMartApp.dependencyProvider.assembler.resolver.resolve(CatalogView.self)!
    }
}

