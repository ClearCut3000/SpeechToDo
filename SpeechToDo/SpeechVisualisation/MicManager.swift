//
//  MicManager.swift
//  SpeechToDo
//
//  Created by Николай Никитин on 16.09.2022.
//

import Foundation
import AVFoundation

final class MicMonitor: ObservableObject {

  //MARK: - Properties
  private var audioRecorder: AVAudioRecorder
  private var timer: Timer?

  private var currentSample: Int
  private let numberOfSamples: Int

  @Published public var soundSamples: [Float]

  //MARK: - Init
  init(numberOfSamples: Int) {
    self.numberOfSamples = numberOfSamples > 0 ? numberOfSamples : 10
    self.soundSamples = [Float](repeating: .zero, count: numberOfSamples)
    self.currentSample = 0

    let audioSession = AVAudioSession.sharedInstance()
    if audioSession.recordPermission != .granted {
      audioSession.requestRecordPermission { granted in
        if !granted {
          fatalError("We need audio recording for visualisation")
        }
      }
    }
    let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
    let recorderSetting: [String: Any] = [
      AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
      AVSampleRateKey: 44100.0,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
    ]
    do {
      audioRecorder = try AVAudioRecorder(url: url, settings: recorderSetting)
      try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
    } catch {
      fatalError("\(error.localizedDescription)")
    }
  }

  //MARK: - Methods
  public func startMonitoring() {
    audioRecorder.isMeteringEnabled = true
    audioRecorder.record()
    timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { timer in
      self.audioRecorder.updateMeters()
      self.soundSamples[self.currentSample] = self.audioRecorder.averagePower(forChannel: 0)
      self.currentSample = (self.currentSample + 1) % self.numberOfSamples
    })
  }

  public func stopMonitoring() {
    audioRecorder.stop()
  }

  //MARK: - DeInit
  deinit {
    timer?.invalidate()
    audioRecorder.stop()
  }
}
