//
//  SpeechToDoApp.swift
//  SpeechToDo
//
//  Created by Николай Никитин on 16.09.2022.
//

import SwiftUI

@main
struct SpeechToDoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
