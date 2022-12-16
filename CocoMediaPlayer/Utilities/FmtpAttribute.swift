//
/**
 * @file      FmtpAttribute.swift
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

public final class FmtpAttribute: Equatable, Hashable, CustomDebugStringConvertible {
  final var format: String
  final var parameters: [String: String]

  init(format: String, parameters: [String: String]) {
    self.format = format
    self.parameters = parameters
  }

  public static func parse(fmtpAttributeValue: String) -> FmtpAttribute {
    let fmtpComponents = fmtpAttributeValue.split(separator: " ", maxSplits: 1).map(String.init)
    assert(fmtpComponents.count == 2 && !fmtpAttributeValue.isEmpty)

    let parameters = fmtpComponents[1].components(separatedBy: ";\\s?")
    var formatParametersBuilder = [String: String]()

    for parameter in parameters {
      let parameterPair = parameter.split(separator: "=", maxSplits: 1).map(String.init)
      assert(parameterPair.count == 2)
      let key = parameterPair[0]
      let value = parameterPair[1]
      formatParametersBuilder[key] = value
    }

    return FmtpAttribute(format: String(fmtpComponents[0]),
                         parameters: formatParametersBuilder)
  }

  public static func == (lhs: FmtpAttribute, rhs: FmtpAttribute) -> Bool {
    return lhs.parameters == rhs.parameters
      && lhs.format.compare(rhs.format) == .orderedSame
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.format.hashValue + self.parameters.hashValue)
  }

  public var debugDescription: String {
    return """
    FmtpAttribute {
    format='\(self.format)'
    , parameters=\(self.parameters)
    }
    """
  }
}
