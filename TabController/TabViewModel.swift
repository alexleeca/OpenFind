//
//  TabViewModel.swift
//  TabBarController
//
//  Created by Zheng on 10/30/21.
//

import SwiftUI

class TabViewModel: ObservableObject {
    @Published var tabState: TabState = .camera {
        didSet {
            tabBarAttributes = tabState.tabBarAttributes()
            photosIconAttributes = tabState.photosIconAttributes()
            cameraIconAttributes = tabState.cameraIconAttributes()
            listsIconAttributes = tabState.listsIconAttributes()
            animatorProgress = tabState.getAnimatorProgress()
        }
    }

    @Published var tabBarAttributes = TabBarAttributes.darkBackground
    @Published var photosIconAttributes = PhotosIconAttributes.inactiveDarkBackground
    @Published var cameraIconAttributes = CameraIconAttributes.active
    @Published var listsIconAttributes = ListsIconAttributes.inactiveDarkBackground
    @Published var animatorProgress = CGFloat(0) /// for blur
   
    var updateTabBarHeight: ((TabState) -> Void)?
    
    var tabStateChanged: ((TabStateChangeAnimation) -> Void)?
    
    /// animated = clicked
    func changeTabState(newTab: TabState, animation: TabStateChangeAnimation = .fractionalProgress) {
        if animation == .clickedTabIcon || animation == .animate {
            withAnimation(.easeOut(duration: 0.3)) {
                tabState = newTab
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.updateTabBarHeight?(newTab)
            }
        } else {
            tabState = newTab
        }
        tabStateChanged?(animation)
    }
    
    enum TabStateChangeAnimation {
        /// used when swiping
        case fractionalProgress
        
        /// clicked an icon
        case clickedTabIcon
        
        /// special case, animate transition
        case animate
    }
}

/**
 attributes which can have an intermediate value
 */
protocol AnimatableAttributes {
    init(progress: CGFloat, from fromAttributes: Self, to toAttributes: Self)
}

enum AnimatableUtilities {
    static func mixedValue(from: CGFloat, to: CGFloat, progress: CGFloat) -> CGFloat {
        let value = from + (to - from) * progress
        return value
    }

    static func mixedValue(from: CGPoint, to: CGPoint, progress: CGFloat) -> CGPoint {
        let valueX = from.x + (to.x - from.x) * progress
        let valueY = from.y + (to.y - from.y) * progress
        return CGPoint(x: valueX, y: valueY)
    }
}

struct TabBarAttributes: AnimatableAttributes {
    /// color of the tab bar
    var backgroundColor: UIColor
    
    /// height of the visual background
    var backgroundHeight: CGFloat
    
    /// top padding of everything inside the tab bar
    var topPadding: CGFloat
    
    /// how much y offset for the camera toolbar
    var toolbarOffset: CGFloat
    
    /// **Note!** fade out quicker than swipe
    var toolbarAlpha: CGFloat
    
    /// alpha of the top divider line
    var topLineAlpha: CGFloat
    
    static let lightBackground: Self = .init(
        backgroundColor: Constants.tabBarLightBackgroundColor,
        backgroundHeight: ConstantVars.tabBarTotalHeight,
        topPadding: 0,
        toolbarOffset: -40,
        toolbarAlpha: 0,
        topLineAlpha: 1
    )
    
    /// when active tab is camera
    static let darkBackground: Self = .init(
        backgroundColor: Constants.tabBarDarkBackgroundColor,
        backgroundHeight: ConstantVars.tabBarTotalHeightExpanded,
        topPadding: 16,
        toolbarOffset: 0,
        toolbarAlpha: 1,
        topLineAlpha: 0
    )
}

/// keep normal initializer, so put in extension
extension TabBarAttributes {
    init(progress: CGFloat, from fromAttributes: TabBarAttributes, to toAttributes: TabBarAttributes) {
        let backgroundColor = fromAttributes.backgroundColor.toColor(toAttributes.backgroundColor, percentage: progress)
        let backgroundHeight = max(
            ConstantVars.tabBarTotalHeight,
            AnimatableUtilities.mixedValue(from: fromAttributes.backgroundHeight, to: toAttributes.backgroundHeight, progress: progress)
        )
        
        let topPadding = AnimatableUtilities.mixedValue(from: fromAttributes.topPadding, to: toAttributes.topPadding, progress: progress)
        
        let toolbarOffset = AnimatableUtilities.mixedValue(from: fromAttributes.toolbarOffset, to: toAttributes.toolbarOffset, progress: progress)
        
        /// move a bit faster for the toolbar
        let fasterProgress = min(1, progress * Constants.tabBarToolbarAlphaMultiplier)
        let toolbarAlpha = AnimatableUtilities.mixedValue(from: fromAttributes.toolbarAlpha, to: toAttributes.toolbarAlpha, progress: fasterProgress)
        let topLineAlpha = AnimatableUtilities.mixedValue(from: fromAttributes.topLineAlpha, to: toAttributes.topLineAlpha, progress: progress)
        
        self.backgroundColor = backgroundColor
        self.backgroundHeight = backgroundHeight
        self.topPadding = topPadding
        self.toolbarOffset = toolbarOffset
        self.toolbarAlpha = toolbarAlpha
        self.topLineAlpha = topLineAlpha
    }
}

