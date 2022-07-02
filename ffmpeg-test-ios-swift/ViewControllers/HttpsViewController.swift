//
//  HttpsViewController.swift
//  FFmpegKitSwift
//
//  Created by Mark Khmelnitskii on 30.06.2022.
//

import UIKit
import ffmpegkit

class HttpsViewController : UIViewController {
    
    private var outputLock = NSObject()
    private var header = UILabel()
    private var urlText = UITextField()
    private var getInfoFromUrlButton = UIButton()
    private var getRandomInfoButton1 = UIButton()
    private var getRandomInfoButton2 = UIButton()
    private var getInfoAndFailButton = UIButton()
    private var outputText = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        // STYLE UPDATE
        Util.applyEditTextStyle(urlText)
        Util.applyButtonStyle(getInfoFromUrlButton)
        Util.applyButtonStyle(getRandomInfoButton1)
        Util.applyButtonStyle(getRandomInfoButton2)
        Util.applyButtonStyle(getInfoAndFailButton)
        Util.applyOutputTextStyle(outputText)
        Util.applyHeaderStyle(header)
        
        addUIAction {
            FFmpegKitConfig.enableLogCallback(nil)
            FFmpegKitConfig.enableStatisticsCallback(nil)
        }
        setupViews()
        setupLayout()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func runGetInfoFromUrl() {
        self.runGetMediaInformation(1)
    }
        
    @objc func runGetRandomInfo1() {
        self.runGetMediaInformation(2)
    }
        
    @objc func runGetRandomInfo2() {
        self.runGetMediaInformation(3)
    }
        
    @objc func runGetInfoAndFail() {
        self.runGetMediaInformation(4)
    }
    
    func runGetMediaInformation(_ buttonNumber: Int) {
        // SELECT TEST URL
        var testUrl = ""
        switch (buttonNumber) {
        case 1:
            testUrl = urlText.text ?? ""
            if testUrl.isEmpty {
                testUrl = HTTPS_TEST_DEFAULT_URL
                urlText.text = testUrl
            }
        case 2, 3:
            testUrl = self.getRandomTestUrl()
        default:
            testUrl = HTTPS_TEST_FAIL_URL
            urlText.text = testUrl
        }
        
        print("Testing HTTPS with for button %d using url %@.", buttonNumber, testUrl)
        
        if buttonNumber == 4 {
            
            // ONLY THIS BUTTON CLEARS THE TEXT VIEW
            self.clearOutput()
        }
        
        FFprobeKit.getMediaInformationAsync(testUrl, withCompleteCallback: createNewCompleteCallback())
    }
    
    func appendOutput(_ message: String) {
        outputText.text = outputText.text.appending(message)
        if !outputText.text.isEmpty  {
            let bottom = NSMakeRange(self.outputText.text.count - 1, 1)
            outputText.scrollRangeToVisible(bottom)
        }
    }
    
    func clearOutput() {
        self.outputText.text = ""
    }
    
    func getRandomTestUrl() -> String! {
        switch (arc4random_uniform(3)) {
        case 0:
            return HTTPS_TEST_RANDOM_URL_1
        case 1:
            return HTTPS_TEST_RANDOM_URL_2
        default:
            return HTTPS_TEST_RANDOM_URL_3
        }
    }
    
