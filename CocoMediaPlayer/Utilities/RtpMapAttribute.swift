//
/**
 * @file      RtpMapAttribute.swift
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

public final class RtpMapAttribute: Equatable, Hashable, CustomDebugStringConvertible {
  /**
   * Parses the RTPMAP attribute value (with the part "a=rtpmap:" removed).
   */
  public static func parse(rtpMapString: String) -> RtpMapAttribute {
    let rtpmapInfo = rtpMapString.components(separatedBy: " ")
    assert(rtpmapInfo.count == 2)
    let payloadType = Int(rtpmapInfo[0]) ?? -1

    let mediaInfo = rtpmapInfo[1].components(separatedBy: "/")
    assert(mediaInfo.count >= 2)
    let clockRate = Int(mediaInfo[1]) ?? -1
    var encodingParameters = -1 // C.INDEX_UNSET
    if mediaInfo.count == 3 {
      encodingParameters = Int(mediaInfo[2]) ?? -1
    }

    return RtpMapAttribute(payload: payloadType,
                           mediaEncoding: mediaInfo[0],
                           clockRate: clockRate,
                           encodingParameters: encodingParameters)
  }

  public let payloadType: Int
  public let mediaEncoding: String
  public let clockRate: Int
  public let encodingParameters: Int

  public init(payload: Int, mediaEncoding: String, clockRate: Int, encodingParameters: Int) {
    self.payloadType = payload
    self.mediaEncoding = mediaEncoding
    self.clockRate = clockRate
    self.encodingParameters = encodingParameters
  }

  public static func == (lhs: RtpMapAttribute, rhs: RtpMapAttribute) -> Bool {
    return lhs.payloadType == rhs.payloadType
      && lhs.mediaEncoding.compare(rhs.mediaEncoding) == .orderedSame
      && lhs.clockRate == rhs.clockRate
      && lhs.encodingParameters == rhs.encodingParameters
  }

  public func hash(into hasher: inout Hasher) {
    var result = 7
    result = 31 * result + self.payloadType
    result = 31 * result + self.mediaEncoding.hashValue
    result = 31 * result + self.clockRate
    result = 31 * result + self.encodingParameters
    hasher.combine(result)
  }

  public var debugDescription: String {
    return """
    RtpMapAttribute {
    payloadType=\(self.payloadType)
    , mediaEncoding='\(self.mediaEncoding)'
    , clockRate=\(self.clockRate)
    , encodingParameters=\(self.encodingParameters)
    }
    """
  }
}
