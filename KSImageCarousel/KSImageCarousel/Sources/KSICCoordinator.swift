//
//  KSICCoordinator.swift
//  KSImageCarousel
//
//  Created by Lee Kah Seng on 28/05/2017.
//  Copyright © 2017 Lee Kah Seng. All rights reserved. (https://github.com/LeeKahSeng/KSImageCarousel)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

public protocol KSICCoordinatorDelegate {
    
    /// Method triggered when image of carousel being tapped
    ///
    /// - Parameter index: model index of the tapped image
    func carouselDidTappedImage(at index: Int, coordinator: KSICCoordinator)
}

extension KSICCoordinatorDelegate {
    // Optional delegte method
    public func carouselDidTappedImage(at index: Int, coordinator: KSICCoordinator) {}
}

public protocol KSICCoordinator: class, KSICScrollerViewControllerDelegate {
    
    /// The carousel that being show on screen
    var carousel: KSICScrollerViewController? { get }
    
    /// The model (images that need to be show on carousel)
    var model: [KSImageCarouselDisplayable] { get }
    
    /// KSICCoordinator optional delegte
    var delegate: KSICCoordinatorDelegate? { get set }
    
    /// View model for the carousel.
    /// The 3 elements consists of [prev page element, current page element, next page element]
    /// If model only have less than 3 element, view model will have less than 3 element as well
    var carouselViewModel: [KSImageCarouselDisplayable] { get }
    
    /// Page (index) of model that currently visible to user
    var currentPage: Int { get }
    
    /// Add the carousel to it's container
    func showCarousel(inside container: UIView, of parentViewController: UIViewController)
    
    /// Go to next page - calling this will update currentPage -> update caoursel.viewModel -> update images in carousel -> scroll carousel to desire subview
    func nextPage()
    
    /// Go to previous page - calling this will update currentPage -> update caoursel.viewModel -> update images in carousel -> scroll carousel to desire subview
    func previousPage()
}

extension KSICCoordinator {
    
    fileprivate var firstPage: Int {
        return 0
    }
    
    fileprivate var lastPage: Int {
        return model.count - 1
    }
    
    fileprivate var isFirstPage: Bool {
        return currentPage == firstPage
    }
    
    fileprivate var isLastPage: Bool {
        return currentPage == lastPage
    }
    
    /// Check to make sure the page number is in range (between first page & last page)
    ///
    /// - Parameter page: page number to check
    /// - Returns: True -> In range | False -> out of range
    fileprivate func isPageInRange(_ page: Int) -> Bool {
        return  (page >= firstPage && page <= lastPage)
    }

    /// Add carousel as child view controller and follow the size of the container view
    ///
    /// - Parameters:
    ///   - carousel: carousel to be added as child view controller
    ///   - container: container that contain the carousel
    ///   - parentViewController: parent view controller of the carousel
    fileprivate func add(_ carousel: KSICScrollerViewController, to container: UIView, of parentViewController: UIViewController) {
        
        parentViewController.addChildViewController(carousel)
        carousel.didMove(toParentViewController: parentViewController)
        
        // Carousel to follow container size
        container.addSameSizeSubview(carousel.view)
    }
}

// MARK: -

/// Carousel can only scroll until last page or first page when using this coordinator
public class KSICFiniteCoordinator: KSICCoordinator {
    
    public var delegate: KSICCoordinatorDelegate?

    public let model: [KSImageCarouselDisplayable]
    
    private var _carousel: KSICScrollerViewController?
    public var carousel: KSICScrollerViewController? {
        return _carousel
    }
    
    private var _currentPage: Int {
        didSet {
            
            // Note: Everytime current page being set, we will update carousel's viewModel (which will update images in carousel) and scroll carousel to subview that user should see
            
            // Update view model of carousel
            _carousel?.viewModel = carouselViewModel
            
            // Scroll carousel to subview that user should see
            scrollCarouselToDesireSubview()
        }
    }
    
    public var currentPage: Int {
        return _currentPage
    }
    
