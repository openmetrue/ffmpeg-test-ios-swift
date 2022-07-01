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
    
    @IBAction func runGetInfoFromUrl(sender:AnyObject!) {
        self.runGetMediaInformation(1)
    }
    
    @IBAction func runGetRandomInfo1(sender:AnyObject!) {
        self.runGetMediaInformation(2)
    }
    
    @IBAction func runGetRandomInfo2(sender:AnyObject!) {
        self.runGetMediaInformation(3)
    }
    
    @IBAction func runGetInfoAndFail(sender:AnyObject!) {
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
                
                //                guard let streams = information.getStreams() else { return }
                //                for stream in streams {
                //                    self.appendOutput(message: String(format: "Stream index: %@\n", stream.getIndex()))
                //                    self.appendOutput(message: String(format: "Stream type: %@\n", stream.getType()))
                //                    self.appendOutput(message: String(format: "Stream codec: %@\n", stream.getCodec()))
                //                    self.appendOutput(message: String(format: "Stream codec long: %@\n", stream.getCodecLong()))
                //                    self.appendOutput(message: String(format: "Stream format: %@\n", stream.getFormat()))
                //                    self.appendOutput(message: String(format: "Stream width: %@\n", stream.getWidth()))
                //                    self.appendOutput(message: String(format: "Stream height: %@\n", stream.getHeight()))
                //                    self.appendOutput(message: String(format: "Stream bitrate: %@\n", stream.getBitrate()))
                //                    self.appendOutput(message: String(format: "Stream sample rate: %@\n", stream.getSampleRate()))
                //                    self.appendOutput(message: String(format: "Stream sample format: %@\n", stream.getSampleFormat()))
                //                    self.appendOutput(message: String(format: "Stream channel layout: %@\n", stream.getChannelLayout()))
                //                    self.appendOutput(message: String(format: "Stream sample aspect ratio: %@\n", stream.getSampleAspectRatio()))
                //                    self.appendOutput(message: String(format: "Stream display ascpect ratio: %@\n", stream.getDisplayAspectRatio()))
                //                    self.appendOutput(message: String(format: "Stream average frame rate: %@\n", stream.getAverageFrameRate()))
                //                    self.appendOutput(message: String(format: "Stream real frame rate: %@\n", stream.getRealFrameRate()))
                //                    self.appendOutput(message: String(format: "Stream time base: %@\n", stream.getTimeBase()))
                //                    self.appendOutput(message: String(format: "Stream codec time base: %@\n", stream.getCodecTimeBase()))
                //
                //                    if let tags = stream.getTags() {
                //                        for (key, value) in tags.enumerated() {
                //                            self.appendOutput(message: "Stream tag: \(key):\(value)\n")
                //                        }
                //                    }
                //                }
                //}
                
                //                guard let chaptets = information.getChapters() else { return }
                //                for chapter in chaptets {
                //                    if chapter.getId() != nil {
                //                        self.appendOutput(String(format: "Chapter id: %@\n", chapter.getId()))
                //                    }
                //
                //                    if chapter.getTimeBase() != nil {
                //                        self.appendOutput(String(format: "Chapter time base: %@\n", chapter.getTimeBase()))
                //                    }
                //
                //                    if chapter.getStart() != nil {
                //                        self.appendOutput(String(format: "Chapter start: %@\n", chapter.getStart()))
                //                    }
                //
                //                    if chapter.getStartTime() != nil {
                //                        self.appendOutput(String(format: "Chapter start time: %@\n", chapter.getStartTime()))
                //                    }
                //
                //                    if chapter.getEnd() != nil {
                //                        self.appendOutput(String(format: "Chapter end: %@\n", chapter.getEnd()))
                //                    }
                //
                //                    if chapter.getEndTime() != nil {
                //                        self.appendOutput(String(format: "Chapter end time: %@\n", chapter.getEndTime()))
                //                    }
                //
                //                    if chapter.getTags() != nil {
                //                        let tags: NSDictionary! = chapter.getTags()
                //
                //                        for key in tags.allKeys {
                //                            self.appendOutput(String(format: "Chapter tag: %@:%@\n", key, tags.objectForKey(key)))
                //                        }
                //                    }
                //                }
            }
        }
    }
}
//MARK: – Views and layouts
extension HttpsViewController {
    private func setupViews() {
        view.backgroundColor = .white
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
