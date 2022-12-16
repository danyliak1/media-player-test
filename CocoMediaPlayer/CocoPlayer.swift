//
/**
 * @file      CocoPlayer.swift
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

public protocol CocoPlayerDelegate: AnyObject {
  func handle(stateChangedFrom from: CocoPlayer.PlayerState,
              to: CocoPlayer.PlayerState)
}

public protocol CocoPlayerProtocol: AnyObject {
  // Properties of a player
  var state: CocoPlayer.PlayerState { get }
  var isMuted: Bool { get set }
  var displayLayer: CALayer { get }
  var time: CMTime { get }

  // Common functions of a player
  func play()
  func pause()
  func stop()
  func resize(view: UIView)
  func attach(view: UIView)
  func detach()
  func seek(second: Double)
}

public enum CocoPlayer {
  public enum PlayerState: Int {
    case READY = 0
    case LOADING = 1
    case PLAYING = 2
    case FINISHED = 3
    case ERROR = 4
  }
}
