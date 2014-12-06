import Foundation

let args = Process.arguments

let filename = args[1]

var data = NSData(contentsOfFile: filename)!

var hash = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary

if let book = Book.fromJsonDictionary(hash) {
    println("\(book.toJsonDictionary())")
} else {
    println("JSON parse error")
}