struct PhotosIconAttributes: AnimatableAttributes {
    var foregroundColor: UIColor
    var backgroundHeight: CGFloat
    
    /// when active tab is camera
    static let inactiveDarkBackground: Self = { /// `Self` could also be `PhotosIconAttributes`
        .init(
            foregroundColor: UIColor.white,
            backgroundHeight: 48
        )
    }()
    
    static let inactiveLightBackground: Self = .init(
        foregroundColor: UIColor(hex: 0x7E7E7E),
        backgroundHeight: 48
    )
    
    /// always light background
    static let active: Self = .init(
        foregroundColor: UIColor(hex: 0x40C74D),
        backgroundHeight: 48
    )
}

/// keep normal initializer, so put in extension
extension PhotosIconAttributes {
    init(progress: CGFloat, from fromAttributes: Self, to toAttributes: Self) {
        let foregroundColor = fromAttributes.foregroundColor.toColor(toAttributes.foregroundColor, percentage: progress)
        let backgroundHeight = fromAttributes.backgroundHeight + (toAttributes.backgroundHeight - fromAttributes.backgroundHeight) * progress
        
        self.foregroundColor = foregroundColor
        self.backgroundHeight = backgroundHeight
    }
}

struct CameraIconAttributes: AnimatableAttributes {
    /// fill color
    var foregroundColor: UIColor
    
    /// entire background height
    var backgroundHeight: CGFloat
    
    /// length of circle
    var length: CGFloat
    
    /// rim color
    var rimColor: UIColor
    
    /// rim width
    var rimWidth: CGFloat
    
    static let inactive: Self = .init(
        foregroundColor: UIColor(hex: 0x7E7E7E).withAlphaComponent(0.5),
        backgroundHeight: 48,
        length: 26,
        rimColor: UIColor(hex: 0x7E7E7E),
        rimWidth: 1
    )
    
    static let active: Self = .init(
        foregroundColor: UIColor(hex: 0x00AEEF).withAlphaComponent(0.5),
        backgroundHeight: 98,
        length: 64,
        rimColor: .white,
        rimWidth: 3
    )
}

extension CameraIconAttributes {
    init(progress: CGFloat, from fromAttributes: Self, to toAttributes: Self) {
        let foregroundColor = fromAttributes.foregroundColor.toColor(toAttributes.foregroundColor, percentage: progress)
        let backgroundHeight = fromAttributes.backgroundHeight + (toAttributes.backgroundHeight - fromAttributes.backgroundHeight) * progress
        let length = fromAttributes.length + (toAttributes.length - fromAttributes.length) * progress
        let rimColor = fromAttributes.rimColor.toColor(toAttributes.rimColor, percentage: progress)
        let rimWidth = fromAttributes.rimWidth + (toAttributes.rimWidth - fromAttributes.rimWidth) * progress
        
        self.foregroundColor = foregroundColor
        self.backgroundHeight = backgroundHeight
        self.length = length
        self.rimColor = rimColor
        self.rimWidth = rimWidth
    }
}

struct ListsIconAttributes: AnimatableAttributes {
    var foregroundColor: UIColor
    var backgroundHeight: CGFloat
    
    static let inactiveDarkBackground: ListsIconAttributes = .init(
        foregroundColor: UIColor.white,
        backgroundHeight: 48
    )
    
    static let inactiveLightBackground: ListsIconAttributes = .init(
        foregroundColor: UIColor(hex: 0x7E7E7E),
        backgroundHeight: 48
    )
    
    static let active: ListsIconAttributes = .init(
        foregroundColor: UIColor(hex: 0xFFC600),
        backgroundHeight: 48
    )
}

/// keep normal initializer, so put in extension
extension ListsIconAttributes {
    init(progress: CGFloat, from fromAttributes: ListsIconAttributes, to toAttributes: ListsIconAttributes) {
        let foregroundColor = fromAttributes.foregroundColor.toColor(toAttributes.foregroundColor, percentage: progress)
        let backgroundHeight = fromAttributes.backgroundHeight + (toAttributes.backgroundHeight - fromAttributes.backgroundHeight) * progress
        
        self.foregroundColor = foregroundColor
        self.backgroundHeight = backgroundHeight
    }
}
