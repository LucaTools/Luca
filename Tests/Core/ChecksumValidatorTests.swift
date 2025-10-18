//  ChecksumValidatorTests.swift

import Foundation
import Testing
@testable import LucaCore

struct ChecksumValidatorTests {
    
    private let fileManager = FileManager.default
    
    @Test(arguments: [
        (ChecksumAlgorithm.md5, "6fb6ef98c6623834c019ae26a8865fd6"),
        (ChecksumAlgorithm.sha1, "427eea4725eae77913015c0b72bd4cd329160526"),
        (ChecksumAlgorithm.sha256, "76b801daea0ed90f2871b0c66ebb8c4b9680d14e8011277d971cd74445fdaac5"),
        (ChecksumAlgorithm.sha512, "59a54e243611746feb9c2506396e5be7acb5fdfcb063de391b1a03476e8ba036488c66a126121818beb8d8e99959d5f16b90824eeb3e7866cbc6a47616751e32")
    ])
    func validateChecksum(algorithm: ChecksumAlgorithm, checksum: String) throws {
        let checksumValidatorFileManager = ChecksumValidatorFileManagerMock(fileManager: .default)
        let checksumValidator = ChecksumValidator(fileManager: checksumValidatorFileManager)
        
        let fixture = Fixture(filename: "MockRelease", type: "zip")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        
        try checksumValidator.validate(checksum: checksum, for: path, using: algorithm)
    }
}
