//
//  TabViewModel.swift
//  LifeMart
//
//  Created by Andrey on 08.03.2022.
//

import Combine

enum Page {
    case home
    case search
    case profile
    case chat
    case cart
}

final class TabViewModel: ObservableObject {
        
    // MARK: Dependence injection vars
    
    final let mainRouter: MainRouter
    final let catalogRouter: CatalogRouter
    final let deliveryRouter: DeliveryRouter
    final let searchRouter: SearchRouter
    final let profileRouter: ProfileRouter
    final let chatRouter: ChatRouter
    final let cartRouter: CartRouter
    private final let checkLoggedInUseCase: CheckLoggedInUseCase
    private final let setSkipLoginUseCase: SetSkipLoginUseCase
    private final let pushReceivedUseCase: PushReceivedUseCase
    private final let setShownTabContentShow: SetShownTabContentShow
    private final let getShownTabContentShow: GetShownTabContentShow
    private final let getCartUseCase: GetCartUseCase
    private final let getChatUnreadMessageUseCase: GetChatUnreadMessageUseCase
    private final let getCurrentOrderIdUseCase: GetCurrentOrderIdUseCase
    private final let getBannersUseCase: GetBannersUseCase
    private final let getCatalogUseCase: GetCatalogUseCase
    
    // MARK: Public vars
    
    @Published var cart: Cart?
    @Published var currentPage: Page = .home
    @Published var oldCurrentPage: Page = .home
    @Published var chatUnreadMessage: Int = 0
    @Published var isPresentingChat = false
    @Published var showDelivery = false
    //@Published var showCurrentOrder = false
    @Published var banners = [Banner]()
    @Published var showBanners = false
    @Published var showProduct = false
    var loggedIn = false
    var pushProduct: Product?
    
    // MARK: Private vars
    
    private var cancellables = [AnyCancellable]()
    private var shownTabContent = true
    private var bannersShown = false
    private var currentOrderReceived = false
    @Published var catalog: Catalog?
    
    // MARK: - Init
    
    init(mainRouter: MainRouter, catalogRouter: CatalogRouter, deliveryRouter: DeliveryRouter, searchRouter: SearchRouter, profileRouter: ProfileRouter, chatRouter: ChatRouter, cartRouter: CartRouter, checkLoggedInUseCase: CheckLoggedInUseCase, setSkipLoginUseCase: SetSkipLoginUseCase, pushReceivedUseCase: PushReceivedUseCase, setShownTabContentShow: SetShownTabContentShow, getShownTabContentShow: GetShownTabContentShow, getCartUseCase: GetCartUseCase, getChatUnreadMessageUseCase: GetChatUnreadMessageUseCase, getCurrentOrderIdUseCase: GetCurrentOrderIdUseCase, getBannersUseCase: GetBannersUseCase, getCatalogUseCase: GetCatalogUseCase) {
        print("TabViewModel_init")
        self.mainRouter = mainRouter
        self.catalogRouter = catalogRouter
        self.deliveryRouter = deliveryRouter
        self.searchRouter = searchRouter
        self.profileRouter = profileRouter
        self.chatRouter = chatRouter
        self.cartRouter = cartRouter
        self.checkLoggedInUseCase = checkLoggedInUseCase
        self.setSkipLoginUseCase = setSkipLoginUseCase
        self.pushReceivedUseCase = pushReceivedUseCase
        self.setShownTabContentShow = setShownTabContentShow
        self.getShownTabContentShow = getShownTabContentShow
        self.getCartUseCase = getCartUseCase
        self.getChatUnreadMessageUseCase = getChatUnreadMessageUseCase
        self.getCurrentOrderIdUseCase = getCurrentOrderIdUseCase
        self.getBannersUseCase = getBannersUseCase
        self.getCatalogUseCase = getCatalogUseCase
        
        self.banners = self.getBannersUseCase.fetch()
        
        self.shownTabContent = self.getShownTabContentShow.fetch()
        if !self.shownTabContent {
            self.setShownTabContentShow.fetch(value: true)
        }
        
        self.checkLoggedInUseCase.fetch()
            .receive(on: RunLoop.main)
            .weakAssign(to: \.loggedIn, on: self)
            .store(in: &cancellables)

        self.getCartUseCase.fetch()
            .receive(on: RunLoop.main)
            //.weakAssign(to: \.cart, on: self)
            .sink(receiveValue: { [weak self] cart in
                guard let self = self else { return }
                self.cart = cart
                self.showDelivery = cart?.deliveryType == nil
                print("TabViewModel_self.showDelivery = \(self.showDelivery)")
                
                if !self.showDelivery && self.banners.count > 0 && self.shownTabContent && !self.bannersShown {
                    self.showBanners = true
                    self.bannersShown = true
                }
            })
            .store(in: &cancellables)
        
        self.getChatUnreadMessageUseCase.fetch()
            .receive(on: RunLoop.main)
            .weakAssign(to: \.chatUnreadMessage, on: self)
            .store(in: &cancellables)
                
        self.getCatalogUseCase.fetch()
            .receive(on: RunLoop.main)
            .weakAssign(to: \.catalog, on: self)
            .store(in: &cancellables)
        
        self.getCurrentOrderIdUseCase.fetch()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] value in
                guard let self = self else { return }
                if value != nil && !self.currentOrderReceived {
                    self.setPage(.profile)
                    self.currentOrderReceived = true
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Public helpers
    
    func skipLogin(_ value: Bool) {
        setSkipLoginUseCase.fetch(value)
    }
    
    func receivePush(_ receivedPush: ReceivedPush) {
        print("receivePush = \(receivedPush)")
        send(receivedPush: receivedPush)
        switch receivedPush.action {
        case .appCart:
            setPage(.cart)
        case .showOrder:
            if let orderId = receivedPush.orderId {
                setPage(.profile)
                NotificationCenter.default.post(name: .pushShowOrder, object: nil, userInfo: ["orderId": orderId])
            }
        case .scoreOrder:
            if let orderId = receivedPush.orderId {
                setPage(.profile)
                NotificationCenter.default.post(name: .pushShowScoreOrder, object: nil, userInfo: ["orderId": orderId])
            }
        case .showMessages:
            isPresentingChat = true
        case .product:
            if let productId = receivedPush.productId {
                if let product = findProduct(productId: Int(productId) ?? 0) {
                    pushProduct = product
                    showProduct = true
                }
                //setPage(.home)
                //NotificationCenter.default.post(name: .pushShowProduct, object: nil, userInfo: ["productId": productId, "categoryId": categoryId])
            }
        default:
            break
        }
    }
    
    func receiveShowProduct(_ productId: Int) {
        if let product = findProduct(productId: productId) {
            pushProduct = product
            showProduct = true
        }
    }
        
    // MARK: - Public helpers
    
    func setPage(_ page: Page) {
        print("setPage = \(setPage)")
        currentPage = page
        oldCurrentPage = page
    }
    
    // MARK: - Private helpers
    
    private func findProduct(productId: Int) -> Product? {
        return catalog?.products?.first(where: { $0.productId == productId})
    }
        
    // MARK: - API
    
    private func send(receivedPush: ReceivedPush) {
        pushReceivedUseCase.fetch(messageId: receivedPush.messageId, userId: Int(receivedPush.userId ?? ""))
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    print("11111")
                    print(error.localizedDescription)
                case .finished: break
                }
            } receiveValue: { _ in
            }
            .store(in: &cancellables)
    }
}