    public var carouselViewModel: [KSImageCarouselDisplayable] {
        
        if model.count == 1 {
            // When model have only 1 element
            return [model[0]]
            
        } else if model.count == 2 {
            // When model have only 2 elements
            return [model[0], model[1]]
            
        } else {
            // When model have only 3 or more elements
            if isFirstPage {
                
                return [model[currentPage],
                        model[currentPage + 1],
                        model[currentPage + 2]]
                
            } else if isLastPage {
                
                return [model[currentPage - 2],
                        model[currentPage - 1],
                        model[currentPage]]
                
            } else {
                
                return [model[currentPage - 1],
                        model[currentPage],
                        model[currentPage + 1]]
            }
        }
    }
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - model: Model for carousel
    ///   - initialPage: Page to display when carousel first shown
    /// - Throws: emptyModel, pageOutOfRange
    public init(with model: [KSImageCarouselDisplayable], initialPage: Int) throws {
        
        // Make sure model is not empty
        guard model.count > 0 else {
            throw CoordinatorError.emptyModel
        }
        
        self.model = model
        self._currentPage = initialPage
        
        // Make sure initial page is in range
        guard isPageInRange(initialPage) else {
            throw CoordinatorError.pageOutOfRange
        }
    }
    
    // MARK: KSICCoordinator conformation
    public func showCarousel(inside container: UIView, of parentViewController: UIViewController) {
        _carousel = KSICScrollerViewController(withViewModel: carouselViewModel)
        _carousel!.delegate = self
        add(_carousel!, to: container, of: parentViewController)
    }

    public func nextPage() {
        if currentPage == lastPage {
            return
        } else {
            let newPage = currentPage + 1
            try! goto(page: newPage)
        }
    }
    
    public func previousPage() {
        if currentPage == firstPage {
            return
        } else {
            let newPage = currentPage - 1
            try! goto(page: newPage)
        }
    }
    
    // MARK: Private functions
    
    /// Go to a specific page
    ///
    /// - Parameter p: page number
    /// - Throws: pageOutOfRange
    private func goto(page p: Int) throws {
        
        // Make sure page is between first page and last page
        guard isPageInRange(p) else {
            // throw exception
            throw CoordinatorError.pageOutOfRange
        }
        
        _currentPage = p
    }
    
    
    /// Base on current page, scroll carousel to subview that should be visible to user
    fileprivate func scrollCarouselToDesireSubview() {
        // TODO: Add unit test
        if isFirstPage {
            // Scroll to first image view
            carousel?.scrollToFirstSubview()
        } else if isLastPage {
            // Scroll to last image view
            carousel?.scrollToLastSubview()
        } else {
            // Scroll to center image view
            carousel?.scrollToCenterSubview()
        }
    }
}

// MARK: KSICScrollerViewControllerDelegate
extension KSICCoordinator where Self == KSICFiniteCoordinator {
    public func scrollerViewControllerDidFinishLayoutSubviews(_ viewController: KSICScrollerViewController) {
        // Scroll carousel to subview that user should see
        scrollCarouselToDesireSubview()
    }
    
    public func scrollerViewControllerDidGotoNextPage(_ viewController: KSICScrollerViewController) {
        // Calling nextPage() will update currentPage -> update caoursel.viewModel -> update images in carousel -> scroll carousel to desire subview
        nextPage()
    }
    
    public func scrollerViewControllerDidGotoPreviousPage(_ viewController: KSICScrollerViewController) {
        // Calling previousPage() will update currentPage -> update caoursel.viewModel -> update images in carousel -> scroll carousel to desire subview
        previousPage()
    }
    
    public func scrollerViewControllerDidTappedImageView(at index: Int, viewController: KSICScrollerViewController) {
        delegate?.carouselDidTappedImage(at: currentPage, coordinator: self)
    }
}

// MARK: -

/// Carousel will be able to scroll infinitely when using this coordinator
public class KSICInfiniteCoordinator: KSICCoordinator {
    
    public enum KSICAutoScrollDirection {
        case left
        case right
    }
    
    public var delegate: KSICCoordinatorDelegate?
    
    public let model: [KSImageCarouselDisplayable]
    
    private var _carousel: KSICScrollerViewController?
    public var carousel: KSICScrollerViewController? {
        return _carousel
    }
    
    private var _currentPage: Int {
        didSet {
            
            // Note: Everytime current page being set, we will update carousel's viewModel (which will update images in carousel) and scroll carousel to subview that user should see
            
            // Update view model of carousel
            _carousel?.viewModel = carouselViewModel
            
            // Scroll carousel to subview that user should see
            scrollCarouselToDesireSubview()
        }
    }
    public var currentPage: Int {
        return _currentPage
    }
    
