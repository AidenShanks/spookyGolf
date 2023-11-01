//
//  SplashScreenView.swift
//  iosSpookyGolf
//
//  Created by Aiden Shanks on 10/26/23.
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image("spookyGolfBackgroundV2")
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        .onAppear(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { // 3 seconds delay
                withAnimation {
                    isPresented = false
                }
            }
        })
    }
}


struct SplashScreenView_Previews: PreviewProvider {
    @State static var dummyIsPresented = true

    static var previews: some View {
        SplashScreenView(isPresented: $dummyIsPresented)
    }
}
