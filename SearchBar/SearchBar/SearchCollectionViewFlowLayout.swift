//
//  SearchCollectionViewFlowLayout.swift
//  SearchBar
//
//  Created by Zheng on 10/14/21.
//

import UIKit

//struct FieldCellLayout {
//    var origin = CGFloat(0)
//    var width = CGFloat(0)
//    var fullOrigin = CGFloat(0) /// origin when expanded
//    var fullWidth = CGFloat(0) /// width when expanded
//    var percentageShrunk = CGFloat(0) /// how much percent shrunk
//}
struct FieldOffset {
    var fullWidth = CGFloat(0)
    var shift = CGFloat(0) /// already multiplied by percentage
    var percentage = CGFloat(0)
}

class SearchCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override init() {
        super.init()
    }
    
    var getFields: (() -> [Field])?
    var getFullCellWidth: ((Int) -> CGFloat)?
    
    /// store the frame of each item
    /// plus other properties
    var layoutAttributes = [FieldLayoutAttributes]()
    
    var contentSize = CGSize.zero /// the scrollable content size of the collection view
    override var collectionViewContentSize: CGSize { return contentSize } /// pass scrollable content size back to the collection view
    
    /// pass attributes to the collection view flow layout
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributes[indexPath.item]
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        /// edge cells don't shrink, but the animation is perfect
        return layoutAttributes.filter { rect.intersects($0.frame) } /// try deleting this line
        
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        return getTargetOffset(for: proposedContentOffset)
    }
    
    
    /// make the layout (strip vs list) here
    override func prepare() { /// configure the cells' frames
        super.prepare()
        
        guard let collectionView = collectionView else { return }
        
        layoutAttributes = []
        
        var contentSize = CGSize.zero
        
        
        guard let fields = getFields?() else { return }

        let widths = fields.map { $0.valueFrameWidth }
        
        let contentOffset = collectionView.contentOffset.x
//        + Constants.sidePadding
        
        // MARK: Calculate shifting for each cell
        var cellOrigin = Constants.sidePadding /// origin for each cell
        var fieldOffsets = [FieldOffset]() /// array of each cell's shifting offset + percentage complete
        for index in widths.indices {
            let fullCellWidth = getFullCellWidth?(index) ?? 0
            
            
//            let sidePadding = Constants.sidePeekPadding - (Constants.sidePadding + Constants.cellSpacing)
//            let sideOffset = Constants.sidePeekPadding - Constants.sidePadding
//            if index == 2 {
//                print("Content Offset: \(contentOffset), cell's origin: \(cellOrigin), sideOffset: \(sideOffset)")
//            }
            
//            let adjustedDifference =  Constants.sidePeekPadding - Constants.sidePadding
            
//            let sidePadding: CGFloat
            let cellOriginWithoutSidePadding: CGFloat
            if index == 0 {
//                sidePadding =  -Constants.sidePadding
                cellOriginWithoutSidePadding = cellOrigin - Constants.sidePadding
            } else {
//                sidePadding =  -(Constants.sidePadding + Constants.cellSpacing)
                cellOriginWithoutSidePadding = cellOrigin - Constants.sidePeekPadding + Constants.cellSpacing
            }
            sidePadding = Constants.sidePeekPadding - Constants.cellSpacing
            
            if cellOriginWithoutSidePadding > contentOffset { /// cell is not yet approached
                fieldOffsets.append(FieldOffset(fullWidth: fullCellWidth, shift: 0, percentage: 0))
                
//
            } else {
//                fieldOffsets.append(FieldOffset(fullWidth: fullCellWidth, shift: 0, percentage: 0))
                
                /// when the fields stop, the content offset **falls short** of the end of the field.
                /// so, must account for that my subtracting some padding
                let shortenedFullWidth = fullCellWidth
//                - sidePadding

                /// progress of content offset (positive) through the field, until it hits the field's width (`adjustedFullWidth`)
                let differenceBetweenContentOffsetAndCell = min(shortenedFullWidth, contentOffset - cellOriginWithoutSidePadding)
                let percentage = differenceBetweenContentOffsetAndCell / shortenedFullWidth /// fraction

                if index == 2 {
                    print("ContentOffset: \(contentOffset), cell cellOriginWithoutSidePadding: \(cellOriginWithoutSidePadding)")
//                    print("< diff: \(differenceBetweenContentOffsetAndCell), adjusted: \(adjustedFullWidth), original: \(fullCellWidth), percentage: \(percentage)")
                }

                /// how much difference between the full width and the normal width, won't change.
                let differenceBetweenWidthAndFullWidth = max(0, fullCellWidth - widths[index])

                let fieldOffset = FieldOffset(fullWidth: fullCellWidth, shift: percentage * differenceBetweenWidthAndFullWidth, percentage: percentage)
                fieldOffsets.append(fieldOffset)
            }
            
            var additionalOffset = fullCellWidth
            if index != widths.indices.last { additionalOffset += Constants.cellSpacing }
            cellOrigin += additionalOffset
        }
        
        
        // MARK: Apply ALL shifting to the start of the collection view
        var fullOrigin = Constants.sidePadding /// origin for each cell, in expanded mode
        var layoutAttributes = [FieldLayoutAttributes]() /// each cell's positioning attributes + additional custom properties
        for index in fieldOffsets.indices {
            
            let totalShiftingOffset = fieldOffsets.dropFirst(index).reduce(0, { $0 + $1.shift })
            let fieldOffset = fieldOffsets[index]
            
            let origin = fullOrigin + totalShiftingOffset
            let width = fieldOffset.fullWidth - fieldOffset.shift
            
            let indexPath = IndexPath(item: index, section: 0)
            let attributes = FieldLayoutAttributes(forCellWith: indexPath)
            attributes.frame = CGRect(x: origin, y: 0, width: width, height: Constants.cellHeight)
            attributes.fullOrigin = fullOrigin
            attributes.fullWidth = fieldOffset.fullWidth
            attributes.percentage = fieldOffset.percentage
            layoutAttributes.append(attributes)
            
            var additionalOffset = fieldOffset.fullWidth
            if index != widths.indices.last { additionalOffset += Constants.cellSpacing }
            fullOrigin += additionalOffset
        }
        
        contentSize.width = fullOrigin + Constants.sidePadding
        contentSize.height = Constants.cellHeight
        
        self.contentSize = contentSize
        self.layoutAttributes = layoutAttributes
    }
    
    /// boilerplate code
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { return true }
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }
    
    /// get nearest field, then scroll to it (with padding)
    func getTargetOffset(for point: CGPoint) -> CGPoint {
        let centeredProposedContentOffset = point.x + ((collectionView?.bounds.width ?? 0) / 2) /// center to the screen
        
        /// find closest origin (by comparing middle of screen)
        /// use `full` since it was calculated already - it's the ideal origin and width
        let closestOrigin = layoutAttributes.enumerated().min(by: {
            let firstCenter = $0.element.fullOrigin + ($0.element.fullWidth / 2)
            let secondCenter = $1.element.fullOrigin + ($1.element.fullWidth / 2)
            return abs(firstCenter - centeredProposedContentOffset) < abs(secondCenter - centeredProposedContentOffset)
        })!
        
        var targetContentOffset = closestOrigin.element.fullOrigin
        
        if closestOrigin.offset == 0 {
            targetContentOffset -= Constants.sidePadding /// if left edge, account for side padding
        } else {
            targetContentOffset -= Constants.sidePeekPadding /// if inner cell, ignore side padding, instead account for peek padding
        }
        
//        print("---Going to \(targetContentOffset)")
        return CGPoint(x: targetContentOffset, y: 0)
//        return .zero
    }
    
}

open class FieldLayoutAttributes: UICollectionViewLayoutAttributes {
    
    var fullOrigin = CGFloat(0) /// origin when expanded
    var fullWidth = CGFloat(0) /// width when expanded
    var percentage = CGFloat(0) /// percentage shrunk
    
    override open func copy(with zone: NSZone?) -> Any {
        let copy = super.copy(with: zone) as! FieldLayoutAttributes
        copy.fullOrigin = fullOrigin
        copy.fullWidth = fullWidth
        copy.percentage = percentage
        
        return copy
    }
    
    override open func isEqual(_ object: Any?) -> Bool {
        guard let attributes = object as? FieldLayoutAttributes else { return false }
        guard
            attributes.fullOrigin == fullOrigin,
            attributes.fullWidth == fullWidth,
            attributes.percentage == percentage
        else { return false }
    
        return super.isEqual(object)
    }
    
}
