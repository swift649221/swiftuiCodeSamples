//
//  OnBoardingPageView.swift
//  LifeMart
//
//  Created by Andrey on 05.03.2022.
//

import SwiftUI

struct OnBoardingPageView: View {
    
    let onboardingPage: OnboardingPage
    
    var title: String {
        switch onboardingPage {
        case .first:
            return "Отслеживай \nсвой заказ"
        case .second:
            return "Оставляй обратную связь одним кликом"
        case .third:
            return "Вынесем заказ прямо к вашему авто"
        }
    }
    
    var subTitle: String {
        switch onboardingPage {
        case .first:
            return "Покажем, где курьер \nв режиме онлайн"
        case .second:
            return "Вводим и выводим продукты \nна основе оценок покупателей"
        case .third:
            return "Забирай продукты, \nне выходя из машины"
        }
    }
    
    var image: Image {
        switch onboardingPage {
        case .first:
            return Image("onboarding_first")
        case .second:
            return Image("onboarding_second")
        case .third:
            return Image("onboarding_third")
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                VStack {
                    image
                }
                .frame(height: geo.size.height / 2)
                
                VStack {
                    Text(title)
                        .foregroundColor(.appWhite)
                        .font(.appFont(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                    
                    Text(subTitle)
                        .foregroundColor(.appWhite)
                        .font(.appFont(size: 18, weight: .regular))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct OnBoardingPageView_Previews: PreviewProvider {
    static var previews: some View {
        OnBoardingPageView(onboardingPage: .first)
    }
}
