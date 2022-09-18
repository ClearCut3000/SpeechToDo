//
//  SpeechManager.swift
//  SpeechToDo
//
//  Created by Николай Никитин on 16.09.2022.
//

import Foundation
import Speech

enum Language {
  static var current: String {
    return Locale.preferredLanguages[0]
  }
  static let english = "en_US"
  static let german = "de_DE"
  static let italian = "it_IT"
  static let french = "fr_FR"
}

class SpeechManager {

  //MARK: - Properties
  public var isRecording = false
  public var locale = Locale.current

  private var audioEngine: AVAudioEngine!
  private var inputNode: AVAudioInputNode!
  private var audioSession: AVAudioSession!

  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

  //MARK: - Methods
  /// Request authorization to use speech recognition services.
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

  /// Async method for start/stop recording control
  func start(completion: @escaping (String?) -> Void) {
    if isRecording {
      stopRecording()
    } else {
      startRecording(completion: completion)
    }
  }

  /// Async method to initialize SFSpeechRecognizer for recording
  func startRecording(completion: @escaping (String?) -> Void) {
    /// Initialize base class for recognition requests and points the SFSpeechRecognizer to an audio source from which transcription should occur.
    guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
      print("Speech recognition is not available")
      return
    }
    /// Type for reading from a buffer
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    /// Async method for the speech recognition request to initiate the speech recognition process on the audio contained in the request object
    recognizer.recognitionTask(with: recognitionRequest!) { result, error in
      guard error == nil else {
        print("Recognition error \(error!.localizedDescription)")
        return
      }
      guard let result = result else { return }
      /// Checks is result of recognition is final and its transcriptionn won't change
      if result.isFinal {
        /// Async execution of speech recognition result as string
        completion(result.bestTranscription.formattedString)
      }
    }
    /// initializing audio engine with inputNode singleton to process input audio signals from the microphone
    audioEngine = AVAudioEngine()
    inputNode = audioEngine.inputNode
    /// Configuring recording format
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    /// Installs a tap on the output bus of node, using the same recording format.
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [unowned self] (buffer, _) in
      self.recognitionRequest?.append(buffer)
    }
    /// Prepares and starts the audioEngine to start recording
    audioEngine.prepare()
    do {
      audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.record, mode: .spokenAudio, options: .duckOthers)
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
      try audioEngine.start()
    } catch let error {
      print("There was a problem starting recording: \(error.localizedDescription)")
    }
  }

  func stopRecording() {
    /// Marks the end of audio input for the recognition request.
    recognitionRequest?.endAudio()
    /// Deinit request
    recognitionRequest = nil
    /// Stop audio engine and releases any allocated resources
    audioEngine.stop()
    /// Removes tap
    inputNode.removeTap(onBus: 0)
    /// Deactivates audio session
    try? audioSession.setActive(false)
    /// Deinit audio session 
    audioSession = nil
  }
}
