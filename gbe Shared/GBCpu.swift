//  Created by abonham on 20/8/18.

import Foundation

let bootstrap: [UInt8] = [0x33, 0xFF, 0xFE, 0xAF]

class GBCpu {
  var a = Accumulator()
  var b = Register()
  var c = Register()
  var d = Register()
  var e = Register()
  var f = Status()
  var hl = CombinedRegister()
  var pc = Counter()
  var sp = Counter()
  
  var ram = Array(repeating: UInt8.min, count: Int(UInt16.max))
  
  init() {
    for i in 0..<bootstrap.count {
      ram[i] = bootstrap[i]
    }
    pc.value = 0
  }
  
  func processNext() {
    let instruction = ram[Int(pc.value)]
    let op = opcode(for: Int(instruction))
    var operand = Operand.none
    switch op.length {
    case 2:
      operand = .single(ram[Int(pc.value) + 1])
    case 3:
      operand = .double(ram[Int(pc.value) + 1], ram[Int(pc.value) + 2])
    default:
      break
    }
    op.executionBlock(self, operand)
    pc.value += op.length
  }
  
  func opcode(for op: Int) -> Opcode {
    return Opcode.ops[op]()
  }
}

public func combineValues(high: UInt8, low: UInt8) -> UInt16 {
  let h = UInt16(high) << 8
  return UInt16(h + UInt16(low))
}
