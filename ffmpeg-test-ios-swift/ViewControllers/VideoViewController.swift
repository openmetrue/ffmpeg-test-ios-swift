//
//  VideoViewController.swift
//  FFmpegKitSwift
//
//  Created by Mark Khmelnitskii on 30.06.2022.
//

import UIKit
import AVFoundation
import ffmpegkit

class VideoViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    private var codecData = ["mpeg4", "h264 (x264)", "h264 (openh264)", "h264 (videotoolbox)", "x265", "xvid", "vp8", "vp9", "aom", "kvazaar", "theora", "hap"]
    private var selectedCodec: Int = 0
    
    private var player = AVQueuePlayer()
    private var activeItem: AVPlayerItem? = nil
    
    private var alertController = UIAlertController()
    private var indicator = UIActivityIndicatorView()
    private var statistics: Statistics? = nil
    private var header = UILabel()
    private var videoCodecPicker = UIPickerView()
    private var encodeButton = UIButton()
    private var videoPlayerFrame = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        self.videoCodecPicker.dataSource = self
        self.videoCodecPicker.delegate = self
        // STYLE UPDATE
        Util.applyButtonStyle(encodeButton)
        Util.applyPickerViewStyle(videoCodecPicker)
        Util.applyVideoPlayerFrameStyle(videoPlayerFrame)
        Util.applyHeaderStyle(header)
        addUIAction {
            self.setActive()
        }
        setupViews()
        setupLayout()
    }
    
    override func viewDidLayoutSubviews() {
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoPlayerFrame.layer.bounds
        videoPlayerFrame.layer.addSublayer(playerLayer)
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
        return codecData.count
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    /**
     * The data to return for the row and component (column) that's being passed in
     */
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return codecData[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCodec = row
    }

    @objc func encodeVideo() {
        let resourceFolder = Bundle.main.resourcePath!
        let image1 = resourceFolder.appending("/machupicchu.jpg")
        let image2 = resourceFolder.appending("/pyramid.jpg")
        let image3 = resourceFolder.appending("/stonehenge.jpg")
        let videoFile = getVideoPath()

        player.removeAllItems()
        activeItem = nil
        do {
            try FileManager.default.removeItem(atPath: videoFile)
        } catch let error {
            print(error.localizedDescription)
        }
        let videoCodec = codecData[selectedCodec]
        print("Testing VIDEO encoding with \(videoCodec) codec")
        showProgressDialog("Encoding video")

        let ffmpegCommand = Video.generateVideoEncodeScriptWithCustomPixelFormat(image1, image2, image3, videoFile, getSelectedVideoCodec(), getPixelFormat(), getCustomOptions())
        print("FFmpeg process started with arguments: \(ffmpegCommand)")

        let session = FFmpegKit.executeAsync(ffmpegCommand) { session in
            guard let session = session,
                  let returnCode = session.getReturnCode() else { return }
            print("FFmpeg process exited with state \(FFmpegKitConfig.sessionState(toString: session.getState()) ?? "") and \(returnCode)")
            addUIAction {
                self.hideProgressDialog()
            }
            if ReturnCode.isSuccess(returnCode) {
                print("Encode completed successfully in \(session.getDuration()) milliseconds; playing video")
                addUIAction {
                    self.playVideo()
                }
            } else {
                print("Encode failed with state \(session.getState()) and \(returnCode)")
                addUIAction {
                    self.hideProgressDialogAndAlert("Encode failed. Please check logs for the details.")
                }
            }
        } withLogCallback: { log in
            guard let log = log else { return }
            print(log.getMessage() ?? "")
        } withStatisticsCallback: { stat in
            addUIAction {
                self.statistics = stat
                self.updateProgressDialog()
            }
        }

        print("Async FFmpeg process started with sessionId \(session?.getId() ?? 0)")
    }
    
    func playVideo() {
        let videoFile = getVideoPath()
        let videoURL = NSURL.fileURL(withPath: videoFile)
        
        let asset = AVAsset(url: videoURL)
        let assetKeys = ["playable", "hasProtectedContent"]
        let newVideo = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys:assetKeys)
        activeItem = newVideo
        newVideo.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
        player.insert(newVideo, after: nil)
    }

    func getPixelFormat() -> String! {
        let videoCodec = codecData[selectedCodec]
        var pixelFormat = ""
        if (videoCodec == "x265") {
            pixelFormat = "yuv420p10le"
        } else {
            pixelFormat = "yuv420p"
        }

        return pixelFormat
    }

    func getSelectedVideoCodec() -> String {
        var videoCodec = codecData[selectedCodec]
        // VIDEO CODEC PICKER HAS BASIC NAMES, FFMPEG NEEDS LONGER AND EXACT CODEC NAMES.
        // APPLYING NECESSARY TRANSFORMATION HERE
        if (videoCodec == "h264 (x264)") {
            videoCodec = "libx264"
        } else if (videoCodec == "h264 (openh264)") {
            videoCodec = "libopenh264"
        } else if (videoCodec == "h264 (videotoolbox)") {
            videoCodec = "h264_videotoolbox"
        } else if (videoCodec == "x265") {
            videoCodec = "libx265"
        } else if (videoCodec == "xvid") {
            videoCodec = "libxvid"
        } else if (videoCodec == "vp8") {
            videoCodec = "libvpx"
        } else if (videoCodec == "vp9") {
            videoCodec = "libvpx-vp9"
        } else if (videoCodec == "aom") {
            videoCodec = "libaom-av1"
        } else if (videoCodec == "kvazaar") {
            videoCodec = "libkvazaar"
        } else if (videoCodec == "theora") {
            videoCodec = "libtheora"
        }
        return videoCodec
    }

    func getVideoPath() -> String {
        let videoCodec: String = codecData[selectedCodec]
        var ext = ""
        if (videoCodec == "vp8") || (videoCodec == "vp9") {
            ext = "webm"
        } else if (videoCodec == "aom") {
            ext = "mkv"
        } else if (videoCodec == "theora") {
            ext = "ogv"
        } else if (videoCodec == "hap") {
            ext = "mov"
        } else {
            // mpeg4, x264, x265, xvid, kvazaar
            ext = "mp4"
        }
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return docFolder.appending("/video.").appending(ext)
    }

    func getCustomOptions() -> String! {
        let videoCodec:String! = codecData[selectedCodec]

        if (videoCodec == "x265") {
            return "-crf 28 -preset fast "
        } else if (videoCodec == "vp8") {
            return "-b:v 1M -crf 10 "
        } else if (videoCodec == "vp9") {
            return "-b:v 2M "
        } else if (videoCodec == "aom") {
            return "-crf 30 -strict experimental "
        } else if (videoCodec == "theora") {
            return "-qscale:v 7 "
        } else if (videoCodec == "hap") {
            return "-format hap_q "
        } else {
            return ""
        }
    }

    func setActive() {
        FFmpegKitConfig.enableLogCallback(nil)
        FFmpegKitConfig.enableStatisticsCallback(nil)
    }
    func showProgressDialog(_ dialogMessage: String) {
        // CLEAN STATISTICS
        statistics = nil
        
        alertController = UIAlertController(title: nil, message: dialogMessage, preferredStyle: .alert)
        indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .black
        indicator.translatesAutoresizingMaskIntoConstraints = false
        alertController.view.addSubview(indicator)
        let views: [String: UIView] = ["pending": alertController.view, "indicator": indicator]
        let constraintsVertical = NSLayoutConstraint.constraints(withVisualFormat: "V:[indicator]-(20)-|", metrics: nil, views: views)
        let constraintsHorizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|[indicator]|", metrics: nil, views: views)
        let constraints = constraintsVertical + constraintsHorizontal
        
        alertController.view.addConstraints(constraints)
        indicator.startAnimating()
        self.present(alertController, animated: true, completion: nil)
    }

    func updateProgressDialog() {
        guard let statistics = statistics else { return }
        let timeInMilliseconds = statistics.getTime()
        if timeInMilliseconds > 0 {
            let totalVideoDuration = 9000
            let percentage = Int(timeInMilliseconds)*100/totalVideoDuration
            alertController.message = String(format:"Encoding video  %% %d \n\n", percentage)
        }
    }

    func hideProgressDialog() {
        indicator.stopAnimating()
        self.dismiss(animated: true, completion:nil)
    }

    func hideProgressDialogAndAlert(_ message: String) {
        indicator.stopAnimating()
        self.dismiss(animated: true) {
            Util.alert(self, withTitle: "Error", message: message, andButtonText: "OK")
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let change = change else { return }
        let statusNumber = change[.newKey]
        if let status = statusNumber as? NSNumber {
            switch status {
            case 1:
                player.play()
            case 2:
                if let activeItem = activeItem,
                   let error = activeItem.error {
                    let message = error.localizedDescription
                    Util.alert(self, withTitle: "Player Error", message: message, andButtonText: "OK")
                }
            default:
                print("Status \(status) received from player")
            }
        }
    }
}
//MARK: ??? Views and layouts
extension VideoViewController {
    private func setupViews() {
        view.addSubview(header)
        encodeButton.setTitle("ENCODE", for: .normal)
        encodeButton.addTarget(self, action: #selector(encodeVideo), for: .touchDown)
        view.addSubview(encodeButton)
        view.addSubview(videoCodecPicker)
        view.addSubview(videoPlayerFrame)
    }
    private func setupLayout() {
        header.translatesAutoresizingMaskIntoConstraints = false
        videoCodecPicker.translatesAutoresizingMaskIntoConstraints = false
        encodeButton.translatesAutoresizingMaskIntoConstraints = false
        videoPlayerFrame.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            header.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            header.heightAnchor.constraint(equalToConstant: 50),
            header.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1),
            
            videoCodecPicker.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 40),
            videoCodecPicker.widthAnchor.constraint(equalToConstant: 200),
            videoCodecPicker.heightAnchor.constraint(equalToConstant: 100),
            videoCodecPicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            encodeButton.topAnchor.constraint(equalTo: videoCodecPicker.bottomAnchor, constant: 40),
            encodeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            encodeButton.heightAnchor.constraint(equalToConstant: 32),
            encodeButton.widthAnchor.constraint(equalToConstant: 80),
            
            videoPlayerFrame.topAnchor.constraint(equalTo: encodeButton.bottomAnchor, constant: 30),
            videoPlayerFrame.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            videoPlayerFrame.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            videoPlayerFrame.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
}
