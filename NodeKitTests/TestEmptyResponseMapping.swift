//
//  TestEmptyResponseMapping.swift
//  CoreNetKitIntegrationTests
//
//  Created by Александр Кравченков on 04/02/2019.
//  Copyright © 2019 Кравченков Александр. All rights reserved.
//

import Foundation
import XCTest

@testable
import NodeKit

public class TestEmptyResponseMapping: XCTestCase {

    /// We send request on server and await response with empty array in body
    /// In this test we assert that this resposne body will seccessfully parse in array of entities
    public func testDefaultChainArrSucessParseResponseInCaseOfEmptyArray() {

        // Arrange

        let chainRoot: Node<Void, [User]> = UrlChainsBuilder()
            .route(.get, Routes.emptyUsers)
            .build()

        // Act

        var result: [User]?
        var resultError: Error?

        let exp = self.expectation(description: "\(#function)")

        chainRoot.process()
            .onCompleted { (user) in
                result = user
                exp.fulfill()
            }.onError { (error) in
                resultError = error
                exp.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)

        // Assert

        XCTAssertNotNil(result)
        XCTAssertNil(resultError, resultError!.localizedDescription)
        XCTAssertTrue(result!.isEmpty)
    }

    public func testArraySuccessMappingWithNoContentResponse() {

        // Arrange


        let chainRoot: Node<Void, [User]> = UrlChainsBuilder()
            .route(.get, Routes.emptyUsersWith402)
            .build()

        // Act

        var result: [User]?
        var resultError: Error?

        let exp = self.expectation(description: "\(#function)")

        chainRoot.process()
            .onCompleted { (user) in
                result = user
                exp.fulfill()
            }.onError { (error) in
                resultError = error
                exp.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)

        // Assert

        XCTAssertNotNil(result)
        XCTAssertNil(resultError, resultError!.localizedDescription)
        XCTAssertTrue(result!.isEmpty)
    }

}
