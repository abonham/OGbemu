//  Created by abonham on 22/8/18.

import Foundation

extension Opcode {
  typealias U = RegisterProtocol
  static let extendedOps: [Opcode] = {
    var opArray = [Opcode](repeating: Opcode.noop, count: Int(UInt8.max))

    for i in 0..<keyPaths.count {
      opArray[0x40 + i] = makeBitCheckOpcode(keyPath: keyPaths[i], bitPattern: 0b00000001)
      opArray[0x48 + i] = makeBitCheckOpcode(keyPath: keyPaths[i], bitPattern: 0b00000010)
      opArray[0x50 + i] = makeBitCheckOpcode(keyPath: keyPaths[i], bitPattern: 0b00000100)
      opArray[0x58 + i] = makeBitCheckOpcode(keyPath: keyPaths[i], bitPattern: 0b00001000)
      opArray[0x60 + i] = makeBitCheckOpcode(keyPath: keyPaths[i], bitPattern: 0b00010000)
      opArray[0x68 + i] = makeBitCheckOpcode(keyPath: keyPaths[i], bitPattern: 0b00100000)
      opArray[0x70 + i] = makeBitCheckOpcode(keyPath: keyPaths[i], bitPattern: 0b01000000)
      opArray[0x78 + i] = makeBitCheckOpcode(keyPath: keyPaths[i], bitPattern: 0b10000000)
    }
    return opArray
  }()
  
  static func makeBitCheckOpcode(keyPath: PartialKeyPath<GBCpu>, bitPattern: UInt8) -> Opcode {
    return Opcode(length: 2, operandType: .none, name: "bit check \(keyPath): \(bitPattern)") { cpu, _ in
      let value: Int
      let register = cpu[keyPath: keyPath]
      switch register {
      case let register as Register:
        value = Int(register.value)
      case let register as CombinedRegister:
        value = Int(register.value)
      default:
        fatalError()
      }
      let opposite = value & Int(bitPattern) > 0
      cpu.f.setZ(!opposite)
      cpu.f.setHC(true)
      cpu.f.setS(false)
    }
  }
}
