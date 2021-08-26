//
//  MainViewController.swift
//  MyPlaces
//
//  Created by Игорь Капустин on 23.07.2021.
//

import UIKit
import RealmSwift

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let searchController = UISearchController(searchResultsController: nil) // Передавая nil, сообщаем контроллеру поиска, что для отображения
                                                                            // результата поиска хотим использоавть вью с основным контентом
    private var places: Results<Place>! // Results - это автообновляемый тип контейнера, который возвращает запрашиваемые объекты.
                                // Текущее состояние хранилища в текущем потоке. Работа с данными в реальном времени.
    private var filteredPlaces: Results<Place>! // Массив с отфильтрованными записями
    private var ascendingSorting = true // Сортировка по возрастанию "true". Для осртировки по убыванию меняем на "false"
    // Переменная возвращает true, если строка поиска пустая
    private var searchBarIsEmpty : Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    
    // Когда строка поиска активирована и не является пустой, возвращает true
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }

    @IBOutlet var tableView: UITableView!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var reversedSortingButton: UIBarButtonItem!
    


    override func viewDidLoad() {
        super.viewDidLoad()

        places = realm.objects(Place.self) // Подставляем не объект, а тип данных Place.
        
        // Setup the search controller
        searchController.searchResultsUpdater = self // Получателем информации об изменении текста в поисковой строке должен быть наш класс
        searchController.obscuresBackgroundDuringPresentation = false // По умолочнию VC с результатами поиска не позволяет взаимодействовать
                                                                      // с отображаемым контентом. Если false, то позволяет.
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController // Строка поиска интегрирована в navigation bar
        definesPresentationContext = true // Позволяет опустить строку поиска при переходе на другой экран
    }

    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredPlaces.count // Кол-во элементов filteredPlaces
        }
        return places.count // Проверка количества элементов коллекции.
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomTableViewCell
     
        let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]

        // Обращаемся к конкретному объекту из массива places.
        cell.nameLabel.text = place.name
        cell.locationLabel.text = place.location
        cell.typeLabel.text = place.type
        cell.imageOfPlace.image = UIImage(data: place.imageData!) // Опционал, т.к. данное свойство никогда не будет nul.
        cell.ratingLabel.text = String(Int(place.rating)) + " ⭐️"
        cell.cosmosView.rating = place.rating

        return cell
    }

    // MARK: Table view delegate
    
    // Снимаем выделение с ячейки после выхода из экрана редактирования
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Сюда помещены все действия при свайпе по строке
    // Fixed "'UITableViewRowAction' was deprecated in iOS 13.0: Use UIContextualAction and related APIs instead."
    // Added trailingSwipeActionsConfigurationRowAt in UISwipeActionsConfiguration
    private func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let place = places[indexPath.row] // Удаляемый объект массива с индексом текущей строки
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (contextualAction, view, boolValue) in // Действие при свайпе. Меню удаления красное
            
            StorageManager.deleteObject(place) // Удаление объекта
            tableView.deleteRows(at: [indexPath], with: .automatic) // Удаляем саму строку
        }
        
        let swipeAction = UISwipeActionsConfiguration(actions: [deleteAction])
        
        return swipeAction // Возвращаем данное действие как элемент массива
    }


    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            // Определяет индекс выбранной ячейки
            guard let indexPath = tableView.indexPathForSelectedRow else { return } // Извлекаем опциональное значение
            let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
            let newPlaceVC = segue.destination as! NewPlaceViewController // Создаем экземпляр VC
            newPlaceVC.currentPlace = place // Передали объект с типом Place из выбранной ячейки на NewPlaceViewController
        }
    }
    
    
    @IBAction func unwindSegue(_ segue: UIStoryboardSegue) {
        
        // Возврат через source.
        guard let newPlaceVC = segue.source as? NewPlaceViewController else { return }
        
        newPlaceVC.savePlace()
        tableView.reloadData()
    }

    // Метод выбора сортировки
    @IBAction func sortSelection(_ sender: UISegmentedControl) {
        
        sorting()
    }
    
    //
    @IBAction func reversedSorting(_ sender: Any) {
        
        ascendingSorting.toggle() // Меняет значение на противоположное
        
        // Меняем изображение кнопки
        if ascendingSorting {
            reversedSortingButton.image = #imageLiteral(resourceName: "AZ")
        } else {
            reversedSortingButton.image = #imageLiteral(resourceName: "ZA")
        }
        
        sorting()
    }
    
    // Метод сортировки
    private func sorting() {
        
        // Если выбран нулевой сегмент, сортируем по дате
        if segmentedControl.selectedSegmentIndex == 0 {
            places = places.sorted(byKeyPath: "date", ascending: ascendingSorting) // По ключу "date" и значению ascendingSorting (true/false)
        } else { // Иначе сортируем по имени
            places = places.sorted(byKeyPath: "name", ascending: ascendingSorting) // По ключу "name" и значению ascendingSorting (true/false)
        }
        
        tableView.reloadData() // Обновление таблицы
    }
}

extension MainViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!) // Даже если строка поиска будет пустой, она не будет nil. UISC информирует MVC, вызывая метод updateSearchResults,
                                                                     // который будет вызывать filterContentForSearchText
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        
        filteredPlaces = places.filter("name CONTAINS[c] %@ OR location CONTAINS[c] %@", searchText, searchText) // [c] - не зависит от регистра символов. Выполняем поиск по полю name и                                                                                                             // location, фильтруем данные по параметру из значения searchText
        
        tableView.reloadData()
    }
}
