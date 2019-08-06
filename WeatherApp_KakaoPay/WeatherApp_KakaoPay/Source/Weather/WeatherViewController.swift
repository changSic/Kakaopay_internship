//
//  ViewController.swift
//  WeatherApp_KakaoPay
//
//  Created by Sicc on 31/07/2019.
//  Copyright © 2019 chang sic jung. All rights reserved.
//

import UIKit
import CoreLocation

final class WeatherViewController: UIViewController {
  
  // MARK: - Observer
  //위치정보와 날씨정보 모두 받을 때 collectionView 를 한번만 reload 시켜줄 의도
  private var reloadObserver: [String : Bool] = ["weather" : false, "locationInfo" : false, "subInfoValues" : false] {
    didSet {
      if !self.reloadObserver.values.contains(false) {
        DispatchQueue.main.async {
          self.weatherCollectionView.reloadData()
        }
      }
    }
  }
  
  private var weather: [Weather]? {
    didSet {
      self.subInfoValues = DataManager.shared.getSubInfoValues()
      self.reloadObserver["weather"] = true
    }
  }
  
  private var locationInfo: String? {
    didSet {
      self.reloadObserver["locationInfo"] = true
    }
  }
  
  internal var subInfoTitles = ["일출", "비 올 확률", "바람", "강수량", "가시거리", "일몰", "습도", "체감", "기압", "자외선 지수"]
  internal var subInfoValues: [[String]] = [] {
    didSet {
      self.reloadObserver["subInfoValues"] = true
    }
  }
  
  // MARK: - Location Properties
  private let locationManager = CLLocationManager()
  
  // 지금으로 부터 10초 전
  private var lastRequestDate = Date(timeIntervalSinceNow: -10)
  
  // MARK: - Properties
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  private let backgroundImageView: UIImageView = {
    let screenBounds = UIScreen.main.bounds
    let iv = UIImageView(frame: screenBounds)
    iv.image = UIImage(named: "night")
    iv.contentMode = .scaleToFill
    return iv
  }()
  
  private lazy var weatherCollectionView: UICollectionView = {
    // init
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.scrollDirection = .horizontal
    let c = UICollectionView(frame: .zero, collectionViewLayout: layout)
    
    // collection 설정
    c.register(cell: WeatherCollectionCell.self)
    
    c.dataSource = self
    c.delegate = self
    
    // 레이아웃 설정
    c.isPagingEnabled = true
    c.backgroundColor = .clear
    
    view.addSubview(c)
    return c
  }()
  
  
  private lazy var weatherToolBar: WeatherToolBar = {
    let tb = WeatherToolBar(frame: .zero)
    view.addSubview(tb)
    return tb
  }()

  // MARK: - VC LifeCycle
  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(backgroundImageView)
    configureLocationManager()
    makeConstraints()
    weatherToolBarCallback()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // 사용자 위치정보 체크
    requestLocationAuthorization()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    // reloadObserver 초기화 시켜주기
    self.reloadObserver.keys.forEach {
      self.reloadObserver[$0] = false
    }
  }
  
  
  // MARK: - Callbacks : ToolBar Button Action
  private func weatherToolBarCallback() {
    weatherToolBar.locationListButtonDidTap = {
      self.present(MyWeatherListViewController(), animated: true, completion: nil)
    }
    weatherToolBar.detailWeatherButtonDidTap = {
      guard let url = URL(string: "https://weather.com/ko-KR/weather/today/l/Seodaemun+gu+Seoul?canonicalCityId=41c20b9e59a1464c5b8d316200c6deb511ff191cf1fadb295f52bf3b6b7b5642"),
        UIApplication.shared.canOpenURL(url) else {
          return logger("Can't open Safari App")
      }
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
  }
  
  // MARK: - Location
  private func configureLocationManager() {
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    locationManager.delegate = self
  }
  
  // 위치서비스 권한 받기
  private func requestLocationAuthorization() {
    guard CLLocationManager.locationServicesEnabled() else {
      return self.showAlert("앱을 사용하기 위해서는 위치 권한이 필요합니다.")
    }
    switch CLLocationManager.authorizationStatus() {
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    case .restricted, .denied:
      break
    case .authorizedAlways, .authorizedWhenInUse:
      break
    default:
      self.showAlert("앱을 사용하기 위해서는 위치 권한이 필요합니다.")
    }
  }
  
  // MARK: - Layout
  private func makeConstraints() {
    weatherCollectionView.layout.top().leading().trailing()
    weatherToolBar.layout.top(equalTo: weatherCollectionView.bottomAnchor).leading().trailing().bottom()
  }

}


