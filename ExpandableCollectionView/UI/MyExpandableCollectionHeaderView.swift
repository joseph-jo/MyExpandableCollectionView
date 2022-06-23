//
//  MyExpandableCollectionHeaderView.swift
//  PhotoDirector
//
//  Created by Joseph Chen on 2022/6/15.
//  Copyright © 2022 CyberLink. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit
import Kingfisher

// MARK: - Header view
class MyExpandableCollectionHeaderView: UICollectionReusableView {
        
    var guid: String = ""
    var thumbnailUrl: URL? = nil
    var text: String = ""
    
    let btn = UIButton()
    var disposeBag = DisposeBag()
    
    private let imageView = UIImageView()
    private let label = UILabel()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
                
        imageView.contentMode = .scaleAspectFit
        self.addSubview(imageView)
        
        label.textColor = .red
        label.textAlignment = .center
        self.addSubview(label)
        
        btn.frame = self.bounds
        self.addSubview(btn)
        
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 4.0
    }
    
    override func layoutSubviews() {
        
        self.imageView.snp.removeConstraints()
        self.imageView.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.width.equalToSuperview()
            $0.height.equalTo(imageView.snp.width)
        }
        
        self.label.snp.removeConstraints()
        self.label.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        
        self.btn.snp.removeConstraints()
        self.btn.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }
    
    func updateUI() {
        imageView.kf.setImage(with: thumbnailUrl)
        label.text = text
    }
}
