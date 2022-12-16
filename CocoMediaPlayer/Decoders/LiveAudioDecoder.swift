//
/**
 * @file      LiveAudioDecoder.swift
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

public class LiveAudioDecoder: LiveDecoder {
  
  override public func feed(data: Data, sampleTime: CMTime) throws {
    let mediaFrame = AudioMediaFrame(with: data, sampleTime: sampleTime,
                                     format: AudioMediaFrame.ALawFormatHelper())
    try mediaFrame.makeCMSampleBuffer()
    self.delegate?.output(mediaFrame: mediaFrame, sender: self)
  }
}
