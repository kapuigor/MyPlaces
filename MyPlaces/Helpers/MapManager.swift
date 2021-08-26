//
//  MapManager.swift
//  MyPlaces
//
//  Created by Игорь Капустин on 26.08.2021.
//

import UIKit
import MapKit

class MapManager {
    
    let locationManager = CLLocationManager() // Настройка и управление службами геолокации
    
    private var placeCoordinate: CLLocationCoordinate2D? // Get place location
    private let regionInMeters = 1000.00
    private var directionsArray: [MKDirections] = []
    
    func setupPlacemark(place: Place, mapView: MKMapView) {
        
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
            annotaion.title = place.name // Заголовок аннотации
            annotaion.subtitle = place.type // Подзаголовок аннотации
            
            guard let placemarkLocation = placemark?.location else { return } // Присваиваем геопозицию маркера
            
            annotaion.coordinate = placemarkLocation.coordinate // Привязываем аннотацию к этой же точке на карте
            self.placeCoordinate = placemarkLocation.coordinate // Set plcaemarkLocation to placeCoordinate
            
            mapView.showAnnotations([annotaion], animated: true) // Указываем все аннотации, которые должны быть определены в зоне видимости карты
            mapView.selectAnnotation(annotaion, animated: true) // Выделяем созданную аннотацию
        }
    }
    
    // Проверяет активность служб геолокации
    func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: () -> ()) {
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest // Разрешение пользователя на отслеживание геолокации
            checkLocationAuthorization(mapView: mapView, segueIdentifier: segueIdentifier) // Если СГ нам доступны
            closure()
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
    
    // Проверка статуса на разрешение использования геолокации
    func checkLocationAuthorization(mapView: MKMapView, segueIdentifier: String) {
        // Возвращает различные состояния авторизации приложения для СГ
        switch locationManager.authorizationStatus { // Fixed "'authorizationStatus()' was deprecated in iOS 14.0"
        case .authorizedWhenInUse: // Статус определения геолокации в момент его использования
            mapView.showsUserLocation = true
            if segueIdentifier == "getAddress" { showUserLocation(mapView: mapView) }
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
    func showUserLocation(mapView: MKMapView) {
        
        // Если координаты пользователя пределяются
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func getDirections(for mapView: MKMapView, previousLocation: (CLLocation) -> ()) {
        // Get user location
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Error", message: "Current location is not found") // If cannot get user location
            return
        }
        
        locationManager.startUpdatingLocation() // Continuous tracking of the user's current location
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude)) // User's current location
        
        // Route request
        guard let request = createDirectionsRequest(from: location) else {
            showAlert(title: "Error", message: "Destination is not found")
            return
        }
        
        // Routing
        let directions = MKDirections(request: request)
        
        resetMapView(withNew: directions, mapView: mapView) // Remove current routes before ctreating new route
        
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
                mapView.addOverlay(route.polyline) // Route geometry
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true) // Entire route
                
                let distance = String(format: "%.1f", route.distance / 1000) // Route distance
                let timeInterval = route.expectedTravelTime // Route time
                
                print("Расстояние до места: \(distance) км.")
                print("Время в пути состваит: \(timeInterval) сек.")
            }
        }
    }
    
    // Setup up a route
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        
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
    
    func startTrackingUserLocation(for mapView: MKMapView, and location: CLLocation?, closure: (_ currentLocation: CLLocation) -> ()) {
        
        guard let location = location else { return }
        let center = getCenterLocation(for: mapView) // Current coordinates of center
        guard center.distance(from: location) > 50 else { return } // If distance > 50 metres
        
        closure(center)
    }
    
    func resetMapView(withNew directions: MKDirections, mapView: MKMapView) {
        
        mapView.removeOverlays(mapView.overlays) // Remove previous routes
        directionsArray.append(directions) // Add current routes
        let _ = directionsArray.map { $0.cancel() } // Undo the route for each element of the array
        directionsArray.removeAll() // Remove all elements from array
    }
    
    // Return map center coordinates
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // Create alert controller
    private func showAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okAction)
        
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1
        alertWindow.rootViewController?.present(alert, animated: true)
    }
}
