//
//  MyExpandableCollectionView.swift
//  ExpandCollectionViewTest
//
//  Created by Joseph Chen on 2022/6/8.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol MyExpandableCollectionViewDataSource: NSObjectProtocol {
    
    func numberOfSections() -> Int
    func numberOfItemsInSection(section: Int) -> Int
    func updateCell(indexPath: IndexPath, cell: MyExpandableCollectionViewCell)
    func updateHeader(indexPath: IndexPath, headerView: MyExpandableCollectionHeaderView)
}
 
class MyExpandableCollectionView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // Data
    weak var dataSource: MyExpandableCollectionViewDataSource?
    
    // Rx
    private(set) var scrollPublishSubject = PublishSubject<Int?>()  // Section
    private(set) var didSelectPublishSubject = PublishSubject<IndexPath>()
    
    // UI
    internal let layout = UICollectionViewFlowLayout()
    internal var collectionView: UICollectionView!
    internal var itemCellClass: AnyClass!
    internal var headerClass: AnyClass!
    internal let disposeBag = DisposeBag()
    
    // Header View
    internal var focusedHeaderViewIndex: Int? = nil
    internal let packTapPublishSub = PublishSubject<Int>()
     
    // Cell Item
    internal var focusedItemIndexPath: IndexPath? = nil
    internal var leftVisibleSection: Int? = nil
 
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(dataSource: MyExpandableCollectionViewDataSource,
                     itemCellClass: AnyClass,
                     headerClass: AnyClass) {
        self.init(frame: .zero)
        
        self.dataSource = dataSource
        self.itemCellClass = itemCellClass
        self.headerClass = headerClass
        
        self.initUI()
        self.initRx()
    }
         
    override func layoutSubviews() {
        self.layoutMe()
    }
    
    internal func initUI() {
         
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4);
        layout.minimumLineSpacing = 4
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        collectionView.register(itemCellClass.self, forCellWithReuseIdentifier: "CellItem")
        collectionView.register(headerClass.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
          withReuseIdentifier: "Header")
        collectionView.register(MyExpandableCollectionFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
          withReuseIdentifier: "Footer")
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .black
        self.addSubview(collectionView)
    }
    
    internal func layoutMe() {
                 
        self.collectionView.snp.removeConstraints()
        self.collectionView.snp.makeConstraints{ (make) -> () in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(80)
        }
        
        layout.itemSize = CGSize(width: 65, height: 80)
        layout.headerReferenceSize = CGSize(width: 65, height: 80)
        layout.footerReferenceSize = CGSize(
            width: layout.itemSize.width * 0.3, height: 80)
    }
    
    internal func initRx() {
        
        packTapPublishSub.subscribe { val in
            
            self.handleCategoryCellExpandCollapse(packIndex: val)
        }
        .disposed(by: disposeBag)
    }
}

extension MyExpandableCollectionView {
    
    func reloadData() {
        self.collectionView.reloadData()
    }
    
    func scrollToSection(index: Int, animated: Bool = true) {
        
        let scrollToIndexPath = IndexPath(row: 0, section: index)
        if let headerAttributes: UICollectionViewLayoutAttributes = self.collectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: scrollToIndexPath) {
            
            // Should take the headerView into consideration
        self.collectionView.setContentOffset(CGPoint(x: headerAttributes.frame.origin.x, y: 0), animated: animated);
//        self.collectionView.scrollToItem(at: scrollToIndexPath, at: .left, animated: true)
        }
    }
    
    func onSelectIndexPath(indexPath: IndexPath) {
        
        self.handleItemCellSelect(didSelectItemAt: indexPath)
        didSelectPublishSubject.onNext(indexPath)
    }
    
    func onSelectNext(scrollTo: Bool = true) {
        guard let dataSource = self.dataSource else { return }
        
        guard let currentItemIndexPath = self.focusedItemIndexPath else {
            self.handleCategoryCellExpandCollapse(packIndex: 0)
            self.onSelectIndexPath(indexPath: IndexPath(row: 0, section: 0))
            return
        }
        
        // Move to next item in current section
        let nextRow = currentItemIndexPath.row + 1
        if nextRow < dataSource.numberOfItemsInSection(section: currentItemIndexPath.section) {
            self.onSelectIndexPath(indexPath: IndexPath(row: nextRow, section: currentItemIndexPath.section))
            return
        }
        // or Move to next section
        else {
            
            let nextSection = currentItemIndexPath.section + 1
            guard nextSection < dataSource.numberOfSections() else {
                return
            }
            self.handleCategoryCellExpandCollapse(packIndex: nextSection, scrollTo: false)
            self.onSelectIndexPath(indexPath: IndexPath(row: 0, section: nextSection))
        }
    }
    
    func onSelectPrev(scrollTo: Bool = true) {
        guard let dataSource = self.dataSource else { return }
        
        guard let currentItemIndexPath = self.focusedItemIndexPath else {
            self.handleCategoryCellExpandCollapse(packIndex: 0)
            self.onSelectIndexPath(indexPath: IndexPath(row: 0, section: 0))
            return
        }
        
        // Move to prev item in current section
        let prevRow = currentItemIndexPath.row - 1
        if prevRow != -1 {
            self.onSelectIndexPath(indexPath: IndexPath(row: prevRow, section: currentItemIndexPath.section))
            return
        }
        // or Move to next section
        else {
            
            let prevSection = currentItemIndexPath.section - 1
            guard prevSection != -1 else {
                return
            }
            let lastRow = dataSource.numberOfItemsInSection(section: prevSection) - 1
            self.handleCategoryCellExpandCollapse(packIndex: prevSection, scrollTo: false)
            self.onSelectIndexPath(indexPath: IndexPath(row: lastRow, section: prevSection))
        }
    }
    
    func onRotateTo() {
        
//        self.collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader)
//            .forEach {
//                $0.transform = $0.transform.rotated(by: .pi / 2)
//            }
//
//        self.collectionView.visibleCells
//            .forEach {
//            $0.transform = $0.transform.rotated(by: .pi / 2)
//        }
    }
}

