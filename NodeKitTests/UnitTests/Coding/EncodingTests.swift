//
//  FormUrlEncodingTests.swift
//  CoreNetKit
//
//  Created by Александр Кравченков on 31/03/2019.
//  Copyright © 2019 Кравченков Александр. All rights reserved.
//
import Foundation
import XCTest

@testable
import NodeKit

final class EncodingTests: XCTestCase {

    // MARK: - Dependencies
    
    private var nextNodeMock: AsyncNodeMock<URLRequest, Json>!
    private var requestCreatorNode: RequestCreatorNode<Json>!
    private var logContextMock: LoggingContextMock!
    
    // MARK: - Sut
    
    private var sut: UrlJsonRequestEncodingNode<Json>!
    
    // MARK: - Lifecycle
    
    public override func setUp() {
        super.setUp()
        nextNodeMock = AsyncNodeMock()
        logContextMock = LoggingContextMock()
        requestCreatorNode = RequestCreatorNode(next: nextNodeMock)
        sut = UrlJsonRequestEncodingNode(next: requestCreatorNode)
    }
    
    public override func tearDown() {
        super.tearDown()
        nextNodeMock = nil
        logContextMock = nil
        requestCreatorNode = nil
        sut = nil
    }
    
    // MARK: - Tests
    
    func testProcess_thenFormUrlConvertinWork() {
        // given
        
        let url = "http://test.com/usr"
        let headersArray: [String: String] = [
            "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
        ]
        let dataRaw: Json = ["id": "123455"]
        let urlParameters = TransportUrlParameters(method: .post, url: URL(string: url)!)
        let encodingModel = RequestEncodingModel(
            urlParameters: urlParameters,
            raw: dataRaw,
            encoding: .formUrl
        )
        
        nextNodeMock.stubbedProccessResult = .emit(data: Json())

        // when

        _ = sut.process(encodingModel)

        // then
        
        XCTAssertEqual(nextNodeMock.invokedProcessCount, 1)
        XCTAssertEqual(nextNodeMock.invokedProcessParameter?.url!.absoluteString, url)
        XCTAssertEqual(
            nextNodeMock.invokedProcessParameter?.headers.dictionary,
            headersArray
        )
    }
    
    public func testProcess_thenUrlQueryConvertionWork() {
        // given

        let url = "http://test.com/usr"
        let dataRaw: Json = ["id": "12345"]
        let urlParameters = TransportUrlParameters(method: .post, url: URL(string: url)!)
        let encodingModel = RequestEncodingModel(
            urlParameters: urlParameters,
            raw: dataRaw,
            encoding: .urlQuery
        )
        
        nextNodeMock.stubbedProccessResult = .emit(data: Json())
        
        // when

        _ = sut.process(encodingModel)

        // then
        
        XCTAssertEqual(nextNodeMock.invokedProcessCount, 1)
        XCTAssertEqual(
            nextNodeMock?.invokedProcessParameter?.url!.absoluteString, 
            "\(url)?id=12345"
        )
    }

    func testProcess_thenJsonConvertionWork() {
        // given

        let url = "http://test.com/usr"
        let headersArray: [String: String] = ["Content-Type": "application/json"]
        let dataRaw: Json = ["id": "12345"]
        let urlParameters = TransportUrlParameters(method: .post, url: URL(string: url)!)
        let encodingModel = RequestEncodingModel(
            urlParameters: urlParameters,
            raw: dataRaw,
            encoding: .json
        )
        
        nextNodeMock.stubbedProccessResult = .emit(data: Json())

        // when
        
        _ = sut.process(encodingModel)

        // then
        
        XCTAssertEqual(nextNodeMock.invokedProcessCount, 1)
        XCTAssertEqual(nextNodeMock.invokedProcessParameter?.url!.absoluteString, url)
        XCTAssertEqual(nextNodeMock.invokedProcessParameter?.headers.dictionary, headersArray)
    }
    
    func testAsyncProcess_thenFormUrlConvertinWork() async throws {
        // given
        
        let url = "http://test.com/usr"
        let headersArray: [String: String] = [
            "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
        ]
        let dataRaw: Json = ["id": "123455"]
        let urlParameters = TransportUrlParameters(method: .post, url: URL(string: url)!)
        let encodingModel = RequestEncodingModel(
            urlParameters: urlParameters,
            raw: dataRaw,
            encoding: .formUrl
        )
        let expectedResult = ["Test": "Value"]
        
        nextNodeMock.stubbedAsyncProccessResult = .success(expectedResult)

        // when

        let result = await sut.process(encodingModel, logContext: logContextMock)

        // then
        
        let unwrappedResult = try XCTUnwrap(try result.get() as? [String: String])
        
        XCTAssertEqual(nextNodeMock.invokedAsyncProcessCount, 1)
        XCTAssertEqual(nextNodeMock.invokedAsyncProcessParameter?.url!.absoluteString, url)
        XCTAssertEqual(
            nextNodeMock.invokedAsyncProcessParameter?.headers.dictionary,
            headersArray
        )
        XCTAssertEqual(unwrappedResult, expectedResult)
    }
    
    public func testAsyncProcess_thenUrlQueryConvertionWork() async throws {
        // given

        let url = "http://test.com/usr"
        let dataRaw: Json = ["id": "12345"]
        let urlParameters = TransportUrlParameters(method: .post, url: URL(string: url)!)
        let encodingModel = RequestEncodingModel(
            urlParameters: urlParameters,
            raw: dataRaw,
            encoding: .urlQuery
        )
        
        let expectedResult = ["Test1": "Value1"]
        
        nextNodeMock.stubbedAsyncProccessResult = .success(expectedResult)
        
        // when

        let result = await sut.process(encodingModel, logContext: logContextMock)

        // then
        
        let unwrappedResult = try XCTUnwrap(try result.get() as? [String: String])
        
        XCTAssertEqual(nextNodeMock.invokedAsyncProcessCount, 1)
        XCTAssertEqual(
            nextNodeMock?.invokedAsyncProcessParameter?.url!.absoluteString,
            "\(url)?id=12345"
        )
        XCTAssertEqual(unwrappedResult, expectedResult)
    }

    func testAsyncProcess_thenJsonConvertionWork() async throws {
        // given

        let url = "http://test.com/usr"
        let headersArray: [String: String] = ["Content-Type": "application/json"]
        let dataRaw: Json = ["id": "12345"]
        let urlParameters = TransportUrlParameters(method: .post, url: URL(string: url)!)
        let encodingModel = RequestEncodingModel(
            urlParameters: urlParameters,
            raw: dataRaw,
            encoding: .json
        )
        
        let expectedResult = ["Test2": "Value2"]
        
        nextNodeMock.stubbedAsyncProccessResult = .success(expectedResult)

        // when
        
        let result = await sut.process(encodingModel, logContext: logContextMock)

        // then
        
        let unwrappedResult = try XCTUnwrap(try result.get() as? [String: String])
        
        XCTAssertEqual(nextNodeMock.invokedAsyncProcessCount, 1)
        XCTAssertEqual(nextNodeMock.invokedAsyncProcessParameter?.url!.absoluteString, url)
        XCTAssertEqual(
            nextNodeMock.invokedAsyncProcessParameter?.headers.dictionary,
            headersArray
        )
        XCTAssertEqual(unwrappedResult, expectedResult)
    }
}
