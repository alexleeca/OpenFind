//
//  PhotosVC+Setup.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 2/14/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import Photos
import SwiftUI

/**
 Pin the collection view, listen to the model, set up the navigation bar
 Show permissions view if needed
 */
extension PhotosViewController {
    func setup() {
        setupCollectionView(collectionView, with: flowLayout)
        setupCollectionView(resultsCollectionView, with: resultsFlowLayout)
        showResults(false)
        resultsCollectionView.backgroundColor = .secondarySystemBackground

        setupNavigationBar()
        checkPermissions()
        listenToModel()
    }

    func checkPermissions() {
        switch permissionsViewModel.currentStatus {
        case .notDetermined:
            showPermissionsView()
        case .restricted:
            showPermissionsView()
        case .denied:
            showPermissionsView()
        case .authorized:
            model.load()
        case .limited:
            model.load()
        @unknown default:
            fatalError()
        }
    }

    func showPermissionsView() {
        collectionView.alpha = 0
        let permissionsView = PhotosPermissionsView(model: permissionsViewModel)
        let hostingController = UIHostingController(rootView: permissionsView)
        addChildViewController(hostingController, in: view)
        view.bringSubviewToFront(hostingController.view)
        permissionsViewModel.permissionsGranted = { [weak self] in
            guard let self = self else { return }
            self.model.load()

            UIView.animate(withDuration: 0.5) { [weak hostingController] in
                hostingController?.view.alpha = 0
                self.collectionView.alpha = 1
            } completion: { [weak hostingController] _ in
                hostingController?.view.removeFromSuperview()
            }
        }
    }
}

extension PhotosViewController {
    func setupCollectionView(_ collectionView: UICollectionView, with layout: UICollectionViewFlowLayout) {
        view.addSubview(collectionView)
        collectionView.pinEdgesToSuperview()

        collectionView.delegate = self
        collectionView.allowsSelection = false
        collectionView.delaysContentTouches = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.keyboardDismissMode = .interactive
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset.top = searchViewModel.getTotalHeight()
        collectionView.verticalScrollIndicatorInsets.top = searchViewModel.getTotalHeight() + SearchNavigationConstants.scrollIndicatorTopPadding
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.collectionViewLayout = layout
    }
}
