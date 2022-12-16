//
/**
 * @file      LiveAudioEncoder.swift
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

import AudioToolbox
import AVFoundation
import Foundation

@available(iOS 13.0, *)
public class LiveAudioEncoder: NSObject {
  
  public var naluHandling: ((_ data: Data, _ pts: Int) -> Void)?
  public var testHandle: ((CMSampleBuffer) -> Void)?
  
  private func convertToData(buffer: CMSampleBuffer) {
    guard let dataBuffer = CMSampleBufferGetDataBuffer(buffer) else { return }
    var totalLength = 0
    var dataPointer: UnsafeMutablePointer<Int8>?
    CMBlockBufferGetDataPointer(dataBuffer,
                                atOffset: 0,
                                lengthAtOffsetOut: nil,
                                totalLengthOut: &totalLength,
                                dataPointerOut: &dataPointer)
    if let pointer = dataPointer {
      let data = Data(bytes: pointer, count: totalLength)
      naluHandling?(data, Int(buffer.presentationTimeStamp.value))
    }
  }
  
  private func changeFormat(buffer: AVAudioPCMBuffer, time: CMTime) {
    let inputFormat = buffer.format
    let outputFormat = AudioMediaFrame.ALawFormatHelper(sampleRate: 16000)
    let converter = AVAudioConverter(from: inputFormat, to: outputFormat)
    let bufferDuration = AVAudioSession.sharedInstance().ioBufferDuration
    let frameCount = AVAudioFrameCount(
      outputFormat.sampleRate * bufferDuration
    )
    let newbuffer = AVAudioPCMBuffer(pcmFormat: outputFormat,
                                     frameCapacity: frameCount)!

    let inputBlock: AVAudioConverterInputBlock = { _, outStatus -> AVAudioBuffer? in
      outStatus.pointee = AVAudioConverterInputStatus.haveData
      let audioBuffer: AVAudioBuffer = buffer
      return audioBuffer
    }

    var error: NSError?

    converter?.convert(to: newbuffer,
                       error: &error,
                       withInputFrom: inputBlock)
    
    let audioData = newbuffer.audioBufferList.pointee.mBuffers
    if let mData = audioData.mData {
      let length = Int(audioData.mDataByteSize)
      let data = Data(bytes: mData, count: length)
      naluHandling?(data, Int(time.value))
    }
  }
  
  private func convert(from sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {
    guard let description = CMSampleBufferGetFormatDescription(sampleBuffer) else {
      return nil
    }
    let numSamples = AVAudioFrameCount(UInt(CMSampleBufferGetNumSamples(sampleBuffer)))
    let format = AVAudioFormat(cmAudioFormatDescription: description)
    
    guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: numSamples) else {
      return nil
    }
    audioBuffer.frameLength = numSamples
    CMSampleBufferCopyPCMDataIntoAudioBufferList(sampleBuffer, at: 0, frameCount: Int32(numSamples), into: audioBuffer.mutableAudioBufferList)
    
    return audioBuffer
  }
}

// MARK: - AVCaptureAudioDataOutputSampleBufferDelegate

@available(iOS 13.0, *)
extension LiveAudioEncoder: AVCaptureAudioDataOutputSampleBufferDelegate {
  public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let audioBuf = convert(from: sampleBuffer) else {
      return
    }
    changeFormat(buffer: audioBuf, time: sampleBuffer.presentationTimeStamp)
  }
}

class Converter {
    static func configureSampleBuffer(pcmBuffer: AVAudioPCMBuffer) -> CMSampleBuffer? {
        let audioBufferList = pcmBuffer.mutableAudioBufferList
        let asbd = pcmBuffer.format.streamDescription

        var sampleBuffer: CMSampleBuffer? = nil
        var format: CMFormatDescription? = nil
        
        var status = CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault,
                                                         asbd: asbd,
                                                   layoutSize: 0,
                                                       layout: nil,
                                                       magicCookieSize: 0,
                                                       magicCookie: nil,
                                                       extensions: nil,
                                                       formatDescriptionOut: &format);
        if (status != noErr) { return nil; }
        
        var timing: CMSampleTimingInfo = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: Int32(asbd.pointee.mSampleRate)),
                                                            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
                                                            decodeTimeStamp: CMTime.invalid)
        status = CMSampleBufferCreate(allocator: kCFAllocatorDefault,
                                      dataBuffer: nil,
                                      dataReady: false,
                                      makeDataReadyCallback: nil,
                                      refcon: nil,
                                      formatDescription: format,
                                      sampleCount: CMItemCount(pcmBuffer.frameLength),
                                      sampleTimingEntryCount: 1,
                                      sampleTimingArray: &timing,
                                      sampleSizeEntryCount: 0,
                                      sampleSizeArray: nil,
                                      sampleBufferOut: &sampleBuffer);
        if (status != noErr) { NSLog("CMSampleBufferCreate returned error: \(status)"); return nil }
        
        status = CMSampleBufferSetDataBufferFromAudioBufferList(sampleBuffer!,
                                                                blockBufferAllocator: kCFAllocatorDefault,
                                                                blockBufferMemoryAllocator: kCFAllocatorDefault,
                                                                flags: 0,
                                                                bufferList: audioBufferList);
        if (status != noErr) { NSLog("CMSampleBufferSetDataBufferFromAudioBufferList returned error: \(status)"); return nil; }
        
        return sampleBuffer
    }
}
