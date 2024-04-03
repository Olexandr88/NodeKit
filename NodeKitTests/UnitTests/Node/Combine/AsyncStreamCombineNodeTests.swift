//
//  AsyncStreamCombineNodeTests.swift
//  NodeKitTests
//
//  Created by Andrei Frolov on 03.04.24.
//  Copyright © 2024 Surf. All rights reserved.
//

@testable import NodeKit
import Combine
import XCTest

final class AsyncStreamCombineNodeTests: XCTestCase {
    
    // MARK: - Dependencies
    
    private var nodeMock: AsyncStreamNodeMock<Int, Int>!
    private var logContextMock: LoggingContextMock!
    private var cancellable: Set<AnyCancellable>!
    
    // MARK: - Sut
    
    private var sut: AsyncStreamCombineNode<Int, Int>!
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        nodeMock = AsyncStreamNodeMock()
        logContextMock = LoggingContextMock()
        sut = AsyncStreamCombineNode(node: nodeMock)
        cancellable = Set()
    }
    
    override func tearDown() {
        super.tearDown()
        nodeMock = nil
        logContextMock = nil
        sut = nil
        cancellable = Set()
    }
    
    // MARK: - Tests
    
    func testProcess_withPublisherOnMainQueue_thenResultsReceivedOnMainQueue() async {
        // given
        
        let expectation = expectation(description: "result")
        
        var isMainThread = false
        
        nodeMock.stubbedAsyncStreamProccessResult = {
            AsyncStream { continuation in
                continuation.yield(.success(100))
                continuation.finish()
            }
        }
        
        // when
        
        sut.nodeResultPublisher(on: DispatchQueue.main)
            .sink(receiveValue: { value in
                isMainThread = Thread.isMainThread
                expectation.fulfill()
            })
            .store(in: &cancellable)
        
        sut.process(12, logContext: logContextMock)
        
        await fulfillment(of: [expectation], timeout: 0.1)
        
        // then
        
        XCTAssertTrue(isMainThread)
    }
    
    func testProcess_withPublisherOnCustom_thenResultsReceivedOnCustomQueue() async {
        // given
        
        let expectation = expectation(description: "result")
        let expectedLabel = "Test Process Queue"
        let queue = DispatchQueue(label: expectedLabel)
        
        var isMainThread = false
        var queueLabel: String?
        
        nodeMock.stubbedAsyncStreamProccessResult = {
            AsyncStream { continuation in
                continuation.yield(.success(100))
                continuation.finish()
            }
        }
        
        // when
        
        sut.nodeResultPublisher(on: queue)
            .sink(receiveValue: { value in
                isMainThread = Thread.isMainThread
                queueLabel = DispatchQueue.currentLabel
                expectation.fulfill()
            })
            .store(in: &cancellable)
        
        sut.process(12, logContext: logContextMock)
        
        await fulfillment(of: [expectation], timeout: 0.1)
        
        // then
        
        XCTAssertFalse(isMainThread)
        XCTAssertEqual(queueLabel, expectedLabel)
    }
    
    func testProcess_thenResultsReceived() async {
        // given
        
        let expectation = expectation(description: "result")
        let expectedInput = 43
        
        let expectedResults: [Result<Int, Error>] = [
            .success(100),
            .failure(MockError.firstError),
            .failure(MockError.secondError),
            .success(99),
            .failure(MockError.thirdError)
        ]
        
        var results: [NodeResult<Int>] = []
        
        nodeMock.stubbedAsyncStreamProccessResult = {
            AsyncStream { continuation in
                expectedResults.forEach { continuation.yield($0) }
                continuation.finish()
            }
        }
        
        // when
        
        sut.nodeResultPublisher(on: DispatchQueue.main)
            .sink(receiveValue: { value in
                results.append(value)
                if results.count == expectedResults.count {
                    expectation.fulfill()
                }
            })
            .store(in: &cancellable)
        
        sut.process(expectedInput, logContext: logContextMock)
        
        await fulfillment(of: [expectation], timeout: 0.1)
        
        // then
        
        XCTAssertEqual(nodeMock.invokedAsyncStreamProcessCount, 1)
        XCTAssertEqual(nodeMock.invokedAsyncStreamProcessParameter?.0, expectedInput)
        XCTAssertTrue(nodeMock.invokedAsyncStreamProcessParameter?.1 === logContextMock)
        XCTAssertEqual(
            results.compactMap { $0.castToMockError() },
            expectedResults.compactMap { $0.castToMockError() }
        )
    }
    
    func testProcess_withMultipleSubsciptions_thenResultsReceived() async {
        // given
        
        let expectation1 = expectation(description: "result1")
        let expectation2 = expectation(description: "result2")
        let expectedInput = 42
        
        let expectedResults: [Result<Int, MockError>] = [
            .success(500),
            .failure(.secondError),
            .success(1),
            .failure(.secondError),
            .failure(.thirdError)
        ]
        let nodeResults: [NodeResult<Int>] = expectedResults.map { res in res.mapError { $0 } }
        
        var results1: [NodeResult<Int>] = []
        var results2: [NodeResult<Int>] = []
        
        nodeMock.stubbedAsyncStreamProccessResult = {
            AsyncStream { continuation in
                nodeResults.forEach {
                    continuation.yield($0)
                }
                continuation.finish()
            }
        }
        
        // when
        
        let multicast = sut.nodeResultPublisher(on: DispatchQueue.main)
            .multicast { PassthroughSubject() }
        
        multicast
            .sink(receiveValue: { value in
                results1.append(value)
                if results1.count == expectedResults.count {
                    expectation1.fulfill()
                }
            })
            .store(in: &cancellable)
        
        multicast
            .sink(receiveValue: { value in
                results2.append(value)
                if results2.count == expectedResults.count {
                    expectation2.fulfill()
                }
            })
            .store(in: &cancellable)
        
        multicast.connect().store(in: &cancellable)
        
        sut.process(expectedInput, logContext: logContextMock)
        
        await fulfillment(of: [expectation1, expectation2], timeout: 1)
        
        // then
        
        XCTAssertEqual(nodeMock.invokedAsyncStreamProcessCount, 1)
        XCTAssertEqual(nodeMock.invokedAsyncStreamProcessParameter?.0, expectedInput)
        XCTAssertTrue(nodeMock.invokedAsyncStreamProcessParameter?.1 === logContextMock)
        XCTAssertEqual(results1.compactMap { $0.castToMockError() }, expectedResults)
        XCTAssertEqual(results2.compactMap { $0.castToMockError() }, expectedResults)
    }
}