    public var carouselViewModel: [KSImageCarouselDisplayable] {
        if model.count == 1 {
            // When model only have 1 element, next page & previous page is same as current page
            return [model[currentPage],
                    model[currentPage],
                    model[currentPage]]
        } else {
            
            if isFirstPage {
                // When at first page, previous page should be last page
                return [model[lastPage],
                        model[currentPage],
                        model[currentPage + 1]]
            } else if isLastPage {
                // When at last page, next page should be first page
                return [model[currentPage - 1],
                        model[currentPage],
                        model[firstPage]]
            } else {
                return [model[currentPage - 1],
                        model[currentPage],
                        model[currentPage + 1]]
            }
        }
    }
    
    
    /// Timer object needed for auto scrolling
    lazy private var autoScrollTimer: Timer = Timer()
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - model: Model for carousel
    ///   - initialPage: Page to display when carousel first shown
    /// - Throws: emptyModel, pageOutOfRange
    public init(with model: [KSImageCarouselDisplayable], initialPage: Int) throws {
        
        // Make sure model is not empty
        guard model.count > 0 else {
            throw CoordinatorError.emptyModel
        }
        
        self.model = model
        self._currentPage = initialPage
        
        // Make sure initial page is in range
        guard isPageInRange(initialPage) else {
            throw CoordinatorError.pageOutOfRange
        }
    }
    
    // MARK: KSICCoordinator conformation
    public func showCarousel(inside container: UIView, of parentViewController: UIViewController) {
        _carousel = KSICScrollerViewController(withViewModel: carouselViewModel)
        _carousel!.delegate = self
        add(_carousel!, to: container, of: parentViewController)
    }
    
    public func nextPage() {
        if currentPage == lastPage {
            try! goto(page: firstPage)
        } else {
            let newPage = currentPage + 1
            try! goto(page: newPage)
        }
    }
    
    public func previousPage() {
        if currentPage == firstPage {
            try! goto(page: lastPage)
        } else {
            let newPage = currentPage - 1
            try! goto(page: newPage)
        }
    }
    
    
    // MARK: Public functions
    public func startAutoScroll(withDirection direction: KSICAutoScrollDirection, interval: TimeInterval) {
        switch direction {
        case .left:
            autoScrollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [unowned self] (timer) in
                self.nextPage()
            })
        case .right:
            autoScrollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [unowned self] (timer) in
                self.previousPage()
            })
        }
    }
    
    public func stopAutoScroll() {
        autoScrollTimer.invalidate()
    }
    
    
    // MARK: Private functions
    
    /// Go to a specific page
    ///
    /// - Parameter p: page number
    /// - Throws: pageOutOfRange
    private func goto(page p: Int) throws {
        
        // Make sure page is between first page and last page
        guard isPageInRange(p) else {
            // throw exception
            throw CoordinatorError.pageOutOfRange
        }
        
        _currentPage = p
    }
    
    /// Base on current page, scroll carousel to subview that should be visible to user
    fileprivate func scrollCarouselToDesireSubview() {
        // TODO: Add unit test
        
        // Center page should always be the current visible page
        carousel?.scrollToCenterSubview()
    }
}

// MARK: KSICScrollerViewControllerDelegate
extension KSICCoordinator where Self == KSICInfiniteCoordinator {
    public func scrollerViewControllerDidFinishLayoutSubviews(_ viewController: KSICScrollerViewController) {
        // Scroll carousel to subview that user should see
        scrollCarouselToDesireSubview()
    }
    
    public func scrollerViewControllerDidGotoNextPage(_ viewController: KSICScrollerViewController) {
        // Calling nextPage() will update currentPage -> update caoursel.viewModel -> update images in carousel -> scroll carousel to desire subview
        nextPage()
    }
    
    public func scrollerViewControllerDidGotoPreviousPage(_ viewController: KSICScrollerViewController) {
        // Calling previousPage() will update currentPage -> update caoursel.viewModel -> update images in carousel -> scroll carousel to desire subview
        previousPage()
    }
    
    public func scrollerViewControllerDidTappedImageView(at index: Int, viewController: KSICScrollerViewController) {
        delegate?.carouselDidTappedImage(at: currentPage, coordinator: self)
    }
}

