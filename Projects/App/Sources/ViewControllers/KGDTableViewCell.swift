//
//  KGDTableViewCell.swift
//  wherewego
//
//  Created by 영준 이 on 2017. 3. 29..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit

class KGDTableViewCell: UITableViewCell {

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var darkCoverView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        LSThemeManager.shared.apply(imageView: self.backgroundImageView);
        //LSThemeManager.shared.apply(imageView: self.titleLabel);
        self.backgroundImageView.layer.backgroundColor = UIColor.black.cgColor;
        self.backgroundImageView.layer.opacity = 0.7;
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        self.backgroundImageView.layer.opacity = selected ? 1.0 : 0.7;
    }
}
