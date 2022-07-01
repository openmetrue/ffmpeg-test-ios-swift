//
//  PipeViewController.swift
//  FFmpegKitSwift
//
//  Created by Mark Khmelnitskii on 30.06.2022.
//

import UIKit
import AVFoundation
import ffmpegkit

class PipeViewController: UIViewController {
    
    private var player = AVQueuePlayer()
    private lazy var playerLayer = AVPlayerLayer(player: player)
    private var activeItem: AVPlayerItem? = nil
    
    private var alertController = UIAlertController()
    private var indicator = UIActivityIndicatorView()
    private var statistics: Statistics? = nil
    private var header = UILabel()
    private var createButton = UIButton()
    private var videoPlayerFrame = UILabel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // STYLE UPDATE
        Util.applyButtonStyle(createButton)
        Util.applyVideoPlayerFrameStyle(videoPlayerFrame)
        Util.applyHeaderStyle(header)
        
        var rectangularFrame:CGRect = self.view.layer.bounds
        rectangularFrame.size.width = self.view.layer.bounds.size.width - 40
        rectangularFrame.origin.x = 20
        rectangularFrame.origin.y = self.createButton.layer.bounds.origin.y + 120
        
        playerLayer.frame = rectangularFrame
        self.view.layer.addSublayer(playerLayer)
        
        addUIAction {
            self.enableLogCallback()
            self.enableStatisticsCallback()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func enableLogCallback() {
        FFmpegKitConfig.enableLogCallback { log in
            guard let log = log else { return }
            addUIAction {
                print(log.getMessage() ?? "")
            }
        }
    }
    
    func enableStatisticsCallback() {
        FFmpegKitConfig.enableStatisticsCallback { stat in
            addUIAction {
                self.statistics = stat
                self.updateProgressDialog()
            }
        }
    }
    
    static func startAsyncCopyImageProcess(_ imagePath: String, onPipe namedPipePath: String?) {
        guard let namedPipePath = namedPipePath else { return }
        DispatchQueue.global().async {
            print("Starting copy \(imagePath) to pipe \(namedPipePath) operation")
            guard let fileHandle = FileHandle(forReadingAtPath: imagePath) else {
                print("Failed to open file \(imagePath)")
                return
            }
            guard let pipeHandle = FileHandle(forWritingAtPath: namedPipePath) else {
                print("Failed to open pipe \(namedPipePath)")
                fileHandle.closeFile()
                return
            }
            let BUFFER_SIZE: Int = 4096
            var readBytes: Int = 0
            var totalBytes: Int = 0
            let startTime: Double = CACurrentMediaTime()
            
            fileHandle.seek(toFileOffset: 0)
            defer {
                fileHandle.closeFile()
                pipeHandle.closeFile()
            }
            repeat {
                let data = fileHandle.readData(ofLength: BUFFER_SIZE)
                readBytes = data.count
                if readBytes > 0 {
                    totalBytes += readBytes
                    pipeHandle.write(data)
                }
            } while readBytes > 0
            let endTime = CACurrentMediaTime()
            print("Completed copy \(imagePath) to pipe \(namedPipePath) operation. \(totalBytes) bytes copied in \(endTime - startTime) seconds")
        }
    }
    
    @IBAction func createVideo(sender:AnyObject!) {
        
        let resourceFolder = Bundle.main.resourcePath!
        let image1 = resourceFolder.appending("/machupicchu.jpg")
        let image2 = resourceFolder.appending("/pyramid.jpg")
        let image3 = resourceFolder.appending("/stonehenge.jpg")
        let videoFile = getVideoPath()
        
        let pipe1 = FFmpegKitConfig.registerNewFFmpegPipe()
        let pipe2 = FFmpegKitConfig.registerNewFFmpegPipe()
        let pipe3 = FFmpegKitConfig.registerNewFFmpegPipe()
        
        //if player != nil {
        player.removeAllItems()
        activeItem = nil
        //}
        do {
            try FileManager.default.removeItem(atPath: videoFile)
        } catch let error {
            print(error.localizedDescription)
        }
        
        print("Testing PIPE with 'mpeg4' codec")
        showProgressDialog("Creating video\n")
        let ffmpegCommand = Video.generateCreateVideoWithPipesScript(pipe1, pipe2, pipe3, videoFile)
        print("FFmpeg process started with arguments: \(ffmpegCommand)")
        
        FFmpegKit.executeAsync(ffmpegCommand) { session in
            guard let session = session,
                  let returnCode = session.getReturnCode() else { return }
            print("FFmpeg process exited with state \(FFmpegKitConfig.sessionState(toString: session.getState()) ?? "") and \(returnCode)")
            addUIAction {
                self.hideProgressDialog()
            }
            // CLOSE PIPES
            FFmpegKitConfig.closeFFmpegPipe(pipe1)
            FFmpegKitConfig.closeFFmpegPipe(pipe2)
            FFmpegKitConfig.closeFFmpegPipe(pipe3)
            addUIAction {
                if ReturnCode.isSuccess(returnCode) {
                    print("Create completed successfully.")
                    self.playVideo()
                } else {
                    self.hideProgressDialogAndAlert("Create failed. Please check logs for the details.")
                }
            }
        }
        // START ASYNC PROCESSES AFTER INITIATING FFMPEG COMMAND
        PipeViewController.startAsyncCopyImageProcess(image1, onPipe: pipe1)
        PipeViewController.startAsyncCopyImageProcess(image2, onPipe: pipe2)
        PipeViewController.startAsyncCopyImageProcess(image3, onPipe: pipe3)
    }
    
    func playVideo() {
        let videoFile = getVideoPath()
        let videoURL = NSURL.fileURL(withPath: videoFile)
        
        let asset = AVAsset(url: videoURL)
        let assetKeys = ["playable", "hasProtectedContent"]
        
        let newVideo = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys:assetKeys)
        activeItem = newVideo
        newVideo.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
        player.insert(newVideo, after: nil)
    }
    
