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
  case r8(Int8)
}

struct Opcode {
  let length: UInt16
  let operandType: OperandType
  let name: String?
  let executionBlock: (GBCpu, Operand) -> Void
  
  static let keyPaths = [\GBCpu.b,
                         \GBCpu.c,
                         \GBCpu.d,
                         \GBCpu.e,
                         \GBCpu.h,
                         \GBCpu.l,
                         \GBCpu.hl,
                         \GBCpu.a]
  
  static let ops: [Opcode] = {
    var opArray = [Opcode](repeating: Opcode.stop, count: Int(UInt8.max))
    opArray[0x00] = noop
    opArray[0x01] = makeLDImmediate16(destinationKeyPath: \GBCpu.bc)
    opArray[0x02] = makeLDOpcode(sourceKeyPath: \GBCpu.a, destinationKeyPath: \GBCpu.bc)
    opArray[0x06] = makeLDImmediate(destinationKeyPath: \GBCpu.b)
    opArray[0x0A] = makeLDOpcode(sourceKeyPath: \GBCpu.bc, destinationKeyPath: \GBCpu.a)
    opArray[0x0C] = makeIncrementRegister(keyPath: \GBCpu.c)
    opArray[0x0E] = makeLDImmediate(destinationKeyPath: \GBCpu.c)
    
    opArray[0x10] = stop
    opArray[0x11] = makeLDImmediate16(destinationKeyPath: \GBCpu.de)
    opArray[0x02] = makeLDOpcode(sourceKeyPath: \GBCpu.a, destinationKeyPath: \GBCpu.de)
    opArray[0x16] = makeLDImmediate(destinationKeyPath: \GBCpu.c)
    opArray[0x1A] = makeLDOpcode(sourceKeyPath: \GBCpu.de, destinationKeyPath: \GBCpu.a)
    opArray[0x1E] = makeLDImmediate(destinationKeyPath: \GBCpu.e)
    
    opArray[0x20] = jpnz
    opArray[0x21] = makeLDImmediate16(destinationKeyPath: \GBCpu.hl)
    opArray[0x26] = makeLDImmediate(destinationKeyPath: \GBCpu.h)
    opArray[0x2E] = makeLDImmediate(destinationKeyPath: \GBCpu.l)
    
    opArray[0x31] = ldsp
    opArray[0x32] = ldHLDa
    opArray[0x36] = makeLDMemFromRegisterAddress(sourceKeyPath: \GBCpu.hl)
    opArray[0x3E] = makeLDImmediate(destinationKeyPath: \GBCpu.a)
    
    //0x40 in loop below
    
    opArray[0xE0] = LDHA
    opArray[0xE2] = ldCA
    opArray[0xEA] = lda16A
    
    opArray[0xF0] = LDHa8
    opArray[0xF2] = ldAC
    opArray[0xFA] = ldAa16
    
    var ldArray: [Opcode] = []
    var xorArray: [Opcode] = []
    var orArray: [Opcode] = []
    var andArray: [Opcode] = []
    for kp in keyPaths {
      keyPaths.forEach { destination in
        let op = makeLDOpcode(sourceKeyPath: kp, destinationKeyPath: destination)
        ldArray.append(op)
      }
      
      xorArray.append(makeXorRegisterOpcode(keyPath: kp))
      orArray.append(makeOrRegisterOpcode(keyPath: kp))
      andArray.append(makeAndRegisterOpcode(keyPath: kp))
    }
    for (index, op) in ldArray.enumerated() {
      opArray[0x40 + index] = op
    }
    
    for (index, op) in xorArray.enumerated() {
      opArray[0xA8 + index] = op
    }
    
    for (index, op) in orArray.enumerated() {
      opArray[0xB0 + index] = op
    }
    
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
  static var noop: Opcode {
    return Opcode(length: 1, operandType: .none) { _,_ in return }
  }

  //0x10
  static var stop: Opcode {
    return Opcode(length: 1, operandType: .none) { cpu, _ in cpu.stop = true }
  }
  
  //20 JPNZ, r8
  static var jpnz: Opcode {
    return Opcode(length: 2, operandType: .signed8, name: "jpnz") { cpu, operand in
      guard case Operand.r8(let value) = operand else { fatalError() }
      if cpu.f.z == 0 {
        cpu.pc.value = UInt16(Int(cpu.pc.value) + Int(value))
      }
    }
  }
  
  //21 LD HL, d16
  static var ldhlImmediate: Opcode {
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
  static var ldsp: Opcode {
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
  static var ldHLDa: Opcode {
    return Opcode(length: 1, operandType: .none, name: "LD (HL-), A") { cpu, _ in
      cpu.memoryController.set(cpu.hl.value, value: cpu.a.value)
      cpu.hl.decrement()
    }
  }
  
  //0xE0
  static var LDHA: Opcode {
    return Opcode(length: 2, operandType: .unsigned8, name: "LDH (a8), A") { cpu, operand in
      guard case Operand.a8(let value) = operand else { fatalError() }
      cpu.a.value = cpu.memoryController.ram[0xFF00 + Int(value)]
    }
  }
  
  //0xF0
  static var LDHa8: Opcode {
    return Opcode(length: 2, operandType: .unsigned8, name: "LDH A, (a8)") { cpu, operand in
      guard case Operand.a8(let value) = operand else { fatalError() }
      cpu.memoryController.set(0xFF00 + UInt16(value), value: cpu.a.value)
    }
  }
  
  //0xE2 LD (C),A       - Put A into address $FF00 + register C.
  static var ldCA: Opcode {
    return Opcode(length: 1, operandType: .none, name: "LD (C), A") { cpu, _ in
      cpu.memoryController.set(0xFF00 + UInt16(cpu.c.value), value: cpu.a.value)
    }
  }
  
  //0xEA
  static var ldAa16: Opcode {
    return Opcode(length: 3, operandType: .address, name: "LD A, a16") {cpu, operand in
      guard case Operand.a16(let address) = operand else { fatalError() }
      cpu.a.value = cpu.memoryController.ram[Int(address)]
    }
  }
  
  //0xF2LD A,(C)       - Put value at address $FF00 + register C into A.
  static var ldAC: Opcode {
    return Opcode(length: 1, operandType: .none, name: "LD (A), C") { cpu, _ in
      cpu.a.value = cpu.memoryController.ram[Int(0xFF00 + UInt16(cpu.c.value))]
    }
  }
  
  //0xFA
  static var lda16A: Opcode {
    return Opcode(length: 3, operandType: .address, name: "LD A, a16") {cpu, operand in
      guard case Operand.a16(let address) = operand else { fatalError() }
        cpu.memoryController.set(address, value: cpu.a.value)
    }
  }
}

extension Opcode {
  //0xEx
  static func makeLDImmediate(destinationKeyPath: PartialKeyPath<GBCpu>) -> Opcode {
    let name = "ld immediate value to \(String(describing: destinationKeyPath))"
    return Opcode(length: 2, operandType: .immediate8, name: name) { cpu, operand in
      guard let register = cpu[keyPath: destinationKeyPath] as? Register,
      case Operand.d8(let value) = operand else { fatalError() }
      register.value = value
    }
  }

  //0x01,11,21
  static func makeLDImmediate16(destinationKeyPath: PartialKeyPath<GBCpu>) -> Opcode {
    let name = "ld immediate 16 value to \(String(describing: destinationKeyPath))"
    return Opcode(length: 3, operandType: .immediate16, name: name) { cpu, operand in
      guard var register = cpu[keyPath: destinationKeyPath] as? CombinedRegister,
        case Operand.d16(let value) = operand else { fatalError() }
      register.value = value
    }
  }
  
  static func makeLDMemFromRegisterAddress(sourceKeyPath: PartialKeyPath<GBCpu>) -> Opcode {
    let name = "ld value at address to \(String(describing: sourceKeyPath))"
    return Opcode(length: 2, operandType: .immediate8, name: name) { cpu, operand in
      guard let register = cpu[keyPath: sourceKeyPath] as? CombinedRegister,
        case Operand.d8(let value) = operand else { fatalError() }
      cpu.memoryController.set(register.value, value: value)
    }
  }
  
  static func makeLDRegisterFromAddress(destinationKeyPath: PartialKeyPath<GBCpu>) -> Opcode {
    return Opcode(length: 3, operandType: .address, name: "LD n, a16") {cpu, operand in
      guard case Operand.a16(let address) = operand,
        let register = cpu[keyPath: destinationKeyPath] as? Register else { fatalError() }
      register.value = cpu.memoryController.ram[Int(address)]
    }
  }
  
  //0x40 - 0x7F
  static func makeLDOpcode(sourceKeyPath: PartialKeyPath<GBCpu>, destinationKeyPath: PartialKeyPath<GBCpu>) -> Opcode {
    let name = "ld \(String(describing: sourceKeyPath)) to \(String(describing: destinationKeyPath))"
    return  Opcode(length: 1, operandType: .none, name: name) {  cpu, _ in
      let value: UInt8
      let register = cpu[keyPath: sourceKeyPath]
      let destination = cpu[keyPath: destinationKeyPath]
      if let _ = register as? CombinedRegister,
        let _ = destination as? CombinedRegister {
        fatalError("HALT")
      }
      
      switch register {
      case let register as Register:
        value = register.value
      case let register as CombinedRegister:
        value = cpu.memoryController.ram[Int(register.value)]
      default:
        fatalError()
      }
      
      switch destination {
      case let destination as Register:
        destination.value = value
      case let destination as CombinedRegister:
        cpu.memoryController.set(destination.value, value: value)
      default:
        fatalError()
      }
    }
  }
  
  //0xA8 - 0xAF
  static func makeXorRegisterOpcode(keyPath: PartialKeyPath<GBCpu>) -> Opcode {
    return Opcode(length: 1, operandType: .none, name: "XOR r") { cpu, _ in
      let register = cpu[keyPath: keyPath]
      switch register {
      case let register as Register:
        cpu.a.value = cpu.a.value ^ register.value
        cpu.f.setZ(cpu.a.value == 0)
        cpu.f.setS(false)
        cpu.f.setC(false)
        cpu.f.setHC(false)
      case let register as CombinedRegister:
        cpu.a.value = cpu.a.value ^ cpu.memoryController.ram[Int(register.value)]
        cpu.f.setZ(cpu.a.value == 0)
        cpu.f.setS(false)
        cpu.f.setC(false)
        cpu.f.setHC(false)
      default:
        fatalError()
      }
    }
  }
  
  //0xA0 - 0xA7
  static func makeAndRegisterOpcode(keyPath: PartialKeyPath<GBCpu>) -> Opcode {
    return Opcode(length: 1, operandType: .none, name: "OR r") { cpu, _ in
      let register = cpu[keyPath: keyPath]
      switch register {
      case let register as Register:
        cpu.a.value = cpu.a.value & register.value
        cpu.f.setZ(cpu.a.value == 0)
        cpu.f.setS(false)
        cpu.f.setC(false)
        cpu.f.setHC(true)
      case let register as CombinedRegister:
        cpu.a.value = cpu.a.value & cpu.memoryController.ram[Int(register.value)]
        cpu.f.setZ(cpu.a.value == 0)
        cpu.f.setS(false)
        cpu.f.setC(false)
        cpu.f.setHC(true)
      default:
        fatalError()
      }
    }
  }
  
  //0xA8 - 0xAF
  static func makeOrRegisterOpcode(keyPath: PartialKeyPath<GBCpu>) -> Opcode {
    return Opcode(length: 1, operandType: .none, name: "OR r") { cpu, _ in
      let register = cpu[keyPath: keyPath]
      switch register {
      case let register as Register:
        cpu.a.value = cpu.a.value | register.value
        cpu.f.setZ(cpu.a.value == 0)
        cpu.f.setS(false)
        cpu.f.setC(false)
        cpu.f.setHC(false)
      case let register as CombinedRegister:
        cpu.a.value = cpu.a.value | cpu.memoryController.ram[Int(register.value)]
        cpu.f.setZ(cpu.a.value == 0)
        cpu.f.setS(false)
        cpu.f.setC(false)
        cpu.f.setHC(false)
      default:
        fatalError()
      }
    }
  }
  
  static func makeIncrementRegister(keyPath: PartialKeyPath<GBCpu>) -> Opcode {
    return Opcode(length: 1, operandType: .none, name: "Inc Register") { cpu, _ in
      guard let register = cpu[keyPath: keyPath] as? Register else { fatalError() }
      let result = Int(register.value) + 1
      let halfCarry = ((register.value & 0xF) + ( 1 & 0xF)) > 0xF
      register.value = UInt8(result & 0xFF)
      cpu.f.setZ(result == 0)
      cpu.f.setHC(halfCarry)
      cpu.f.setS(false)
    }
  }
}

