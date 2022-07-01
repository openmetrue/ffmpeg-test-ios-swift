//
//  SubtitleViewController.swift
//  FFmpegKitSwift
//
//  Created by Mark Khmelnitskii on 30.06.2022.
//

import UIKit
import AVFoundation
import ffmpegkit

class SubtitleViewController: UIViewController {
    
    private var player = AVQueuePlayer()
    private lazy var playerLayer = AVPlayerLayer(player: player)
    
    private var alertController = UIAlertController()
    private var indicator = UIActivityIndicatorView()
    private var statistics: Statistics? = nil
    private var sessionId: Int = 0
    private var header = UILabel()
    private var burnSubtitlesButton = UIButton()
    private var videoPlayerFrame = UIView()

    enum State {
        case IdleState
        case CreatingState
        case BurningState
    }
    private var state: State = .IdleState

    override func viewDidLoad() {
        super.viewDidLoad()

        // STYLE UPDATE
        Util.applyButtonStyle(burnSubtitlesButton)
        Util.applyVideoPlayerFrameStyle(videoPlayerFrame)
        Util.applyHeaderStyle(header)

        var rectangularFrame:CGRect = self.view.layer.bounds
        rectangularFrame.size.width = self.view.layer.bounds.size.width - 40
        rectangularFrame.origin.x = 20
        rectangularFrame.origin.y = self.burnSubtitlesButton.layer.bounds.origin.y + 80

        playerLayer.frame = rectangularFrame
        self.view.layer.addSublayer(playerLayer)


        addUIAction {
            self.enableLogCallback()
            self.enableStatisticsCallback()
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
            print(log.getMessage() ?? "")
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

    @IBAction func burnSubtitles(sender:AnyObject!) {
        
        let resourceFolder = Bundle.main.resourcePath!
        let image1 = resourceFolder.appending("/machupicchu.jpg")
        let image2 = resourceFolder.appending("/pyramid.jpg")
        let image3 = resourceFolder.appending("/stonehenge.jpg")
        let subtitle = getSubtitlePath()
        let videoFile = getVideoPath()
        let videoWithSubtitlesFile = getVideoWithSubtitlesPath()

        player.removeAllItems()
        print("Testing SUBTITLE burning")
        showProgressDialog("Creating video")
        let ffmpegCommand = Video.generateVideoEncodeScript(image1, image2, image3, videoFile, "mpeg4", "")
        print("FFmpeg process started with arguments: \(ffmpegCommand)")
        
        state = .CreatingState
        
        sessionId = FFmpegKit.executeAsync(ffmpegCommand) { session in
            guard let session = session,
                  let returnCode = session.getReturnCode() else { return }
            print("FFmpeg process exited with state \(FFmpegKitConfig.sessionState(toString: session.getState()) ?? "") and \(returnCode)")
            addUIAction {
                self.hideProgressDialog()
            }
            if ReturnCode.isSuccess(returnCode) {
                print("Create completed successfully; burning subtitles")
                let burnSubtitlesCommand = String(format:"-hide_banner -y -i %@ -vf subtitles=%@:force_style='FontName=MyFontName' %@", videoFile, subtitle, videoWithSubtitlesFile)
                addUIAction {
                    self.showProgressDialog("Burning subtitles")
                }
                print("FFmpeg process started with arguments: \(burnSubtitlesCommand)")
                self.state = .BurningState

                FFmpegKit.executeAsync(burnSubtitlesCommand) { secondSession in
                    guard let secondSession = secondSession,
                          let returnCode = secondSession.getReturnCode() else { return }
                    addUIAction {
                        self.hideProgressDialog()
                        if ReturnCode.isSuccess(returnCode) {
                            print("Burn subtitles completed successfully; playing video")
                            self.playVideo()
                        } else if ReturnCode.isCancel(returnCode) {
                            print("Burn subtitles operation cancelled")
                            self.indicator.stopAnimating()
                            Util.alert(self, withTitle:"Error", message:"Burn subtitles operation cancelled.", andButtonText:"OK")
                        } else {
                            print("Burn subtitles failed with state \(secondSession.getState()) and \(returnCode)")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                                self.hideProgressDialogAndAlert(message: "Burn subtitles failed. Please check logs for the details.")
                            }
                        }
                    }
                }
            }
        }.getId()

        print("Async FFmpeg process started with sessionId %ld.\n", sessionId)
    }
    func playVideo() {
        let videoWithSubtitlesFile = getVideoWithSubtitlesPath()
        let videoWithSubtitlesURL = NSURL.fileURL(withPath: videoWithSubtitlesFile)
        
        let asset = AVAsset(url: videoWithSubtitlesURL)
        let assetKeys = ["playable", "hasProtectedContent"]
        
        let newVideo = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys:assetKeys)
        player.insert(newVideo, after:nil)
        player.play()
    }
    
    func getSubtitlePath() -> String {
        let resourceFolder = Bundle.main.resourcePath!
        return resourceFolder.appending("/subtitle.srt")
    }

    func getVideoPath() -> String {
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return docFolder.appending("/video.mp4")
    }

    func getVideoWithSubtitlesPath() -> String {
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return docFolder.appending("/video-with-subtitles.mp4")
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
        
        let cancelAction = UIAlertAction(title: "CANCEL", style: .default) { action in
            if self.state == .CreatingState {
                if self.sessionId != 0 {
                    FFmpegKit.cancel(self.sessionId)
                }
            } else if self.state == .BurningState {
                FFmpegKit.cancel()
            }
        }
        alertController.addAction(cancelAction)
        
        let constraintsVertical = NSLayoutConstraint.constraints(withVisualFormat: "V:[indicator]-(56)-|", metrics: nil, views: views)
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
            if state == .CreatingState {
                alertController.message = String(format:"Creating video  %% %d \n\n", percentage)
            } else if state == .BurningState {
                alertController.message = String(format:"Burning subtitles  %% %d \n\n", percentage)
            }
        }
    }

    func hideProgressDialog() {
        indicator.stopAnimating()
        self.dismiss(animated: true, completion:nil)
    }

    func hideProgressDialogAndAlert(message: String) {
        indicator.stopAnimating()
        self.dismiss(animated: true) {
            Util.alert(self, withTitle: "Error", message: message, andButtonText: "OK")
        }
    }
}
//MARK: – Views and layouts
extension SubtitleViewController {
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
