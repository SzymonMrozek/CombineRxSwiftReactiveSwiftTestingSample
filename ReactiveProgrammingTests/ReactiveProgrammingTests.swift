//
//  ReactiveProgrammingTests.swift
//  ReactiveProgrammingTests
//
//  Created by Szymon Mrozek on 01/10/2019.
//  Copyright © 2019 SzymonMrozek. All rights reserved.
//

import XCTest
@testable import ReactiveProgramming

import Combine
import ReactiveSwift
import RxSwift

class ReactiveProgrammingTests: XCTestCase {
    
    private var webServiceMock: WebServiceMock!
    private var sut: ViewController!
    private var combineDisposables = Set<Combine.AnyCancellable>()
    private var rxSwiftDisposables = DisposeBag()
    
    override func setUp() {
        super.setUp()
        webServiceMock = WebServiceMock()
        sut = UIStoryboard(name: "Main", bundle: .main)
            .instantiateInitialViewController(creator: {
                ViewController(coder: $0, webService: self.webServiceMock)
            })
        
    }
    
    override func tearDown() {
        combineDisposables = Set()
        rxSwiftDisposables = DisposeBag()
        super.tearDown()
    }

    func testCombinetTap_TappedOnce_ExpectTextToContainCombineLibrary() {
        // Given
        webServiceMock.getLibrary_Combine_Closure = {
            Combine.Deferred(createPublisher: {
                Result.success(Library(name: "Combine"))
                    .publisher
                    .eraseToAnyPublisher()
            })
        }
        let viewModel = sut.viewModel()
        let sink = Combine.CurrentValueSubject<String?, Never>(nil)
        viewModel.output.textChangesCombine
            .map(Optional.init)
            .subscribe(sink)
            .store(in: &combineDisposables)
        
        // When
        viewModel.input.didTapCombineButton.send(Void())
                
        // Then
        XCTAssertTrue(sink.value?.contains("Combine") ?? false)
    }
    
    func testReactiveSwift_TappedOnce_ExpectTextToContainReactiveSwiftLibrary() {
        // Given
        webServiceMock.getLibrary_ReactiveSwift_Closure = {
            ReactiveSwift.SignalProducer(value: Library(name: "ReactiveSwift"))
        }
        let viewModel = sut.viewModel()
        let sink = ReactiveSwift.MutableProperty<String?>(nil)
        sink <~ viewModel.output.textChangesReactiveSwift
        
        // When
        viewModel.input.didTapReactiveSwiftButton.send(value: Void())
        
        // Then
        XCTAssertTrue(sink.value?.contains("ReactiveSwift") ?? false)
    }
    
    func testRxSwift_TappedOnce_ExpectTextToContainRxSwiftLibrary() {
        // Given
        webServiceMock.getLibrary_RxSwift_Closure = {
            RxSwift.Single.just(Library(name: "RxSwift"))
        }
        let viewModel = sut.viewModel()
        let sink = RxSwift.BehaviorSubject<String?>(value: nil)
        viewModel.output.textChangesRxSwift.map(Optional.init)
            .subscribe(sink)
            .disposed(by: rxSwiftDisposables)
        
        // When
        viewModel.input.didTapRxSwiftButton.onNext(Void())

        // Then
        XCTAssertTrue((try? sink.value())?.contains("RxSwift") ?? false)
    }
}

class WebServiceMock: WebService {
    var getLibrary_Combine_Closure: (() -> Combine.Deferred<Combine.AnyPublisher<Library, URLError>>)!
    func getLibrary_Combine() -> Combine.Deferred<Combine.AnyPublisher<Library, URLError>> {
        return getLibrary_Combine_Closure()
    }
    
    var getLibrary_ReactiveSwift_Closure: (() -> ReactiveSwift.SignalProducer<Library, URLError>)!
    func getLibrary_ReactiveSwift() -> ReactiveSwift.SignalProducer<Library, URLError> {
        return getLibrary_ReactiveSwift_Closure()
    }
    
    var getLibrary_RxSwift_Closure: (() -> RxSwift.Single<Library>)!
    func getLibrary_RxSwift() -> RxSwift.Single<Library> {
        return getLibrary_RxSwift_Closure()
    }
}
