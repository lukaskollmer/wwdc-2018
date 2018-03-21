import Foundation

/// Simple string table generator. Used when displaying match infos
struct LKTextTable {
    let numberOfColumns: Int
    private var rows = [[String]]()
    
    init(numberOfColumns: Int) {
        self.numberOfColumns = numberOfColumns
    }
    
    mutating func addRow(values: [String]) {
        precondition(values.count == numberOfColumns, "Attempted to add a row with the wrong numbe of columns (got \(values.count), expected \(numberOfColumns))")
        rows.append(values)
    }
    
    var stringValue: String {
        var rowStrings = [String](repeating: "", count: rows.count)
        
        (0..<numberOfColumns).forEach { column in
            let columnValues = rows.map { $0[column] }
            let maxLength = columnValues.reduce(0) { max($0, $1.count) }
            
            columnValues.enumerated().forEach { index, columnValue in
                rowStrings[index] += columnValue.padding(toLength: maxLength + 1, withPad: " ", startingAt: 0)
            }
        }
        return rowStrings.joined(separator: "\n")
    }
}

