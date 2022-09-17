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
  @State private var isEditing = false

  @ObservedObject private var mic = MicMonitor(numberOfSamples: 30)

  private var speechManager = SpeechManager()

  //MARK: - View Body
  var body: some View {
    NavigationView {
      ZStack(alignment: .bottom) {
        List {
          ForEach(todos) { item in
            HStack {
              Image(systemName: "\(todos.firstIndex(of: item) ?? 0).circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.red)
              VStack {
                Text(item.text ?? " - E M P T Y - ")
                  .font(.headline)
                Text(item.created?.formatted(date: .numeric, time: .shortened) ?? "n/a")
                  .font(.subheadline)
              }
            }
          }
          .onDelete(perform: deleteItems)
        }
        .disabled(speechManager.isRecording)
        .environment(\.editMode, .constant((todos.count != 0 && isEditing) ? EditMode.active : EditMode.inactive))
        .listStyle(.plain)
        .navigationTitle("SpeechToDo List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          Button {
            isEditing.toggle()
          } label: {
            Image(systemName: "pencil")
              .foregroundColor(isEditing ? .red : .green)
          }
            .disabled(todos.count == 0 || recording)
        }
        RoundedRectangle(cornerRadius: 25)
          .fill(Color.black.opacity(0.7))
          .frame(maxWidth: UIScreen.main.bounds.size.width - 20 ,maxHeight: 300)
          .overlay(RoundedRectangle(cornerRadius: 25)
                    .strokeBorder(Color.secondary)
          )
          .overlay(VStack {
            visualizerView()
          })
          .padding(.bottom, UIScreen.main.bounds.size.width / 2)
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
          .resizable()
          .scaledToFit()
          .frame(width: 30, height: 30)
          .padding(10)
          .background(Color(UIColor.systemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 30))
          .overlay(RoundedRectangle(cornerRadius: 30)
                    .stroke(lineWidth: recording ? 5 : 2)
                    .foregroundColor(recording ? .red : .secondary))
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
