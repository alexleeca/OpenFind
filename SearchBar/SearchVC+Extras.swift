//
//  SearchVC+Extras.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 4/19/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import Popovers
import SwiftUI
import WebKit

extension SearchViewController {
    static let extrasPopoverTag = "Extras"
    func checkExtras(text: String) {
        if text.roughlyEquals("/resetlaunch") {
            realmModel.launchedBefore = false
            showPopover(configuration: .checkmark(message: "Launch Reset"), autoDismiss: true)
        }

        if text.roughlyEquals("/about") {
            showPopover(configuration: .about, autoDismiss: false)
        }

        if text.roughlyEquals("/help") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let viewController = SettingsData.getHelpCenter?() {
                    self.present(viewController, animated: true)
                }
                self.view.endEditing(true)
            }
        }

        if text.roughlyEquals("/flip") {
            UIView.animate(
                duration: 1.8,
                dampingFraction: 1
            ) {
                guard let mainView = UIApplication.rootViewController?.view else { return }
                mainView.transform = mainView.transform.rotated(by: CGFloat.pi)
                mainView.transform = mainView.transform.rotated(by: CGFloat.pi)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.view.endEditing(true)
            }
        }

        if text.roughlyEquals("/rick") {
            if let url = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ") {
                showPopover(configuration: .url(url: url), autoDismiss: false)
            }
        }

        if text.roughlyEquals("/apple") {
            showPopover(configuration: .image(systemName: "applelogo"), autoDismiss: true)
        }
    }

    func showPopover(configuration: ExtrasView.Configuration, autoDismiss: Bool) {
        var attributes = Popover.Attributes()
        attributes.tag = SearchViewController.extrasPopoverTag
        attributes.position = .relative(popoverAnchors: [.top])
        attributes.sourceFrame = { UIScreen.main.bounds }

        var insets = Global.safeAreaInsets
        insets.top += 160
        attributes.sourceFrameInset = insets

        let searchConfiguration = searchViewModel.configuration
        let popover = Popover(attributes: attributes) {
            ExtrasView(searchConfiguration: searchConfiguration, configuration: configuration)
        }
        if let existingPopover = view.popover(tagged: SearchViewController.extrasPopoverTag) {
            replace(existingPopover, with: popover)
        } else {
            present(popover)
        }

        if autoDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if let existingPopover = self.view.popover(tagged: SearchViewController.extrasPopoverTag) {
                    self.dismiss(existingPopover)
                }
            }
        }
    }
}

struct ExtrasView: View {
    enum Configuration {
        case checkmark(message: String)
        case about
        case url(url: URL)
        case image(systemName: String)
    }

    var searchConfiguration: SearchConfiguration
    var configuration: Configuration

    @State var transform: SettingsProfileTransformState?
    var body: some View {
        switch configuration {
        case .checkmark(message: let message):
            VStack(spacing: 20) {
                Image(systemName: "checkmark")
                    .font(UIFont.systemFont(ofSize: 52, weight: .semibold).font)
                Text(message)
                    .font(UIFont.preferredCustomFont(forTextStyle: .title3, weight: .medium).font)
            }
            .padding(36)
            .foregroundColor(searchConfiguration.popoverTextColor.color)
            .background(VisualEffectView(searchConfiguration.popoverBackgroundBlurStyle))
            .cornerRadius(20)
        case .about:
            VStack(spacing: 16) {
                Button {
                    withAnimation(
                        .spring(
                            response: 0.6,
                            dampingFraction: 0.6,
                            blendDuration: 1
                        )
                    ) {
                        if transform == nil {
                            transform = SettingsProfileTransformState.allCases.randomElement()
                        } else {
                            transform = nil
                        }
                    }
                } label: {
                    PortraitView(length: 180, circular: true, transform: $transform)
                }
                .buttonStyle(LaunchButtonStyle())

                Group {
                    Text("Made by Andrew Zheng")

                    Button {
                        if let url = URL(string: "https://twitter.com/intent/user?screen_name=aheze0") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Follow me on Twitter!")
                            .opacity(0.75)
                    }
                }
                .font(UIFont.preferredCustomFont(forTextStyle: .title3, weight: .medium).font)
                .foregroundColor(searchConfiguration.fieldIsDark ? UIColor.white.color : UIColor.secondaryLabel.color)
            }
            .padding(36)
            .background(VisualEffectView(searchConfiguration.popoverBackgroundBlurStyle))
            .cornerRadius(20)
        case .url(url: let url):
            WebView(url: url)
                .frame(height: 200)
                .frame(maxWidth: 350)
                .cornerRadius(10)
                .shadow(color: UIColor.systemBackground.color.opacity(0.25), radius: 4, x: 0, y: 2)

        case .image(systemName: let systemName):
            Image(systemName: systemName)
                .font(UIFont.systemFont(ofSize: 84, weight: .semibold).font)
                .foregroundColor(searchConfiguration.fieldIsDark ? UIColor.white.color : UIColor.secondaryLabel.color)
                .padding(36)
                .aspectRatio(1, contentMode: .fill)
                .background(VisualEffectView(searchConfiguration.popoverBackgroundBlurStyle))
                .cornerRadius(20)
        }
    }
}

private extension String {
    func roughlyEquals(_ otherText: String) -> Bool {
        let a = trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let b = otherText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return a == b
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: UIViewRepresentableContext<WebView>) -> WKWebView {
        let view = WKWebView()
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        view.load(request)

        return view
    }

    func updateUIView(_ view: WKWebView, context: UIViewRepresentableContext<WebView>) {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        view.load(request)
    }
}
