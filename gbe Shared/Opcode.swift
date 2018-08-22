//  Created by abonham on 21/8/18.

import Foundation

enum OperandType {
  /*
   d8  means immediate 8 bit data
   d16 means immediate 16 bit data
   a8  means 8 bit unsigned data, which are added to $FF00 in certain instructions (replacement for missing IN and OUT instructions)
   a16 means 16 bit address
   r8  means 8 bit signed data, which are added to program counter
 */
  case none, immediate8, immediate16, unsigned8, address, signed8
}

enum Operand {
  case none
  case d8(UInt8)
  case d16(UInt16)
  case a8(UInt8)
  case a16(UInt16)
  case r8(UInt16)
}

struct Opcode {
  typealias OpcodeFetch = () -> Opcode
  
  let length: UInt16
  let operandType: OperandType
  let name: String?
  let executionBlock: (GBCpu, Operand) -> Void
  
  static let ops: [OpcodeFetch] = {
    var opArray = [OpcodeFetch](repeating: Opcode.noop, count: Int(UInt8.max))
    opArray[0x21] = ldhlImmediate
    opArray[0x31] = ldsp
    opArray[0x32] = ldHLDa
    opArray[0xAF] = xorA
    return opArray
  }()
  
  init(length: UInt16, operandType: OperandType, name: String? = nil, executionBlock: @escaping (GBCpu, Operand) -> Void) {
    self.length = length
    self.operandType = operandType
    self.name = name
    self.executionBlock = executionBlock
  }
}

extension Opcode {
  
  //00
  static func noop() -> Opcode {
    return Opcode(length: 1, operandType: .none) { _,_ in return }
  }
  
  //21 LD HL, d16
  static func ldhlImmediate() -> Opcode {
    return Opcode(length: 3, operandType: .immediate16, name: "ld hl,d16") { cpu, operand in
      switch operand {
      case .d16(let value):
        cpu.hl.value = value
      default:
        fatalError()
      }
    }
  }
  
  //31 LD SP, d16
  static func ldsp() -> Opcode {
    return Opcode(length: 3, operandType: .immediate16, name: "ldsp") { cpu, operand in
      switch operand {
      case .d16(let value):
        cpu.sp.value = value
      default:
        fatalError()
      }
    }
  }
  
  //32 LD (HL-), A
  static func ldHLDa() -> Opcode {
    return Opcode(length: 1, operandType: .none, name: "LD (HL-), A") { cpu, _ in
      cpu.memoryController.set(cpu.hl.value, value: cpu.a.value)
      cpu.hl.decrement()
    }
  }
  //AF, XOR A
  static func xorA() -> Opcode {
    return Opcode(length: 1, operandType: .none, name: "XOR A") { cpu, _ in
      cpu.a.value = cpu.a.value ^ cpu.a.value
      cpu.f.setZ(cpu.a.value == 0)
      cpu.f.setS(false)
      cpu.f.setC(false)
      cpu.f.setHC(false)
    }
  }
}

