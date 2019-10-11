//
//  ViewController.swift
//  ReactiveProgramming
//
//  Created by Szymon Mrozek on 01/10/2019.
//  Copyright © 2019 SzymonMrozek. All rights reserved.
//

import Foundation
import UIKit

import ReactiveSwift
import Combine
import RxSwift

struct Library {
    let name: String
}

protocol WebService {
    func getLibrary_Combine() -> Combine.Deferred<AnyPublisher<Library, URLError>>
    func getLibrary_ReactiveSwift() -> ReactiveSwift.SignalProducer<Library, URLError>
    func getLibrary_RxSwift() -> RxSwift.Single<Library>
}

struct WebServiceImp: WebService {
    func getLibrary_Combine() -> Deferred<AnyPublisher<Library, URLError>> {
        return Deferred(createPublisher: {
            Result.success(
                Library(name: "Combine!")
            ).publisher.eraseToAnyPublisher()
        })
    }
    
    func getLibrary_ReactiveSwift() -> SignalProducer<Library, URLError> {
        return SignalProducer(
            value: Library(name: "ReactiveSwift!")
        )
    }
    
    func getLibrary_RxSwift() -> Single<Library> {
        return Single.just(
            Library(name: "RxSwift!")
        )
    }
}

struct ViewModel {
    struct Input {
        let didTapCombineButton: Combine.PassthroughSubject<Void, Never>
        let didTapReactiveSwiftButton: ReactiveSwift.Signal<Void, Never>.Observer
        let didTapRxSwiftButton: RxSwift.AnyObserver<Void>
    }
    
    struct Output {
        let textChangesCombine: Combine.AnyPublisher<String, Never>
        let textChangesReactiveSwift: ReactiveSwift.Signal<String, Never>
        let textChangesRxSwift: RxSwift.Observable<String>
    }

    let input: Input
    let output: Output
}

final class ViewController: UIViewController {

    @IBOutlet private weak var combineButton: UIButton!
    @IBOutlet private weak var reactiveSwiftButton: UIButton!
    @IBOutlet private weak var rxSwiftButton: UIButton!
    @IBOutlet private weak var textLabel: UILabel!
    
    private let webService: WebService
    
    private var combineDisposables = Set<Combine.AnyCancellable>()
    private var reactiveSwiftDisposables = ReactiveSwift.CompositeDisposable()
    private var rxSwiftDisposables = RxSwift.DisposeBag()
    
    private var viewModelInput: ViewModel.Input!
    
    init?(coder: NSCoder, webService: WebService) {
        self.webService = webService
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let viewModel = self.viewModel()
        subscribeToViewModelOutput(output: viewModel.output)
        viewModelInput = viewModel.input
        combineButton.addTarget(
            self,
            action: #selector(didTapCombineButton(sender:)),
            for: .touchUpInside
        )
        reactiveSwiftButton.addTarget(
            self,
            action: #selector(didTapReactiveSwiftButton(sender:)),
            for: .touchUpInside
        )
        rxSwiftButton.addTarget(
            self,
            action: #selector(didTapRxSwiftButton(sender:)),
            for: .touchUpInside
        )
    }
    
    private func subscribeToViewModelOutput(output: ViewModel.Output) {
        output.textChangesCombine
            .sink(receiveValue: { [weak self] in
                self?.textLabel.text = $0
            })
            .store(in: &combineDisposables)
        reactiveSwiftDisposables += output.textChangesReactiveSwift
            .observeValues { [weak self] in
                self?.textLabel.text = $0
            }
        output.textChangesRxSwift
            .subscribe(onNext: { [weak self] in
                self?.textLabel.text = $0
            })
            .disposed(by: rxSwiftDisposables)
        
    }
        
    @objc private func didTapCombineButton(sender: UIButton) {
        viewModelInput.didTapCombineButton.send(Void())
    }
    
    @objc private func didTapReactiveSwiftButton(sender: UIButton) {
        viewModelInput.didTapReactiveSwiftButton.send(value: Void())
    }
    
    @objc private func didTapRxSwiftButton(sender: UIButton) {
        viewModelInput.didTapRxSwiftButton.onNext(Void())
    }
    
    func viewModel() -> ViewModel {
        let combine = createCombineTextChanges()
        let reactiveSwift = createReactiveSwiftTextChanges()
        let rxSwift = createRxSwiftTextChanges()

        return ViewModel(
            input: ViewModel.Input(
                didTapCombineButton: combine.0,
                didTapReactiveSwiftButton: reactiveSwift.0,
                didTapRxSwiftButton: rxSwift.0
            ),
            output: ViewModel.Output(
                textChangesCombine: combine.1,
                textChangesReactiveSwift: reactiveSwift.1,
                textChangesRxSwift: rxSwift.1
            )
        )
    }
    
    private func createCombineTextChanges(
        ) -> (
        Combine.PassthroughSubject<Void, Never>,
        Combine.AnyPublisher<String, Never>
        ) {
        let subject = Combine.PassthroughSubject<Void, Never>()
        let textChanges = subject
            .flatMap { [webService] in
                webService.getLibrary_Combine()
                    .map { "Library name: \($0.name)" }
                    .catch { Combine.Just("Error occurred: \($0.localizedDescription)") }
            }
            .eraseToAnyPublisher()
        
        return (subject, textChanges)
    }
    
    private func createReactiveSwiftTextChanges(
        ) -> (
        ReactiveSwift.Signal<Void, Never>.Observer,
        ReactiveSwift.Signal<String, Never>
        ) {
        let (tap, tapObserver) = ReactiveSwift.Signal<Void, Never>.pipe()
        let textChanges = tap.flatMap(
            .latest,
            { [webService] in
                webService.getLibrary_ReactiveSwift()
                    .map { "Library name: \($0.name)" }
                    .flatMapError {
                        ReactiveSwift.SignalProducer<String, Never>(
                            value: "Error occurred: \($0.localizedDescription)"
                        )
                    }
            })
            .observe(on: UIScheduler())
        return (tapObserver, textChanges)
    }
    
    private func createRxSwiftTextChanges(
        ) -> (
        RxSwift.AnyObserver<Void>,
        RxSwift.Observable<String>
        ) {
        let subject = RxSwift.PublishSubject<Void>()
        let textChanges = subject.flatMapLatest { [webService] in
            webService.getLibrary_RxSwift()
                .map { $0.name }
                .asObservable()
                .catchError {
                    RxSwift.Observable<String>.just(
                        "Error Occurred: \($0.localizedDescription)"
                    )
                }
            }
        return (subject.asObserver(), textChanges)
    }
}
