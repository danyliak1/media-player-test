//
/**
 * @file      AudioMediaFrame.swift
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

public class AudioMediaFrame: MediaFrame {
  private(set) var audioFormat: AVAudioFormat
  
  init(with data: Data, sampleTime: CMTime,
       format: AVAudioFormat)
  {
    self.audioFormat = format
    super.init(with: data, sampleTime: sampleTime, sampleRate: Int32(format.sampleRate),
               format: self.audioFormat.formatDescription)
  }
  
  override func makeCMSampleBuffer() throws {
    guard let pcmBuffer = data.makePCMBuffer(format: AudioMediaFrame.ALawFormatHelper(sampleRate: 16000)) else {
      return
    }
    let sBuf = Converter.configureSampleBuffer(pcmBuffer: pcmBuffer)
    sampleBuffer = sBuf
  }
  
  public class func ALawFormatHelper(sampleRate: Int = 16000,
                                     channels: Int = 1)
  -> AVAudioFormat
  {
    var asbd = AudioStreamBasicDescription()
    asbd.mSampleRate = Float64(sampleRate)
    asbd.mFormatID = kAudioFormatALaw
    asbd.mFormatFlags = 0
    asbd.mFramesPerPacket = 1
    asbd.mChannelsPerFrame = UInt32(channels)
    asbd.mBitsPerChannel = 8 * UInt32(MemoryLayout<UInt8>.size)
    asbd.mReserved = 0
    asbd.mBytesPerFrame = asbd.mChannelsPerFrame * UInt32(MemoryLayout<UInt8>.size) // channels * sizeof(data type)
    asbd.mBytesPerPacket = asbd.mBytesPerFrame * asbd.mFramesPerPacket // mBytesPerFrame * mFramesPerPacket
    let _audioFormat = AVAudioFormat(streamDescription: &asbd)!
    return _audioFormat
  }
  
  public class func AmrWbFormatHelper(sampleRate: Int,
                                      channels: Int = 1) -> AVAudioFormat
  {
    var asbd = AudioStreamBasicDescription()
    asbd.mSampleRate = Float64(sampleRate)
    asbd.mFormatID = kAudioFormatAMR_WB
    asbd.mFormatFlags = 0
    asbd.mFramesPerPacket = 320
    asbd.mChannelsPerFrame = UInt32(channels)
    asbd.mBitsPerChannel = 16 * UInt32(MemoryLayout<UInt8>.size)
    asbd.mReserved = 0
    asbd.mBytesPerFrame = 2
    asbd.mBytesPerPacket = asbd.mBytesPerFrame * asbd.mFramesPerPacket
    let _audioFormat = AVAudioFormat(streamDescription: &asbd)!
    return _audioFormat
  }
  
  public class func LpcmFormatHelper(sampleRate: Int,
                                     channels: Int = 1) -> AVAudioFormat
  {
    let _audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                     sampleRate: Double(sampleRate),
                                     channels: AVAudioChannelCount(channels),
                                     interleaved: false)!
    return _audioFormat
  }
}
