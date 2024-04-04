//
//  UrlETagSaverNodeTests.swift
//  CoreNetKitUnitTests
//
//  Created by Александр Кравченков on 05/03/2019.
//  Copyright © 2019 Кравченков Александр. All rights reserved.
//

import Foundation
import XCTest

@testable
import NodeKit

final class UrlETagSaverNodeTests: XCTestCase {

    func testNodeSaveTag() {

        // Arrange

        let node = UrlETagSaverNode(next: nil)
        let url = URL(string: "http://urletagsaver.tests/testNodeSaveTag")!
        let tag = "\(NSObject().hash)"

        let data = Utils.getMockUrlProcessedResponse(url: url, headers: [ETagConstants.eTagResponseHeaderKey: tag])

        var callCount = 0

        let expectation = self.expectation(description: "\(#function)")

        defer {
            UserDefaults.etagStorage?.removeObject(forKey: url.absoluteString)
        }

        // Act

        node.processLegacy(data).onCompleted { model in
            callCount += 1
            expectation.fulfill()
        }.onError { error in
            callCount += 1
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1, handler: nil)

        guard let readedTag = UserDefaults.etagStorage?.string(forKey: url.absoluteString) else {
            XCTFail("Cant read tag from UD")
            return
        }

        // Assert

        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(readedTag, tag)
    }

    func testNodeNotSaveTag() {

        // Arrange

        let node = UrlETagSaverNode(next: nil)
        let url = URL(string: "http://urletagsaver.tests/testNodeNotSaveTag")!

        let data = Utils.getMockUrlProcessedResponse(url: url)

        var callCount = 0

        let expectation = self.expectation(description: "\(#function)")

        defer {
            UserDefaults.etagStorage?.removeObject(forKey: url.absoluteString)
        }

        // Act

        node.processLegacy(data).onCompleted { model in
            callCount += 1
            expectation.fulfill()
            }.onError { error in
                callCount += 1
                expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1, handler: nil)

        let readedTag = UserDefaults.etagStorage?.string(forKey: url.absoluteString)

        // Assert

        XCTAssertEqual(callCount, 1)
        XCTAssertNil(readedTag)
    }

    func testSaveWorkForCustomKey() {

        // Arrange


        let url = URL(string: "http://urletagsaver.tests/testSaveWorkForCustomKey")!
        let tag = "\(NSObject().hash)"
        let tagKey = "My-Custom-ETag-Key"

        let node = UrlETagSaverNode(next: nil, eTagHeaderKey: tagKey)

        let data = Utils.getMockUrlProcessedResponse(url: url, headers: [tagKey: tag])

        var callCount = 0

        let expectation = self.expectation(description: "\(#function)")

        defer {
            UserDefaults.etagStorage?.removeObject(forKey: url.absoluteString)
        }

        // Act

        node.processLegacy(data).onCompleted { model in
            callCount += 1
            expectation.fulfill()
            }.onError { error in
                callCount += 1
                expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1, handler: nil)

        guard let readedTag = UserDefaults.etagStorage?.string(forKey: url.absoluteString) else {
            XCTFail("Cant read tag from UD")
            return
        }

        // Assert

        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(readedTag, tag)
    }

    /// Проверяет что при сохранении данных от двух одинаковых запросов с разным порядком ключей
    /// Будет создана только одна запись
    func testSaveDataForTwoSameRequestsWithDifferentOrderOfKeys() {

        // Arrange


        let url1 = URL(string: "http://urletagsaver.tests/test?q1=1&q2=2")!
        let url2 = URL(string: "http://urletagsaver.tests/test?q2=2&q1=1")!

        let tag = "\(NSObject().hash)"
        
        let headers = [ETagConstants.eTagResponseHeaderKey: tag]

        let node = UrlETagSaverNode(next: nil)

        let data1 = Utils.getMockUrlProcessedResponse(url: url1, headers: headers)
        let data2 = Utils.getMockUrlProcessedResponse(url: url2, headers: headers)

        let expectation1 = self.expectation(description: "\(#function)")
        let expectation2 = self.expectation(description: "\(#function)")

        defer {
            UserDefaults.etagStorage?.removeObject(forKey: url1.absoluteString)
            UserDefaults.etagStorage?.removeObject(forKey: url2.absoluteString)
        }

        // Act

        node.processLegacy(data1)
            .onCompleted { _ in expectation1.fulfill() }
            .onError { _ in expectation1.fulfill() }

        node.processLegacy(data2)
            .onCompleted { _ in expectation2.fulfill() }
            .onError { _ in expectation2.fulfill() }

        self.wait(for: [expectation1, expectation2], timeout: 1, enforceOrder: false)

        // Assert

        XCTAssertNotNil(UserDefaults.etagStorage?.string(forKey: url1.withOrderedQuery()!))
        XCTAssertNil(UserDefaults.etagStorage?.string(forKey: url2.absoluteString))
    }
    
