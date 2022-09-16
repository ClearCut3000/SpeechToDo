//
//  SpeechManager.swift
//  SpeechToDo
//
//  Created by Николай Никитин on 16.09.2022.
//

import Foundation
import Speech

class SpeechManager {
  public var isRecording = false

  private var audioEngine: AVAudioEngine!
  private var inputNode: AVAudioInputNode!
  private var audioSession: AVAudioSession!

  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

  func checkPermissions() {
    SFSpeechRecognizer.requestAuthorization { status in
      DispatchQueue.main.async {
        switch status {
        case .authorized:
          break
        default:
          print("Speechrecognition is not available!")
        }
      }
    }
  }

  func start(completion: @escaping (String?) -> Void) {
    if isRecording {
      stopRecording()
    } else {
      startRecording(completion: completion)
    }
  }

  func startRecording(completion: @escaping (String?) -> Void) {
    guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
      print("Speech recognition is not available")
      return
    }
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    recognitionRequest!.shouldReportPartialResults = true
    recognizer.recognitionTask(with: recognitionRequest!) { result, error in
      guard error == nil else {
        print("Recognition error \(error!.localizedDescription)")
        return
      }
      guard let result = result else { return }
      if result.isFinal {
        completion(result.bestTranscription.formattedString)
      }
    }
    audioEngine = AVAudioEngine()
    inputNode = audioEngine.inputNode
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
      self.recognitionRequest?.append(buffer)
    }
    audioEngine.prepare()
    do {
      audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.record, mode: .spokenAudio, options: .duckOthers)
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
      try audioEngine.start()
    } catch {

    }
  }

  func stopRecording() {
    recognitionRequest?.endAudio()
    recognitionRequest = nil
    audioEngine.stop()
    inputNode.removeTap(onBus: 0)
    try? audioSession.setActive(false)
    audioSession = nil

  }
}
