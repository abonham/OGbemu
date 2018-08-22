//  Created by abonham on 22/8/18.

import Foundation

class MemoryController {
  private(set) var ram: [UInt8] = Array(repeating: 0, count: Int(UInt16.max))
  
  func set(_ address: UInt16, value: UInt8) {
    ram[Int(address)] = value
  }
}
