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

  @State private var editMode = EditMode.inactive

  @State private var recording = false

  @State private var selectedLanguage = Language.current

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
                .frame(width: 40, height: 40)
                .padding(.trailing, 10)
                .foregroundColor(.red)
              VStack {
                Text(item.text ?? " - E M P T Y - ")
                  .font(.headline)
                Text(item.created?.formatted(date: .numeric, time: .shortened) ?? "n/a")
                  .font(.caption2)
              }
            }
          }
          .onDelete(perform: deleteItems)
        }
        .disabled(speechManager.isRecording)
        .environment(\.editMode, $editMode)
        .onChange(of: todos.count, perform: { newValue in
          if todos.isEmpty && editMode == .active {
            editMode = .inactive
          }
        })
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Picker("Language", selection: $selectedLanguage) {
              Text("\(Language.current.prefix(2).capitalized)").tag(Language.current)
              Text("En").tag("en_US")
              Text("De").tag("de_DE")
              Text("It").tag("it_IT")
              Text("Fr").tag("fr_FR")
            }
            .pickerStyle(SegmentedPickerStyle())
            .colorMultiply(.red)
            .disabled(recording)
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              if editMode == .active {
                editMode = .inactive
              } else {
                editMode = .active
              }
            } label: {
              Image(systemName: !todos.isEmpty ? "pencil" : "pencil.slash")
                .foregroundColor((editMode == .active || todos.isEmpty) ? .red : .green)
            }
            .disabled(todos.isEmpty || recording)
          }
        }
        .listStyle(.plain)
        .navigationTitle("SpeechToDo List")
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
                  .foregroundColor(recording ? .red : .secondary)
        )
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
      speechManager.locale = Locale(identifier: selectedLanguage)
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
        print("Deleted")
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
