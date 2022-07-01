//
//  VidStabViewController.swift
//  FFmpegKitSwift
//
//  Created by Mark Khmelnitskii on 30.06.2022.
//

import UIKit
import AVFoundation
import ffmpegkit

class VidStabViewController: UIViewController {
    
    private var player = AVQueuePlayer()
    private lazy var playerLayer = AVPlayerLayer(player: player)
    private var stabilizedVideoPlayer = AVQueuePlayer()
    private lazy var stabilizedVideoPlayerLayer = AVPlayerLayer(player: stabilizedVideoPlayer)
    
    private var indicator = UIActivityIndicatorView()
    private var header = UILabel()
    private var stabilizeVideoButton = UIButton()
    private var videoPlayerFrame = UIView()
    private var stabilizedVideoPlayerFrame = UIView()


    override func viewDidLoad() {
        super.viewDidLoad()

        // STYLE UPDATE
        Util.applyButtonStyle(stabilizeVideoButton)
        Util.applyVideoPlayerFrameStyle(videoPlayerFrame)
        Util.applyVideoPlayerFrameStyle(stabilizedVideoPlayerFrame)
        Util.applyHeaderStyle(header)

        // SETTING VIDEO FRAME POSITIONS, RANDOMLY (?)
        self.stabilizedVideoPlayerFrame.frame = CGRect(x: 20, y: 20, width: self.view.bounds.size.width - 40, height: self.view.bounds.size.height/4)

        var upperRectangularFrame:CGRect = self.view.bounds
        upperRectangularFrame.size.width = self.stabilizedVideoPlayerFrame.bounds.size.width
        upperRectangularFrame.size.height = self.stabilizedVideoPlayerFrame.bounds.size.height - 4
        upperRectangularFrame.origin.x = 0
        upperRectangularFrame.origin.y = self.view.bounds.size.height/100 - 4

        playerLayer.frame = upperRectangularFrame
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        self.videoPlayerFrame.layer.addSublayer(playerLayer)

        var lowerRectangularFrame:CGRect = self.view.bounds
        lowerRectangularFrame.size.width = self.stabilizedVideoPlayerFrame.bounds.size.width
        lowerRectangularFrame.size.height = self.stabilizedVideoPlayerFrame.bounds.size.height + 4
        lowerRectangularFrame.origin.x = 0
        lowerRectangularFrame.origin.y = self.view.bounds.size.height/50 - 4

        stabilizedVideoPlayerLayer.frame = lowerRectangularFrame
        stabilizedVideoPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        self.stabilizedVideoPlayerFrame.layer.addSublayer(stabilizedVideoPlayerLayer)

        addUIAction {
            FFmpegKitConfig.enableLogCallback { log in
                if let log = log,
                   let message = log.getMessage() {
                    print(message)
                }
            }
        }
        setupViews()
        setupLayout()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func stabilizedVideo(sender:AnyObject!) {
        
        let resourceFolder = Bundle.main.resourcePath!
        let image1 = resourceFolder.appending("/machupicchu.jpg")
        let image2 = resourceFolder.appending("/pyramid.jpg")
        let image3 = resourceFolder.appending("/stonehenge.jpg")
        let shakeResultsFile = getShakeResultsFilePath()
        let videoFile = getVideoPath()
        let stabilizedVideoFile = getStabilizedVideoPath()

        player.removeAllItems()
        stabilizedVideoPlayer.removeAllItems()

        do {
            try FileManager.default.removeItem(atPath: shakeResultsFile)
            try FileManager.default.removeItem(atPath: videoFile)
            try FileManager.default.removeItem(atPath: stabilizedVideoFile)
        } catch let error {
            print(error.localizedDescription)
        }
        print("Testing VID.STAB")
        showProgressDialog("Creating video")

        let ffmpegCommand = Video.generateShakingVideoScript(image1, image2, image3, videoFile)

        print("FFmpeg process started with arguments: \(ffmpegCommand)")
        FFmpegKit.executeAsync(ffmpegCommand) { session in
            guard let session = session,
                  let returnCode = session.getReturnCode() else { return }
            print("FFmpeg process exited with state \(session.getState()) and \(returnCode)")
            addUIAction {
                self.hideProgressDialog()
            }
            if ReturnCode.isSuccess(session.getReturnCode()) {
                print("Create completed successfully; stabilizing video.")
                let analyzeVideoCommand = String(format:"-hide_banner -y -i %@ -vf vidstabdetect=shakiness=10:accuracy=15:result=%@ -f null -", videoFile, shakeResultsFile)
                addUIAction {
                    self.showProgressDialog("Stabilizing video")
                }
                print("FFmpeg process started with arguments: \(analyzeVideoCommand)")

                FFmpegKit.executeAsync(analyzeVideoCommand) { secondSession in
                    guard let secondSession = secondSession,
                          let returnCode = secondSession.getReturnCode() else { return }
                    print("FFmpeg process exited with state \(secondSession.getState()) and \(returnCode)")
                    if ReturnCode.isSuccess(secondSession.getReturnCode()) {
                        
                        let stabilizeVideoCommand = String(format:"-hide_banner -y -i %@ -vf vidstabtransform=smoothing=30:input=%@ %@", videoFile, shakeResultsFile, stabilizedVideoFile)
                        print("FFmpeg process started with arguments: \(stabilizeVideoCommand)")

                        FFmpegKit.executeAsync(stabilizeVideoCommand) { thirdSession in
                            guard let thirdSession = thirdSession,
                                  let returnCode = thirdSession.getReturnCode() else { return }
                            print("FFmpeg process exited with state \(thirdSession.getState()) and \(returnCode)")
                            addUIAction {
                                self.hideProgressDialog()
                                if ReturnCode.isSuccess(thirdSession.getReturnCode()) {
                                    print("Stabilize video completed successfully; playing videos.\n")
                                    self.playVideo()
                                    self.playStabilizedVideo()
                                } else {
                                    self.hideProgressDialogAndAlert("Stabilize video failed. Please check logs for the details.")
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                            self.hideProgressDialogAndAlert("Stabilize video failed. Please check logs for the details")
                        }
                    }
                }
            } else {
                addUIAction {
                    self.hideProgressDialogAndAlert("Create video failed. Please check logs for the details.")
                }
            }
        }
    }
    func playVideo() {
        let videoFile = getVideoPath()
        let videoURL = NSURL.fileURL(withPath: videoFile)
        
        let asset = AVAsset(url: videoURL)
        let assetKeys = ["playable", "hasProtectedContent"]
        let video = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys:assetKeys)
        
        player.insert(video, after: nil)
        player.play()
    }
    
    func playStabilizedVideo() {
        let stabilizedVideoFile = getStabilizedVideoPath()
        let stabilizedVideoURL = NSURL.fileURL(withPath: stabilizedVideoFile)
        let asset = AVAsset(url: stabilizedVideoURL)
        let assetKeys = ["playable", "hasProtectedContent"]
        let stabilizedVideo = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys:assetKeys)
        
        stabilizedVideoPlayer.insert(stabilizedVideo, after: nil)
        stabilizedVideoPlayer.play()
    }

    func getShakeResultsFilePath() -> String {
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return docFolder.appending("/transforms.trf")
    }

    func getVideoPath() -> String {
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return docFolder.appending("/video.mp4")
    }

    func getStabilizedVideoPath() -> String {
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return docFolder.appending("/video-stabilized.mp4")
    }
    
    func showProgressDialog(_ dialogMessage: String) {
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
}
//MARK: – Views and layouts
extension VidStabViewController {
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
