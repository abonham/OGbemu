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
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}
