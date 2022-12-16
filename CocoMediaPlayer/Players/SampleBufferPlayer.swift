//
/**
 * @file      SampleBufferPlayer.swift
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
import OSLog
import UIKit

@available(iOS 13.0, *)
public class SampleBufferPlayer {
  private let logger = OSLog(SampleBufferPlayer.self)
  private let dispatchQueue = DispatchQueue(label: "buzz.getcoco.sbplayer")

  private(set) var synchronizer: AVSampleBufferRenderSynchronizer
  private(set) var videoRenderer: AVSampleBufferDisplayLayer
  public private(set) var audioRenderer: AVSampleBufferAudioRenderer
  private var pts: CMTime?

  public var state: CocoPlayer.PlayerState

  public var displayLayer: CALayer {
    return self.videoRenderer
  }

  public var time: CMTime {
    return self.synchronizer.currentTime()
  }

  public var frame: CGRect {
    get {
      return self.displayLayer.frame
    }
    set {
      self.displayLayer.frame = newValue
    }
  }

  public init() {
    os_log("%s started", log: self.logger, type: .debug, #function)
    self.synchronizer = .init()
    self.synchronizer.setRate(0.0, time: .zero)

    self.videoRenderer = AVSampleBufferDisplayLayer()
    self.videoRenderer.videoGravity = .resizeAspectFill
    self.videoRenderer.backgroundColor = UIColor.black.cgColor

    self.synchronizer.addRenderer(self.videoRenderer)

    self.audioRenderer = AVSampleBufferAudioRenderer()
    self.synchronizer.addRenderer(self.audioRenderer)
    self.state = .READY
    os_log("%s completed", log: self.logger, type: .debug, #function)
  }

  deinit {
    self.stop()
    state = .FINISHED
  }

  public func enqueue(_ mediaFrame: MediaFrame) {
    os_log("%s started", log: self.logger, type: .debug, #function)

    guard let sbuf = mediaFrame.sampleBuffer else {
      os_log("%s failed", log: self.logger, type: .error, #function)
      return
    }

    guard CMSampleBufferGetFormatDescription(sbuf) != nil else {
      os_log("%s failed", log: self.logger, type: .error, #function)
      return
    }
    
    pts = sbuf.presentationTimeStamp
    
    if (mediaFrame as? VideoMediaFrame) != nil {
      self.videoRenderer.enqueue(sbuf)
      let status = self.videoRenderer.status
      os_log("%s videoRenderer status: %s", log: self.logger, type: .debug,
             #function, String(describing: status.rawValue))
      if status == AVQueuedSampleBufferRenderingStatus.failed {
        os_log("%s videoRenderer error: %s", log: self.logger, type: .error,
               #function,
               String(describing: videoRenderer.error))
      }
    }

    if (mediaFrame as? AudioMediaFrame) != nil {
      self.audioRenderer.enqueue(sbuf)
      let status = self.audioRenderer.status
      os_log("%s audioRenderer status: %s", log: self.logger, type: .debug,
             #function, String(describing: status.rawValue))
      if status == AVQueuedSampleBufferRenderingStatus.failed {
        os_log("%s audioRenderer error: %s", log: self.logger, type: .error,
               #function,
               String(describing: audioRenderer.error))
      }
    }
    os_log("%s completed", log: self.logger, type: .debug, #function)
  }

  private func setRate(_ rate: Double) {
    guard let pts = pts else { return }
    self.state = .PLAYING
    self.synchronizer.setRate(Float(rate), time: pts)
  }
}

@available(iOS 13.0, *)
extension SampleBufferPlayer: CocoPlayerProtocol {
  public func seek(second: Double) {
    // Note: Ignore because of live streaming is going on
  }

  public var isMuted: Bool {
    get {
      return self.audioRenderer.isMuted
    }
    set {
      self.audioRenderer.isMuted = newValue
    }
  }

  public func play() {
    self.dispatchQueue.sync {
      self.setRate(1.0)
    }
  }

  public func pause() {
    self.state = .READY
    self.dispatchQueue.sync {
      self.setRate(0.0)
    }
  }

  public func stop() {
    self.state = .FINISHED
    self.dispatchQueue.sync {
      self.setRate(0.0)
      self.audioRenderer.flush()
      self.videoRenderer.flushAndRemoveImage()
    }
  }

  public func resize(view: UIView) {
    self.attach(view: view)
  }

  public func attach(view: UIView) {
    DispatchQueue.main.async {
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      
      self.detach()
      self.displayLayer.frame = view.bounds
      view.layer.insertSublayer(self.displayLayer, at: 0)
      
      CATransaction.commit()
    }
  }
  
  public func rotate(angle: CGFloat = 90) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    
    let radians = CGFloat(angle * Double.pi / 180)
    displayLayer.transform = CATransform3DMakeRotation(radians, 0, 0, -1)
    
    CATransaction.commit()
  }

  public func detach() {
    self.displayLayer.removeFromSuperlayer()
  }
}

@available(iOS 13.0, *)
public extension SampleBufferPlayer {
  func parse(sdpString: String) -> SessionDescription? {
    let parser = try? SessionDescriptionParser
      .parse(sdpString: sdpString)
    return parser
    }
  }
