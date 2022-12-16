//
/**
 * @file      Extensions.swift
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

import CoreMedia
import Foundation
import AVFoundation
import OSLog
import UIKit

// MARK: - String

extension String {
  func matches(regex: String) -> [[String]] {
    guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
    let nsString = self as NSString
    let results  = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
    return results.map { result in
      (0..<result.numberOfRanges).map {
        result.range(at: $0).location != NSNotFound
          ? nsString.substring(with: result.range(at: $0))
          : ""
      }
    }
  }
//  func match(_ regex: String) -> [[String]] {
//    let nsString = self as NSString
//    return (try? NSRegularExpression(pattern: regex, options: []))?.matches(in: self, options: [], range: NSMakeRange(0, nsString.length)).map { match in
//      (0..<match.numberOfRanges).map { match.range(at: $0).location == NSNotFound ? "" : nsString.substring(with: match.range(at: $0)) }
//    } ?? []
//  }
}

// MARK: - Data

extension Data {
  var hex: String { map { .init(format: "%02X ", $0) }.joined() }
  
  init(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
    let audioBuffer = buffer.audioBufferList.pointee.mBuffers
    self.init(bytes: audioBuffer.mData!, count: Int(audioBuffer.mDataByteSize))
  }
  
  func makePCMBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
    let streamDesc = format.streamDescription.pointee
    let frameCapacity = UInt32(count) / streamDesc.mBytesPerFrame
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else { return nil }
    
    buffer.frameLength = buffer.frameCapacity
    let audioBuffer = buffer.audioBufferList.pointee.mBuffers
    
    withUnsafeBytes { (bufferPointer) in
      guard let addr = bufferPointer.baseAddress else { return }
      audioBuffer.mData?.copyMemory(from: addr, byteCount: Int(audioBuffer.mDataByteSize))
    }
    
    return buffer
  }

  func toCMBlockBuffer() throws -> CMBlockBuffer {
    let dataLength = self.count

    var blockBuffer: CMBlockBuffer?
    var status: OSStatus = noErr

    status = CMBlockBufferCreateWithMemoryBlock(
      allocator: kCFAllocatorDefault,
      memoryBlock: nil,
      blockLength: dataLength,
      blockAllocator: kCFAllocatorDefault,
      customBlockSource: nil,
      offsetToData: 0,
      dataLength: dataLength,
      flags: kCMBlockBufferAssureMemoryNowFlag,
      blockBufferOut: &blockBuffer
    )

    guard status == noErr else {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }

    status = self.withUnsafeBytes {
      (vp: UnsafeRawBufferPointer) -> OSStatus in
      CMBlockBufferReplaceDataBytes(with: vp.baseAddress!, blockBuffer: blockBuffer!, offsetIntoDestination: 0, dataLength: dataLength)
    }

    guard status == noErr else {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }

    return blockBuffer! // assume non-null block buffer if noErr was returned
  }
}

// MARK: - Array

extension Array {
  var pointer: UnsafePointer<Element> {
    self.withUnsafeBufferPointer {
      ptr in ptr.baseAddress!
    }
  }

  var rawPointer: UnsafeMutablePointer<Element> {
    return .init(mutating: self.pointer)
  }

  var data: Data {
    let dataLength = self.count
    return self.withUnsafeBytes { bufferPointer in
      Data(bytes: bufferPointer.baseAddress!,
           count: MemoryLayout<Element>.size * dataLength)
    }
  }

  func toCMBlockBuffer() throws -> CMBlockBuffer {
    return try self.data.toCMBlockBuffer()
  }
}

// MARK: - UIView

extension UIView {
  func removeSublayers() {
    if let sublayers = self.layer.sublayers {
      for eachLayer in sublayers {
        eachLayer.removeFromSuperlayer()
      }
    }
  }
}

// MARK: - UInt32

extension UInt32 {
  var data: Data {
    var int = self
    return Data(bytes: &int, count: MemoryLayout<UInt32>.size)
  }
}

// MARK: - OSLog

public extension OSLog {
  static let defaultSubsystem = Bundle.main.bundleIdentifier! as String
  static let defaultCategory = "CocoMediaPlayer"

  convenience init(_ bundle: Bundle = .main, category: String? = nil) {
    let identifier = bundle.bundleIdentifier
    self.init(subsystem: identifier ?? Self.defaultSubsystem,
              category: category ?? Self.defaultCategory)
  }

  convenience init(_ aClass: AnyClass, category: String? = nil) {
    self.init(Bundle(for: aClass),
              category: category ?? String(describing: aClass))
  }
}

// MARK: - CMSampleBuffer

extension CMSampleBuffer {
  var isKeyFrame: Bool {
    let attachments =  CMSampleBufferGetSampleAttachmentsArray(self, createIfNecessary: true) as? [[CFString: Any]]
    
    let isNotKeyFrame = (attachments?.first?[kCMSampleAttachmentKey_NotSync] as? Bool) ?? false
    
    return !isNotKeyFrame
  }
}
