//
// Created by owen on 25.01.23.
//

import Foundation

class File {
    static func writeText(path: String, content: String) throws {
        try content.write(toFile: path, atomically: true, encoding: .utf8)
    }

    static func readText(path: String) throws -> String {
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    static func readJSON<Type>(path: String) throws -> Type {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try JSONSerialization.jsonObject(with: data, options: []) as! Type
    }

    static func exportJSON<Type>(path: String, data: Type) throws {
        let json = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        try json.write(to: URL(fileURLWithPath: path))
    }
}