    func createNewCompleteCallback() -> MediaInformationSessionCompleteCallback {
        return { (session: MediaInformationSession!) in
            addUIAction {
                let _lockTarget = self.outputLock
                
                objc_sync_enter(_lockTarget)
                
                defer {
                    objc_sync_exit(_lockTarget)
                }
                
                guard let information = session.getMediaInformation() else {
                    self.appendOutput("Get media information failed\n")
                    self.appendOutput(String(format: "State: %@\n", FFmpegKitConfig.sessionState(toString: session.getState())))
                    self.appendOutput(String(format: "Duration: %ld\n", session.getDuration()))
                    self.appendOutput(String(format: "Return Code: %@\n", session.getReturnCode()))
                    self.appendOutput(String(format: "Fail stack trace: %@\n", notNull(session.getFailStackTrace(), "\n")))
                    self.appendOutput(String(format: "Output: %@\n", session.getOutput()))
                    return
                }
                
                self.appendOutput(String(format: "Media information for %@\n", information.getFilename()))
                self.appendOutput(String(format: "Format: %@\n", information.getFormat()))
                self.appendOutput(String(format: "Bitrate: %@\n", information.getBitrate()))
                self.appendOutput(String(format: "Duration: %@\n", information.getDuration()))
                self.appendOutput(String(format: "Start time: %@\n", information.getStartTime()))
                
                if let tags = information.getTags() {
                    for (key, value) in tags.enumerated() {
                        self.appendOutput("Tag: \(key):\(value)\n")
                    }
                }
            }
        }
    }
}
//MARK: – Views and layouts
extension HttpsViewController {
    private func setupViews() {
        view.addSubview(header)
        view.addSubview(urlText)
        view.addSubview(getInfoFromUrlButton)
        getInfoFromUrlButton.setTitle("GET INFO FROM URL", for: .normal)
        getInfoFromUrlButton.addTarget(self, action: #selector(runGetInfoFromUrl), for: .touchDown)
        view.addSubview(getRandomInfoButton1)
        getRandomInfoButton1.setTitle("GET RANDOM INFO", for: .normal)
        getRandomInfoButton1.addTarget(self, action: #selector(runGetRandomInfo1), for: .touchDown)
        view.addSubview(getRandomInfoButton2)
        getRandomInfoButton2.setTitle("GET RANDOM INFO", for: .normal)
        getRandomInfoButton2.addTarget(self, action: #selector(runGetRandomInfo2), for: .touchDown)
        view.addSubview(getInfoAndFailButton)
        getInfoAndFailButton.setTitle("GET INFO AND FAIL", for: .normal)
        getInfoAndFailButton.addTarget(self, action: #selector(runGetInfoAndFail), for: .touchDown)
        view.addSubview(outputText)
    }
    private func setupLayout() {
        header.translatesAutoresizingMaskIntoConstraints = false
        urlText.translatesAutoresizingMaskIntoConstraints = false
        getInfoFromUrlButton.translatesAutoresizingMaskIntoConstraints = false
        getRandomInfoButton1.translatesAutoresizingMaskIntoConstraints = false
        getRandomInfoButton2.translatesAutoresizingMaskIntoConstraints = false
        getInfoAndFailButton.translatesAutoresizingMaskIntoConstraints = false
        outputText.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            header.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            header.heightAnchor.constraint(equalToConstant: 50),
            header.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1),
            
            urlText.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 30),
            urlText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            urlText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            urlText.heightAnchor.constraint(equalToConstant: 32),
            
            getInfoFromUrlButton.topAnchor.constraint(equalTo: urlText.bottomAnchor, constant: 20),
            getInfoFromUrlButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            getInfoFromUrlButton.heightAnchor.constraint(equalToConstant: 32),
            getInfoFromUrlButton.widthAnchor.constraint(equalToConstant: 200),
            
            getRandomInfoButton1.topAnchor.constraint(equalTo: getInfoFromUrlButton.bottomAnchor, constant: 10),
            getRandomInfoButton1.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            getRandomInfoButton1.heightAnchor.constraint(equalToConstant: 32),
            getRandomInfoButton1.widthAnchor.constraint(equalToConstant: 200),
            
            getRandomInfoButton2.topAnchor.constraint(equalTo: getRandomInfoButton1.bottomAnchor, constant: 10),
            getRandomInfoButton2.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            getRandomInfoButton2.heightAnchor.constraint(equalToConstant: 32),
            getRandomInfoButton2.widthAnchor.constraint(equalToConstant: 200),
            
            getInfoAndFailButton.topAnchor.constraint(equalTo: getRandomInfoButton2.bottomAnchor, constant: 10),
            getInfoAndFailButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            getInfoAndFailButton.heightAnchor.constraint(equalToConstant: 32),
            getInfoAndFailButton.widthAnchor.constraint(equalToConstant: 200),
            
            outputText.topAnchor.constraint(equalTo: getInfoAndFailButton.bottomAnchor, constant: 20),
            outputText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            outputText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            outputText.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
}

