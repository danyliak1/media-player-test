//
/**
 * @file      MediaFrame.swift
 * @brief     Media frame description
 * @details   Model for a media frame of the player in sampleBuffer mode
 *
 * @see
 * @author    rohan-elear, rohansahay@elear.solutions
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

open class MediaFrame {
  public private(set) var data: Data
  public private(set) var formatDesc: CMFormatDescription?
  public private(set) var sampleTime: CMTime = .invalid
  public var sampleBuffer: CMSampleBuffer?
  public private(set) var sampleRate: Int32

  init(with data: Data, sampleTime: CMTime, sampleRate: Int32,
       format: CMFormatDescription)
  {
    self.data = data
    self.formatDesc = format
    self.sampleTime = sampleTime
    self.sampleRate = sampleRate
  }

  func makeCMSampleBuffer() throws {
    let dataLength = self.data.count
    let sampleRate = self.sampleRate
    let blockBuffer = try data.toCMBlockBuffer()
    let timescale = Int32(sampleRate)
    var timingInfo = CMSampleTimingInfo()
    timingInfo.presentationTimeStamp = self.sampleTime
    timingInfo.decodeTimeStamp = .invalid
    timingInfo.duration = CMTimeMake(value: Int64(dataLength),
                                     timescale: timescale)

    let sampleSizeArray = [dataLength]
    let timingInfoArray = [timingInfo]

    let status = CMSampleBufferCreateReady(
      allocator: kCFAllocatorDefault,
      dataBuffer: blockBuffer,
      formatDescription: self.formatDesc,
      sampleCount: 1,
      sampleTimingEntryCount: timingInfoArray.count, sampleTimingArray: timingInfoArray,
      sampleSizeEntryCount: sampleSizeArray.count, sampleSizeArray: sampleSizeArray,
      sampleBufferOut: &self.sampleBuffer
    )
    guard status == noErr else {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
  }
}
