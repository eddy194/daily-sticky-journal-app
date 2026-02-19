import CoreData
import Foundation

extension Note {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        NSFetchRequest<Note>(entityName: "Note")
    }

    @NSManaged public var content: String
    @NSManaged public var createdAt: Date
    @NSManaged public var dateKey: String
    @NSManaged public var id: String
    @NSManaged public var updatedAt: Date
}

extension Note: Identifiable {}
