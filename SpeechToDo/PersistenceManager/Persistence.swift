//
//  Persistence.swift
//  SpeechToDo
//
//  Created by Николай Никитин on 16.09.2022.
//

import CoreData

struct PersistenceController {
  
  static let shared = PersistenceController()

  let container: NSPersistentContainer

  init() {
    container = NSPersistentContainer(name: "SpeechToDo")
    container.loadPersistentStores { persistentStoreDescription, error in
      if let error = error as NSError? {
        fatalError("Unresolver error case \(error), \(error.userInfo)")
      }
    }
  }
}
