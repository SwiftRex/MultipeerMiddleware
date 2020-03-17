import XCTest

import MultipeerMiddlewareTests

var tests = [XCTestCaseEntry]()
tests += MultipeerCombineTests.allTests()
tests += MultipeerMiddlewareTests.allTests()
XCTMain(tests)
