//
//  URLProcessedResponse.swift
//  CoreNetKit
//
//  Created by Александр Кравченков on 04/02/2019.
//  Copyright © 2019 Кравченков Александр. All rights reserved.
//

import Foundation

/// Используется для передачи данных внутри слоя постпроцессинга запроса.
public struct URLProcessedResponse {

    private let _dataResponse: URLDataResponse

    /// URL запрос, отправленный серверу.
    public var request: URLRequest {
        return self._dataResponse.request
    }

    /// Ответ, полученный от сервера.
    public var response: HTTPURLResponse {
        return self._dataResponse.response
    }

    /// Ответ, возвращенный сервером.
    public var data: Data {
        return self._dataResponse.data
    }

    /// JSON сериализованный после обработки ответа.
    public let json: Json

    /// Инициаллизирует объект.
    ///
    /// - Parameters:
    ///   - dataResponse: Модель полученная после обрабокти ответа.
    ///   - json: Сериализованный JSON
    public init(dataResponse: URLDataResponse, json: Json) {
        self._dataResponse = dataResponse
        self.json = json
    }
}
