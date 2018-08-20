//  Created by abonham on 21/8/18.

import Foundation

enum Operand {
  case none
  case single(UInt8)
  case double(UInt8, UInt8)
  case combined(UInt16)
  case address(UInt16)
}

struct Opcode {
  typealias OpcodeFetch = () -> Opcode
  
  let length: UInt16
  let executionBlock: (GBCpu, Operand) -> Void
  
  static let ops: [OpcodeFetch] = {
    var opArray = [OpcodeFetch](repeating: Opcode.noop, count: Int(UInt8.max))
    opArray[0x33] = Opcode.ldsp
    opArray[0xAF] = Opcode.xorA
    return opArray
  }()
}

extension Opcode {
  
  static func noop() -> Opcode {
    return Opcode(length: 0) { _,_ in fatalError() }
  }
  
  //33
  static func ldsp() -> Opcode {
    return Opcode(length: 3) { cpu, operand in
      switch operand {
      case .double(let first, let second):
        let value = combineValues(high: first, low: second)
        cpu.sp.value = value
      default:
        fatalError()
      }
    }
  }
  
  //AF
  static func xorA() -> Opcode {
    return Opcode(length: 1) { cpu, _ in
      cpu.a.value = cpu.a.value ^ cpu.a.value
      cpu.f.setZ(cpu.a.value == 0)
      cpu.f.setS(false)
      cpu.f.setC(false)
      cpu.f.setHC(false)
    }
  }
}

