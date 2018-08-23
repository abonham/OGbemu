//  Created by abonham on 21/8/18.

import Foundation

protocol RegisterProtocol {
  associatedtype U: FixedWidthInteger
  var value: U { get set }
  static var idKey: WritableKeyPath<Self, U> { get }
}

extension RegisterProtocol {
  mutating func decrement() {
    value -= 1
  }
}

final class Register: RegisterProtocol {
  var value: UInt8 = 0
  static var idKey: WritableKeyPath<Register, UInt8> = \value
}

struct Accumulator: RegisterProtocol {
  var value: UInt8 = 0
  static var idKey: WritableKeyPath<Accumulator, UInt8> = \value
}
struct Status: RegisterProtocol {
  static var idKey: WritableKeyPath<Status, UInt8> = \value
  var value: UInt8 {
    get {
      return z + s + hc + c
    }
    
    set {
      s = newValue & 0b10000000
      z = newValue & 0b01000000
      hc = newValue & 0b00010000
      c = newValue & 0b00100000
    }
  }
  private(set) var s: UInt8 = 0b00000000
  private(set) var z: UInt8 = 0b00000000
  private(set) var hc: UInt8 = 0b00000000
  private(set) var c: UInt8 = 0b00000000
  
  mutating func setZ(_ to: Bool) {
    z = to ? 0b10000000 : 0
  }
  
  mutating func setS(_ to: Bool) {
    s = to ? 0b01000000 : 0
  }
  
  mutating func setHC(_ to: Bool) {
    hc = to ? 0b00100000 : 0
  }
  
  mutating func setC(_ to: Bool) {
    c = to ? 0b00010000 : 0
  }
}

struct CombinedRegister: RegisterProtocol {
  static var idKey: WritableKeyPath<CombinedRegister, UInt16> = \value
  var value: UInt16 {
    set {
      let h = newValue & 0xFF00
      high.value = UInt8(h >> 8)
      let l = newValue & 0x00FF
      low.value = UInt8(l)
    }
    get {
      let h = UInt16(high.value) << 8
      let l = UInt16(low.value)
      return UInt16(h + l)
    }
  }
  var high: Register
  var low: Register
}

struct Counter: RegisterProtocol {
  static var idKey: WritableKeyPath<Counter, UInt16> = \value
  var value: UInt16 = 0
}