    func testAsyncProcess_whenHasTag_thenNodeSaveTag() async throws {
        // given

        let sut = UrlETagSaverNode(next: nil)
        let url = URL(string: "http://urletagsaver.tests/testNodeSaveTag")!
        let tag = "\(NSObject().hash)"
        let data = Utils.getMockUrlProcessedResponse(url: url, headers: [ETagConstants.eTagResponseHeaderKey: tag])

        defer {
            UserDefaults.etagStorage?.removeObject(forKey: url.absoluteString)
        }

        // when
        
        let result = await sut.process(data, logContext: LoggingContextMock())
        let readedTag = UserDefaults.etagStorage?.string(forKey: url.absoluteString)

        // then
        
        let unwrappedTag = try XCTUnwrap(readedTag)

        XCTAssertNotNil(result.value)
        XCTAssertEqual(unwrappedTag, tag)
    }

    func testAsyncProcess_withoutTag_thenNodeNotSaveTag() async {
        // given

        let sut = UrlETagSaverNode(next: nil)
        let url = URL(string: "http://urletagsaver.tests/testNodeNotSaveTag")!
        let data = Utils.getMockUrlProcessedResponse(url: url)

        defer {
            UserDefaults.etagStorage?.removeObject(forKey: url.absoluteString)
        }

        // when
        
        let result = await sut.process(data, logContext: LoggingContextMock())
        let readedTag = UserDefaults.etagStorage?.string(forKey: url.absoluteString)

        // then

        XCTAssertNotNil(result.value)
        XCTAssertNil(readedTag)
    }

    func testAsyncProcess_withCustomKey_thenTagSaved() async throws {
        // given
        
        let url = URL(string: "http://urletagsaver.tests/testSaveWorkForCustomKey")!
        let tag = "\(NSObject().hash)"
        let tagKey = "My-Custom-ETag-Key"
        let sut = UrlETagSaverNode(next: nil, eTagHeaderKey: tagKey)
        let data = Utils.getMockUrlProcessedResponse(url: url, headers: [tagKey: tag])

        defer {
            UserDefaults.etagStorage?.removeObject(forKey: url.absoluteString)
        }

        // when

        let result = await sut.process(data, logContext: LoggingContextMock())
        let readedTag = UserDefaults.etagStorage?.string(forKey: url.absoluteString)

        // then
        
        let unwrappedTag = try XCTUnwrap(readedTag)

        XCTAssertNotNil(result.value)
        XCTAssertEqual(unwrappedTag, tag)
    }

    /// Проверяет что при сохранении данных от двух одинаковых запросов с разным порядком ключей
    /// Будет создана только одна запись
    func testAsyncProcess_whenSaveDataForTwoSameRequestsWithDifferentOrderOfKeys_thenOnlyOneSaved() async throws {
        // given

        let url1 = URL(string: "http://urletagsaver.tests/test?q1=1&q2=2")!
        let url2 = URL(string: "http://urletagsaver.tests/test?q2=2&q1=1")!
        let tag = "\(NSObject().hash)"
        let headers = [ETagConstants.eTagResponseHeaderKey: tag]
        let sut = UrlETagSaverNode(next: nil)
        let data1 = Utils.getMockUrlProcessedResponse(url: url1, headers: headers)
        let data2 = Utils.getMockUrlProcessedResponse(url: url2, headers: headers)

        defer {
            UserDefaults.etagStorage?.removeObject(forKey: url1.absoluteString)
            UserDefaults.etagStorage?.removeObject(forKey: url2.absoluteString)
        }

        // when
        
        let firstResult = await sut.process(data1, logContext: LoggingContextMock())
        let secondResult = await sut.process(data1, logContext: LoggingContextMock())
        let firstTag = UserDefaults.etagStorage?.string(forKey: url1.absoluteString)
        let secondTag = UserDefaults.etagStorage?.string(forKey: url2.absoluteString)
        let savedTag = UserDefaults.etagStorage?.string(forKey: url1.withOrderedQuery()!)

        // then

        XCTAssertEqual(savedTag, tag)
        XCTAssertNil(firstTag)
        XCTAssertNil(secondTag)
    }
}
