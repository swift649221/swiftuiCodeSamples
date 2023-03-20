//
//  TabView.swift
//  LifeMart
//
//  Created by Andrey on 05.03.2022.
//

import SwiftUI

struct TabContentView: View {

    @ObservedObject var model: TabViewModel
    @ObservedObject private var keyboard = KeyboardResponder()
    
    //@State var isPresentingChat = false
    
    init(viewModel: TabViewModel) {
        self.model = viewModel
        setupTabBar()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                /// TabView
                TabView(selection: $model.currentPage) {
                    catalogView()
                        .tabItem {
                            Image(model.currentPage == .home ? "home_selected" : "home")
                        }
                        .tag(Page.home)
                        .navigationBarHidden(true)
                    
                    searchView()
                        .tabItem {
                            Image(model.currentPage == .search ? "search_selected" : "search")
                        }
                        .tag(Page.search)
                        .navigationBarHidden(true)
                    
                    profileView()
                        .tabItem {
                            Image(model.currentPage == .profile ? "profile_selected" : "profile")
                        }
                        .tag(Page.profile)
                        .navigationBarHidden(true)
                    
                    Text("")
                        .tabItem {
                            Image(model.currentPage == .chat ? "chat" : "chat")
                            
                        }
                        .tag(Page.chat)
                        .navigationBarHidden(true)
                        .disabled(true)
                    
                    takeOrderView()
                        .tabItem {
                            Image(model.currentPage == .cart ? "order_selected" : "order")
                            
                        }
                        .tag(Page.cart)
                        .navigationBarHidden(true)
                }
                
                /// ChatUnreadMessages
                ZStack {
                    Button {
                        model.currentPage = .chat
                    } label: {
                        Text("\(model.chatUnreadMessage)")
                            .foregroundColor(.white)
                            .font(.appFont(size: 12, weight: .bold))
                            .padding(.horizontal, 5)
                            .frame(height: 16, alignment: .center)
                            .background(model.currentPage == .chat ? Color.appGreen : Color.appDarkGrey)
                            .cornerRadius(8)
                    }
                    
                }
                .frame(width: geometry.size.width/5)
                .offset(x: geometry.size.width - (geometry.size.width/5) * 2, y: -13)
                .opacity((model.chatUnreadMessage == 0 || keyboard.currentHeight > 0) ? 0 : 1)
                
                /// Badge View
                ZStack {
                    Button {
                        model.currentPage = .cart
                    } label: {
                        Text(model.cart?.totalAmount?.clean(numbers: 0).addCurrency ?? "")
                            .foregroundColor(.white)
                            .font(.appFont(size: 12, weight: .bold))
                            .padding(.horizontal, 5)
                            .frame(height: 16, alignment: .center)
                            .background(model.currentPage == .cart ? Color.appGreen : Color.appDarkGrey)
                            .cornerRadius(8)
                    }
                    
                }
                .frame(width: geometry.size.width/5)
                .offset(x: geometry.size.width - geometry.size.width/5, y: -13)
                .opacity( ((model.cart?.totalAmount ?? 0) > 0 && keyboard.currentHeight == 0) ? 1 : 0)
                
            }
            .onChange(of: model.currentPage) {
                if !model.loggedIn {
                    if model.currentPage == .chat {
                        model.skipLogin(false)
                        LifeMartApp.dependencyProvider.container.resetObjectScope(.tabContentView)
                    } else if model.currentPage == .cart {
                        model.skipLogin(false)
                        LifeMartApp.dependencyProvider.container.resetObjectScope(.tabContentView)
                    }
                } else {
                    if model.currentPage == .chat {
                        model.isPresentingChat = true
                    } else {
                        model.oldCurrentPage = $0
                    }
                }
            }
            .sheet(isPresented: $model.showProduct, onDismiss: {
                LifeMartApp.dependencyProvider.container.resetObjectScope(.modalView)
            }, content: {
                if let product = model.pushProduct {
                    self.productView(product: product)
                }
            })
            .background(
                EmptyView().fullScreenCover(isPresented: $model.isPresentingChat, onDismiss: {
                    model.currentPage = model.oldCurrentPage
                }, content: {
                    chatView()
                })
            )
            .background(
                EmptyView().fullScreenCover(isPresented: $model.showDelivery, onDismiss: {
                    model.showDelivery = false
                }, content: {
                    NavigationView {
                        deliveryMethodView()
                    }
                })
            )
            .background(
                EmptyView().fullScreenCover(isPresented: $model.showBanners, onDismiss: {

                }, content: {
                    bannersList()
                })
            )
            .onReceive(.receivePush) { obj in
                if let userInfo = obj.userInfo, let receivedPush = userInfo["receivedPush"] as? ReceivedPush {
                    model.receivePush(receivedPush)
                }
            }
            .onReceive(.showProduct) { obj in
                if let userInfo = obj.userInfo, let productId = userInfo["showProduct"] as? Int {
                    model.receiveShowProduct(productId)
                }
            }
        }
    }
}

extension TabContentView {

    func catalogView() -> some View {
        LazyView(model.catalogRouter.catalogView())
    }
    
    func searchView() -> some View {
        LazyView(model.searchRouter.searchView())
    }
    
    func profileView() -> some View {
        LazyView(model.profileRouter.profileView())
    }
    
    func chatView() -> some View {
        LazyView(model.chatRouter.chatView(isShowSheet: $model.isPresentingChat.animation()))
    }
    
    func takeOrderView() -> some View {
        LazyView(model.cartRouter.takeOrderView())
    }
    
    func deliveryMethodView() -> some View {
        LazyView(model.deliveryRouter.deliveryMethodView(presentationState: PresentationState.fullscreen))
    }
    
    func bannersList() -> some View {
        LazyView(model.mainRouter.bannersListView(promoPage: nil, banners: model.banners))
    }
    
    func productView(product: Product) -> some View {
        LazyView(model.catalogRouter.productView(sourceScreen: .catalog, product: product))
    }
}

extension TabContentView {
    func setupTabBar() {
        UITabBar.appearance().barTintColor = .white
        UITabBar.appearance().backgroundColor = UIColor.white
    }
}
