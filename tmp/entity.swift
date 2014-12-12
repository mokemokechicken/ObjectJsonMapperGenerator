import Foundation
public class Book_option : EntityBase {
    var hoge: String?
    var hara: Bool?

    public override func toJsonDictionary() -> NSDictionary {
        var hash = NSMutableDictionary()
        // Encode hoge
        if let x = self.hoge {
            hash["hoge"] = encode(x)
        }

        // Encode hara
        if let x = self.hara {
            hash["hara"] = encode(x)
        }

        return hash
    }

    public override class func fromJsonDictionary(hash: NSDictionary?) -> Book_option? {
        if let h = hash {
            var this = Book_option()
            // Decode hoge
            this.hoge = h["hoge"] as? String
            // Decode hara
            this.hara = h["hara"] as? Bool
            return this
        } else {
            return nil
        }
    }
}

public class Book : EntityBase {
    var authors: [Author] = [Author]()
    var title: String = ""
    var year: Int = 0
    var note: String?
    var price: Double = 0
    var option: Book_option?

    public override func toJsonDictionary() -> NSDictionary {
        var hash = NSMutableDictionary()
        // Encode authors
        hash["authors"] = self.authors.map {x in encode(x)}
        // Encode title
        hash["title"] = encode(self.title)
        // Encode year
        hash["year"] = encode(self.year)
        // Encode note
        if let x = self.note {
            hash["note"] = encode(x)
        }

        // Encode price
        hash["price"] = encode(self.price)
        // Encode option
        if let x = self.option {
            hash["option"] = x.toJsonDictionary()
        }

        return hash
    }

    public override class func fromJsonDictionary(hash: NSDictionary?) -> Book? {
        if let h = hash {
            var this = Book()
            // Decode authors
            if let xx = h["authors"] as? [NSDictionary] {
                for x in xx {
                    if let obj = Author.fromJsonDictionary(x) {
                        this.authors.append(obj)
                    } else {
                        return nil
                    }
                }
            } else {
                return nil
            }

            // Decode title
            if let x = h["title"] as? String {
                this.title = x
            } else {
                return nil
            }

            // Decode year
            if let x = h["year"] as? Int {
                this.year = x
            } else {
                return nil
            }

            // Decode note
            this.note = h["note"] as? String
            // Decode price
            if let x = h["price"] as? Double {
                this.price = x
            } else {
                return nil
            }

            // Decode option
            this.option = Book_option.fromJsonDictionary((h["option"] as? NSDictionary))
            return this
        } else {
            return nil
        }
    }
}

public class Author : EntityBase {
    var name: String = ""
    var others: [Book]?

    public override func toJsonDictionary() -> NSDictionary {
        var hash = NSMutableDictionary()
        // Encode name
        hash["name"] = encode(self.name)
        // Encode others
        if let x = self.others {
            hash["others"] = x.map {x in encode(x)}
        }

        return hash
    }

    public override class func fromJsonDictionary(hash: NSDictionary?) -> Author? {
        if let h = hash {
            var this = Author()
            // Decode name
            if let x = h["name"] as? String {
                this.name = x
            } else {
                return nil
            }

            // Decode others
            if let xx = h["others"] as? [NSDictionary] {
                this.others = [Book]()
                for x in xx {
                    if let obj = Book.fromJsonDictionary(x) {
                        this.others!.append(obj)
                    } else {
                        return nil
                    }
                }
            }

            return this
        } else {
            return nil
        }
    }
}

