//
//  AccessSafeNode.swift
//  CoreNetKit
//
//  Created by Александр Кравченков on 22/02/2019.
//  Copyright © 2019 Кравченков Александр. All rights reserved.
//

import Foundation

/// Ошибка для узла сохранения доступа
///
/// - nodeWasRelease: Возникает в случае, если узел релизнулся из памяти.
public enum AccessSafeNodeError: Error {
    case nodeWasRelease
}

/// ## Описание
/// Узел имплементриующий логику для сохранения доступа к удаленному ресурсу.
/// Например можно рассмотреть схему для AOuth 2.0
///
/// ## Пример
/// После авторизации пользователь получает:
/// - AccessToken - для получения доступа к ресурсу. Токен имеет время жизни.
/// - RefreshToken - токен, для обновления AccessToken'а без прохождения процедуры аутентификации
///
/// Рассмотрим ситуацию с "протухшим" токеном:
/// 1. Отправляем запрос с "протухшим" токеном.
/// 2. Сервер возвращает ошибку с кодом 403 (либо 401)
/// 3. Узел запускает цепочку для обновления токена, а сам запрос сохраняет
/// 4. Цепочка вернула результат
///     1. Успех - продолжаем работу
///     2. Ошибка - пробрасываем ее выше. Работа цепочек завершается.
/// 5. Повторяем запрос с новым токеном.
///
/// ## Нужно знать
/// - Important: Очевидно, что этот узел должен находится **перед** узлом, который подставляет токен в запрос.
///
/// Узел также потокобезопасно умеет работать с несколькими запросами.
/// То есть, если мы "одновременно" посылаем несколько запросов и первый запрос завершился с ошибкой доступа, то все остальные запросы будут заморожены.
/// Когда токен обновится, то все замороженные запросы будут повторно отправлены в сеть.
///
/// Очевидно, что если во время ожидания обновления токена придет новый запрос, то он так же будет заморожен и позже отправлен заново.
///
/// - Warning: Есть веротяность того, что запрос не отправится, если он был послан в тот самый момент, когда токен обновился и мы начали отправлять запросы повторно, но верооятность этого события ничтожно мала. Нужно отправлять сотни запросов в секунду, чтобы такого добиться. Причем скорее всего эта ситуация не возможна, потому что после обновления токена запрос не заморозится.
///
/// - SeeAlso:
///     - `TransportLayerNode`
///     - `TokenRefresherNode`
open class AccessSafeNode: AsyncNode {

    /// Следующий в цепочке узел.
    public var next: any TransportLayerNode

    /// Цепочка для обновления токена.
    /// Эта цепочкаа в самом начале должна выключать узел, который имплементирует заморозку запросов и их возобновление.
    /// Из-коробки это реализует узел `TokenRefresherNode`
    public var updateTokenChain: any AsyncNode<Void, Void>

    /// Инициаллизирует узел.
    ///
    /// - Parameters:
    ///   - next: Следующий в цепочке узел.
    ///   - updateTokenChain: Цепочка для обновления токена.
    public init(next: some TransportLayerNode, updateTokenChain: some AsyncNode<Void, Void>) {
        self.next = next
        self.updateTokenChain = updateTokenChain
    }

    /// Просто передает управление следующему узлу.
    /// В случае если вернулась доступа, то обноляет токен и повторяет запрос.
    open func process(
        _ data: TransportURLRequest,
        logContext: LoggingContextProtocol
    ) async -> NodeResult<Json> {
        return await next.process(data, logContext: logContext)
            .asyncFlatMapError { error in
                switch error {
                case ResponseHttpErrorProcessorNodeError.forbidden, ResponseHttpErrorProcessorNodeError.unauthorized:
                    return await processWithTokenUpdate(data, logContext: logContext)
                default:
                    return .failure(error)
                }
            }
    }

    // MARK: - Private Methods

    private func processWithTokenUpdate(
        _ data: TransportURLRequest,
        logContext: LoggingContextProtocol
    ) async -> NodeResult<Json> {
        return await updateTokenChain.process((), logContext: logContext)
            .asyncFlatMap { await next.process(data, logContext: logContext) }
    }
}
