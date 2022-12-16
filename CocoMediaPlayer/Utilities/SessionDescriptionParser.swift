//
/**
 * @file      SessionDescriptionParser.swift
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

public final class SessionDescriptionParser {
  enum ParserError: Error {
    case invalid
    case unsupported(reason: String)
    case illegalLength(attribute: String)
    case nilValue
  }

  private static let SDP_LINE_PATTERN = #"([a-z])=\s?(.+)"#
  private static let ATTRIBUTE_PATTERN = #"([0-9A-Za-z-]+)(?::(.*))?"#

  // above regex doesn't  assume the case of: "audio 0 RTP/AVP 97 98"
  private static let ATTRIBUTE_SPLITTER = ":"
  private static let MEDIA_DESCRIPTION_SPLITTER = " "
  private static let FMTP_DESCRIPTION_SPLITTER = ";"
  private static let FMTP_DESCRIPTION_ASSIGNMENT_SPLITTER = "="

  private static let VERSION_TYPE = "v"
  private static let ORIGIN_TYPE = "o"
  private static let SESSION_TYPE = "s"
  private static let INFORMATION_TYPE = "i"
  private static let URI_TYPE = "u"
  private static let EMAIL_TYPE = "e"
  private static let PHONE_NUMBER_TYPE = "p"
  private static let CONNECTION_TYPE = "c"
  private static let BANDWIDTH_TYPE = "b"
  private static let TIMING_TYPE = "t"
  private static let KEY_TYPE = "k"
  private static let ATTRIBUTE_TYPE = "a"
  private static let MEDIA_TYPE = "m"
  private static let REPEAT_TYPE = "r"
  private static let ZONE_TYPE = "z"

  private static let CR = "\r"
  private static let LF = "\n"
  private static let CRLF = "\r\n"

  private static let RTP_MAP_FORMAT = "\(SessionDescription.ATTR_RTPMAP)\(ATTRIBUTE_SPLITTER)%d %s/%d"
  private static let RTP_MAP_ENCODED_PARAM_FORMAT = "\(SessionDescription.ATTR_RTPMAP)\(ATTRIBUTE_SPLITTER)%d %@/%d/%d"

  private static let FMTP_FORMAT = "\(SessionDescription.ATTR_FMTP)\(ATTRIBUTE_SPLITTER)%s %s"

  private static let SDP_ATTRIBUTE_FORMAT = "%@:%@"
  private static let SDP_MESSAGE_FORMAT = "%@=%@\(CRLF)"

  public static func parse(sdpString: String) throws -> SessionDescription {
    let sessionDescriptionBuilder = SessionDescription.Builder()
    var mediaDescriptionBuilder: MediaDescription.Builder?

    let lines = sdpString.components(separatedBy: sdpString.contains(self.CRLF) ? self.CRLF : self.LF)
    for line in lines {
      if line == "" {
        continue
      }
      var matched = line.matches(regex: self.SDP_LINE_PATTERN)
      if matched.count == 0 {
        throw ParserError.invalid
      }

      let sdpType = matched[0][1]
      let sdpValue = matched[0][2]

      switch sdpType {
        case self.VERSION_TYPE:
          if SessionDescription.SUPPORTED_SDP_VERSION != sdpValue {
            throw ParserError.unsupported(reason: "SDP version \(sdpValue) is not supported.")
          }
        case self.ORIGIN_TYPE:
          sessionDescriptionBuilder.origin = sdpValue
        case self.SESSION_TYPE:
          sessionDescriptionBuilder.sessionName = sdpValue
        case self.INFORMATION_TYPE:
          if mediaDescriptionBuilder == nil {
            sessionDescriptionBuilder.sessionInfo = sdpValue
          } else {
            mediaDescriptionBuilder?.mediaTitle = sdpValue
          }

        case self.URI_TYPE:
          sessionDescriptionBuilder.uri = URL(string: sdpValue)

        case self.EMAIL_TYPE:
          sessionDescriptionBuilder.emailAddress = sdpValue

        case self.PHONE_NUMBER_TYPE:
          sessionDescriptionBuilder.phoneNumber = sdpValue

        case self.CONNECTION_TYPE:
          if mediaDescriptionBuilder == nil {
            sessionDescriptionBuilder.connection = sdpValue
          } else {
            mediaDescriptionBuilder?.connection = sdpValue
          }

        case self.BANDWIDTH_TYPE:
          let bandwidthComponents = sdpValue.components(separatedBy: ":\\s?")
          assert(bandwidthComponents.count == 2)
          let bitrateKbps = Int(bandwidthComponents[1]) ?? 0

          // Converting kilobits per second to bits per second.
          if mediaDescriptionBuilder == nil {
            sessionDescriptionBuilder.bitrate = (bitrateKbps * 1000)
          } else {
            mediaDescriptionBuilder?.bitrate = (bitrateKbps * 1000)
          }

        case self.TIMING_TYPE:
          sessionDescriptionBuilder.timing = sdpValue

        case self.KEY_TYPE:
          if mediaDescriptionBuilder == nil {
            sessionDescriptionBuilder.key = sdpValue
          } else {
            mediaDescriptionBuilder?.key = sdpValue
          }

        case self.ATTRIBUTE_TYPE:
          matched = sdpValue.matches(regex: self.ATTRIBUTE_PATTERN)
          if matched.count == 0 {
            throw ParserError.invalid
          }

          let attributeName = matched[0][1]
          // The second catching group is optional and thus could be null.
          let attributeValue = matched[0][2]

          if mediaDescriptionBuilder == nil {
            sessionDescriptionBuilder.addAttribute(name: attributeName, value: attributeValue)
          } else {
            _ = mediaDescriptionBuilder?.addAttribute(name: attributeName, value: attributeValue)
          }

        case self.MEDIA_TYPE:
          if let mediaDescriptionBuilder = mediaDescriptionBuilder {
            self.addMediaDescriptionToSession(sessionDescriptionBuilder, mediaDescriptionBuilder)
          }
          mediaDescriptionBuilder = try? self.parseMediaDescription(sdpValue)
        case self.REPEAT_TYPE,
             self.ZONE_TYPE:
          break
        default:
          break
      }
    }

    if let mediaDescriptionBuilder = mediaDescriptionBuilder {
      self.addMediaDescriptionToSession(sessionDescriptionBuilder, mediaDescriptionBuilder)
    }

    return sessionDescriptionBuilder.build()
  }

  private static func formatSDP(type: String, value: String) -> String {
    return String(format: self.SDP_MESSAGE_FORMAT, type, value)
  }

  private static func formatAttributeEntry(attribute: Dictionary<String, String>.Element) -> String {
    if attribute.value == "" {
      return attribute.key
    }

    return String(format: self.SDP_ATTRIBUTE_FORMAT, attribute.key, attribute.value)
  }

  private static func formatRtpMap(_ rtpMap: RtpMapAttribute) -> String {
    if rtpMap.encodingParameters == -1 { // C.INDEX_UNSET
      return String(format: self.RTP_MAP_FORMAT,
                    rtpMap.payloadType,
                    rtpMap.mediaEncoding,
                    rtpMap.clockRate)
    } else {
      return String(format: self.RTP_MAP_ENCODED_PARAM_FORMAT,
                    rtpMap.payloadType,
                    rtpMap.mediaEncoding,
                    rtpMap.clockRate,
                    rtpMap.encodingParameters)
    }
  }

  private static func formatFmtp(_ fmtpAttribute: FmtpAttribute) -> String {
    var firstEntry = true
    var fmtp = String()

    for param in fmtpAttribute.parameters {
      if !firstEntry {
        fmtp.append(self.FMTP_DESCRIPTION_SPLITTER)
      }

      firstEntry = false

      fmtp.append(param.key)
      fmtp.append(self.FMTP_DESCRIPTION_ASSIGNMENT_SPLITTER)
      fmtp.append(param.value)
    }

    return String(format: self.FMTP_FORMAT, fmtpAttribute.format, fmtp)
  }

  public static func unParse(sessionDescription: SessionDescription, strict: Bool = true) -> String {
    var sdpBuilder = String()
    sdpBuilder.append(self.formatSDP(type: self.VERSION_TYPE, value: SessionDescription.SUPPORTED_SDP_VERSION))
    sdpBuilder.append(self.formatSDP(type: self.ORIGIN_TYPE, value: sessionDescription.origin))
    sdpBuilder.append(self.formatSDP(type: self.SESSION_TYPE, value: sessionDescription.sessionName))
    sdpBuilder.append(self.formatSDP(type: self.TIMING_TYPE, value: sessionDescription.timing))

    if let uri = sessionDescription.uri {
      sdpBuilder.append(self.formatSDP(type: self.URI_TYPE, value: uri.absoluteString))
    }

    if let sessionInfo = sessionDescription.sessionInfo {
      sdpBuilder.append(self.formatSDP(type: self.INFORMATION_TYPE, value: sessionInfo))
    }

    if let key = sessionDescription.key {
      sdpBuilder.append(self.formatSDP(type: self.KEY_TYPE, value: key))
    }

    self.appendAttributes(&sdpBuilder,
                          attributes: sessionDescription.attributes)
    try? self.appendMedia(&sdpBuilder, sessionDescription.mediaDescriptionList, strict)
    return sdpBuilder
  }

  private static func appendMedia(_ sdpBuilder: inout String, _ mediaDescriptionList: [MediaDescription], _ strict: Bool) throws {
    for mediaDesc in mediaDescriptionList {
      if strict {
        if mediaDesc.payloadType.count != 1 {
          throw ParserError.illegalLength(attribute: "payload")
        }

        if mediaDesc.rtpMapAttributes.count != 1 {
          throw ParserError.illegalLength(attribute: "rtpMapAttributes")
        }

        if mediaDesc.fmtpAttributes.count > 1 {
          throw ParserError.illegalLength(attribute: "fmtpAttributes")
        }
      }

      var mediaTypeValue = String()

      mediaTypeValue.append(mediaDesc.mediaType)
      mediaTypeValue.append(self.MEDIA_DESCRIPTION_SPLITTER)

      mediaTypeValue.append(String(describing: mediaDesc.port))
      mediaTypeValue.append(self.MEDIA_DESCRIPTION_SPLITTER)

      mediaTypeValue.append(mediaDesc.transportProtocol)

      for item in mediaDesc.payloadType {
        mediaTypeValue.append(self.MEDIA_DESCRIPTION_SPLITTER)
        mediaTypeValue.append(String(describing: item))
      }

      sdpBuilder.append(self.formatSDP(type: self.MEDIA_TYPE, value: mediaTypeValue))

      if let mediaTitle = mediaDesc.mediaTitle {
        sdpBuilder.append(self.formatSDP(type: self.INFORMATION_TYPE, value: mediaTitle))
      }

      if let connection = mediaDesc.connection {
        sdpBuilder.append(self.formatSDP(type: self.CONNECTION_TYPE, value: connection))
      }

      if let key = mediaDesc.key {
        sdpBuilder.append(self.formatSDP(type: self.KEY_TYPE, value: key))
      }

      for rtpMapAttribute in mediaDesc.rtpMapAttributes {
        sdpBuilder.append(self.formatSDP(type: self.ATTRIBUTE_TYPE, value: self.formatRtpMap(rtpMapAttribute)))
      }

      for fmtpAttribute in mediaDesc.fmtpAttributes {
        sdpBuilder.append(self.formatSDP(type: self.ATTRIBUTE_TYPE, value: self.formatFmtp(fmtpAttribute)))
      }

      self.appendAttributes(&sdpBuilder, attributes: mediaDesc.attributes)
    }
  }

  private static func appendAttributes(_ builder: inout String,
                                       attributes: [String: String])
  {
    for element in attributes {
      let attrib = self.formatAttributeEntry(attribute: element)
      builder.append(attrib)
    }
  }

  private static func addMediaDescriptionToSession(
    _ sessionDescriptionBuilder: SessionDescription.Builder,
    _ mediaDescriptionBuilder: MediaDescription.Builder
  ) {
    sessionDescriptionBuilder.addMediaDescription(mediaDescriptionBuilder.build())
  }

  private static func parseMediaDescription(_ line: String) throws -> MediaDescription.Builder {
    let groups = line.components(separatedBy: self.MEDIA_DESCRIPTION_SPLITTER)
    var index = 0
    let mediaType = groups[index]
    index = index + 1
    let portString = groups[index]
    index = index + 1
    let mProtocol = groups[index]
    index = index + 1
    let port = Int(portString) ?? -1
    var payloadTypes = [Int](repeating: 0, count: groups.count - index)

    for i in index ..< groups.count {
      payloadTypes[i - index] = Int(groups[i]) ?? 0
    }
    return MediaDescription.Builder(mediaType: mediaType,
                                    port: port,
                                    transportProtocol: mProtocol,
                                    payloadTypes: payloadTypes)
  }

  private init() {}
}
