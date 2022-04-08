//
//  PhotosVM+Load.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 2/14/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    
import Photos
import UIKit

extension PhotosViewModel {
    /// only call this once!
    func load() {
        getRealmModel?().container.loadPhotoMetadatas()
        loadAssets()
        loadPhotos { [weak self] in
            guard let self = self else { return }
            self.sort()
            self.reload?()
            
            if self.getRealmModel?().photosScanOnLaunch ?? false {
                self.startScanning()
            }
        }
    }

    func loadAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    }
    
    /// 1. all photos, 2. ignored photos, 3. photos to scan
    func getPhotos(completion: (([Photo], [Photo], [Photo]) -> Void)?) {
        DispatchQueue.global(qos: .userInitiated).async {
            var photos = [Photo]()
            var ignoredPhotos = [Photo]()
            var photosToScan = [Photo]()
            
            self.assets?.enumerateObjects { [weak self] asset, _, _ in
                
                guard let self = self else { return }
                
                let photo: Photo
                let identifier = asset.localIdentifier
                if let metadata = self.getRealmModel?().container.getPhotoMetadata(from: identifier) {
                    photo = Photo(asset: asset, metadata: metadata)
                    
                    if metadata.isIgnored {
                        ignoredPhotos.append(photo)
                    } else if metadata.dateScanned == nil {
                        photosToScan.append(photo)
                    }
                } else {
                    photo = Photo(asset: asset)
                    photosToScan.append(photo)
                }
                
                photos.append(photo)
            }
            completion?(photos, ignoredPhotos, photosToScan)
        }
    }
    
    func loadPhotos(completion: (() -> Void)?) {
        getPhotos { photos, ignoredPhotos, photosToScan in
            DispatchQueue.main.async {
                self.photos = photos
                self.ignoredPhotos = ignoredPhotos
                self.photosToScan = photosToScan.reversed() /// newest photos go first
                completion?()
            }
        }
    }
}
