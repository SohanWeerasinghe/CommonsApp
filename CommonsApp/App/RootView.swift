//
//  RootView.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

//use for maintain which ui need to show user based on user's stage
import SwiftUI

struct RootView : View {
    
    @EnvironmentObject var store : AppStore
    
    var body: some View {
        if store.onboardingStage == .signIn {
            SignInView()
        }
        else if store.onboardingStage == .waitingRoom {
            WaitingRoomView()
        }
        else if store.onboardingStage == .profileSetup {
            ProfileSetupView()
        }
        else {
            //after user fully signed in
            MainTabView()
        }
    }
}
