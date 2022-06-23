//
//  ViewController.swift
//  ExpandableCollectionView
//
//  Created by Joseph Chen on 2022/6/15.
//

import UIKit

let itemsInSection = [1, 3, 5, 7, 9, 2, 4, 6, 8, 10]

class ViewController: UIViewController, MyExpandableCollectionViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()
         
        let view = MyExpandableCollectionView.init(dataSource: self,
                                                    itemCellClass: MyExpandableCollectionViewCell.self,
                                                    headerClass: MyExpandableCollectionHeaderView.self)
        self.view.addSubview(view)
        
        view.snp.makeConstraints {
            $0.height.equalTo(80)
            $0.leading.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
    }
    
}

extension ViewController {
    
    func numberOfSections() -> Int {
        return itemsInSection.count
    }
    
    func numberOfItemsInSection(section: Int) -> Int {
        return itemsInSection[section]
    }
    
    func updateCell(indexPath: IndexPath, cell: MyExpandableCollectionViewCell) {
        cell.contentView.backgroundColor = .red
    }
    
    func updateHeader(indexPath: IndexPath, headerView: MyExpandableCollectionHeaderView) {
        headerView.backgroundColor = .orange
    }
    
}

