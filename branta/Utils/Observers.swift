//
//  Observers.swift
//  branta
//
//  Created by Keith Gardner on 12/25/23.
//

protocol VerifyObserver: AnyObject {
    func verifyDidChange(newResults: Array<[String: String]>)
}

protocol DataFeedObserver: AnyObject {
    func dataFeedExecutionStarted(started: Bool)
    func dataFeedCount(count: Int)
}
