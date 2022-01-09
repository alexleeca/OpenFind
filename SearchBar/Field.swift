//
//  Field.swift
//  SearchBar
//
//  Created by Zheng on 10/14/21.
//

import UIKit

struct Field: Identifiable {
    
    let id = UUID()
    
    /// delete button deletes the entire field
    /// clear button is normal, shown when is editing no matter what
    var showingDeleteButton = false
    
    /// width of text label + side views, nothing more
    var fieldHuggingWidth = CGFloat(200)
    
    var configuration: SearchConfiguration
    
    var value: FieldValue {
        didSet {
            fieldHuggingWidth = getFieldHuggingWidth()
        }
    }
    
    var overrides: Overrides
    
    init(configuration: SearchConfiguration, value: FieldValue, overrides: Overrides = Overrides()) {
        self.configuration = configuration
        self.value = value
        self.overrides = overrides
        fieldHuggingWidth = getFieldHuggingWidth()
    }
    
    /// same as `Value`, but with an extra case: `addNew`
    enum FieldValue {
        case word(Word)
        case list(List)
        case addNew(Word) /// `String` for input text during add new -> full cell animation
        
        func getText() -> String {
            switch self {
            case .word(let word):
                return word.string
            case .list(let list):
                return list.name
            case .addNew(let word):
                return word.string
            }
        }
        
        func getColor() -> UInt {
            switch self {
            case .word(let word):
                return word.color
            case .list(let list):
                return list.color
            case .addNew(let word):
                return word.color
            }
        }
    }
    
    struct Overrides {
        var selectedColor: UIColor?
        var alpha: CGFloat = 1
    }
    
    private func getFieldHuggingWidth() -> CGFloat {
        if case .addNew(let word) = value, word.string.isEmpty {
            return configuration.addWordFieldHuggingWidth
        } else {
            let fieldText = value.getText()
            let finalText = fieldText.isEmpty ? configuration.addTextPlaceholder : fieldText
            let textWidth = finalText.width(withConstrainedHeight: 10, font: configuration.fieldFont)
            let leftPaddingWidth = configuration.fieldBaseViewLeftPadding
            let rightPaddingWidth = configuration.fieldBaseViewRightPadding
            let textPadding = 2 * configuration.addWordFieldSidePadding
            return textWidth + leftPaddingWidth + rightPaddingWidth + textPadding
        }
    }
}

struct FieldOffset {
    var fullWidth = CGFloat(0)
    var percentage = CGFloat(0)
    var shift = CGFloat(0) /// already multiplied by percentage
    var alpha = CGFloat(1) /// percent visible of add new
}

open class FieldLayoutAttributes: UICollectionViewLayoutAttributes {
    var fullOrigin = CGFloat(0) /// origin when expanded
    var fullWidth = CGFloat(0) /// width when expanded
    var percentage = CGFloat(0) /// percentage shrunk
    var beingDeleted = false
    
    override open func copy(with zone: NSZone?) -> Any {
        let copy = super.copy(with: zone) as! FieldLayoutAttributes
        copy.fullOrigin = fullOrigin
        copy.fullWidth = fullWidth
        copy.percentage = percentage
        copy.beingDeleted = beingDeleted
        
        return copy
    }
    
    override open func isEqual(_ object: Any?) -> Bool {
        guard let attributes = object as? FieldLayoutAttributes else { return false }
        guard
            attributes.fullOrigin == fullOrigin,
            attributes.fullWidth == fullWidth,
            attributes.percentage == percentage,
            attributes.beingDeleted == beingDeleted
        else { return false }
    
        return super.isEqual(object)
    }
}
