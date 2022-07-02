//
//  OtherViewController.swift
//  FFmpegKitSwift
//
//  Created by Mark Khmelnitskii on 30.06.2022.
//

import UIKit
import ffmpegkit

class OtherViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    private var testData = ["chromaprint", "dav1d", "webp", "zscale"]
    private var selectedTest: Int = 0
    private var header = UILabel()
    private var otherTestPicker = UIPickerView()
    private var runButton = UIButton()
    private var outputText = UITextView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.otherTestPicker.dataSource = self
        self.otherTestPicker.delegate = self
        
        // STYLE UPDATE
        Util.applyPickerViewStyle(otherTestPicker)
        Util.applyButtonStyle(runButton)
        Util.applyOutputTextStyle(outputText)
        Util.applyHeaderStyle(header)
        setupViews()
        setupLayout()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /**
     * The number of columns of data
     */
    func numberOfComponentsInPickerView(pickerView:UIPickerView!) -> Int {
        return 1
    }
    
    /**
     * The number of rows of data
     */
    func pickerView(_ pickerView:UIPickerView, numberOfRowsInComponent component:Int) -> Int {
        return testData.count
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    /**
     * The data to return for the row and component (column) that's being passed in
     */
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return testData[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedTest = row
    }
    
    @objc func runTest() {
        self.clearOutput()
        switch selectedTest {
        case 0:
            self.testChromaprint()
        case 1:
            self.testDav1d()
        case 2:
            self.testWebp()
        case 3:
            self.testZscale()
        default:
            break
        }
    }
    
    func testChromaprint() {
        print("Testing 'chromaprint' mutex")
        let audioSampleFile = getChromaprintSamplePath()
        do {
            try FileManager.default.removeItem(atPath: audioSampleFile)
        } catch let error {
            print(error.localizedDescription)
        }
        
        let ffmpegCommand = String(format: "-hide_banner -y -f lavfi -i sine=frequency=1000:duration=5 -c:a pcm_s16le %@", audioSampleFile)
        print("Creating audio sample with \(ffmpegCommand)")
        
        FFmpegKit.executeAsync(ffmpegCommand) { session in
            guard let session = session,
                  let returnCode = session.getReturnCode() else { return }
            if ReturnCode.isSuccess(returnCode) {
                print("AUDIO sample created")
                let chromaprintCommand = String(format: "-hide_banner -y -i %@ -f chromaprint -fp_format 2 %@", audioSampleFile, self.getChromaprintOutputPath())
                print("FFmpeg process started with arguments: \(chromaprintCommand)")
                
                FFmpegKit.executeAsync(chromaprintCommand) { session in
                    guard let session = session,
                          let returnCode = session.getReturnCode() else { return }
                    NSLog("FFmpeg process exited with state %@ and rc %@.", FFmpegKitConfig.sessionState(toString: session.getState()), returnCode)
                } withLogCallback: { log in
                    guard let log = log else { return }
                    addUIAction {
                        self.appendOutput(log.getMessage())
                    }
                } withStatisticsCallback: { _ in }
            }
        }
    }
    func testDav1d() {
        print("Testing decoding 'av1' codec")
        let ffmpegCommand = String(format: "-hide_banner -y -i %@ %@", DAV1D_TEST_DEFAULT_URL, self.getDav1dOutputPath())
        print("FFmpeg process started with arguments: \(ffmpegCommand)")
        
        FFmpegKit.executeAsync(ffmpegCommand) { session in
            guard let session = session,
                  let returnCode = session.getReturnCode() else { return }
            NSLog("FFmpeg process exited with state %@ and rc %@.", FFmpegKitConfig.sessionState(toString: session.getState()), returnCode)
        } withLogCallback: { log in
            guard let log = log else { return }
            addUIAction {
                self.appendOutput(log.getMessage())
            }
        } withStatisticsCallback: { _ in }
    }
    func testWebp() {
        let resourceFolder = Bundle.main.resourcePath!
        let imageFile = resourceFolder.appending("/machupicchu.jpg")
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let outputFile = docFolder.appending("/video.webp")
        
        print("Testing 'webp' codec")
        let ffmpegCommand = String(format: "-hide_banner -y -i %@ %@", imageFile, outputFile)
        print("FFmpeg process started with arguments: \(ffmpegCommand)")
        
        FFmpegKit.executeAsync(ffmpegCommand) { session in
            guard let session = session,
                  let returnCode = session.getReturnCode() else { return }
            NSLog("FFmpeg process exited with state %@ and rc %@.", FFmpegKitConfig.sessionState(toString: session.getState()), returnCode)
        } withLogCallback: { log in
            guard let log = log else { return }
            addUIAction {
                self.appendOutput(log.getMessage())
            }
        } withStatisticsCallback: { _ in }
    }
    func testZscale() {
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let videoFile = docFolder.appending("/video.mp4")
        let zscaledVideoFile = docFolder.appending("/video.zscaled.mp4")
        
        print("Testing 'zscale' filter with video file created on the Video tab")
        let ffmpegCommand = Video.generateZscaleVideoScript(videoFile, zscaledVideoFile)
        print("FFmpeg process started with arguments: \(ffmpegCommand)")
        
        FFmpegKit.executeAsync(ffmpegCommand) { session in
            guard let session = session,
                  let returnCode = session.getReturnCode() else { return }
            NSLog("FFmpeg process exited with state %@ and rc %@.", FFmpegKitConfig.sessionState(toString: session.getState()), returnCode)
        } withLogCallback: { log in
            guard let log = log else { return }
            addUIAction {
                self.appendOutput(log.getMessage())
            }
        } withStatisticsCallback: { _ in }
    }
    
    func getChromaprintSamplePath() -> String {
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return docFolder.appending("/audio-sample.wav")
    }
    
    func getDav1dOutputPath() -> String {
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return docFolder.appending("/video.mp4")
    }
    
    func getChromaprintOutputPath() -> String {
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return docFolder.appending("/chromaprint.txt")
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
}
//MARK: – Views and layouts
extension OtherViewController {
    private func setupViews() {
        view.backgroundColor = .white
        view.addSubview(header)
        view.addSubview(otherTestPicker)
        runButton.setTitle("RUN", for: .normal)
        runButton.addTarget(self, action: #selector(runTest), for: .touchDown)
        view.addSubview(runButton)
        outputText.isEditable = false
        view.addSubview(outputText)
    }
    private func setupLayout() {
        header.translatesAutoresizingMaskIntoConstraints = false
        otherTestPicker.translatesAutoresizingMaskIntoConstraints = false
        runButton.translatesAutoresizingMaskIntoConstraints = false
        outputText.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            header.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            header.heightAnchor.constraint(equalToConstant: 50),
            header.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1),
            
            otherTestPicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            otherTestPicker.widthAnchor.constraint(equalToConstant: 260),
            otherTestPicker.heightAnchor.constraint(equalToConstant: 100),
            otherTestPicker.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 20),
            
            runButton.topAnchor.constraint(equalTo: otherTestPicker.bottomAnchor, constant: 20),
            runButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            runButton.heightAnchor.constraint(equalToConstant: 32),
            runButton.widthAnchor.constraint(equalToConstant: 80),
            
            outputText.topAnchor.constraint(equalTo: runButton.bottomAnchor, constant: 70),
            outputText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            outputText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            outputText.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
}
