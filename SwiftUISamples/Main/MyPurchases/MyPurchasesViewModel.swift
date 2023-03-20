//
//  MyPurchasesViewModel.swift
//  LifeMart
//
//  Created by Andrey on 05.04.2022.
//

import SwiftUI
import Combine

final class MyPurchasesViewModel: ObservableObject {
    
    // MARK: Dependence injection vars
    
    final let catalogRouter: CatalogRouter
    private final let getSortingTypeUseCase: GetSortingTypeUseCase
    private final let getCartUseCase: GetCartUseCase
    private final let downloadPreferableProductsUseCase: DownloadPreferableProductsUseCase
    private final let addProductToCartUseCase: AddProductToCartUseCase
    
    // MARK: User Interaction vars
    
    @Published var loading = false
    @Published var errorMessage: ErrorMessage?
    @Published var activeSheet: ProductsActiveSheet?

    // MARK: Public vars
    
    @Published var products = [Product]()
    @Published var selectedProduct: Product?
    
    // MARK: Private vars
    
    @Published private var cart: Cart?
    private var cancellables = [AnyCancellable]()
    
    // MARK: - Init
    
    init(catalogRouter: CatalogRouter, getCartUseCase: GetCartUseCase, getSortingTypeUseCase: GetSortingTypeUseCase, downloadPreferableProductsUseCase: DownloadPreferableProductsUseCase, addProductToCartUseCase: AddProductToCartUseCase) {
        self.catalogRouter = catalogRouter
        self.getCartUseCase = getCartUseCase
        self.getSortingTypeUseCase = getSortingTypeUseCase
        self.downloadPreferableProductsUseCase = downloadPreferableProductsUseCase
        self.addProductToCartUseCase = addProductToCartUseCase
        
        self.getCartUseCase.fetch()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] cart in
                self?.cart = cart
                self?.configeDefaultProductQuantities()
            })
            .store(in: &cancellables)
        
        self.downloadPreferableProducts()
    }
    
    // MARK: - Public helpers
    
    func addProduct(_ product: Product) {
        changeProductInCart(product: product, changeProductAction: .add)
    }
    
    func removeProduct(_ product: Product) {
        changeProductInCart(product: product, changeProductAction: .remove)
    }
    
    func configeDefaultProductQuantities() {
        for index in self.products.indices {
            self.products[index].quantity = 0
            if let cart = self.cart, let cartProducts = cart.products {
                if let cartProduct = cartProducts.first(where: { $0.productId == self.products[index].productId }) {
                    self.products[index].quantity = cartProduct.quantity
                }
            }
        }
    }
    
    func sortItems() {
        let sortingType = getSortingTypeUseCase.getSortingType()
        switch sortingType {
        case .decreasePrice:
            products.sort(by: { ($0.price ?? 0) > ($1.price ?? 0) })
        case .increasePrice:
            products.sort(by: { ($0.price ?? 0) < ($1.price ?? 0) })
        case .likes:
            products.sort(by: { ($0.rating ?? 0) > ($1.rating ?? 0) })
        case .stars:
            products.sort(by: { ($0.scoresCount ?? 0) > ($1.scoresCount ?? 0) })
        case .alphabet:
            products.sort(by: { ($0.name?.lowercased() ?? "") < ($1.name?.lowercased() ?? "") })
        case .none:
            products.sort(by: { ($0.sortOrder ?? 0) > ($1.sortOrder ?? 0) })
        }
    }
    
    // MARK: - Private helpers

    private func configeNewProductQuantity(product: Product, newQuantity: Float) {
        if let index = self.products.firstIndex(where: { $0.productId == product.productId }) {
            self.products[index].quantity = newQuantity
        }
    }
    
    // MARK: - API
    
    private func downloadPreferableProducts() {
        self.loading = true
        downloadPreferableProductsUseCase.fetch()
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.loading = false
                switch completion {
                case .failure(let error):
                    self.errorMessage = ErrorMessage(networkRequestError: error)
                case .finished: break
                }
            } receiveValue: { [weak self] products in
                guard let self = self else { return }
                self.products = products
                self.configeDefaultProductQuantities()
            }
            .store(in: &cancellables)
    }
        
    private func changeProductInCart(product: Product, changeProductAction: ChangeProductAction) {
        let id = product.productId
        let newQuantity = product.calculateNewQuantity(changeProductType: changeProductAction)
        let modifiers = [[String : Any]]()
        self.loading = true
        addProductToCartUseCase.fetch(id: id, quantity: newQuantity, modifiers: modifiers)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.loading = false
                switch completion {
                case .failure(let error):
                    self.errorMessage = ErrorMessage(networkRequestError: error)
                case .finished: break
                }
            } receiveValue: { [weak self] cart in
                guard let self = self else { return }
                self.configeNewProductQuantity(product: product, newQuantity: newQuantity)
            }
            .store(in: &cancellables)
    }
}
