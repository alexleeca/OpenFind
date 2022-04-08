//
//  PhotosScanningView.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 2/18/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import SwiftUI

struct PhotosScanningView: View {
    @ObservedObject var model: PhotosViewModel
    @ObservedObject var realmModel: RealmModel
    var body: some View {
        PhotosScanningViewHeader(model: model, realmModel: realmModel)
    }
}

struct PhotosScanningViewHeader: View {
    @ObservedObject var model: PhotosViewModel
    @ObservedObject var realmModel: RealmModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                /// Header
                Container(description: "Find works completely offline, so your photos and other data never leave your phone.") {
                    HStack(spacing: 16) {
                        PhotosScanningGradientProgressView(
                            scannedPhotosCount: model.scannedPhotosCount,
                            totalPhotosCount: model.totalPhotosCount,
                            lineWidth: 10,
                            iconFont: .systemFont(ofSize: 42, weight: PhotosConstants.scanningCheckmarkWeight),
                            state: model.scanningIconState
                        )
                        .frame(width: 90, height: 90)
                        .padding(20)
                        .frame(maxHeight: .infinity)
                        .blueBackground()

                        VStack(alignment: .leading) {
                            Text(model.getRemainingTime() ?? "All Photos Scanned")
                                .foregroundColor(.accent.opacity(0.75))
                                .font(.headline.weight(.medium))

                            HStack {
                                Text("\(model.scannedPhotosCount)")
                                    .foregroundColor(.accent)
                                    +
                                    Text("/")
                                    .foregroundColor(.accent.opacity(0.75))
                                    +
                                    Text("\(model.totalPhotosCount)")
                                    .foregroundColor(.accent.opacity(0.75))
                            }
                            .font(.largeTitle.weight(.semibold))

                            let image = getImage()
                            let title = getTitle()

                            PhotosScanningButton(image: image, title: title) {
                                if model.scanningState == .dormant {
                                    model.startScanning()
                                } else {
                                    model.pauseScanning()
                                }
                            }
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(PhotosScanningConstants.padding)
                    .blueBackground()
                }

                PhotoScanningLink(
                    model: model,
                    title: "Ignored Photos",
                    arrowLabel: "\(model.ignoredPhotos.count)",
                    description: "Choose which photos to never scan."
                ) {
                    model.ignoredPhotosTapped?()
                }

                PhotoScanningRow(
                    model: model,
                    realmModel: realmModel,
                    title: "Scan on Launch",
                    description: "Automatically scan photos as soon as you open the app.",
                    storage: \.$photosScanOnLaunch
                )
                
                PhotoScanningRow(
                    model: model,
                    realmModel: realmModel,
                    title: "Scan on Addition",
                    description: "Automatically scan photos when they are added.",
                    storage: \.$photosScanOnAddition
                )
                
                PhotoScanningRow(
                    model: model,
                    realmModel: realmModel,
                    title: "Scan on Find",
                    description: "Automatically scan photos when you type in the search bar.",
                    storage: \.$photosScanOnFind
                )

                Spacer()
            }
            .padding(PhotosScanningConstants.padding)
        }
    }

    func getImage() -> String {
        var image = model.scanningState == .scanningAllPhotos ? "pause.fill" : "play.fill"
        if model.scannedPhotosCount == model.totalPhotosCount {
            image = "checkmark"
        }
        return image
    }

    func getTitle() -> String {
        var title = model.scanningState == .scanningAllPhotos ? "Pause" : "Resume"
        if model.scannedPhotosCount == model.totalPhotosCount {
            title = "Scanning Done"
        }
        return title
    }
}

struct PhotosScanningButton: View {
    var image: String?
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if let image = image {
                    Image(systemName: image)
                }

                Text(title)
            }
            .foregroundColor(Color.accent)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.accent.opacity(0.15))
            .cornerRadius(PhotosScanningConstants.innerCornerRadius)
        }
    }
}

struct Container<Content: View>: View {
    var description: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 10) {
            content

            Text(description)
                .foregroundColor(UIColor.secondaryLabel.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PhotosScanningConstants.padding)
        }
    }
}

struct PhotoScanningLink: View {
    @ObservedObject var model: PhotosViewModel
    var title: String
    var arrowLabel: String /// usually a number
    var description: String
    var action: () -> Void

    var body: some View {
        Container(description: description) {
            Button(action: action) {
                HStack {
                    Text(title)
                    Spacer()

                    HStack {
                        Text(arrowLabel)
                        Image(systemName: "chevron.forward")
                    }
                    .foregroundColor(UIColor.secondaryLabel.color)
                }
                .foregroundColor(UIColor.label.color)
                .padding(PhotosScanningConstants.padding)
                .background(UIColor.systemBackground.color)
                .cornerRadius(PhotosScanningConstants.cornerRadius)
            }
        }
    }
}

struct PhotoScanningRow: View {
    @ObservedObject var model: PhotosViewModel
    @ObservedObject var realmModel: RealmModel
    var title: String
    var description: String
    var storage: KeyPath<RealmModel, Binding<Bool>>

    var body: some View {
        Container(description: description) {
            HStack {
                Text(title)
                Spacer()
                Toggle(isOn: realmModel[keyPath: storage]) {
                    EmptyView()
                }
                .labelsHidden()
            }
            .padding(PhotosScanningConstants.padding)
            .background(UIColor.systemBackground.color)
            .cornerRadius(PhotosScanningConstants.cornerRadius)
        }
    }
}
