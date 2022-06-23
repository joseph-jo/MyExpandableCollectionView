//
//  MyExpandableCollectionViewCell.swift
//  PhotoDirector
//
//  Created by Joseph Chen on 2022/6/15.
//  Copyright © 2022 CyberLink. All rights reserved.
//

import UIKit

// #MARK: -
class MyExpandableCollectionViewCell: UICollectionViewCell {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
       
    override func layoutSubviews() {

        super.layoutSubviews()
        self.layoutMe()
    }
    
    func layoutMe() {
        
    }
    
    func updateUI() {
        
    }
}
