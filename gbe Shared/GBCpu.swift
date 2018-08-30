//  Created by abonham on 20/8/18.

import Foundation

class GBCpu: NSObject {
  var a = Register()
  var b = Register()
  var c = Register()
  var d = Register()
  var e = Register()
  var f = Status()
  var h = Register()
  var l = Register()
  lazy var bc = CombinedRegister(high: b, low: c)
  lazy var de = CombinedRegister(high: d, low: e)
  lazy var hl = CombinedRegister(high: h, low: l)
  var pc = Counter()
  var sp = Counter()
  
  var memoryController = MemoryController()
  
  var halt = false
  var stop = false
  
  override init() {
    super.init()
    guard let bootstrap = loadBootstap() else { fatalError() }
    for i in 0..<bootstrap.count {
      memoryController.set(UInt16(i), value: bootstrap[i])
    }
    memoryController.set(UInt16(bootstrap.count), value: 0x10)
    pc.value = 0
  }
  
  func start() {
    while(!halt && !stop) {
      processNext()
    }
  }
  
  func processNext() {
    let instruction = memoryController.ram[Int(pc.value)]
    let op = opcode(for: Int(instruction))
    print("Op: \(op.name ?? "unnamed"), length: \(op.length), pc: \(pc.value)")
    var operand = Operand.none
    switch op.operandType {
    case .immediate8:
      operand = .d8(memoryController.ram[Int(pc.value) + 1])
    case .immediate16:
      let value = combineValues(high: memoryController.ram[Int(pc.value) + 2], low: memoryController.ram[Int(pc.value) + 1])
      operand = .d16(value)
    case .signed8:
      let value = Int8(bitPattern: memoryController.ram[Int(pc.value) + 1])
      operand = .r8(value)
    case .unsigned8:
      operand = .a8(memoryController.ram[Int(pc.value) + 1])
    default:
      break
    }
    op.executionBlock(self, operand)
    pc.value += op.length
  }
  
  func opcode(for op: Int) -> Opcode {
    return op == 0xCB
      ? Opcode.extendedOps[Int(memoryController.ram[Int(pc.value) + 1])]
      : Opcode.ops[op]
  }
  
  func loadBootstap() -> Data? {
    let bundle = Bundle.main
    if let url = bundle.url(forResource: "DMG_ROM", withExtension: "bin") {
      return try? Data(contentsOf: url)
    }
    return nil
  }
}

public func combineValues(high: UInt8, low: UInt8) -> UInt16 {
  let h = UInt16(high) << 8
  return UInt16(h + UInt16(low))
}
