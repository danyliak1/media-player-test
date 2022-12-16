//
/**
 * @file      LiveVideoDecoder.swift
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

import Foundation
import VideoToolbox

typealias StartCode = (firstIndex: Int, lastIndex: Int, count: Int)

public protocol VideoRotationDelegate: AnyObject {
  func rotate(angle: CGFloat, sender: LiveDecoder)
}

public class LiveVideoDecoder: LiveDecoder {
  private(set) var formatDesc: CMFormatDescription?
  private var isSEIProcessed = false
  private var rotationSEIType = 47
  
  public weak var rotationDelegate: VideoRotationDelegate?
    
  enum NALUtype: UInt8 {
    case Undefined = 0
    case CodedSlice = 1
    case DataPartitionA = 2
    case DataPartitionB = 3
    case DataPartitionC = 4
    /// Instantaneous Decoding Refresh Picture
    case IDR = 5
    /// Supplemental Enhancement Information
    case SEI = 6
    /// Sequence Parameter Set
    case SPS = 7
    /// Picture Parameter Set
    case PPS = 8
    case AccessUnitDelimiter = 9
    case EndOfSequence = 10
    case EndOfStream = 11
    case FilterData = 12
  }
  
  private func findStartCode(data: Data, offSet: Int) -> StartCode {
    let dataLength = data.count
    for idx in offSet ..< dataLength {
      if data[idx + 0] == 0,
         data[idx + 1] == 0,
         data[idx + 2] == 0,
         data[idx + 3] == 1
      {
        return (idx, idx + 4, 4)
      } else if data[idx + 0] == 0,
                data[idx + 1] == 0,
                data[idx + 2] == 1
      {
        return (idx, idx + 3, 3)
      }
    }
    return (0, 0, 0)
  }
  
  private func calculate(angle: Int) -> CGFloat {
    let newAngle = 360 - 360 * angle / 1 << 16
    
    return CGFloat(newAngle)
  }
  
  override public func feed(data: Data, sampleTime: CMTime) throws {
    let dataLength = data.count
    guard dataLength > 0 else {
      return
    }
    var nalu = NALUtype.Undefined
    var idx = self.findStartCode(data: data, offSet: 0)
    nalu = NALUtype(rawValue: data[idx.lastIndex] & 0x1F) ?? .Undefined
    
    if nalu == .SEI && !isSEIProcessed {
      if data.count >= 7, data[5] == rotationSEIType {
        let bytes = [data[6], data[7]]
        let angleFromBits = BitHelper.angle(from: bytes)
        
        rotationDelegate?.rotate(angle: calculate(angle: angleFromBits ?? 0), sender: self)
      }
      isSEIProcessed = true
    }
    
    var len = 0
    var ptr = 0
    
    var sps: [UInt8]?
    var pps: [UInt8]?
    
    if nalu == .SPS {
      ptr = idx.lastIndex
      idx = self.findStartCode(data: data, offSet: idx.lastIndex)
      len = idx.count == 0 ? dataLength : idx.firstIndex // start code not found
      sps = [UInt8](data.subdata(in: ptr ..< len))
      nalu = NALUtype(rawValue: data[idx.lastIndex] & 0x1F) ?? .Undefined
    }
    
    if nalu == .PPS {
      ptr = idx.lastIndex
      idx = self.findStartCode(data: data, offSet: idx.lastIndex)
      len = idx.count == 0 ? dataLength : idx.firstIndex // start code not found
      pps = [UInt8](data.subdata(in: ptr ..< len))
      nalu = NALUtype(rawValue: data[idx.lastIndex] & 0x1F) ?? .Undefined
    }
    
    if let sps = sps, let pps = pps {
      self.formatDesc = try VideoMediaFrame.VideoFormatHelper(sps: sps,
                                                              pps: pps)
    }
    
    if nalu == .CodedSlice || nalu == .IDR {
      if self.formatDesc == nil || !isSEIProcessed {
        return
      }
      ptr = idx.lastIndex
      idx = self.findStartCode(data: data, offSet: ptr)
      let size = idx.count == 0 ? (dataLength - ptr) : (idx.firstIndex - ptr)
      let header = UInt32(size).bigEndian
      let _data = header.data + Data(data[ptr...])
      if let _formatDesc = self.formatDesc, size != 0 {
        let mediaFrame = VideoMediaFrame(with: _data, sampleTime: sampleTime,
                                         format: _formatDesc)
        try mediaFrame.makeCMSampleBuffer()
        self.delegate?.output(mediaFrame: mediaFrame, sender: self)
      }
    }
  }
}
