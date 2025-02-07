//
//  PhotoSlidesVC+FastFind.swift
//  Find
//
//  Created by Zheng on 1/22/21.
//  Copyright © 2021 Andrew. All rights reserved.
//

import Photos
import UIKit
import Vision

extension PhotoSlidesViewController {
    func fastFind(resultPhoto: ResultPhoto, index: Int) {
        numberCurrentlyFastFinding += 1
        
        DispatchQueue.global(qos: .userInitiated).async {
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            
            PHImageManager.default().requestImageDataAndOrientation(for: resultPhoto.findPhoto.asset, options: options) { data, _, _, _ in
                if let imageData = data {
                    let request = VNRecognizeTextRequest { request, error in
                        self.handleFastDetectedText(request: request, error: error, resultPhoto: resultPhoto, indexOfPhoto: index)
                    }
                    request.recognitionLevel = .fast
                    request.recognitionLanguages = Defaults.recognitionLanguages
                    
                    var customFindArray = [String]()
                    for findWord in self.matchToColors.keys {
                        customFindArray.append(findWord)
                        customFindArray.append(findWord.lowercased())
                        customFindArray.append(findWord.uppercased())
                        customFindArray.append(findWord.capitalizingFirstLetter())
                    }
                    
                    request.customWords = customFindArray
                    
                    let imageRequestHandler = VNImageRequestHandler(data: imageData, orientation: .up, options: [:])
                    do {
                        try imageRequestHandler.perform([request])
                    } catch {}
                }
            }
        }
    }
    
    func handleFastDetectedText(request: VNRequest?, error: Error?, resultPhoto: ResultPhoto, indexOfPhoto: Int) {
        numberCurrentlyFastFinding -= 1
        
        guard indexOfPhoto == currentIndex, numberCurrentlyFastFinding == 0 else {
            return
        }
        
        guard
            let results = request?.results,
            results.count > 0
        else {
            DispatchQueue.main.async {
                resultPhoto.currentMatchToColors = self.matchToColors
                self.setPromptToFinishedFastFinding(howMany: resultPhoto.components.count)
                self.drawHighlightsAndTranscripts()
            }
            return
        }
        
        var transcripts = [Component]()
        
        for result in results {
            if let observation = result as? VNRecognizedTextObservation {
                for text in observation.topCandidates(1) {
                    let origX = observation.boundingBox.origin.x
                    let origY = 1 - observation.boundingBox.minY
                    let origWidth = observation.boundingBox.width
                    let origHeight = observation.boundingBox.height
                    
                    let transcript = Component()
                    transcript.text = text.string
                    transcript.x = origX
                    transcript.y = origY
                    transcript.width = origWidth
                    transcript.height = origHeight
                    transcripts.append(transcript)
                }
            }
        }
        
        var fastFoundComponents = [Component]()
        var numberOfMatches = 0
        
        for transcript in transcripts {
            var matchRanges = [ArrayOfMatchesInComp]()
            
            let lowercaseContentText = transcript.text.lowercased()
            
            let individualCharacterWidth = CGFloat(transcript.width) / CGFloat(lowercaseContentText.count)
            for match in matchToColors.keys {
                if lowercaseContentText.contains(match) {
                    let finalW = individualCharacterWidth * CGFloat(match.count)
                    let indices = lowercaseContentText.indicesOf(string: match)
                    
                    for index in indices {
                        numberOfMatches += 1
                        let addedWidth = individualCharacterWidth * CGFloat(index)
                        let finalX = CGFloat(transcript.x) + addedWidth
                        
                        let newComponent = Component()
                        
                        newComponent.x = finalX
                        newComponent.y = CGFloat(transcript.y) - CGFloat(transcript.height)
                        newComponent.width = finalW
                        newComponent.height = CGFloat(transcript.height)
                        newComponent.text = match
                        newComponent.transcriptComponent = transcript
                        
                        fastFoundComponents.append(newComponent)
                        
                        let newRangeObject = ArrayOfMatchesInComp()
                        newRangeObject.descriptionRange = index...index + match.count
                        newRangeObject.text = match
                        matchRanges.append(newRangeObject)
                    }
                }
            }
        }
        
        var componentsToAdd = [Component]()
        
        for newFindComponent in fastFoundComponents {
            var smallestDistance = CGFloat(999)
            for findMatch in resultPhoto.components {
                let point1 = CGPoint(x: findMatch.x, y: findMatch.y)
                let point2 = CGPoint(x: newFindComponent.x, y: newFindComponent.y)
                let pointDistance = relativeDistance(point1, point2)
                
                if pointDistance < smallestDistance {
                    smallestDistance = pointDistance
                }
            }
            
            if smallestDistance >= 0.008 { /// Bigger, so add it
                componentsToAdd.append(newFindComponent)
            }
        }
        
        if resultPhoto.transcripts.isEmpty {
            resultPhoto.transcripts = transcripts
        }
        resultPhoto.components += componentsToAdd
        resultPhoto.currentMatchToColors = matchToColors
        
        DispatchQueue.main.async {
            self.setPromptToFinishedFastFinding(howMany: resultPhoto.components.count)
            self.drawHighlightsAndTranscripts()
        }
    }
}

extension PhotoSlidesViewController {
    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(sqrt(xDist * xDist + yDist * yDist))
    }

    func relativeDistance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(xDist * xDist + yDist * yDist)
    }
}
