//
//  ConcurrentExecutionViewController.swift
//  FFmpegKitSwift
//
//  Created by Mark Khmelnitskii on 30.06.2022.
//

import UIKit
import ffmpegkit

class ConcurrentExecutionViewController: UIViewController {
    
    private var sessionId1: Int = 0
    private var sessionId2: Int = 0
    private var sessionId3: Int = 0
    
    private var header = UILabel()
    private var encode1Button = UIButton()
    private var encode2Button = UIButton()
    private var encode3Button = UIButton()
    private var cancel1Button = UIButton()
    private var cancel2Button = UIButton()
    private var cancel3Button = UIButton()
    private var cancelAllButton = UIButton()
    private var outputText = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        // STYLE UPDATE
        Util.applyButtonStyle(encode1Button)
        Util.applyButtonStyle(encode2Button)
        Util.applyButtonStyle(encode3Button)
        Util.applyButtonStyle(cancel1Button)
        Util.applyButtonStyle(cancel2Button)
        Util.applyButtonStyle(cancel3Button)
        Util.applyButtonStyle(cancelAllButton)
        Util.applyOutputTextStyle(outputText)
        Util.applyHeaderStyle(header)
        addUIAction {
            self.enableLogCallback()
        }
        setupViews()
        setupLayout()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func enableLogCallback() {
        FFmpegKitConfig.enableLogCallback { (log:Log!) in
            addUIAction {
                self.appendOutput(String(format:"%ld -> %@", log.getSessionId(), log.getMessage()))
            }
        }
    }
    
    @objc func encode1Clicked() {
        self.encodeVideo(1)
    }
    
    @objc func encode2Clicked() {
        self.encodeVideo(2)
    }
    
    @objc func encode3Clicked() {
        self.encodeVideo(3)
    }
    
    @objc func cancel1ButtonClicked() {
        self.cancel(1)
    }
    
    @objc func cancel2ButtonClicked() {
        self.cancel(2)
    }
    
    @objc func cancel3ButtonClicked() {
        self.cancel(3)
    }
    
    @objc func cancelAllButtonClicked() {
        self.cancel(0)
    }
    
    func encodeVideo(_ buttonNumber: Int) {
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let resourceFolder = Bundle.main.resourcePath!
        let image1 = resourceFolder.appending("/machupicchu.jpg")
        let image2 = resourceFolder.appending("/pyramid.jpg")
        let image3 = resourceFolder.appending("/stonehenge.jpg")
        let videoFile = docFolder.appending(String(format:"/video%d.mp4", buttonNumber))
        
        print("Testing CONCURRENT EXECUTION for button \(buttonNumber)")
        
        let ffmpegCommand = Video.generateVideoEncodeScript(image1, image2, image3, videoFile, "mpeg4", "")
        
        print("FFmpeg process starting for button \(buttonNumber) with arguments\n\(String(describing: ffmpegCommand))")
        
        let session = FFmpegKit.executeAsync(ffmpegCommand) { session in
            guard let session = session,
                  let returnCode = session.getReturnCode() else { return }
            if ReturnCode.isCancel(returnCode) {
                print("FFmpeg process ended with cancel for button %d with sessionId %ld.", buttonNumber, session.getId())
            } else {
                print("FFmpeg process ended with state %lu and rc %@ for button %d with sessionId %ld.%@", session.getState(), returnCode, buttonNumber, session.getId(), notNull(session.getFailStackTrace(), "\n"))
            }
        }
        guard let session = session else { return }
        let sessionId = session.getId()
        print("Async FFmpeg process started for button \(buttonNumber) with sessionId \(sessionId)")
        switch (buttonNumber) {
        case 1:
            sessionId1 = sessionId
        case 2:
            sessionId2 = sessionId
        default:
            sessionId3 = sessionId
        }
        //AppDelegate.listFFmpegSessions()
    }
    
    func cancel(_ buttonNumber: Int) {
        var sessionId: Int = 0
        switch buttonNumber {
        case 1:
            sessionId = sessionId1
        case 2:
            sessionId = sessionId2
        case 3:
            sessionId = sessionId3
        default:
            break
        }
        print("Cancelling FFmpeg process for button \(buttonNumber) with sessionId \(sessionId)")
        if sessionId == 0 {
            FFmpegKit.cancel()
        } else {
            FFmpegKit.cancel(sessionId)
        }
    }
    
