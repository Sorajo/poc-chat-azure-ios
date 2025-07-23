//
//  DispatchGroup+Extention.swift
//  poc-chat-azure-ios
//
//  Created by Suriya on 21/7/2568 BE.
//
import Foundation

public typealias AsyncResultTask<T> = (@escaping (Result<T, Error>) -> Void) -> Void

extension DispatchGroup {
    private static let unknownError = NSError(domain: "DispatchGroup.zip", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown state"])
    /// A helper for zipping 2 asynchronous tasks that return Result<T, Error>.
    /// It waits for both tasks to complete, then calls the completion handler
    /// with a tuple of results if both succeeded, or the first error encountered.
    ///
    /// - Parameters:
    ///   - task1: The first async task of type (@escaping (Result<T1, Error>) -> Void) -> Void
    ///   - task2: The second async task of type (@escaping (Result<T2, Error>) -> Void) -> Void
    ///   - completion: Called with .success((T1, T2)) when both succeed,
    ///                 or .failure(Error) if any of them fails.
    
    public static func zip<T1, T2>(
        task1: AsyncResultTask<T1>,
        task2: AsyncResultTask<T2>,
        completion: @escaping (Result<(T1, T2), Error>) -> Void
    ) {
        let group = DispatchGroup()
        var result1: Result<T1, Error>?
        var result2: Result<T2, Error>?
        
        group.enter()
        task1 { result in
            result1 = result
            group.leave()
        }
        
        group.enter()
        task2 { result in
            result2 = result
            group.leave()
        }
        group.notify(queue: .main) {
            if case .success(let t1) = result1, case .success(let t2) = result2 {
                completion(.success((t1, t2)))
            } else if case .failure(let e1) = result1 {
                completion(.failure(e1))
            } else if case .failure(let e2) = result2 {
                completion(.failure(e2))
            } else {
                completion(.failure(DispatchGroup.unknownError))
            }
        }
    }
    
    public static func zip<T1, T2, T3>(
        task1: AsyncResultTask<T1>,
        task2: AsyncResultTask<T2>,
        task3: AsyncResultTask<T3>,
        completion: @escaping (Result<(T1, T2, T3), Error>) -> Void
    ) {
        let group = DispatchGroup()
        var result1: Result<T1, Error>?
        var result2: Result<T2, Error>?
        var result3: Result<T3, Error>?
        group.enter()
        
        task1 { result in
            result1 = result
            group.leave()
        }
        
        group.enter()
        task2 { result in
            result2 = result
            group.leave()
        }
        
        group.enter()
        task3 { result in
            result3 = result
            group.leave()
        }
        
        group.notify(queue: .main) {
            if case .success(let t1) = result1,
               case .success(let t2) = result2,
               case .success(let t3) = result3 {
                completion(.success((t1, t2, t3)))
            } else if case .failure(let e1) = result1 {
                completion(.failure(e1))
            } else if case .failure(let e2) = result2 {
                completion(.failure(e2))
            } else if case .failure(let e3) = result3 {
                completion(.failure(e3))
            } else {
                completion(.failure(DispatchGroup.unknownError))
            }
        }
    }
    
    public static func zip<T1, T2, T3, T4>(
        task1: AsyncResultTask<T1>,
        task2: AsyncResultTask<T2>,
        task3: AsyncResultTask<T3>,
        task4: AsyncResultTask<T4>,
        completion: @escaping (Result<(T1, T2, T3, T4), Error>) -> Void
    ) {
        let group = DispatchGroup()
        var result1: Result<T1, Error>?
        var result2: Result<T2, Error>?
        var result3: Result<T3, Error>?
        var result4: Result<T4, Error>?
        group.enter()
        
        task1 { result in
            result1 = result
            group.leave()
        }
        
        group.enter()
        task2 { result in
            result2 = result
            group.leave()
        }
        
        group.enter()
        task3 { result in
            result3 = result
            group.leave()
        }
        
        group.enter()
        task4 { result in
            result4 = result
            group.leave()
        }
        
        group.notify(queue: .main) {
            if case .success(let t1) = result1,
               case .success(let t2) = result2,
               case .success(let t3) = result3,
               case .success(let t4) = result4 {
                completion(.success((t1, t2, t3, t4)))
            } else if case .failure(let e1) = result1 {
                completion(.failure(e1))
            } else if case .failure(let e2) = result2 {
                completion(.failure(e2))
            } else if case .failure(let e3) = result3 {
                completion(.failure(e3))
            } else if case .failure(let e4) = result4 {
                completion(.failure(e4))
            } else {
                completion(.failure(DispatchGroup.unknownError))
            }
        }
    }
    
    public static func zip<T1, T2, T3, T4, T5>(
        task1: AsyncResultTask<T1>,
        task2: AsyncResultTask<T2>,
        task3: AsyncResultTask<T3>,
        task4: AsyncResultTask<T4>,
        task5: AsyncResultTask<T5>,
        completion: @escaping (Result<(T1, T2, T3, T4, T5), Error>) -> Void
    ) {
        let group = DispatchGroup()
        var result1: Result<T1, Error>?
        var result2: Result<T2, Error>?
        var result3: Result<T3, Error>?
        var result4: Result<T4, Error>?
        var result5: Result<T5, Error>?
        group.enter()
        
        task1 { result in
            result1 = result
            group.leave()
        }
        
        group.enter()
        task2 { result in
            result2 = result
            group.leave()
        }
        
        group.enter()
        task3 { result in
            result3 = result
            group.leave()
        }
        
        group.enter()
        task4 { result in
            result4 = result
            group.leave()
        }
        
        group.enter()
        task5 { result in
            result5 = result
            group.leave()
        }
        
        group.notify(queue: .main) {
            if case .success(let t1) = result1,
               case .success(let t2) = result2,
               case .success(let t3) = result3,
               case .success(let t4) = result4,
               case .success(let t5) = result5 {
                completion(.success((t1, t2, t3, t4, t5)))
            } else if case .failure(let e1) = result1 {
                completion(.failure(e1))
            } else if case .failure(let e2) = result2 {
                completion(.failure(e2))
            } else if case .failure(let e3) = result3 {
                completion(.failure(e3))
            } else if case .failure(let e4) = result4 {
                completion(.failure(e4))
            } else if case .failure(let e5) = result5 {
                completion(.failure(e5))
            } else {
                completion(.failure(DispatchGroup.unknownError))
            }
        }
    }
    
    public static func zip<T1, T2, T3, T4, T5, T6>(
        task1: AsyncResultTask<T1>,
        task2: AsyncResultTask<T2>,
        task3: AsyncResultTask<T3>,
        task4: AsyncResultTask<T4>,
        task5: AsyncResultTask<T5>,
        task6: AsyncResultTask<T6>,
        completion: @escaping (Result<(T1, T2, T3, T4, T5, T6), Error>) -> Void
    ) {
        let group = DispatchGroup()
        var result1: Result<T1, Error>?
        var result2: Result<T2, Error>?
        var result3: Result<T3, Error>?
        var result4: Result<T4, Error>?
        var result5: Result<T5, Error>?
        var result6: Result<T6, Error>?
        group.enter()
        
        task1 { result in
            result1 = result
            group.leave()
        }
        
        group.enter()
        task2 { result in
            result2 = result
            group.leave()
        }
        
        group.enter()
        task3 { result in
            result3 = result
            group.leave()
        }
        
        group.enter()
        task4 { result in
            result4 = result
            group.leave()
        }
        
        group.enter()
        task5 { result in
            result5 = result
            group.leave()
        }
        
        group.enter()
        task6 { result in
            result6 = result
            group.leave()
        }
        group.notify(queue: .main) {
            if case .success(let t1) = result1,
               case .success(let t2) = result2,
               case .success(let t3) = result3,
               case .success(let t4) = result4,
               case .success(let t5) = result5,
               case .success(let t6) = result6 {
                completion(.success((t1, t2, t3, t4, t5, t6)))
            } else if case .failure(let e1) = result1 {
                completion(.failure(e1))
            } else if case .failure(let e2) = result2 {
                completion(.failure(e2))
            } else if case .failure(let e3) = result3 {
                completion(.failure(e3))
            } else if case .failure(let e4) = result4 {
                completion(.failure(e4))
            } else if case .failure(let e5) = result5 {
                completion(.failure(e5))
            } else if case .failure(let e6) = result6 {
                completion(.failure(e6))
            } else {
                completion(.failure(DispatchGroup.unknownError))
            }
        }
    }
}
