//
//  AsyncNodeMock.swift
//  NodeKitTests
//
//  Created by Andrei Frolov on 22.03.24.
//  Copyright © 2024 Surf. All rights reserved.
//

@testable import NodeKit
import Combine

class AsyncNodeMock<Input, Output>: AsyncNode {
    
    var invokedProcessLegacy = false
    var invokedProcessLegacyCount = 0
    var invokedProcessLegacyParameter: Input?
    var invokedProcessLegacyParameterList: [Input] = []
    var stubbedProccessLegacyResult: Observer<Output>!
    
    func processLegacy(_ data: Input) -> Observer<Output> {
        invokedProcessLegacy = true
        invokedProcessLegacyCount += 1
        invokedProcessLegacyParameter = data
        invokedProcessLegacyParameterList.append(data)
        return stubbedProccessLegacyResult
    }
    
    var invokedAsyncProcess = false
    var invokedAsyncProcessCount = 0
    var invokedAsyncProcessParameter: (Input, LoggingContextProtocol)?
    var invokedAsyncProcessParameterList: [(Input, LoggingContextProtocol)] = []
    var stubbedAsyncProccessResult: NodeResult<Output>!
    var stubbedAsyncProcessRunFunction: (() async -> Void)?
    
    func process(_ data: Input, logContext: LoggingContextProtocol) async -> NodeResult<Output> {
        invokedAsyncProcess = true
        invokedAsyncProcessCount += 1
        invokedAsyncProcessParameter = (data, logContext)
        invokedAsyncProcessParameterList.append((data, logContext))
        if let function = stubbedAsyncProcessRunFunction {
            await function()
        }
        return stubbedAsyncProccessResult
    }
}
