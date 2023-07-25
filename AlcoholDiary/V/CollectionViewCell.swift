//
//  CollectionViewCell.swift
//  Alcohol Diary
//
//  Created by 양홍찬 on 2023/07/12.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cellimage: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
  
    
    var alData: AlcoholData? {
        didSet {
            configureUIwithData()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellimage.contentMode = .scaleAspectFill // 이미지 뷰에 꽉 채우도록 설정
        cellimage.clipsToBounds = true // 이미지 뷰의 경계를 넘어가는 이미지는 잘라냄
        //configureUIwithData()
        
        dateLabel.backgroundColor = UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 0.3)
        nameLabel.backgroundColor = UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 0.3)
        
        // 텍스트 뷰의 레이어 속성 설정
        cellimage.layer.borderWidth = 1.0 // 윤곽선 두께 설정
        cellimage.layer.borderColor = UIColor.gray.cgColor // 윤곽선 색상 설정
       
    }
   
    
    func configureUIwithData() {
        if let imageData = alData?.image, let image = UIImage(data: imageData) {
            // 이미지를 리사이즈하여 낮은 화질로 표시
            let resizedImage = image.resize(to: CGSize(width: 180, height: 220))
            cellimage.image = resizedImage
        } else {
            cellimage.image = UIImage(named: "placeholder") // placeholder 이미지 설정
        }
        
        nameLabel.text = alData?.name ?? ""
        dateLabel.text = alData?.dateString
        // 나머지 레이블들 설정...
    }
}

extension UIImage {
    func resize(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        self.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
