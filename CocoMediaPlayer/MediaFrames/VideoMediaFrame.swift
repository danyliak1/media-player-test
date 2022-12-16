//
/**
 * @file      VideoMediaFrame.swift
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

class VideoMediaFrame: MediaFrame {
  static let SAMPLE_RATE = 90000

  override init(with data: Data, sampleTime: CMTime,
                sampleRate: Int32 = Int32(VideoMediaFrame.SAMPLE_RATE),
                format: CMFormatDescription)
  {
    super.init(with: data, sampleTime: sampleTime, sampleRate: sampleRate,
               format: format)
  }

  func setDisplayImmediately(_ value: Bool) {
    if let buffer = self.sampleBuffer,
       let attachmentArray = CMSampleBufferGetSampleAttachmentsArray(
         buffer, createIfNecessary: true
       )
    {
      let dic = unsafeBitCast(
        CFArrayGetValueAtIndex(attachmentArray, 0),
        to: CFMutableDictionary.self
      )
      CFDictionarySetValue(dic,
                           Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                           Unmanaged.passUnretained(value ? kCFBooleanTrue : kCFBooleanFalse).toOpaque())
    }
  }

  class func VideoFormatHelper(sps: [UInt8], pps: [UInt8]) throws -> CMFormatDescription {
    var formatDesc: CMFormatDescription?

    let pointerSPS = sps.pointer
    let pointerPPS = pps.pointer

    let dataParamArray = [pointerSPS, pointerPPS]
    let parameterSetPointers = dataParamArray.pointer

    let sizeParamArray = [sps.count, pps.count]
    let parameterSetSizes = sizeParamArray.pointer

    let status = CMVideoFormatDescriptionCreateFromH264ParameterSets(
      allocator: kCFAllocatorDefault,
      parameterSetCount: 2,
      parameterSetPointers: parameterSetPointers,
      parameterSetSizes: parameterSetSizes,
      nalUnitHeaderLength: 4,
      formatDescriptionOut: &formatDesc
    )
    guard status == noErr else {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }

    return formatDesc!
  }
}
