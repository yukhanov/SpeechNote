//
//  ViewController.swift
//  SpeachNote
//
//  Created by Юханов Сергей Сергеевич on 28/12/2018.
//  Copyright © 2018 Юханов Сергей Сергеевич. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {

    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ru"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.textColor = UIColor.gray
        recordButton.isEnabled = false
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { status in
            var buttonState = false
            
            switch status {
            case .authorized:
                buttonState = true
                print("Разрешение получено")
            case .denied:
                buttonState = false
                print("Пользователь не дал разрения")
            case .notDetermined:
                buttonState = false
                print("Распознование речи еще не разрешено")
            case .restricted:
                buttonState = false
                print("Распознование не поддерживается на этом устройстве")
            }
            DispatchQueue.main.async {
                self.recordButton.isEnabled = buttonState
            }
        }
    }
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do { // 3
            try audioSession.setCategory(AVAudioSession.Category.record, mode: AVAudioSession.Mode.measurement, policy: AVAudioSession.RouteSharingPolicy.default, options: AVAudioSession.CategoryOptions.mixWithOthers)
            try audioSession.setActive(true)
        } catch {
            print("Не удалось настроить аудиосессию")
        }
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Не могу создать экземпляр запроса")
        }
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            if result != nil {
                self.textView.textColor = .black
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = ((result?.isFinal)!)
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
            }
        })
        let format = inputNode.outputFormat(forBus: 0) // 12
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { // 13
            buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare() //14
        
        do {  // 15
            try audioEngine.start()
        } catch {
            print("Не удается стартнуть движок")
        }
        
        textView.text = "Помедленнее... Я записываю...." // 16
  
    }

    @IBAction func recordButtonTapped(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            recordButton.setTitle("Начать запись", for: .normal)
        } else {
            startRecording()
            recordButton.setTitle("Остановить запись", for: .normal)
        }
    }
    
}

extension ViewController: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
        } else {
            recordButton.isEnabled = false
        }
    }
}
