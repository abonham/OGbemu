//  Created by abonham on 22/8/18.

import Foundation

extension Opcode {
  static let extendedOps: [OpcodeFetch] = {
    var opArray = [OpcodeFetch](repeating: Opcode.noop, count: Int(UInt8.max))
    opArray[0x7C] = bit7h
    return opArray
  }()
  
  static func bit7h() -> Opcode {
    return Opcode(length: 1, operandType: .none, name: "extended Bit 7, h") { cpu, _ in
      let opposite = cpu.h.value & 0b10000000 > 0
      cpu.f.setZ(!opposite)
      cpu.f.setHC(true)
      cpu.f.setS(false)
    }
  }
}
