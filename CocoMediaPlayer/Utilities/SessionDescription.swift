//
/**
 * @file      SessionDescription.swift
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

public final class SessionDescription: Equatable, Hashable, CustomDebugStringConvertible {
  public final class Builder {
    final var attributesBuilder: [String: String]
    final var mediaDescriptionListBuilder: [MediaDescription]
      public var bitrate: Int
      public var sessionName: String?
      public var origin: String?
      public var timing: String?
      public var connection: String?
      public var key: String?
      public var sessionInfo: String?
      public var emailAddress: String?
      public var phoneNumber: String?
      public var uri: URL?

    public init() {
      self.attributesBuilder = [String: String]()
      self.mediaDescriptionListBuilder = [MediaDescription]()
      self.bitrate = -1 // Format.NO_VALUE
    }

    public func addAttribute(name: String, value: String) {
      self.attributesBuilder[name] = value
    }

    public func addAttributes(attributes: [String: String]) -> Builder {
      for attribute in attributes {
        self.addAttribute(name: attribute.key, value: attribute.value)
      }
      return self
    }

    public func addMediaDescription(_ mediaDescription: MediaDescription) {
      self.mediaDescriptionListBuilder.append(mediaDescription)
    }

    public func build() -> SessionDescription {
      return SessionDescription(builder: self)
    }
  }

  public static let SUPPORTED_SDP_VERSION = "0"
  public static let ATTR_CONTROL = "control"
  public static let ATTR_FMTP = "fmtp"
  public static let ATTR_LENGTH = "length"
  public static let ATTR_RANGE = "range"
  public static let ATTR_RTPMAP = "rtpmap"
  public static let ATTR_TOOL = "tool"
  public static let ATTR_TYPE = "type"

  final let attributes: [String: String]
  public final let mediaDescriptionList: [MediaDescription]
  final var sessionName: String
  final var origin: String
  final var timing: String
  final var bitrate: Int
  final var uri: URL?
  final var connection: String?
  final var key: String?
  final var emailAddress: String?
  final var phoneNumber: String?
  final var sessionInfo: String?

  public init(builder: SessionDescription.Builder) {
    self.attributes = builder.attributesBuilder
    self.mediaDescriptionList = builder.mediaDescriptionListBuilder
    self.sessionName = builder.sessionName ?? String()
    self.origin = builder.origin ?? String()
    self.timing = builder.timing ?? String()
    self.uri = builder.uri
    self.connection = builder.connection
    self.bitrate = builder.bitrate
    self.key = builder.key
    self.emailAddress = builder.emailAddress
    self.phoneNumber = builder.phoneNumber
    self.sessionInfo = builder.sessionInfo
  }

  public static func == (lhs: SessionDescription, rhs: SessionDescription) -> Bool {
    return lhs.bitrate == rhs.bitrate
      && lhs.attributes == rhs.attributes
      && lhs.mediaDescriptionList == rhs.mediaDescriptionList
      && lhs.origin == rhs.origin
      && lhs.sessionName == rhs.sessionName
      && lhs.timing == rhs.timing
      && lhs.sessionInfo == rhs.sessionInfo
      && lhs.uri == rhs.uri
      && lhs.emailAddress == rhs.emailAddress
      && lhs.phoneNumber == rhs.phoneNumber
      && lhs.connection == rhs.connection
      && lhs.key == rhs.key
  }

  public func hash(into hasher: inout Hasher) {
    var result = 7
    result = 31 * result + self.attributes.hashValue
    result = 31 * result + self.mediaDescriptionList.hashValue
    result = 31 * result + self.origin.hashValue
    result = 31 * result + self.sessionName.hashValue
    result = 31 * result + self.timing.hashValue
    result = 31 * result + self.bitrate
    result = 31 * result + (self.sessionInfo == nil ? 0 : self.sessionInfo.hashValue)
    result = 31 * result + (self.uri == nil ? 0 : self.uri.hashValue)
    result = 31 * result + (self.emailAddress == nil ? 0 : self.emailAddress.hashValue)
    result = 31 * result + (self.phoneNumber == nil ? 0 : self.phoneNumber.hashValue)
    result = 31 * result + (self.connection == nil ? 0 : self.connection.hashValue)
    result = 31 * result + (self.key == nil ? 0 : self.key.hashValue)
    hasher.combine(result)
  }
  
  public var debugDescription: String {
    return """
    SessionDescription {
      attributes=\(self.attributes)
      , mediaDescriptionList=\(self.mediaDescriptionList)
      , sessionName='\(self.sessionName)'
      , origin='\(self.origin)'
      , timing='\(self.timing)'
      , bitrate=\(self.bitrate)
      , uri=\(String(describing: self.uri))
      , connection='\(String(describing: self.connection))'
      , key='\(String(describing: self.key))'
      , emailAddress='\(String(describing: self.emailAddress))'
      , phoneNumber='\(String(describing: self.phoneNumber))'
      , sessionInfo='\(String(describing: self.sessionInfo))'
    }
    """
  }
}
