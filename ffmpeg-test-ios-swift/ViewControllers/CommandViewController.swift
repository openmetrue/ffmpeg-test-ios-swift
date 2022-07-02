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
        setupViews()
        setupLayout()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @objc func runFFmpeg() {
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

    @objc func runFFprobe() {
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

        //AppDelegate.listFFprobeSessions()
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
//MARK: – Views and layouts
extension CommandViewController {
    private func setupViews() {
        view.backgroundColor = .white
        view.addSubview(header)
        view.addSubview(commandText)
        view.addSubview(runFFmpegButton)
        runFFmpegButton.setTitle("RUN FFMPEG", for: .normal)
        runFFmpegButton.addTarget(self, action: #selector(runFFmpeg), for: .touchDown)
        view.addSubview(runFFprobeButton)
        runFFprobeButton.setTitle("RUN FFPROBE", for: .normal)
        runFFprobeButton.addTarget(self, action: #selector(runFFprobe), for: .touchDown)
        outputText.isEditable = false
        view.addSubview(outputText)
    }
    private func setupLayout() {
        header.translatesAutoresizingMaskIntoConstraints = false
        commandText.translatesAutoresizingMaskIntoConstraints = false
        runFFmpegButton.translatesAutoresizingMaskIntoConstraints = false
        runFFprobeButton.translatesAutoresizingMaskIntoConstraints = false
        outputText.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            header.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            header.heightAnchor.constraint(equalToConstant: 50),
            header.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1),
            
            commandText.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 30),
            commandText.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            commandText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            commandText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            commandText.heightAnchor.constraint(equalToConstant: 32),
            
            runFFmpegButton.topAnchor.constraint(equalTo: commandText.bottomAnchor, constant: 30),
            runFFmpegButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            runFFmpegButton.heightAnchor.constraint(equalToConstant: 32),
            runFFmpegButton.widthAnchor.constraint(equalToConstant: 130),
            
            runFFprobeButton.topAnchor.constraint(equalTo: runFFmpegButton.bottomAnchor, constant: 30),
            runFFprobeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            runFFprobeButton.heightAnchor.constraint(equalToConstant: 32),
            runFFprobeButton.widthAnchor.constraint(equalToConstant: 130),
            
            outputText.topAnchor.constraint(equalTo: runFFprobeButton.bottomAnchor, constant: 30),
            outputText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            outputText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            outputText.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
}
