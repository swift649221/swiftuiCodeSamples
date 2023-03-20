//
//  CatalogVM.swift
//  LifeMart
//
//  Created by Andrey on 21.03.2022.
//

import SwiftUI
import Combine

enum ParentCategoryId: Int {
    case readyDishes = 123
    case recipeSets = 124
    case products = 125
}

final class CatalogViewModel: ObservableObject {
       
    // MARK: Dependence injection vars
    
    final let mainRouter: MainRouter
    final let catalogRouter: CatalogRouter
    final let deliveryRouter: DeliveryRouter
    private final let downloadCatalogUseCase: DownloadCatalogUseCase
    private final let downloadCartUseCase: DownloadCartUseCase
    private final let downloadBannersUseCase: DownloadBannersUseCase
    private final let getCatalogUseCase: GetCatalogUseCase
    private final let getCartUseCase: GetCartUseCase
    private final let checkLoggedInUseCase: CheckLoggedInUseCase
    
    // MARK: User Interaction vars
    
    @Published var loading = false
    @Published var errorMessage: ErrorMessage?
    @Published var showProducts = false
    @Published var showMyPurchases = false
    
    // MARK: Public vars
    
    @Published var promoPages = [PromoPage]()
    @Published var categories = [ProductCategory]()
    @Published var showDeliveryAddress = false
    @Published var catalog: Catalog?
    @Published var cart: Cart?
    @Published var selectedPromoPage: PromoPage?
    @Published var isLoggedIn = false
    var selectedParentCategory: ProductCategory?
    var selectedCategory: ProductCategory?
    
    // MARK: Private vars
    
    private var cancellables = [AnyCancellable]()
    private var downloadingCatalog = false
    
    // MARK: - Init
    
    init(mainRouter: MainRouter, catalogRouter: CatalogRouter, deliveryRouter: DeliveryRouter, downloadCatalogUseCase: DownloadCatalogUseCase, downloadCartUseCase: DownloadCartUseCase, downloadBannersUseCase: DownloadBannersUseCase, getCatalogUseCase: GetCatalogUseCase, getCartUseCase: GetCartUseCase, checkLoggedInUseCase: CheckLoggedInUseCase) {
        print("CatalogViewModel_init")
        self.mainRouter = mainRouter
        self.catalogRouter = catalogRouter
        self.deliveryRouter = deliveryRouter
        self.downloadCatalogUseCase = downloadCatalogUseCase
        self.downloadCartUseCase = downloadCartUseCase
        self.downloadBannersUseCase = downloadBannersUseCase
        self.getCatalogUseCase = getCatalogUseCase
        self.getCartUseCase = getCartUseCase
        self.checkLoggedInUseCase = checkLoggedInUseCase
        
        // MARK: - FIXME тест
        //XApiKey.shared.combineWithKey(s: "q", key: "w")

        self.getCartUseCase.fetch()
            .receive(on: RunLoop.main)
            .weakAssign(to: \.cart, on: self)
            .store(in: &cancellables)

        self.getCatalogUseCase.fetch()
            .receive(on: RunLoop.main)
            .weakAssign(to: \.catalog, on: self)
            .store(in: &cancellables)

        $cart
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] cart in
                guard let self = self else { return }
                if cart != nil, cart?.deliveryType != nil, self.catalog == nil {
                    self.downloadCatalog()
                }
            }
            .store(in: &cancellables)

        $catalog
            .receive(on: RunLoop.main)
            .sink { [weak self] catalog in
                guard let self = self else { return }
                self.categories = catalog?.categories?.filter({ $0.parentId == 0 }) ?? [ProductCategory]()
            }
            .store(in: &cancellables)
        
        self.checkLoggedInUseCase.fetch()
            .receive(on: RunLoop.main)
            .weakAssign(to: \.isLoggedIn, on: self)
            .store(in: &cancellables)
        
        self.downloadCart()
        self.downloadBanners()
    }
    
    // MARK: - Public Helpers

    func deliveryTitle() -> String {
        switch cart?.deliveryType {
        case Constants.Delivery.delivery:
            return "Доставка:"
        case Constants.Delivery.selfDelivery:
            return "Самовывоз:"
        case Constants.Delivery.selfCarDelivery:
            return "До авто:"
        default:
            return ""
        }
    }
    
    func deliveryAddressTitle() -> String {
        switch cart?.deliveryType {
        case Constants.Delivery.delivery:
            return cart?.deliveryAddress?.fullAddressWithoutCity ?? ""
        case Constants.Delivery.selfDelivery:
            return cart?.deliveryDepartmentName ?? ""
        case Constants.Delivery.selfCarDelivery:
            return cart?.deliveryDepartmentName ?? ""
        default:
            return ""
        }
    }
    
    func receiveShowCategory(categoryId: Int) {
        if let category = catalog?.categories?.first(where: { $0.id == categoryId }) {
            if let parentCategory = categories.first(where: { $0.id == category.parentId }) {
                print("OPEN CATEGORY \(categoryId), parentCategory = \(parentCategory)")
                selectedParentCategory = parentCategory
                selectedCategory = category
                showProducts = true
            }

        }
    }

    // MARK: - Private Helpers

    // MARK: - APi
    
    func downloadCatalog() {
        // MARK: - FIXME запретить без города
        downloadingCatalog = true
        self.loading = true
        downloadCatalogUseCase.fetch(cityId: nil)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.downloadingCatalog = false
                self.loading = false
                switch completion {
                case .failure(let error):
                    print("11111")
                    print(error.localizedDescription)
                    self.errorMessage = ErrorMessage(networkRequestError: error)
                case .finished: break
                }
            } receiveValue: { result in
//                print(result.categories?.count)
            }
            .store(in: &cancellables)
    }
    
    func downloadCart() {
        self.loading = true
        downloadCartUseCase.fetch()
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                if !self.downloadingCatalog {
                    self.loading = false
                }
                switch completion {
                case .failure(let error):
                    print("11111")
                    print(error.localizedDescription)
                    self.errorMessage = ErrorMessage(networkRequestError: error)
                case .finished: break
                }
            } receiveValue: { _ in
            }
            .store(in: &cancellables)
    }
        
    func downloadBanners() {
        //loading = true
        downloadBannersUseCase.fetch()
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                //self?.loading = false
                switch completion {
                case .failure(let error):
                    print("11111")
                    print(error.localizedDescription)
                    self?.errorMessage = ErrorMessage(networkRequestError: error)
                case .finished: break
                }
            } receiveValue: {  [weak self] response in
                guard let self = self else { return }
                self.promoPages = response.promoPages ?? [PromoPage]()
            }
            .store(in: &cancellables)
    }
}

