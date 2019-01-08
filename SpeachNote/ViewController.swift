//
//  ViewController.swift
//  SpeachNote
//
//  Created by Юханов Сергей Сергеевич on 28/12/2018.
//  Copyright © 2018 Юханов Сергей Сергеевич. All rights reserved.
//

import UIKit
import Speech
import MessageUI

class ViewController: UIViewController, MFMailComposeViewControllerDelegate {
 
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ru"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    var resultStr = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.textColor = UIColor.gray
        recordButton.isEnabled = false
        speechRecognizer?.delegate = self
        
        if !MFMailComposeViewController.canSendMail() {
            print("Почтовый сервис недоступен")
            return
        }
        
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
                self.resultStr = (result?.bestTranscription.formattedString)!
                self.textView.textColor = .black
                self.textView.text = self.resultStr
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
            recordButton.setTitle("Остановить", for: .normal)
        }
    }
   
    
  
    @IBAction func clearButtonTapped(_ sender: UIButton) {
        textView.text = "Здесь будет отображаться текст после распознания..."
        textView.textColor = UIColor.gray
    }
    
    
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        
        composeVC.setToRecipients(["s.yukhanov@gmail.com"])
        composeVC.setSubject("Speech Note")
        composeVC.setMessageBody(resultStr, isHTML: false)
        self.present(composeVC, animated: true, completion: nil)
    
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result.rawValue {
        case MFMailComposeResult.cancelled.rawValue:
            print("Cancelled")
        case MFMailComposeResult.saved.rawValue:
            print("Saved")
        case MFMailComposeResult.sent.rawValue:
            print("Sent")
        case MFMailComposeResult.failed.rawValue:
            print("Error: \(String(describing: error?.localizedDescription))")
        default:
            break
        }
        controller.dismiss(animated: true, completion: nil)
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
