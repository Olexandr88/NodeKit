//
//  LoggingTests.swift
//  CoreNetKitIntegrationTests
//
//  Created by Александр Кравченков on 07/04/2019.
//  Copyright © 2019 Кравченков Александр. All rights reserved.
//

import Foundation
import XCTest

@testable
import NodeKit

public class LoggingTests: XCTestCase {
    func testLogCopyingInDataMap() {
        // Arrange

        let context = Context<Json>().log(Log("", id: "")).emit(data: Json())

        // Act

        let result = context.map { data in
            return data
        }

        // Assert

        XCTAssertNotNil(result.log)
        XCTAssertNil(result.log?.next)
    }

    func testLogCopyingInErrorMap() {
        // Arrange

        let context = Context<Json>().log(Log("", id: "")).emit(error: NSError(domain: "", code: 0, userInfo: nil))

        // Act

        let result = context.mapError { error in
            return error
        }

        // Assert

        XCTAssertNil(result.log?.next)
        XCTAssertNotNil(result.log)
    }

    func testLogCopyingInObserverMap() {
        // Arrange

        let context = Context<Json>().log(Log("", id: "")).emit(data: Json())
        let exp = self.expectation(description: #function)

        // Act
        let result = context.map { (model) -> Observer<Json> in
            let result = Context<Json>()
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                result.log(Log("1", id: "1")).emit(data: Json())
            })
            return result
        }.onCompleted { _ in
            exp.fulfill()
        }

        // Assert

        self.waitForExpectations(timeout: 10, handler: nil)

        XCTAssertNotNil(result.log)
        XCTAssertNotNil(result.log?.next)
        XCTAssertNil(result.log?.next?.next)
    }

    func testLogCopyingInError() {
        // Arrange

        let context = Context<Json>().log(Log("", id: "")).emit(error: NSError(domain: "", code: 0, userInfo: nil))
        let exp = self.expectation(description: #function)

        // Act
        let result = context.mapError { err -> Context<Json> in
            let result = Context<Json>()
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                result.log(Log("1", id: "1")).emit(data: Json())
            })
            return result
        }.onCompleted { _ in
            exp.fulfill()
        }

        // Assert

        self.waitForExpectations(timeout: 2, handler: nil)

        XCTAssertNotNil(result.log)
        XCTAssertNotNil(result.log?.next)
        XCTAssertNil(result.log?.next?.next)
    }

    func testLogCopyingInObserverCombine() {
        // Arrange

        let context = Context<Json>().log(Log("", id: "")).emit(data: Json())
        let exp = self.expectation(description: #function)

        // Act

        let combined = Context<Json>()

        let result = context.combine(combined).onCompleted { _ in
            exp.fulfill()
        }

        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
            combined.log(Log("1", id: "1")).emit(data: Json())
        })

        // Assert

        self.waitForExpectations(timeout: 2, handler: nil)
        XCTAssertNotNil(result.log)
        XCTAssertNotNil(result.log?.next)
        XCTAssertNil(result.log?.next?.next)
    }

    func testLogCopyingInObserverCombineTolerance() {

        // given
        let context = Context<Json>().log(Log("", id: "")).emit(data: Json())
        let exp = self.expectation(description: #function)

        // when
        let combined = Context<Json>()
        
        let result = context.combineTolerance(combined).onCompleted { _ in
            exp.fulfill()
        }

        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
            combined.log(Log("1", id: "1")).emit(data: Json())
        })

        // Assert
        self.waitForExpectations(timeout: 2, handler: nil)
        XCTAssertNotNil(result.log)
        XCTAssertNotNil(result.log?.next)
        XCTAssertNil(result.log?.next?.next)
    }

    func testLogCopyingInFilter() {
        // Arrange

        let context = Context<[Json]>().log(Log("", id: "")).emit(data: [Json]())

        // Act

        let result = context.filter { data -> Bool in
            return false
        }

        // Assert

        XCTAssertNotNil(result.log)
        XCTAssertNil(result.log?.next)
    }

    func testLogCopyingInChain() {
        // Arrange

        let context = Context<Json>().log(Log("", id: "")).emit(data: Json())
        let exp = self.expectation(description: #function)

        // Act
        let result = context.chain { (model) -> Observer<Json> in
            let result = Context<Json>()
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                result.log(Log("1", id: "1")).emit(data: Json())
            })
            return result
        }.onCompleted { _ in
            exp.fulfill()
        }

        // Assert

        self.waitForExpectations(timeout: 2, handler: nil)
        XCTAssertNotNil(result.log)
        XCTAssertNotNil(result.log?.next)
        XCTAssertNil(result.log?.next?.next)
    }

    func testLogCopyingInDispatchOn() {
        // Arrange

        let context = Context<[Json]>().log(Log("", id: "")).emit(data: [Json]())

        // Act

        let result = context.dispatchOn(.main)

        // Assert

        XCTAssertNotNil(result.log)
        XCTAssertNil(result.log?.next)
    }

    func testLogCopyingInMulticast() {
        // Arrange

        let context = Context<[Json]>().log(Log("", id: "")).emit(data: [Json]())

        // Act

        let result = context.multicast()

        // Assert

        XCTAssertNotNil(result.log)
        XCTAssertNil(result.log?.next)
    }

}
