//
//  Result+Extension.swift
//  NodeKitTests
//
//  Created by Andrei Frolov on 31.03.24.
//  Copyright © 2024 Surf. All rights reserved.
//

@testable import NodeKit

extension Result where Success: Equatable {
    func castToMockError() -> Result<Success, MockError>? {
        switch self {
        case .success(let v):
            return .success(v)
        case .failure(let error):
            if let error = error as? MockError {
                return .failure(error)
            }
            return nil
        }
    }
    
    func findIndex(in array: [Result<Success, MockError>]) -> Int? {
        guard let value = castToMockError() else {
            return nil
        }
        return array.firstIndex(of: value)
    }
}
