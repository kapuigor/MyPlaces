//
//  PlaceModel.swift
//  MyPlaces
//
//  Created by Игорь Капустин on 04.08.2021.
//

import RealmSwift

//  Меняем структуру на класс и наследуем модель от класса Object.
class Place: Object {
    
    @objc dynamic var name = ""
    @objc dynamic var location: String?
    @objc dynamic var type: String?
    @objc dynamic var imageData: Data?
    @objc dynamic var date = Date() // Свойство нужно для внутреннего использования, не доступное пользовател. Инициализируем текущей датой и используем для сортировки по дате добавления
    @objc dynamic var rating = 0.0
    
    
    // Создаем назначенный инициализатор, чтобы полностью инициализировать все данные, представленные классом.
    // Данный инициализатор не создает новый объект, а присваивает новые значения уже созданному объекту.
    convenience init(name: String, location: String?, type: String?, imageData: Data?, rating: Double) {
        self.init() // Инициализирует свойства класса значениями по умолчанию, а затем этим свойствам передаются значения из параметров.
        self.name = name
        self.location = location
        self.type = type
        self.imageData = imageData
        self.rating = rating
    }
}
