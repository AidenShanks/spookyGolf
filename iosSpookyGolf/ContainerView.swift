//
//  ContainerView.swift
//  iosSpookyGolf
//
//  Created by Aiden Shanks on 10/26/23.
//

import SwiftUI

struct ContainerView: View {
    @State private var isSplashScreenViewPresented = true
    
    var body: some View {
        Group {
            if isSplashScreenViewPresented {
                SplashScreenView(isPresented: $isSplashScreenViewPresented)
            } else {
                ContentView()
            }
        }
    }
}

struct ContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ContainerView()
    }
}
