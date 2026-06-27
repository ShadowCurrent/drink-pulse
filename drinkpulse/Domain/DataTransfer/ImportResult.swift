import Foundation

struct ImportResult {
    let imported: Int
    let skipped:  Int
    let failed:   Int
    let errors:   [String]
}
