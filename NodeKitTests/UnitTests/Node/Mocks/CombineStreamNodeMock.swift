//
//  CombineStreamNodeMock.swift
//  NodeKitTests
//
//  Created by Andrei Frolov on 03.04.24.
//  Copyright © 2024 Surf. All rights reserved.
//

@testable import NodeKit
import Combine

final class CombineStreamNodeMock<Input, Output>: CombineStreamNode {
    
    var invokedNodeResultPublisher = false
    var invokedNodeResultPublisherCount = 0
    var invokedNodeResultPublisherParameter: (any Scheduler)?
    var invokedNodeResultPublisherParameterList: [any Scheduler] = []
    var stubbedNodeResultPublisherResult: AnyPublisher<NodeResult<Output>, Never>!
    
    func nodeResultPublisher(on scheduler: some Scheduler) -> AnyPublisher<NodeResult<Output>, Never> {
        invokedNodeResultPublisher = true
        invokedNodeResultPublisherCount += 1
        invokedNodeResultPublisherParameter = scheduler
        invokedNodeResultPublisherParameterList.append(scheduler)
        return stubbedNodeResultPublisherResult
    }
    
    var invokedProcess = false
    var invokedProcessCount = 0
    var invokedProcessParameters: (Input, LoggingContextProtocol)?
    var invokedProcessParameterList: [(Input, LoggingContextProtocol)] = []
    
    func process(_ data: Input, logContext: LoggingContextProtocol) {
        invokedProcess = true
        invokedProcessCount += 1
        invokedProcessParameters = (data, logContext)
        invokedProcessParameterList.append((data, logContext))
    }
    
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
}
