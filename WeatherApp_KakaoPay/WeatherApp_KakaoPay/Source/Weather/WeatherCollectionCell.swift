//
//  WeatherCollectionCell.swift
//  WeatherApp_KakaoPay
//
//  Created by Sicc on 01/08/2019.
//  Copyright © 2019 chang sic jung. All rights reserved.
//
import UIKit

class WeatherCollectionCell: UICollectionViewCell {
  
  
  // MARK: - Properties
  private lazy var locationWeatherCollectionView: LocationWeatherCollectionView = {
    // layout
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    layout.headerReferenceSize = CGSize(width: ScreenBounds.width,
                                        height: ScreenBounds.height * 0.55)
    // init
    let cv = LocationWeatherCollectionView(frame: .zero, collectionViewLayout: layout)
    
    addSubview(cv)
    return cv
  }()
  

  // MARK: - Initializers
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  // MARK: - Layout Methods
  override func layoutSubviews() {
    super.layoutSubviews()
    makeConstraints()
  }
  
  private func makeConstraints() {
    locationWeatherCollectionView.layout.top().leading().trailing().bottom()
  }
}
