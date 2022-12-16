//
/**
 * @file      CocoAVPlayer.swift
 * @brief     <#Brief#>
 * @details   <#Description#>
 *
 * @see
 * @author    rohan-elear, <#Author email#>
 * @copyright Copyright (c) 2021 Elear Solutions Tech Private Limited.
 *            All rights reserved.
 * @license   To any person (the "Recipient") obtaining a copy of this software
 *            and associated documentation files (the "Software"):
 *            All information contained in or disclosed by this software is
 *            confidential and proprietary information of Elear Solutions Tech
 *            Private Limited and all rights therein are expressly reserved.
 *            By accepting this material the recipient agrees that this material
 *            and the information contained therein is held in confidence and
 *            in trust and will NOT be used, copied, modified, merged,
 *            published, distributed, sublicensed, reproduced in whole or
 *            in part, nor its contents revealed in any manner to others
 *            without the express written permission of Elear Solutions Tech
 *            Private Limited.
 */

import AVFoundation
import Foundation
import UIKit

public protocol CocoAVPlayerDelegate: AnyObject {
  func mediaPlayerTimeChanged(time: CMTime)
  func mediaPlayerStateChanged(from: CocoPlayer.PlayerState, to: CocoPlayer.PlayerState)
}

public class CocoAVPlayer {
  private var dispatchQueue = DispatchQueue(label: "buzz.getcoco.avplayer")
  private(set) var player: AVPlayer
  public weak var delegate: CocoAVPlayerDelegate?
  public var state: CocoPlayer.PlayerState

  public var currentItem: AVPlayerItem? {
    return self.player.currentItem
  }

  public var time: CMTime {
    return self.player.currentItem?.currentTime() ?? CMTime()
  }

  public var duration: CMTime {
    return self.player.currentItem?.duration ?? CMTime()
  }

  public static var interval = CMTimeMake(value: 1,
                                          timescale: 1)

  public var displayLayer: CALayer {
    return AVPlayerLayer(player: self.player)
  }

  public init() {
    self.player = AVPlayer()
    self.state = .FINISHED
  }

  public func load(url: URL) {
    self.state = .LOADING
    self.dispatchQueue.async { [self] in
//      let testURL = URL(string: "https://multiplatform-f.akamaihd.net/i/multi/will/bunny/big_buck_bunny_,640x360_400,640x360_700,640x360_1000,950x540_1500,.f4v.csmil/master.m3u8")
      let item = AVPlayerItem(url: url)
      debugPrint("[DBG] \(#file) -> \(#function) item.status: \(item.status.rawValue)")
      self.player.replaceCurrentItem(with: item)
      self.state = .READY
    }
  }

  public func attachTimers(forInterval: CMTime = interval) {
    self.player.addPeriodicTimeObserver(
      forInterval: forInterval,
      queue: self.dispatchQueue,
      using: { playbackTime in
        debugPrint("[DBG] \(#file) -> \(#function) player.status: \(self.player.status.rawValue)")
        self.delegate?.mediaPlayerTimeChanged(time: playbackTime)
      }
    )
  }

  public func seek(to: CMTime, _ completionHandler: ((Bool) -> Void)?) {
    if let completionHandler = completionHandler {
      self.player.seek(to: to, completionHandler: completionHandler)
    } else {
      self.player.seek(to: to)
    }
  }
}

extension CocoAVPlayer: CocoPlayerProtocol {
  public func seek(second: Double) {
    self.player.seek(to: CMTime(value: CMTimeValue(second), timescale: CMTimeScale(1)))
  }

  public var isMuted: Bool {
    get {
      return self.player.isMuted
    }
    set {
      self.player.isMuted = newValue
    }
  }

  public func play() {
    guard self.player.currentItem != nil else {
      return
    }
    self.dispatchQueue.sync {
      player.play()
      state = .PLAYING
    }
  }

  public func pause() {
    guard self.player.currentItem != nil else {
      return
    }
    self.dispatchQueue.sync {
      player.pause()
      state = .READY
    }
  }

  public func stop() {
    self.dispatchQueue.sync {
      player.rate = 0.0
      state = .FINISHED
    }
  }

  public func resize(view: UIView) {
    self.attach(view: view)
  }

  public func attach(view: UIView) {
    self.detach()
    let playerLayer = self.displayLayer as! AVPlayerLayer
    playerLayer.frame = view.bounds
    playerLayer.videoGravity = .resizeAspectFill
    playerLayer.backgroundColor = UIColor.black.cgColor
    view.layer.addSublayer(playerLayer)
  }

  public func detach() {
    self.displayLayer.removeFromSuperlayer()
  }
}
