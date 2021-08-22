//
//  StorageManager.swift
//  MyPlaces
//
//  Created by Игорь Капустин on 12.08.2021.
//

// Сохранение нового объекта.
import RealmSwift

let realm = try! Realm() // Создаем объект Realm, предоставляющий доступ к базе данных. Объявлен как глобальная переменная.

// Класс с методом для сохранения объектов с типом Place.
class StorageManager {
    
    static func saveObject(_ place: Place) {
        
        // Сохранение в базу данных.
        try! realm.write {
            realm.add(place)
        }
    }
    
    
    // Принимает параметр с типом Place
    static func deleteObject(_ place: Place) {
        
        // Удаляем из базы данных
        try! realm.write {
            realm.delete(place)
        }
    }
}