// MARK: - Collection DataSource
extension WeatherViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return weather?.count ?? 0
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeue(WeatherCollectionCell.self, indexPath)
    if let weather = weather,
      let dailyFirst = weather[indexPath.row].daily.first{
      
      let currently = weather[indexPath.row].currently
      let hourly = weather[indexPath.row].hourly
      let daily = weather[indexPath.row].daily
      //let locationInfo = weather.locationInfo
      // Currently
      cell.currentLocationWeatherView.configureCurrentWeather(location: locationInfo ?? "",
                                                              summary: currently.summary,
                                                              temperature: currently.temperature,
                                                              day: currently.time,
                                                              maxTemperature: dailyFirst.temperatureMax,
                                                              minTemperature: daily.first!.temperatureMin
      )
      
      // Hourly CallBack
      cell.locationWeatherCollectionView.headerDidLoad = {
        header in
        header.hourlyCollectionView.hourlyCellDidLoad = {
          hourlycell, hourlyIndexPath in
          hourlycell.configureCell(hour: hourly[hourlyIndexPath.item].time,
                             icon: hourly[hourlyIndexPath.item].icon,
                             temperature: hourly[hourlyIndexPath.item].temperature)
        }
      }
      
      // Daily Callback
      cell.locationWeatherCollectionView.firstCollectionCellDidLoad = {
        firstCell in
        firstCell.dailyWeatherCollectionView.dailyWeatherCollectionCellDidLoad = {
          dailyCell, dailyIndexPath in
          dailyCell.configureCell(day: daily[dailyIndexPath.item].time,
                                  icon: daily[dailyIndexPath.item].icon,
                                  maxTemperature: daily[dailyIndexPath.item].temperatureMax,
                                  minTemperature: daily[dailyIndexPath.item].temperatureMin)
        }
      }
      
      // Summary Callback
      cell.locationWeatherCollectionView.secondCollectionCellDidLoad = {
        secondCell in
        secondCell.configureCell(summary: currently.summary,
                                 temperature: currently.temperature,
                                 maxTemperature: dailyFirst.temperatureMax)
      }
      
      // SubInfo Callback
      cell.locationWeatherCollectionView.thirdCollectionCellDidLoad = {
        thirdCell in
        thirdCell.subInfoCollectionView.subInfoCollectionCellDidLoad = {
          [weak self] infoCell, infoIndexPath in // 클로저 안에서 self 참조하면 Retain Cycle Issue 가능성
          guard let self = self else { return logger(ErrorLog.retainCycle) }
          infoCell.configureCell(topText: self.subInfoTitles[infoIndexPath.item],
                                 bottomText: self.subInfoValues[indexPath.item][infoIndexPath.item])
        }
      }
      cell.locationWeatherCollectionView.reloadData()
      
    }
    return cell
  }
  
  
}

// MARK: - Collection FlowLayout and Delegate
extension WeatherViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let size = (self.weatherCollectionView.bounds.width,
                self.weatherCollectionView.bounds.height)
    return CGSize(width: size.0, height: size.1)
  }
}

// MARK: - Location Delegate
extension WeatherViewController: CLLocationManagerDelegate {
  
  // location 받지 못했을 때
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    logger(error.localizedDescription)
  }
  
  // 위치 권한이 바뀌는 상황 대비
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
      manager.startUpdatingLocation()
    default:
      break
    }
  }
  
  // 위치 정보 받기
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // 정보 배열로(여러 개) 들어오니까 가장 최신인 마지막 것 쓰자
    guard let location = locations.last else { return logger(ErrorLog.unwrap) }
    
    guard abs(location.timestamp.timeIntervalSinceNow) < 5 else {
      return logger("5초가 지난 위치 정보는 버립니다.")
    }
    manager.stopUpdatingLocation()
    
    let currentDate = Date()
    
    // 최초 정보와 시간 차가 2초 이상 날 때만 데이터 업데이트 시킬 생각
    if abs(lastRequestDate.timeIntervalSince(currentDate)) > 2 {
      // 현재위치 지역이름 가져오기
      reverseGeocoding(location: location)
      
      // location 정보를 통해 네트워크로 날씨정보 가져오기
//      fetchWeather(from: location)
      DataManager.shared.fetchCurrentWeather(from: location) {
        self.weather = DataManager.shared.getWeather()
      }
      lastRequestDate = currentDate
    }
  }
  
  // 위치 정보 location 을 인자로 받는다.
  private func reverseGeocoding(location: CLLocation) {
    
    let geocoder = CLGeocoder()
    geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
      guard let `self` = self else { return }
      guard error == nil else { return logger(error!.localizedDescription) }
      guard let place = placemarks?.first else { return }
      
      let locality = place.locality ?? "" //  중구
      let subLocality = place.subLocality ?? "" // 신당동
      let thoroughfare = place.thoroughfare ?? "" // 남산대로 / subLocality 로 나타나지 않는 것들이 thoroughfare 속성으로 들어온다.
      let address = locality + " " + (!subLocality.isEmpty ? subLocality : thoroughfare)
      
      print("locality : \(locality)")
      print("sublocality : \(subLocality)")
      print("thoroughfare : \(thoroughfare)")
      print("address : \(address)")
      
      self.locationInfo = locality
    }
  }
  
  
}
