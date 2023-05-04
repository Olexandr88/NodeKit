//
//  UrlCacheWriterNode.swift
//  CoreNetKitWithExample
//
//  Created by Александр Кравченков on 28/11/2018.
//  Copyright © 2018 Александр Кравченков. All rights reserved.
//

import Foundation

/// Этот узел занимается записью данных в URL кэш.
/// - Important: это "глупая" реализация,
/// в которой не учитываются server-side политики и прочее.
/// Подразумечается, что этот узел не входит в цепочку, а является листом одного из узлов.
open class UrlCacheWriterNode<Type>: Node<UrlProcessedResponse<Type>, Void> {

    /// Формирует `CachedURLResponse` с политикой `.allowed`, сохраняет его в кэш,
    /// а затем возвращает сообщение об успешной операции.
    open override func process(_ data: UrlProcessedResponse<Type>) -> Context<Void> {
        let cahced = CachedURLResponse(response: data.response, data: data.data, storagePolicy: .allowed)
        URLCache.shared.storeCachedResponse(cahced, for: data.request)
        return Context<Void>().emit(data: ())
    }
}
