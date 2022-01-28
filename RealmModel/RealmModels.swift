//
//  RealmModels.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 1/27/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    

import Foundation
import RealmSwift

class RealmList: Object {
    @Persisted(primaryKey: true) var id = UUID()
    @Persisted var name = ""
    @Persisted var desc = ""
    let contents = RealmSwift.List<String>()
    @Persisted var icon = ""
    @Persisted var color = ""
    @Persisted var dateCreated = Date()
}

class RealmWord: Object {
    @Persisted(primaryKey: true) var id = UUID()
    @Persisted var string = ""
}

class RealmHistory: Object {
    
    /// the date when it was searched for
    @Persisted var date = Date()
    
    /// word or list?
    @Persisted var valueType: RealmValueType
    @Persisted var word: RealmWord?
    @Persisted var list: RealmList?
}

enum RealmValueType: String, PersistableEnum {
    case word
    case list
}


//struct Word {
//    var id = UUID()
//    var string = ""
//    var color: UInt = 0x00AEEF
//}
//
//struct List {
//    var id = UUID()
//    var name = ""
//    var desc = ""
//    var image = ""
//    var color: UInt = 0x00AEEF
//    var words = [String]()
//    var dateCreated = Date()
//}

//struct List {
//    var id = UUID()
//    var name = ""
//    var desc = ""
//    var image = ""
//    var color: UInt = 0x00AEEF
//    var words = [String]()
//    var dateCreated = Date()
//}
//
//class EditableFindList: NSObject {
//    var name = ""
//    var descriptionOfList = ""
//    var contents = [String]()
//    var iconImageName = ""
//    var iconColorName = ""
//    var dateCreated = Date()
//    var orderIdentifier = 0
//}
