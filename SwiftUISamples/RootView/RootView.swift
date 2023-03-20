//
//  RootView.swift
//  LifeMart
//
//  Created by Andrey on 08.04.2022.
//

import SwiftUI

struct RootView: View {
        
    @ObservedObject private var model: RootViewModel
        
    init(viewModel: RootViewModel) {
        self.model = viewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Group {
                    Color.appMidnightGreen
                        .ignoresSafeArea()
                    bgImage
                    logo
                        .offset(y: -50)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                switch model.startScreen {
                case .none:
                    EmptyView()
                case .onboarding:
                    onboardingView()
                        .transition(.move(edge: .trailing))
                case .login:
                    loginView()
                        .transition(.move(edge: .trailing))
                case .tabContent:
                    tabView()
                        .transition(.move(edge: .trailing))
                }
                
                if model.loading { LoadingView() }
            }
            .errorView(errorMessage: $model.errorMessage)
        }
        .onReceive(.receivePushToken) { obj in
            // Change key as per your "userInfo"
            if let userInfo = obj.userInfo, let pushToken = userInfo["pushToken"] as? String {
                print(pushToken)
                model.savePushToken(pushToken)
            }
        }
        .onReceive(.unauthorizeUser) { _ in
            print("deliveryChanged")
            model.logout()
        }
    }
}

extension RootView {
    var bgImage: some View {
        Image("launch_Illustration")
            .resizable()
            .aspectRatio(contentMode: .fill)
            //.padding()
    }
    
    var logo: some View {
        Image("logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 183, height: 124, alignment: .center)
    }
}

extension RootView {
    
    func onboardingView() -> some View {
        model.mainRouter.onboardingView()
    }
    
    func loginView() -> some View {
        model.loginRouter.loginView()
    }
    
    func tabView() -> some View {
        model.mainRouter.tabContentView()
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        LifeMartApp.dependencyProvider.assembler.resolver.resolve(RootView.self)!
    }
}
