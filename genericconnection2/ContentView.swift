//
//  ContentView.swift
//  genericconnection2
//
//  Created by Jonn Alves on 22/03/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            Task {
                do{
                    let data = try await  requestAmiiboList()
                    data.amiibo.forEach { amiibo in
                        print(amiibo.character)
                    }
                } catch {
                    
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