    func appendOutput(_ message: String) {
        outputText.text = outputText.text.appending(message)
        if !outputText.text.isEmpty  {
            let bottom = NSMakeRange(self.outputText.text.count - 1, 1)
            outputText.scrollRangeToVisible(bottom)
        }
    }
}
//MARK: – Views and layouts
extension ConcurrentExecutionViewController {
    private func setupViews() {
        view.addSubview(header)
        view.addSubview(encode1Button)
        encode1Button.setTitle("ENCODE 1", for: .normal)
        encode1Button.addTarget(self, action: #selector(encode1Clicked), for: .touchDown)
        view.addSubview(encode2Button)
        encode2Button.setTitle("ENCODE 2", for: .normal)
        encode2Button.addTarget(self, action: #selector(encode2Clicked), for: .touchDown)
        view.addSubview(encode3Button)
        encode3Button.setTitle("ENCODE 3", for: .normal)
        encode3Button.addTarget(self, action: #selector(encode3Clicked), for: .touchDown)
        view.addSubview(cancel1Button)
        cancel1Button.setTitle("CANCEL 1", for: .normal)
        cancel1Button.addTarget(self, action: #selector(cancel1ButtonClicked), for: .touchDown)
        view.addSubview(cancel2Button)
        cancel2Button.setTitle("CANCEL 2", for: .normal)
        cancel2Button.addTarget(self, action: #selector(cancel2ButtonClicked), for: .touchDown)
        view.addSubview(cancel3Button)
        cancel3Button.setTitle("CANCEL 3", for: .normal)
        cancel3Button.addTarget(self, action: #selector(cancel3ButtonClicked), for: .touchDown)
        view.addSubview(cancelAllButton)
        cancelAllButton.setTitle("CANCEL ALL", for: .normal)
        cancelAllButton.addTarget(self, action: #selector(cancelAllButtonClicked), for: .touchDown)
        view.addSubview(outputText)
    }
    private func setupLayout() {
        header.translatesAutoresizingMaskIntoConstraints = false
        encode1Button.translatesAutoresizingMaskIntoConstraints = false
        encode2Button.translatesAutoresizingMaskIntoConstraints = false
        encode3Button.translatesAutoresizingMaskIntoConstraints = false
        cancel1Button.translatesAutoresizingMaskIntoConstraints = false
        cancel2Button.translatesAutoresizingMaskIntoConstraints = false
        cancel3Button.translatesAutoresizingMaskIntoConstraints = false
        cancelAllButton.translatesAutoresizingMaskIntoConstraints = false
        outputText.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            header.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            header.heightAnchor.constraint(equalToConstant: 50),
            header.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1),
            
            encode1Button.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 40),
            encode1Button.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -110),
            encode1Button.heightAnchor.constraint(equalToConstant: 32),
            encode1Button.widthAnchor.constraint(equalToConstant: 100),
            
            encode2Button.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 40),
            encode2Button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            encode2Button.heightAnchor.constraint(equalToConstant: 32),
            encode2Button.widthAnchor.constraint(equalToConstant: 100),
            
            encode3Button.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 40),
            encode3Button.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 110),
            encode3Button.heightAnchor.constraint(equalToConstant: 32),
            encode3Button.widthAnchor.constraint(equalToConstant: 100),
            
            cancel1Button.topAnchor.constraint(equalTo: encode1Button.bottomAnchor, constant: 40),
            cancel1Button.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -150),
            cancel1Button.heightAnchor.constraint(equalToConstant: 32),
            cancel1Button.widthAnchor.constraint(equalToConstant: 90),
            
            cancel2Button.topAnchor.constraint(equalTo: encode2Button.bottomAnchor, constant: 40),
            cancel2Button.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -55),
            cancel2Button.heightAnchor.constraint(equalToConstant: 32),
            cancel2Button.widthAnchor.constraint(equalToConstant: 90),
            
            cancel3Button.topAnchor.constraint(equalTo: encode2Button.bottomAnchor, constant: 40),
            cancel3Button.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 40),
            cancel3Button.heightAnchor.constraint(equalToConstant: 32),
            cancel3Button.widthAnchor.constraint(equalToConstant: 90),
            
            cancelAllButton.topAnchor.constraint(equalTo: encode3Button.bottomAnchor, constant: 40),
            cancelAllButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 145),
            cancelAllButton.heightAnchor.constraint(equalToConstant: 32),
            cancelAllButton.widthAnchor.constraint(equalToConstant: 110),
            
            outputText.topAnchor.constraint(equalTo: cancelAllButton.bottomAnchor, constant: 40),
            outputText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            outputText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            outputText.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40)
        ])
    }
}
