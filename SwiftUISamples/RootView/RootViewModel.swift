//
//  RootViewModel.swift
//  LifeMart
//
//  Created by Andrey on 05.05.2022.
//

import Combine
import SwiftUI

final class RootViewModel: ObservableObject {
        
    // MARK: Dependence injection vars
    
    final let mainRouter: MainRouter
    final let loginRouter: LoginRouter
    final let deliveryRouter: DeliveryRouter
    private final let getShownOnboardingUseCase: GetShownOnboardingUseCase
    private final let checkLoggedInUseCase: CheckLoggedInUseCase
    private final let isSkipLoginUseCase: IsSkipLoginUseCase
    private final let logoutUseCase: LogoutUseCase
    private final let downloadCartUseCase: DownloadCartUseCase
    private final let getCartUseCase: GetCartUseCase
    private final let downloadBannersUseCase: DownloadBannersUseCase
    private final let savePushTokenUseCase: SavePushTokenUseCase
    private final let getPushTokenUseCase: GetPushTokenUseCase
    private final let sendPushUseCase: SendPushUseCase
    
    // MARK: User Interaction vars
    
    @Published var loading = false
    @Published var errorMessage: ErrorMessage?
    
    // MARK: Public vars
    
//    @Published var isDeliverySet: Bool?
//    @Published var isLoggedIn = false
//    @Published var shownOnboarding = false
    
    @Published var startScreen: StartScreen = .none
            
    
    // MARK: Private vars
    
    private var cancellables = [AnyCancellable]()
    @Published private var downloaded = false
    @Published private var cart: Cart?
    //@Published private var banners = [Banner]()
    @Published private var currentOrderId: Int?
    private var loggedIn = false

    // MARK: - Init
        
    init(mainRouter: MainRouter, loginRouter: LoginRouter, deliveryRouter: DeliveryRouter, getShownOnboardingUseCase: GetShownOnboardingUseCase, checkLoggedInUseCase: CheckLoggedInUseCase, isSkipLoginUseCase: IsSkipLoginUseCase, logoutUseCase: LogoutUseCase, downloadCartUseCase: DownloadCartUseCase, getCartUseCase: GetCartUseCase,  downloadBannersUseCase: DownloadBannersUseCase, savePushTokenUseCase: SavePushTokenUseCase, getPushTokenUseCase: GetPushTokenUseCase, sendPushUseCase: SendPushUseCase) {
        print("RootViewModel init")
        self.mainRouter = mainRouter
        self.loginRouter = loginRouter
        self.deliveryRouter = deliveryRouter
        self.getShownOnboardingUseCase = getShownOnboardingUseCase
        self.checkLoggedInUseCase = checkLoggedInUseCase
        self.isSkipLoginUseCase = isSkipLoginUseCase
        self.logoutUseCase = logoutUseCase
        self.downloadCartUseCase = downloadCartUseCase
        self.getCartUseCase = getCartUseCase
        self.downloadBannersUseCase = downloadBannersUseCase
        self.savePushTokenUseCase = savePushTokenUseCase
        self.getPushTokenUseCase = getPushTokenUseCase
        self.sendPushUseCase = sendPushUseCase
        
        self.downloadedPublisher
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] downloaded in
                guard let self = self else { return }
                if downloaded {
                    self.setupStartScreen()
                }
            })
            .store(in: &cancellables)

        self.download()
    }
    
    // MARK: - Public helpers
    
    func savePushToken(_ token: String) {
        savePushTokenUseCase.fetch(token: token)
    }
    
    func logout() {
        logoutUseCase.fetch()
    }
    
    // MARK: - Private helpers
    
    private var downloadedPublisher: AnyPublisher<Bool, Never> {
        $downloaded
            .map { $0 }
            .eraseToAnyPublisher()
    }
    
    private func setupStartScreen() {
        startScreenPublisher
            .receive(on: RunLoop.main)
            //.weakAssign(to: \.startScreen, on: self)
            .sink(receiveValue: { [weak self] startScreen in
                print("startScreen = \(startScreen)")
                withAnimation(.spring()) {
                    self?.startScreen = startScreen
                }
                if self?.loggedIn == true, let pushToken = self?.getPushTokenUseCase.fetch() {
                    self?.sendPush(token: pushToken)
                }
            })
            .store(in: &cancellables)
    }
    
    private var startScreenPublisher: AnyPublisher<StartScreen, Never> {
        Publishers.CombineLatest3(getShownOnboardingUseCase.fetch(), checkLoggedInUseCase.fetch(), isSkipLoginUseCase.fetch())
            .map { [weak self] shownOnboarding, loggedIn, isSkipLogin in
                guard let self = self else { return .none }
                self.loggedIn = loggedIn
                if !shownOnboarding /*&& self.banners.count > 0*/ {
                    return .onboarding
                }
                if isSkipLogin {
                    return .tabContent
                }
                if !loggedIn {
                    return .login
                }
                if loggedIn {
                    return .tabContent
                }
                return .none
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - API
    
    private func download() {
        self.loading = true
        downloadCartUseCase.fetch()
            .zip(downloadBannersUseCase.fetch())
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.loading = false
                switch completion {
                case .failure(let error):
                    print("11111")
                    print(error.localizedDescription)
                    self?.errorMessage = ErrorMessage(networkRequestError: error)
                case .finished: break
                }
            }, receiveValue: { [weak self] cartResponse, bannersResponse in
                print("cartResponse = \(cartResponse)")
                print("bannersResponse = \(bannersResponse)")
                self?.currentOrderId = bannersResponse.currentOrderId
                //self?.banners = bannersResponse.banners ?? [Banner]()
                self?.cart = cartResponse
                self?.downloaded = true
            })
            .store(in: &cancellables)
    }
        
    private func sendPush(token: String) {
        //self.loading = true
        sendPushUseCase.fetch(token: token)
            .receive(on: RunLoop.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                //self.loading = false
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
//    func downloadCart() {
//        self.loading = true
//        downloadCartUseCase.fetch()
//            .receive(on: RunLoop.main)
//            .sink { [weak self] completion in
//                guard let self = self else { return }
//                self.loading = false
//                switch completion {
//                case .failure(let error):
//                    print("11111")
//                    print(error.localizedDescription)
//                    self.errorMessage = ErrorMessage(networkRequestError: error)
//                case .finished: break
//                }
//            } receiveValue: { _ in
//            }
//            .store(in: &cancellables)
//    }
//
//    func downloadBanners() {
//        loading = true
//        downloadBannersUseCase.fetch()
//            .receive(on: RunLoop.main)
//            .sink { [weak self] completion in
//                self?.loading = false
//                switch completion {
//                case .failure(let error):
//                    print("11111")
//                    print(error.localizedDescription)
//                    self?.errorMessage = ErrorMessage(networkRequestError: error)
//                case .finished: break
//                }
//            } receiveValue: {  [weak self] response in
//                guard let self = self else { return }
//                // MARK: - FIXME
//                let banners = Parser.shared.banners()
//                print("banners = \(banners)")
//            }
//            .store(in: &cancellables)
//    }
}
