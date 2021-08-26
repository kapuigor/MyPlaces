//
//  MapViewController.swift
//  MyPlaces
//
//  Created by Игорь Капустин on 22.08.2021.
//

import UIKit
import MapKit
import CoreLocation

// Проктокол для передачи адреса из MVC в NPVC
protocol MapViewControllerDelegate {
    func getAddress(_ address: String?) // Объявляем как опциональный
}

class MapViewController: UIViewController {
    
    var mapViewControllerDelegate: MapViewControllerDelegate? // Опциональный делегат класса
    var place = Place()
    let annotationIdentifier = "annotationIdentifier" // annotation id
    let locationManager = CLLocationManager() // Настройка и управление службами геолокации
    let regionInMeters = 1000.00
    var incomeSegueIdentifier = "" // Входящий идентификатор при переходе на MVC
    var placeCoordinate: CLLocationCoordinate2D? // Get place location
    var directionsArray: [MKDirections] = []
    var previousLocation: CLLocation? {
        didSet {
            startTrackingUserLocation()
        }
    }

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var mapPinImage: UIImageView!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var goButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressLabel.text = "" // Если адрес не определен, то лейбл ничего не отображает
        mapView.delegate = self // Назначаем делегатом сам класс
        setupMapView()
        checkLocationAuthorization()

    }
    
    // Устанавливает центр карты на координаты пользователя
    @IBAction func centerViewInUserLocation() {
        
        showUserLocation()
    }
    
    @IBAction func doneButtonPressed() {
        mapViewControllerDelegate?.getAddress(addressLabel.text) // Передаем в параметр метода getAddress текущее значение адреса
        dismiss(animated: true) // Закрываем MVC
    }
    
    @IBAction func goButtonPressed() {
        getDirections()
    }
    
    @IBAction func closeVC() {
        dismiss(animated: true)
    }
    
    private func setupMapView() {
        
        goButton.isHidden = true // При переходе на MVC скрываем эту кнопку
        
        // Настройки карты при показе места (при переходе по через "showPlace")
        if incomeSegueIdentifier == "showPlace" {
            setupPlacemark()
            mapPinImage.isHidden = true
            addressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
        }
    }
    
    private func resetMapView(withNew directions: MKDirections) {
        
        mapView.removeOverlays(mapView.overlays) // Remove previous routes
        directionsArray.append(directions) // Add current routes
        let _ = directionsArray.map { $0.cancel() } // Undo the route for each element of the array
        directionsArray.removeAll() // Remove all elements from array
    }
    
    private func setupPlacemark() {
        
        guard let location = place.location else { return } // Извлекаем адрес
        
        let geocoder = CLGeocoder() // Данный класс позволяет преобразовать координаты в удобный для пользователя вид и наоборот
        
        // Позволяет определить местополжение на карте по адресу в виде строки, возвращает массив меток, соответствующих переданному адресу
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            
            // Проверяем error на наличие данных
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return } // Извлекаем опционал
            
            let placemark = placemarks.first // Первый индекс массива placemarks
            
            let annotaion = MKPointAnnotation() // Описывает точку на карте
            annotaion.title = self.place.name // Заголовок аннотации
            annotaion.subtitle = self.place.type // Подзаголовок аннотации
            
            guard let placemarkLocation = placemark?.location else { return } // Присваиваем геопозицию маркера
            
            annotaion.coordinate = placemarkLocation.coordinate // Привязываем аннотацию к этой же точке на карте
            self.placeCoordinate = placemarkLocation.coordinate // Set plcaemarkLocation to placeCoordinate
            
            self.mapView.showAnnotations([annotaion], animated: true) // Указываем все аннотации, которые должны быть определены в зоне видимости карты
            self.mapView.selectAnnotation(annotaion, animated: true) // Выделяем созданную аннотацию
        }
    }
    
    // Проверяет активность служб геолокации
    private func checkLocationServices() {
        
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager() // Разрешение пользователя на отслеживание геолокации
            checkLocationAuthorization() // Если СГ нам доступны
        } else {
            // Dalayed for 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(
                    title: "Location Services are Disabled",
                    message: "To enable it go: Setting -> Privacy -> location Services and turn it On"
                )
            }
        }
    }
    
    // Первоначальные установки locationManager
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // Тип данных для определения точности геолокации
    }
    
    // Проверка статуса на разрешение использования геолокации
    private func checkLocationAuthorization() {
        // Возвращает различные состояния авторизации приложения для СГ
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse: // Статус определения геолокации в момент его использования
            mapView.showsUserLocation = true
            if incomeSegueIdentifier == "getAddress" { showUserLocation() }
            break
        case .denied: // Статус отказа использования геолокации (или если они отключены в настройках)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Your location is not Available",
                               message: "To give permission Go to: Settings -> MyPlaces -> Location")
            }
            break
        case .notDetermined: // Статус не определен
            locationManager.requestWhenInUseAuthorization()
        case .restricted: // Возвращается, если приложение не авторизовано для использования СГ
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Your App is not authorize for using location",
                               message: "To give permission Go to: Settings -> MyPlaces -> Location")
            }
            break
        case .authorizedAlways: // Возвращается, когда приложению разрешено использовать СГ
            break
        @unknown default: // Срабатывает, когда появляется новый case
            print("New case is available")
        }
    }
    
    // Вызываем данный метод как при нажатии на кнопку для определения местоположения пользователя, так и при переходе getAddress
    private func showUserLocation() {
        
        // Если координаты пользователя пределяются
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func startTrackingUserLocation() {
        
        guard let previousLocation = previousLocation else { return }
        let center = getCenterLocation(for: mapView) // Current coordinates of center
        guard center.distance(from: previousLocation) > 50 else { return } // If distance > 50 metres
        self.previousLocation = center // User coordinates is now center coordinates
        
        
        // Delay for "showUserLocation" time
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showUserLocation()
        }
        
    }
    
    private func getDirections() {
        // Get user location
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Error", message: "Current location is not found") // If cannot get user location
            return
        }
        
        locationManager.startUpdatingLocation() // Continuous tracking of the user's current location
        previousLocation = CLLocation(latitude: location.latitude, longitude: location.longitude) // User's current location
        
        // Route request
        guard let request = createDirectionsRequest(from: location) else {
            showAlert(title: "Error", message: "Destination is not found")
            return
        }
        // Routing
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions) // Remove current routes before ctreating new route
        
        directions.calculate { (response, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let response = response else {
                self.showAlert(title: "Error", message: "Directions is not available")
                return
            }
            
            for route in response.routes {
                self.mapView.addOverlay(route.polyline) // Route geometry
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true) // Entire route
                
                let distance = String(format: "%.1f", route.distance / 1000) // Route distance
                let timeInterval = route.expectedTravelTime // Route time
                
                print("Расстояние до места: \(distance) км.")
                print("Время в пути состваит: \(timeInterval) сек.")
            }
        }
    }
    
    // Setup up a route
    private func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        
        guard let destinationCoordinate = placeCoordinate else { return nil }
        let startingLocation = MKPlacemark(coordinate: coordinate) // Set starting point
        let destination = MKPlacemark(coordinate: destinationCoordinate) // Set destination point
        
        let request = MKDirections.Request() // Set start, destination, and also transport type
        request.source = MKMapItem(placemark: startingLocation) // Start
        request.destination = MKMapItem(placemark: destination) // Destination
        request.transportType = .automobile // Transport type
        request.requestsAlternateRoutes = true // Available to alternative routes
        
        return request
    }
    
    // Return map center coordinates
    private func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // Create alert controller
    private func showAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else { return nil } // если annotation является объектом MKUserLocation, то не создаем аннотацию /
                                                                  // либо возвращаем nil и выходим
        
        // Вью с аннотацией на карте
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as?
            MKPinAnnotationView
        
        // Если на карте нет ни одного представления с аннотацией
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.canShowCallout = true
        }
        
        if let imageData = place.imageData {
            
            // Изображение баннера на карте
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            annotationView?.rightCalloutAccessoryView = imageView // Отображаем IV на баннере
        }

        
        return annotationView
    }
    // Call while changing the region on the map, show the address of center of the current region
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let center = getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        if incomeSegueIdentifier == "showPlace" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3){
                self.showUserLocation()
            }
        }
        
        geocoder.cancelGeocode()
        
        geocoder.reverseGeocodeLocation(center) { (placemarks, error) in // Возвращает массив меток переданных координат,
                                                                         // или ошибку с причиной по которой метки не были преобразованы
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first
            let streetName = placemark?.thoroughfare
            let buildNumber = placemark?.subThoroughfare
            
            // Асинхронное обновление потока данных
            DispatchQueue.main.async {
                
                if streetName != nil && buildNumber != nil {
                    self.addressLabel.text = "\(streetName!), \(buildNumber!)"
                } else if streetName != nil {
                    self.addressLabel.text = "\(streetName!)"
                } else {
                    self.addressLabel.text = ""
                }
            }
        }
    }
    // Made route visible on the map
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .green
        
        return renderer
    }
}

extension MapViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}
