//
//  ViewController.swift
//  SpeachNote
//
//  Created by Юханов Сергей Сергеевич on 28/12/2018.
//  Copyright © 2018 Юханов Сергей Сергеевич. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var recordButton: UIButton!
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ru"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var regognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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

    @IBAction func recordButtonTapped(_ sender: UIButton) {
    }
    
}

