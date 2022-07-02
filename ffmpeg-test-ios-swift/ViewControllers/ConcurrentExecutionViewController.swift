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
    
    @IBAction func encode1Clicked(sender:AnyObject!) {
        self.encodeVideo(1)
    }
    
    @IBAction func encode2Clicked(sender:AnyObject!) {
        self.encodeVideo(2)
    }
    
    @IBAction func encode3Clicked(sender:AnyObject!) {
        self.encodeVideo(3)
    }
    
    @IBAction func cancel1Button(sender:AnyObject!) {
        self.cancel(1)
    }
    
    @IBAction func cancel2Button(sender:AnyObject!) {
        self.cancel(2)
    }
    
    @IBAction func cancel3Button(sender:AnyObject!) {
        self.cancel(3)
    }
    
    @IBAction func cancelAllButton(sender:AnyObject!) {
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
    }
    private func setupLayout() {
        header.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            header.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            header.heightAnchor.constraint(equalToConstant: 50),
            header.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1)
        ])
    }
}
