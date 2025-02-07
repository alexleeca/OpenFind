//
//  PhotosGeneralExtensions.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 4/5/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import Photos
import UIKit

/// `CGFloat` should be the minimum cell width
extension CGFloat {
    /// get the number of columns and each column's width from available bounds + insets
    func getColumns(availableWidth: CGFloat) -> (Int, CGFloat) {
        let minCellWidth = self
        guard minCellWidth.isNormal else { return (0, 0) }

        let numberOfColumns = Swift.max(1, Int(availableWidth / minCellWidth))

        /// space between columns
        let columnSpacing = CGFloat(numberOfColumns - 1) * PhotosConstants.cellSpacing
        let columnWidth = (availableWidth - columnSpacing) / CGFloat(numberOfColumns)

        return (numberOfColumns, columnWidth)
    }
}

extension Array where Element == FindPhoto {
    mutating func sortedNoteResultsFirst() {
        self = self.sorted { a, b in
            if let fastDescription = a.fastDescription, fastDescription.containsResultsInNote {
                return true
            }
            return false
        }
    }
}

extension PHAsset {
    /// get the image's size
    func getSize() -> CGSize {
        let size = CGSize(width: pixelWidth, height: pixelHeight)
        return size
    }
}
