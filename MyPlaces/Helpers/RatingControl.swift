//
//  RatingControl.swift
//  MyPlaces
//
//  Created by Игорь Капустин on 21.08.2021.
//

import UIKit

@IBDesignable class RatingControl: UIStackView {
    
    // MARK: Properties
    
    var rating = 0 {
        didSet {
            updateButtonSelectionState() // Проверка вызова данного метода
        }
    }
    
    private var ratingButtons = [UIButton]()
    
    @IBInspectable var starSize: CGSize = CGSize(width: 44.0, height: 44.0) {
        // starSize observer
        didSet {
            setupButtons()
        }
    }
    @IBInspectable var starCount: Int = 5 {
        // starCount observer
        didSet {
            setupButtons()
        }
    }

    // MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtons()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }
    
    // MARK: Button Action
    
    @objc func ratingButtonTapped(button: UIButton) {
        
        guard let index = ratingButtons.firstIndex(of: button) else { return } // Присваиваем первый индекс из button
        
        // Calculate the rating of the selected button
        let selectedRating = index + 1 // Порядковый номер выбранной звезды
        
        // Если выбираем уже отмеченную звезду, то обнуляем рейтинг
        if selectedRating == rating {
            rating = 0
        } else {
            rating = selectedRating // Иначе присваиваем номер выбранной звезды
        }
    }
    
    // MARK: Private Methods
    
    private func setupButtons() {
        // Перебираем и удалаяем элементы из StackView
        for button in ratingButtons {
            removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        // Очищаем массив кнопок
        ratingButtons.removeAll()
        
        // Load button image
        let bundle = Bundle(for: type(of: self)) // Определяет местоположение ресурсов, которые хранятся в assets
        
        let filledStar = UIImage(named: "filledStar",
                                 in: bundle,
                                 compatibleWith: self.traitCollection) // Проверяет правильность загруженного изображения
        let emptyStar = UIImage(named: "emptyStar",
                                in: bundle,
                                compatibleWith: self.traitCollection)
        let highlightedStar = UIImage(named: "highlightedStar",
                                      in: bundle,
                                      compatibleWith: self.traitCollection)
        
        
        
        for _ in 0..<starCount {
            // Create the button
            let button = UIButton()
            
            // Set button image
            button.setImage(emptyStar, for: .normal)
            button.setImage(filledStar, for: .selected) // Меняем изображение на filledStar при выборе звезды
            button.setImage(highlightedStar, for: .highlighted) // Подсвечиваем звезду синим цветом при прикосновении к ней
            button.setImage(highlightedStar, for: [.highlighted, .selected]) // Подсвечиваем звезду синим цветом при прикосновении к ней,
                                                                             // даже если она выделена
            
            // Add consrtaints
            button.translatesAutoresizingMaskIntoConstraints = false // Отключает автоматически сгенерированные констрэйнты для кнопки
            button.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true // Высота кнопки
            button.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true // Ширина кнопки
            
            // Setup the button action
            button.addTarget(self, action: #selector(ratingButtonTapped(button:)), for: .touchUpInside)
            
            // Add the button to the stack
            addArrangedSubview(button)
            
            // Add the new button on the ratimg button array
            ratingButtons.append(button)
        }
        
        updateButtonSelectionState()
        
    }
    
    // Выполняем итерацию по всем кнопкам и устанавливаем состояние каждой из них в соответствии с индексом и рейтингом
    private func updateButtonSelectionState() {
        for (index, button) in ratingButtons.enumerated() { // enumerated возвращает пару "объект" и его "индекс"
            button.isSelected = index < rating
        }
    }

}
