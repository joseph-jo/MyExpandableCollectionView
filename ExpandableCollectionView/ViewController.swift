//
//  ViewController.swift
//  ExpandableCollectionView
//
//  Created by Joseph Chen on 2022/6/15.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let view = MyExpandableCollectionView()
        self.view.addSubview(view)
        
        view.snp.makeConstraints {
            $0.height.equalTo(80)
            $0.leading.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
    }


}

