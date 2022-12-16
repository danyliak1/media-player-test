//
//  BitHelper.swift
//  sessions
//
//  Created by Vladyslav Danyliak on 11.11.2022.
//

import Foundation

final class BitHelper {
  
  class func angle(from bytes: [UInt8]) -> Int? {
    let bits = bytes.compactMap({ BitHelper.bits(fromByte: $0) }).reduce([], +)
    
    return BitHelper.decimal(from: bits)
  }
  
  private enum Bit: UInt8, CustomStringConvertible {
    case zero, one
    
    var description: String {
      switch self {
      case .one:
        return "1"
      case .zero:
        return "0"
      }
    }
  }
  
  private class func bits(fromByte byte: UInt8) -> [Bit] {
    var byte = byte
    var bits = [Bit](repeating: .zero, count: 8)
    for i in 0..<8 {
      let currentBit = byte & 0x01
      if currentBit != 0 {
        bits[i] = .one
      }
      
      byte >>= 1
    }
    return bits
  }
  
  private class func decimal(from bits: [Bit]) -> Int? {
    let bitsString = bits.compactMap({ $0.description }).joined()
    
    return Int(bitsString, radix: 2)
  }
}
