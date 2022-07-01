//
//  AudioViewController.swift
//  FFmpegKitSwift
//
//  Created by Mark Khmelnitskii on 30.06.2022.
//

import UIKit
import ffmpegkit

class AudioViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    private var codecData = ["aac (audiotoolbox)","mp2 (twolame)","mp3 (liblame)","mp3 (libshine)","vorbis","opus","amr-nb","amr-wb","ilbc","soxr","speex","wavpack"]
    private var selectedCodec: Int = 0
    private var indicator: UIActivityIndicatorView!
    private var header = UILabel()
    private var audioCodecPicker = UIPickerView()
    private var encodeButton = UIButton()
    private var outputText = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioCodecPicker.dataSource = self
        audioCodecPicker.delegate = self
        // STYLE UPDATE
        Util.applyPickerViewStyle(audioCodecPicker)
        Util.applyButtonStyle(encodeButton)
        Util.applyOutputTextStyle(outputText)
        Util.applyHeaderStyle(header)
        // BUTTON DISABLED UNTIL AUDIO SAMPLE IS CREATED
        encodeButton.isEnabled = false
        
        createAudioSample()
        
        addUIAction {
            self.disableStatisticsCallback()
            self.disableLogCallback()
            self.createAudioSample()
            self.enableLogCallback()
        }
        setupViews()
        setupLayout()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func enableLogCallback() {
        FFmpegKitConfig.enableLogCallback { log in
            guard let log = log else { return }
            addUIAction {
                self.appendOutput(log.getMessage())
            }
        }
    }
    
    func disableLogCallback() { FFmpegKitConfig.enableLogCallback(nil) }
    func disableStatisticsCallback() { FFmpegKitConfig.enableStatisticsCallback(nil) }
    
    //The number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    //The number of rows of data
    func pickerView(_ pickerView:UIPickerView, numberOfRowsInComponent component:Int) -> Int {
        return codecData.count
    }
    //The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component:Int) -> String? {
        return codecData[row]
    }
    //Selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component:Int) {
        selectedCodec = row
    }
    
    @IBAction func encodeAudio(sender:AnyObject!) {
        let audioOutputFile = getAudioOutputFilePath()
        do {
            try FileManager.default.removeItem(atPath: audioOutputFile)
        } catch let error {
            print(error.localizedDescription)
        }
        let audioCodec = codecData[selectedCodec]
        print("Testing AUDIO encoding with \(audioCodec) codec")
        
        let ffmpegCommand = generateAudioEncodeScript()
        showProgressDialog(dialogMessage: "Encoding audio")
        clearOutput()
        print("FFmpeg process started with arguments \(ffmpegCommand)")
        
        FFmpegKit.executeAsync(ffmpegCommand) { session in
            guard let session = session,
                  let returnCode = session.getReturnCode() else { return }
            if ReturnCode.isSuccess(returnCode) {
                print("Encode completed successfully.\n")
                addUIAction {
                    self.hideProgressDialogAndAlert(title: "Success", and:"Encode completed successfully.")
                }
            } else {
                print("Encode failed with \(FFmpegKitConfig.sessionState(toString: session.getState())!) and \(returnCode) \(notNull(session.getFailStackTrace(), "\n"))")
                addUIAction {
                    self.hideProgressDialogAndAlert(title: "Error", and: "Encode failed. Please check logs for the details.")
                }
            }
            
        }
    }
    
    func createAudioSample() {
        print("Creating AUDIO sample before the test")
        let audioSampleFile = getAudioSamplePath()
        do {
            try FileManager.default.removeItem(atPath: audioSampleFile)
        } catch let error {
            print(error.localizedDescription)
        }
        let ffmpegCommand = String(format:"-y -f lavfi -i sine=frequency=1000:duration=5 -c:a pcm_s16le %@", audioSampleFile)
        print("Creating audio sample with \(ffmpegCommand)")
        
        guard let session = FFmpegKit.execute(ffmpegCommand),
              let returnCode = session.getReturnCode() else { return }
        
        if ReturnCode.isSuccess(returnCode) {
            self.encodeButton.isEnabled = true
            print("AUDIO sample created")
        } else {
            print("Creating AUDIO sample failed with \(FFmpegKitConfig.sessionState(toString: session.getState())!) and \(returnCode) \(notNull(session.getFailStackTrace(), "\n"))")
            addUIAction {
                Util.alert(self, withTitle:"Error", message:"Creating AUDIO sample failed. Please check logs for the details.", andButtonText:"OK")
            }
        }
    }
    
    func getAudioOutputFilePath() -> String {
        let audioCodec = codecData[selectedCodec]
        var ext = ""
        switch audioCodec {
        case "aac (audiotoolbox)":
            ext = "m4a"
        case "mp2 (twolame)":
            ext = "mpg"
        case "mp3 (liblame)", "mp3 (libshine)":
            ext = "mp3"
        case "vorbis":
            ext = "ogg"
        case "opus":
            ext = "opus"
        case "amr-nb":
            ext = "amr"
        case "amr-wb":
            ext = "amr"
        case "ilbc":
            ext = "lbc"
        case "speex":
            ext = "spx"
        case "wavpack":
            ext = "wv"
        default:
            ext = "wav"
        }
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return docFolder.appending("/audio.").appending(ext)
    }
    
    func getAudioSamplePath() -> String {
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return docFolder.appending("/audio-sample.wav")
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
    
    func showProgressDialog(dialogMessage: String) {
        let pending = UIAlertController(title: nil, message: dialogMessage, preferredStyle: .alert)
        indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .black
        
        indicator.translatesAutoresizingMaskIntoConstraints = false
        pending.view.addSubview(indicator)
        let views: [String: UIView] = ["pending": pending.view, "indicator": indicator]
        let constraintsVertical = NSLayoutConstraint.constraints(withVisualFormat: "V:[indicator]-(20)-|", metrics: nil, views: views)
        let constraintsHorizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|[indicator]|", metrics: nil, views: views)
        let constraints = constraintsVertical + constraintsHorizontal
        pending.view.addConstraints(constraints)
        indicator.startAnimating()
        self.present(pending, animated:true, completion:nil)
    }
    
    func hideProgressDialogAndAlert(title: String, and message:String!) {
        indicator.stopAnimating()
        self.dismiss(animated: true) {
            Util.alert(self, withTitle: title, message: message, andButtonText:"OK")
        }
    }
    
    func generateAudioEncodeScript() -> String {
        let audioCodec = codecData[selectedCodec]
        let audioSampleFile = getAudioSamplePath()
        let audioOutputFile = getAudioOutputFilePath()
        switch audioCodec {
        case "aac (audiotoolbox)":
            return String(format:"-hide_banner -y -i %@ -c:a aac_at -b:a 192k %@", audioSampleFile, audioOutputFile)
        case "mp2 (twolame)":
            return String(format:"-hide_banner -y -i %@ -c:a mp2 -b:a 192k %@", audioSampleFile, audioOutputFile)
        case "mp3 (liblame)":
            return String(format:"-hide_banner -y -i %@ -c:a libmp3lame -qscale:a 2 %@", audioSampleFile, audioOutputFile)
        case "mp3 (libshine)":
            return String(format:"-hide_banner -y -i %@ -c:a libshine -qscale:a 2 %@", audioSampleFile, audioOutputFile)
        case "vorbis":
            return String(format:"-hide_banner -y -i %@ -c:a libvorbis -b:a 64k %@", audioSampleFile, audioOutputFile)
        case "opus":
            return String(format:"-hide_banner -y -i %@ -c:a libopus -b:a 64k -vbr on -compression_level 10 %@", audioSampleFile, audioOutputFile)
        case "amr-nb":
            return String(format:"-hide_banner -y -i %@ -ar 8000 -ab 12.2k -c:a libopencore_amrnb %@", audioSampleFile, audioOutputFile)
        case "amr-wb":
            return String(format:"-hide_banner -y -i %@ -ar 8000 -ab 12.2k -c:a libvo_amrwbenc -strict experimental %@", audioSampleFile, audioOutputFile)
        case "ilbc":
            return String(format:"-hide_banner -y -i %@ -c:a ilbc -ar 8000 -b:a 15200 %@", audioSampleFile, audioOutputFile)
        case "speex":
            return String(format:"-hide_banner -y -i %@ -c:a libspeex -ar 16000 %@", audioSampleFile, audioOutputFile)
        case "wavpack":
            return String(format:"-hide_banner -y -i %@ -c:a wavpack -b:a 64k %@", audioSampleFile, audioOutputFile)
        default:
            return String(format:"-hide_banner -y -i %@ -af aresample=resampler=soxr -ar 44100 %@", audioSampleFile, audioOutputFile)
        }
    }
}
//MARK: – Views and layouts
extension AudioViewController {
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
