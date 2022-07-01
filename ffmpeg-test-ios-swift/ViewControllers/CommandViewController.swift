//
//  CommandViewController.swift
//  FFmpegKitSwift
//
//  Created by Mark Khmelnitskii on 30.06.2022.
//

import UIKit
import ffmpegkit

class CommandViewController: UIViewController {
    
    private var header = UILabel()
    private var commandText = UITextField()
    private var runFFmpegButton = UIButton()
    private var runFFprobeButton = UIButton()
    private var outputText = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // STYLE UPDATE
        Util.applyEditTextStyle(commandText)
        Util.applyButtonStyle(runFFmpegButton)
        Util.applyButtonStyle(runFFprobeButton)
        Util.applyOutputTextStyle(outputText)
        Util.applyHeaderStyle(header)

        addUIAction {
            FFmpegKitConfig.enableLogCallback(nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func runFFmpeg(sender:AnyObject!) {
        clearOutput()
        commandText.endEditing(true)
        guard let text = commandText.text else { return }
        let ffmpegCommand = String(format:"-hide_banner %@", text)
        
        print("Current log level is \(FFmpegKitConfig.getLogLevel())")
        print("Testing FFmpeg COMMAND asynchronously")
        print("FFmpeg process started with arguments: \(ffmpegCommand)")
        
        FFmpegKit.executeAsync(ffmpegCommand) { session in
            guard let session = session,
                  let returnCode = session.getReturnCode() else { return }
            
            if session.getState() == .failed || !returnCode.isValueSuccess() {
                addUIAction {
                    Util.alert(self, withTitle:"Error", message:"Command failed. Please check output for the details.", andButtonText:"OK")
                }
            }
        } withLogCallback: { log in
            guard let log = log else { return }
            addUIAction {
                self.appendOutput(log.getMessage())
            }
        } withStatisticsCallback: { _ in }
    }

    @IBAction func runFFprobe(sender:AnyObject!) {
        clearOutput()
        commandText.endEditing(true)
        guard let text = commandText.text else { return }
        let ffprobeCommand = String(format:"-hide_banner %@", text)

        print("Testing FFprobe COMMAND asynchronously")
        print("FFprobe process started with arguments: \(ffprobeCommand)")

        let session = FFprobeSession.init(FFmpegKitConfig.parseArguments(ffprobeCommand)) { session in
            guard let session = session,
                  let returnCode = session.getReturnCode() else { return }

            addUIAction {
                self.appendOutput(session.getOutput())
            }

            if session.getState() == .failed || !returnCode.isValueSuccess() {
                addUIAction {
                    Util.alert(self, withTitle:"Error", message:"Command failed. Please check output for the details.", andButtonText:"OK")
                }
            }
        } withLogCallback: { _ in }
        
        FFmpegKitConfig.asyncFFprobeExecute(session)

        AppDelegate.listFFprobeSessions()
    }

    func appendOutput(_ message: String) {
        outputText.text = outputText.text.appending(message)
        if !outputText.text.isEmpty  {
            let bottom = NSMakeRange(self.outputText.text.count - 1, 1)
            outputText.scrollRangeToVisible(bottom)
        }
    }

    func clearOutput() {
        outputText.text = ""
    }
}
