//
//  AlcoholData+CoreDataProperties.swift
//  AlcoholDiary
//
//  Created by 양홍찬 on 2023/07/20.
//
//

import Foundation
import CoreData


extension AlcoholData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AlcoholData> {
        return NSFetchRequest<AlcoholData>(entityName: "AlcoholData")
    }

    @NSManaged public var name: String?
    @NSManaged public var distillery: String?
    @NSManaged public var abv: String?
    @NSManaged public var aged: String?
    @NSManaged public var cask: String?
    @NSManaged public var nose: String?
    @NSManaged public var palate: String?
    @NSManaged public var finish: String?
    @NSManaged public var ratingScore: String?
    @NSManaged public var date: Date?
    @NSManaged public var image: Data?

    var dateString: String? {
        let myFormatter = DateFormatter()
        myFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = self.date else { return "" }
        let savedDateString = myFormatter.string(from: date)
        return savedDateString
    }
}

extension AlcoholData : Identifiable {

}
