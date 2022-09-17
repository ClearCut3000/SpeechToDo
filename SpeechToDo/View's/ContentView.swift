//
//  ContentView.swift
//  SpeechToDo
//
//  Created by Николай Никитин on 16.09.2022.
//

import SwiftUI
import CoreData

struct ContentView: View {

  //MARK: - Properties
  @Environment(\.managedObjectContext) private var viewContext
  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Todo.created, ascending: true)], animation: .default) private var todos: FetchedResults<Todo>

  @State private var recording = false

  @ObservedObject private var mic = MicMonitor(numberOfSamples: 30)

  private var speechManager = SpeechManager()

  //MARK: - View Body
  var body: some View {
    NavigationView {
      ZStack(alignment: .bottomTrailing) {
        List {
          ForEach(todos) { item in
            HStack {
              Image(systemName: "\(todos.firstIndex(of: item) ?? 0).circle.fill")
              VStack {
                Text(item.text ?? " - E M P T Y - ")
                Text(item.created?.formatted(date: .numeric, time: .shortened) ?? "n/a")
              }
            }
          }
          .onDelete(perform: deleteItems)
        }
        .listStyle(.plain)
        .navigationTitle("SpeechToDo List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          EditButton()
            .simultaneousGesture(TapGesture().onEnded({
              //TODO: -
            }))
        }
        RoundedRectangle(cornerRadius: 25)
          .fill(Color.black.opacity(0.7))
          .padding()
          .overlay(VStack {
            visualizerView()
          })
          .opacity(recording ? 1 : 0)
        VStack {
          recordButton()
        }
        .onAppear {
          speechManager.checkPermissions()
        }
      }
    }
  }

  //MARK: - Methods
  private func recordButton() -> some View {
    Button {
      addItem()
    } label: {
      Image(systemName: recording ? "stop.fill" : "mic.fill")
        .font(.system(size: 40))
        .padding()
        .cornerRadius(10)
    }
    .foregroundColor(.red)
  }

  private func addItem() {
    if speechManager.isRecording {
      self.recording = false
      mic.stopMonitoring()
      speechManager.stopRecording()
    } else {
      self.recording = true
      mic.startMonitoring()
      speechManager.start { speechText in
        guard let text = speechText, !text.isEmpty else {
          self.recording = false
          return
        }
        DispatchQueue.main.async {
          withAnimation {
            let newItem = Todo(context: viewContext)
            newItem.id = UUID()
            newItem.text = text
            newItem.created = Date()

            do {
              try viewContext.save()
            } catch {
              print(error.localizedDescription)
            }
          }
        }
      }
    }
    speechManager.isRecording.toggle()
  }

  private func normolizedSoundLevel(level: Float) -> CGFloat {
    let level = max(0.2, CGFloat(level) + 50) / 2
    return CGFloat(level * (100 / 25))
  }

  private func visualizerView() -> some View {
    VStack {
      HStack(spacing: 4) {
        ForEach(mic.soundSamples, id: \.self) { level in
          VisualBarView(value: self.normolizedSoundLevel(level: level))
        }
      }
    }
  }

  private func deleteItems(offsets: IndexSet) {
    withAnimation {
      offsets.map {todos[$0]}.forEach(viewContext.delete)
      do {
        try viewContext.save()
      } catch {
        print(error.localizedDescription)
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
