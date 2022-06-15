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

let itemsInSection = [1, 3, 5, 7, 9, 2, 4, 6, 8, 10]
 
class MyExpandableCollectionView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    internal let layout = UICollectionViewFlowLayout()
    internal var collectionView: UICollectionView!
    
    internal var focusedPackIndex = -1
    internal let packTapPublishSub = PublishSubject<Int>()
    internal let disposeBag = DisposeBag()
     
    internal var focusedItemIndexPath: IndexPath = IndexPath.initAsInvalid()
    internal var appliedItemIndexPath: IndexPath = IndexPath.initAsInvalid()
 
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func layoutSubviews() {
        self.layoutMe()
    }
        
    convenience init() {
        self.init(frame: .zero)
          
        self.initUI()
        self.initRx()
    }
    
    func initUI() {
         
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4);
        layout.minimumLineSpacing = 4
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        collectionView.register(MyExpandableCollectionViewCell.self, forCellWithReuseIdentifier: "CellItem")
        collectionView.register(MyExpandableCollectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
          withReuseIdentifier: "Header")
        collectionView.register(MyExpandableCollectionFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
          withReuseIdentifier: "Footer")
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .black
        self.addSubview(collectionView)
    }
    
    func layoutMe() {
                 
        self.collectionView.snp.removeConstraints()
        self.collectionView.snp.makeConstraints{ (make) -> () in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(80)
        }
        
        self.collectionView.layoutIfNeeded()
        layout.itemSize = CGSize(width: 65, height: 80)
        layout.headerReferenceSize = CGSize(width: 65, height: 80)
        layout.footerReferenceSize = CGSize(
            width: layout.itemSize.width * 0.3, height: 80)
    }
    
    func initRx() {
        
        packTapPublishSub.subscribe { val in
            print(val)
            self.handleCategoryCellExpandCollapse(packIndex: val)
        } onError: { err in
            
        } onCompleted: {
            
        } onDisposed: {
            
        }
        .disposed(by: disposeBag)
    }
}

extension MyExpandableCollectionView {
     
    internal func numberOfSections(in collectionView: UICollectionView) -> Int {
        return itemsInSection.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                        
        if section == self.focusedPackIndex {
            return itemsInSection[section]
        }
        return 0
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: "CellItem", for: indexPath) as! MyExpandableCollectionViewCell
        return cell
    }
}
    
extension MyExpandableCollectionView {
    
    internal func handleCategoryCellExpandCollapse(packIndex: Int, reloadData: Bool = true) {
        
        self.collectionView.performBatchUpdates {
            
            var deleteItemSection = -1
            var addItemSection = -1
            
            // Collapse prev.
            if self.focusedPackIndex != -1 {
                deleteItemSection = self.focusedPackIndex
            }
             
            // Collapse
            if packIndex == self.focusedPackIndex {
                self.focusedPackIndex = -1
            }
            // Expand
            else {

                self.focusedPackIndex = packIndex
                addItemSection = packIndex
            }
            
            if deleteItemSection != -1 {
                let items = itemsInSection[deleteItemSection]
                for i in 0..<items {
                    self.collectionView.deleteItems(at: [IndexPath(row: i, section: deleteItemSection)])
                }
            }
            if addItemSection != -1 {
                let items = itemsInSection[addItemSection]
                for i in 0..<items {
                    self.collectionView.insertItems(at: [IndexPath(row: i, section: addItemSection)])
                }
            }
            
        } completion: { (done) in
            
            // Make the section visable and align to left (with header)
            if self.focusedPackIndex != -1 {
                
                let scrollToIndexPath = IndexPath(row: 0, section: self.focusedPackIndex)
                let headerAttributes: UICollectionViewLayoutAttributes = self.collectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: scrollToIndexPath)!;
 
                self.collectionView.setContentOffset(CGPoint(x: headerAttributes.frame.origin.x, y: 0), animated: true);
//                self.collectionView.scrollToItem(at: scrollToIndexPath, at: .left, animated: true)
            }
        }
    }
}

extension MyExpandableCollectionView {
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        return CGSize(width: 65, height: self.bounds.height)
    }
    
    internal func collectionView(_ collectionView: UICollectionView,
                          layout collectionViewLayout: UICollectionViewLayout,
                          referenceSizeForFooterInSection section: Int) -> CGSize {
        
        return CGSize(width: 15, height: self.bounds.height)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
                
        
        if kind == UICollectionView.elementKindSectionHeader {
            
            let headerView =
                collectionView.dequeueReusableSupplementaryView(
                    ofKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: "Header",
                    for: indexPath) as! MyExpandableCollectionHeaderView
            
            headerView.btn.setTitle("H\(indexPath.section)", for: .normal)
            headerView.btn.rx.tap
                .subscribe(onNext: { [weak self] in
                    print("tapped")
                    self?.packTapPublishSub.onNext(indexPath.section)
                })
                .disposed(by: headerView.disposeBag)
            
            return headerView
        }
        else if kind == UICollectionView.elementKindSectionFooter {
            
            var reusableView = UICollectionReusableView()
            reusableView =
                collectionView.dequeueReusableSupplementaryView(
                    ofKind: UICollectionView.elementKindSectionFooter,
                    withReuseIdentifier: "Footer",
                    for: indexPath)
            
            return reusableView
        }
        
        return UICollectionReusableView()
    }
    
    private func isPackExpandable(sectionIndex: Int) -> Bool {
        
        return (self.collectionView(self.collectionView, numberOfItemsInSection: sectionIndex) > 1)
    }
    
}

     
    
    
    
     
// #MARK: -
class MyExpandableCollectionViewCell: UICollectionViewCell {
        
    let label = UILabel()
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.backgroundColor = .orange
           
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.text = "Cell"
        self.contentView.addSubview(label)
        
        self.contentView.layer.masksToBounds = true
        self.contentView.layer.cornerRadius = 4.0
    }
        
    override func layoutSubviews() {

        super.layoutSubviews()
        
        self.label.frame = self.contentView.bounds
        
    }
}


// MARK: - Header view
class MyExpandableCollectionHeaderView: UICollectionReusableView {
     
    let btn = UIButton()
    var disposeBag = DisposeBag()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        btn.frame = self.bounds
        
        self.addSubview(btn)
        self.backgroundColor = .red
    }
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }
}

// MARK: - Footer view
class MyExpandableCollectionFooterView: UICollectionReusableView {
        
    var separatorView: UILabel?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
         
        self.separatorView = UILabel()
        self.separatorView?.text = "F"
        self.separatorView?.textColor = .white
        if let separatorView = self.separatorView {
            separatorView.frame = self.bounds
            self.addSubview(separatorView)
        }
        
        self.backgroundColor = .blue
    }
}


private extension IndexPath {
    
    static func initAsInvalid() -> IndexPath {
        return IndexPath.init(row: -1, section: -1)
    }
    
    var isValid: Bool {
        get {
            return self.section != -1 && self.row != -1
        }
    }
}
