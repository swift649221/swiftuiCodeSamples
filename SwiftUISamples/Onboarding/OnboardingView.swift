//
//  OnboardingView.swift
//  LifeMart
//
//  Created by Andrey on 05.07.2022.
//

import SwiftUI



struct OnboardingView: View {
    
    @ObservedObject var model: OnboardingViewModel
           
    init(viewModel: OnboardingViewModel) {
        self.model = viewModel
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.appMidnightGreen
                .ignoresSafeArea()
            Image("obboarding_bg")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.bottom, 100)
            
            VStack {
                TabView(selection: $model.currentPage) {
                    ForEach(model.pages, id: \.self) { page in
                        OnBoardingPageView(onboardingPage: page)
                            .tag(page.rawValue)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                
                SubmitButton(text: "Далее", enable: true) {
                    if model.currentPage < model.pages.count - 1 {
                        withAnimation {
                            // прокручиваем на следующую страницу
                            model.currentPage += 1
                         }
                    } else {
                        //  сетим новый экран
                        model.setShownOnboarding()
                    }
                }
                .padding(.horizontal, 16)
                
            }
            .padding(.top, 20)
            .padding(.bottom, 15)
            
            
            Button {
                model.setShownOnboarding()
                print("777 onboarding")
            } label: {
                Image("icon_close")
                    .padding()
            }
            
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        LifeMartApp.dependencyProvider.assembler.resolver.resolve(OnboardingView.self)!
    }
}