    func getVideoPath() -> String {
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return docFolder.appending("/video.mp4")
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
            alertController.message = String(format:"Creating video  %% %d \n\n", percentage)
        }
    }
    
    func hideProgressDialog() {
        indicator.stopAnimating()
        self.dismiss(animated: true, completion: nil)
    }
    
    func hideProgressDialogAndAlert(_ message: String) {
        indicator.stopAnimating()
        self.dismiss(animated: true) {
            Util.alert(self, withTitle: "Error", message: message, andButtonText: "OK")
        }
    }
    
//    func observeValueForKeyPath(keyPath:String, ofObject object:AnyObject, change: NSDictionary, context: Void) {
//
//        let statusNumber: NSNumber = change[NSKeyValueObservingOptions.new]
//        var status: Int = -1
//
//        if (statusNumber is NSNumber) {
//            status = statusNumber.integerValue
//        }
//
//        switch status {
//        case AVPlayerItemStatusReadyToPlay:
//            player.play()
//        case AVPlayerItemStatusFailed:
//            if activeItem != nil && activeItem.error != nil {
//                var message: String! = activeItem.error.localizedFailureReason
//
//                if message == nil {
//                    message = activeItem.error.localizedDescription
//                }
//
//                Util.alert(self, withTitle: "Player Error", message: message, andButtonText: "OK")
//            }
//        default:
//            NSLog("Status %ld received from player.\n", status)
//        }
//    }
}

//MARK: – Views and layouts
extension PipeViewController {
    private func setupViews() {
        view.addSubview(stackView)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(favoriteButton)
        stackView.addArrangedSubview(authorLabel)
        stackView.addArrangedSubview(locationLabel)
        stackView.addArrangedSubview(dateLabel)
        stackView.addArrangedSubview(downloadsLabel)
        stackView.addArrangedSubview(dismissButton)
    }
    private func setupLayout() {
        stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 20).isActive = true
    }
}
