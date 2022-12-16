//
/**
 * @file      MediaDescription.swift
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

public final class MediaDescription: Equatable, Hashable, CustomDebugStringConvertible {
  public final class Builder {
    final var mediaType: String
    final var port: Int
    final var transportProtocol: String
    final var attributesBuilder: [String: String]

    var bitrate: Int

    var mediaTitle: String?
    var connection: String?
    var key: String?

    private final var outOfBandRtpMapBuilder: [RtpMapAttribute]
    private final var outOfBandFmtpBuilder: [FmtpAttribute]
    private final var rtpMapBuilder: [String]
    private final var fmtpBuilder: [String]

    final let payloadType: [Int]

    public init(mediaType: String, port: Int, transportProtocol: String, payloadTypes: [Int]) {
      self.payloadType = payloadTypes
      self.mediaType = mediaType
      self.port = port
      self.transportProtocol = transportProtocol
      self.attributesBuilder = [String: String]()
      self.fmtpBuilder = [String]()
      self.rtpMapBuilder = [String]()
      self.outOfBandFmtpBuilder = [FmtpAttribute]()
      self.outOfBandRtpMapBuilder = [RtpMapAttribute]()
      self.bitrate = -1 // Format.NO_VALUE
    }
      
      public func addAttribute(name: String, value: String) {
          if name.compare(SessionDescription.ATTR_RTPMAP) == .orderedSame {
              self.rtpMapBuilder.append(value)
          } else if name.compare(SessionDescription.ATTR_FMTP) == .orderedSame {
              self.fmtpBuilder.append(value)
          } else {
              
              self.attributesBuilder[name] = value
          }
      }

    public func addAttributes(attributes: [String: String]) -> Builder {
      for attribute in attributes {
        self.addAttribute(name: attribute.key, value: attribute.value)
      }
      return self
    }

    public func addRtpMapAttribute(rtpMapAttribute: RtpMapAttribute) {
      self.outOfBandRtpMapBuilder.append(rtpMapAttribute)
    }

    public func addFmtpAttribute(fmtpAttribute: FmtpAttribute) -> Builder {
      self.outOfBandFmtpBuilder.append(fmtpAttribute)
      return self
    }

    public func build() -> MediaDescription {
      let attributes: [String: String] = self.attributesBuilder
      var rtpMapAttributesBuilder = [RtpMapAttribute]()
      var fmtpAttributesBuilder = [FmtpAttribute]()

      rtpMapAttributesBuilder.append(contentsOf: self.outOfBandRtpMapBuilder)
      fmtpAttributesBuilder.append(contentsOf: self.outOfBandFmtpBuilder)

      for rtpMapAttribute in self.rtpMapBuilder {
        let item = RtpMapAttribute.parse(rtpMapString: rtpMapAttribute)
        rtpMapAttributesBuilder.append(item)
      }

      for fmtpAttribute in self.fmtpBuilder {
        let item = FmtpAttribute.parse(fmtpAttributeValue: fmtpAttribute)
        fmtpAttributesBuilder.append(item)
      }

      return MediaDescription(builder: self,
                              attributes: attributes,
                              rtpMapAttributes: rtpMapAttributesBuilder,
                              fmtpAttributes: fmtpAttributesBuilder)
    }
  }

  public final let MEDIA_TYPE_AUDIO: String = "audio"
  public final let MEDIA_TYPE_VIDEO: String = "video"
  public final let RTP_AVP_PROFILE: String = "RTP/AVP"

  public final let SEND_ONLY = "sendonly"
  public final let RECV_ONLY = "recvonly"
  public final let SEND_RECV = "sendrecv"
  public final let INACTIVE = "inactive"

  public final var mediaType: String
  public final var port: Int
  public final var transportProtocol: String
  public final var bitrate: Int

  public final var mediaTitle: String?
  public final var connection: String?
  public final var key: String?

  public final var attributes: [String: String]
  public final var rtpMapAttributes: [RtpMapAttribute]
  public final var fmtpAttributes: [FmtpAttribute]
  public final var payloadType: [Int]

  init(builder: MediaDescription.Builder,
       attributes: [String: String],
       rtpMapAttributes: [RtpMapAttribute],
       fmtpAttributes: [FmtpAttribute])
  {
    assert(rtpMapAttributes.count != 0)

    self.mediaType = builder.mediaType
    self.port = builder.port
    self.transportProtocol = builder.transportProtocol
    self.payloadType = builder.payloadType
    self.mediaTitle = builder.mediaTitle
    self.connection = builder.connection
    self.bitrate = builder.bitrate
    self.key = builder.key
    self.attributes = attributes
    self.rtpMapAttributes = rtpMapAttributes
    self.fmtpAttributes = fmtpAttributes
  }

  public static func == (lhs: MediaDescription, rhs: MediaDescription) -> Bool {
    return lhs.mediaType == rhs.mediaType
      && lhs.transportProtocol == rhs.transportProtocol
      && lhs.mediaTitle == rhs.mediaTitle
      && lhs.connection == rhs.connection
      && lhs.key == rhs.key
      && lhs.attributes == rhs.attributes
      && lhs.rtpMapAttributes == rhs.rtpMapAttributes
      && lhs.fmtpAttributes == rhs.fmtpAttributes
      && lhs.payloadType == rhs.payloadType
  }

  public func hash(into hasher: inout Hasher) {
    var result = self.mediaType.hashValue
    result = result + self.port.hashValue
    result = result + self.transportProtocol.hashValue
    result = result + self.bitrate.hashValue
    result = result + (self.mediaTitle ?? String()).hashValue
    result = result + (self.connection ?? String()).hashValue
    result = result + (self.key ?? String()).hashValue
    result = result + self.attributes.hashValue
    result = result + self.rtpMapAttributes.hashValue
    result = result + self.fmtpAttributes.hashValue
    result = result + self.payloadType.hashValue
    hasher.combine(result)
  }

  public var debugDescription: String {
    return """
    MediaDescription {
    mediaType='\(self.mediaType)'
    , port=\(self.port),
    , transportProtocol='\(self.transportProtocol)'
    , bitrate=\(self.bitrate)
    , mediaTitle='\(self.mediaTitle ?? String())'
    , connection='\(self.connection ?? String())'
    , key='\(self.key ?? String())'
    , attributes=\(self.attributes)
    , rtpMapAttributes=\(self.rtpMapAttributes)
    , fmtpAttributes=\(self.fmtpAttributes)
    , payloadType=\(self.payloadType)
    }
    """
  }
}
