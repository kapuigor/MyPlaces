//
//  NewPlaceTableViewController.swift
//  MyPlaces
//
//  Created by Игорь Капустин on 07.08.2021.
//

import UIKit

class NewPlaceViewController: UITableViewController {
    
    var currentPlace: Place! // Свойство, в которое передается объект типа Place (!, так как редактируем существующий объект)
    var imageIsChanged = false
    
    @IBOutlet var saveButton: UIBarButtonItem!
    
    @IBOutlet var placeImage: UIImageView!
    @IBOutlet var placeName: UITextField!
    @IBOutlet var placeLocation: UITextField!
    @IBOutlet var placeType: UITextField!
    @IBOutlet var ratingControl: RatingControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        tableView.tableFooterView = UIView(frame: CGRect(x: 0,
                                                         y: 0,
                                                         width: tableView.frame.size.width,
                                                         height: 1)) // Белый фон вместо разлиновки
        saveButton.isEnabled = false
        placeName.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged) // Вызываем метод textFieldChanged, следящий, заполнено ли текстовое поле или нет. Если поле заполнено, то кнопка "save" будет доступна.
        setupEditScreen() // данный метод вызываем после строки "saveButton.isEnabled = false", иначе кнопка saveButton останется выключенной
        
    }
    
    // MARK: Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Если ячейка имеет индекс "0".
        if indexPath.row == 0 {
            
            let cameraIcon = #imageLiteral(resourceName: "camera")
            let photoIcon = #imageLiteral(resourceName: "photo")
            
            let actionSheet = UIAlertController(title: nil,
                                                message: nil,
                                                preferredStyle: .actionSheet)
            
            let camera = UIAlertAction(title: "Camera", style: .default) { _ in
                self.chooseImagePicker(source: .camera)
            }
            
            camera.setValue(cameraIcon, forKey: "image") // Присваиваем изображение камеры.
            camera.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment") // Сдвигаем тескт левее, к иконке.
            
            let photo = UIAlertAction(title: "Photo", style: .default) { _ in
                self.chooseImagePicker(source: .photoLibrary)
            }
            
            photo.setValue(photoIcon, forKey: "image") // Присваиваем изображение фотобиблиотеки.
            photo.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment") // Сдвигаем тескт левее, к иконке.
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            
            
            actionSheet.addAction(camera)
            actionSheet.addAction(photo)
            actionSheet.addAction(cancel)
            
            present(actionSheet, animated: true)
            
        } else {
            view.endEditing(true) // Конец редактирования.
        }
    }

    
    // Передаем данные заполненных полей в соответствующие свойства нашей модели.
    func savePlace() {
        
        var image: UIImage?
        
        if imageIsChanged {
            image = placeImage.image // Либо выбранное изображение.
        } else {
            image = #imageLiteral(resourceName: "imagePlaceholder") // Либо изображение по умолчанию.
        }
        
        let imageData = image?.pngData()
        
        // ОБъявляем экземпляр модели и инициализируем его свойства.
        let newPlace = Place(name: placeName.text!,
                             location: placeLocation.text,
                             type: placeType.text,
                             imageData: imageData,
                             rating: Double(ratingControl.rating))
        
        if currentPlace != nil { // Меняем текущее значение currentPlace на новое
            try! realm.write {
                currentPlace?.name = newPlace.name
                currentPlace?.location = newPlace.location
                currentPlace?.type = newPlace.type
                currentPlace?.imageData = newPlace.imageData
                currentPlace?.rating = newPlace.rating
            }
        } else {
            // Сохраняем новый объект в базу данных.
            StorageManager.saveObject(newPlace)
        }
        
        
    }
    
    // В этом методе работаем над экраном редактирования записи
    private func setupEditScreen() {
        if currentPlace != nil {
            
            setupNavigationBar()
            imageIsChanged = true // Изображение не меняется на фоновое, если мы редактируем запись
            
            guard let data = currentPlace?.imageData, let image = UIImage(data: data) else { return } //
            
            placeImage.image = image
            placeImage.contentMode = .scaleAspectFill // Позволяет масштабировать изображение по размеру imageView
            placeName.text = currentPlace?.name
            placeLocation.text = currentPlace?.location
            placeType.text = currentPlace?.type
            ratingControl.rating = Int(currentPlace.rating)
        }
        
    }
    
    private func setupNavigationBar() {
        // Если получается извлечь данный объект, то делаем кнопку возврата без заголовка, просто стрелка "<"
        if let topItem = navigationController?.navigationBar.topItem {
            topItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }
        // Все данные параметры должны быть доступны только при редактировании записи, а не при создании новой записи
        navigationItem.leftBarButtonItem = nil // Убираем Cancel
        title = currentPlace?.name // Передаем текущее название заведения
        saveButton.isEnabled = true // Кнопка Save всегда доступна
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        
        dismiss(animated: true)
    }
    
}

// MARK: Text field delegate

extension NewPlaceViewController: UITextFieldDelegate {
    
    // Скрываем клавиатуру при нажатии на Done.
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    // Метод textFieldChanged, следящий, заполнено ли текстовое поле или нет. Если поле заполнено, то кнопка "save" будет доступна.
    @objc private func textFieldChanged() {
        
        if placeName.text?.isEmpty == false {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
}

// MARK: Work with image
extension NewPlaceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func chooseImagePicker(source: UIImagePickerController.SourceType) {
        
        if UIImagePickerController.isSourceTypeAvailable(source) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = source
            present(imagePicker, animated: true)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        placeImage.image = info[.editedImage] as? UIImage
        placeImage.contentMode = .scaleAspectFill
        placeImage.clipsToBounds = true
        
        imageIsChanged = true
        
        dismiss(animated: true)
    }
}
