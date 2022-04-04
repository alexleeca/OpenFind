//
//  SettingsViewModel.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 3/31/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    

import SwiftUI

class SettingsViewModel: ObservableObject {
    @Saved("swipeToNavigate") var swipeToNavigate = true
    
    @Saved("scanOnLaunch") var scanOnLaunch = false
    @Saved("scanOnFind") var scanOnFind = true
}


