//
//  gbeTests.swift
//  gbeTests
//
//  Created by abonham on 20/8/18.
//

import XCTest
@testable import gbe

class gbeTests: XCTestCase {
  var testCpu: GBCpu!
  override func setUp() {
    super.setUp()
    testCpu = GBCpu()
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testHLRegisterSet() {
    testCpu.hl.value = 0xAABB
    XCTAssertEqual(testCpu.hl.low.value, 0xBB)
    XCTAssertEqual(testCpu.hl.high.value, 0xAA)
  }
  
  func testHLCPURegisters() {
    testCpu.h.value = 0xAA
    testCpu.l.value = 0xBB
    XCTAssertEqual(testCpu.hl.value, 0xAABB)
    testCpu.hl.value = 0xCCDD
    XCTAssertEqual(testCpu.h.value, 0xCC)
    XCTAssertEqual(testCpu.l.value, 0xDD)
  }
  
  func testHLRegisterLowHigh() {
    testCpu.hl.high.value = 0xCC
    testCpu.hl.low.value = 0xDD
    XCTAssertEqual(testCpu.hl.value, 0xCCDD)
  }
  
  func testLDSP() {
    testCpu.processNext()
    XCTAssertEqual(testCpu.sp.value, 0xFFFE)
  }
  
  func testXorA() {
    testCpu.a.value = 0xAB
    testCpu.f.value = 0xFF
    testCpu.pc.value = 3
    testCpu.processNext()
    XCTAssertEqual(testCpu.a.value, 0x00)
    XCTAssertEqual(testCpu.f.z > 0, true)
    XCTAssertEqual(testCpu.f.s == 0, true)
    XCTAssertEqual(testCpu.f.hc == 0, true)
    XCTAssertEqual(testCpu.f.c == 0, true)
  }
  
  func testPC() {
    testCpu.processNext()
    testCpu.processNext()
    XCTAssertEqual(testCpu.pc.value, 0x04)
  }
  
  func testBootThree() {
    testCpu.pc.value = 4
    testCpu.processNext()
    XCTAssertEqual(testCpu.hl.value, 0x9FFF)
    XCTAssertEqual(testCpu.pc.value, 7)
  }
  
  func testLDHLDa() {
    testCpu.a.value = 0xFF
    testCpu.hl.value = 1
    Opcode.ldHLDa().executionBlock(testCpu, Operand.none)
    XCTAssertEqual(testCpu.memoryController.ram[1], 0xFF)
    XCTAssertEqual(testCpu.hl.value, 0)
  }
  
  func testBootFour() {
    for address in 0xFF..<testCpu.memoryController.ram.count {
      testCpu.memoryController.set(UInt16(address), value: 1)
    }
    
    for _ in 0...4 {
      testCpu.processNext()
    }
    
    XCTAssertEqual(testCpu.hl.value, 0x9FFE)
    XCTAssertEqual(testCpu.memoryController.ram[0x9FFF], 0)
  }
  
  func testBit7h() {
    testCpu.h.value = 0b10000000
    testCpu.f.setS(true)
    let testOp = Opcode.extendedOps[0x7C]()
    testOp.executionBlock(testCpu, Operand.none)
    XCTAssertEqual(testCpu.f.z, 0)
    testCpu.h.value = 0
    testOp.executionBlock(testCpu, Operand.none)
    XCTAssert(testCpu.f.z > 0)
    XCTAssert(testCpu.f.hc > 0)
    XCTAssertEqual(testCpu.f.s, 0)
  }
//
//  func testPerformanceExample() {
//
//    self.measure {
//      testCpu.processNext()
//      testCpu.pc.value = 0
//    }
//  }
}