extension MyExpandableCollectionView {
     
    internal func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let dataSource = self.dataSource else { return 0 }
        return dataSource.numberOfSections()
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let dataSource = self.dataSource else { return 0 }
        
        if section == self.focusedHeaderViewIndex {
            return dataSource.numberOfItemsInSection(section: section)
        }
        return 0
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: "CellItem", for: indexPath) as! MyExpandableCollectionViewCell
        
        self.dataSource?.updateCell(indexPath: indexPath, cell: cell)
        if let focusedItemIndexPath = self.focusedItemIndexPath {
            cell.isSelected = (indexPath == focusedItemIndexPath)
        }
        else {
            cell.isSelected = false
        }
        cell.updateUI()
        return cell
    }
}
    
extension MyExpandableCollectionView {
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        return CGSize(width: 65, height: self.bounds.height)
    }
    
    internal func collectionView(_ collectionView: UICollectionView,
                          layout collectionViewLayout: UICollectionViewLayout,
                          referenceSizeForFooterInSection section: Int) -> CGSize {
        
        if section == self.focusedHeaderViewIndex {
            return CGSize(width: 15, height: self.bounds.height)
        }
        else {
            return .zero
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
                        
        if kind == UICollectionView.elementKindSectionHeader {
            
            let headerView =
                collectionView.dequeueReusableSupplementaryView(
                    ofKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: "Header",
                    for: indexPath) as! MyExpandableCollectionHeaderView
            
            headerView.btn.rx.tap
                .subscribe(onNext: { [weak self] in
                    
                    self?.packTapPublishSub.onNext(indexPath.section)
                })
                .disposed(by: headerView.disposeBag)
            
            self.dataSource?.updateHeader(indexPath: indexPath, headerView: headerView)
            headerView.updateUI()
            
            return headerView
        }
        else if kind == UICollectionView.elementKindSectionFooter {
            
            let footerView =
                collectionView.dequeueReusableSupplementaryView(
                    ofKind: UICollectionView.elementKindSectionFooter,
                    withReuseIdentifier: "Footer",
                    for: indexPath) as! MyExpandableCollectionFooterView
                         
            return footerView
        }
        
        return UICollectionReusableView()
    }
}

extension MyExpandableCollectionView {
         
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.onSelectIndexPath(indexPath: indexPath)
    }
}

extension MyExpandableCollectionView {
     
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        // Scrolling by the user
        if scrollView.isDragging || scrollView.isDecelerating {
            
            let indexPath = self.collectionView.indexPathsForVisibleSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader)
            let leftSection = indexPath
                .map{ $0.section }
                .sorted(by: {$0 < $1} )
                .first
            
    //        print("section: \(leftSection))")
            if leftSection != leftVisibleSection {
                leftVisibleSection = leftSection
                scrollPublishSubject.onNext(leftSection)
            }
        }
        // Scrolling by the code
        else {
        }
    }
}
         
extension MyExpandableCollectionView {
    
    internal func handleCategoryCellExpandCollapse(packIndex: Int, scrollTo: Bool = true) {
        
        guard let dataSource = self.dataSource else { return }
        
        var deleteItemSection = -1
        var addItemSection = -1
        
        // Collapse prev.
        if let focusedHeaderViewIndex = self.focusedHeaderViewIndex {
            deleteItemSection = focusedHeaderViewIndex
        }
         
        // Collapse
        if packIndex == self.focusedHeaderViewIndex {
            self.focusedHeaderViewIndex = nil
        }
        // Expand
        else {
            self.focusedHeaderViewIndex = packIndex
            addItemSection = packIndex
        }
        
        // Header/Footer reload
        self.collectionView.collectionViewLayout.invalidateLayout()
        
        // Animation
        self.collectionView.performBatchUpdates {
            
            if deleteItemSection != -1 {
                let items = dataSource.numberOfItemsInSection(section: deleteItemSection)
                for i in 0..<items {
                    self.collectionView.deleteItems(at: [IndexPath(row: i, section: deleteItemSection)])
                }
            }
            if addItemSection != -1 {
                let items = dataSource.numberOfItemsInSection(section: addItemSection)
                for i in 0..<items {
                    self.collectionView.insertItems(at: [IndexPath(row: i, section: addItemSection)])
                }
            }
            
        } completion: { (done) in
            
            if scrollTo {
                // Make the section visable and align to left (with header)
                if let focusedHeaderViewIndex = self.focusedHeaderViewIndex {
                    self.scrollToSection(index: focusedHeaderViewIndex)
                }
            }
        }
    }
    
    internal func handleItemCellSelect(didSelectItemAt indexPath: IndexPath, scrollTo: Bool = true) {
        
        let prevFoucsItemIndexPath = self.focusedItemIndexPath
        self.focusedItemIndexPath = indexPath
        
        if let prevFoucsItemIndexPath = prevFoucsItemIndexPath {
            collectionView.reloadItems(at: [prevFoucsItemIndexPath])
        }
        collectionView.reloadItems(at: [indexPath])
        
        // ScrollTo
        if scrollTo {
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
}

// MARK: - Footer view
class MyExpandableCollectionFooterView: UICollectionReusableView {

    var separatorView = UILabel()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
         
        self.separatorView.text = "F"
        self.separatorView.textColor = .white
        self.separatorView.frame = self.bounds
        self.addSubview(separatorView)

        self.backgroundColor = .blue
    }

}
