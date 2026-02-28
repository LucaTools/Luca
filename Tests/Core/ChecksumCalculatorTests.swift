//  ChecksumCalculatorTests.swift

import Foundation
import Testing
@testable import LucaCore

struct ChecksumCalculatorTests {
    
    @Test(arguments: [
        (ChecksumAlgorithm.md5, "6c2378ee7f1ab7d46f90b3a0969f4be8"),
        (ChecksumAlgorithm.sha1, "a54295ead556697442a7e3e180566ca5df6dce50"),
        (ChecksumAlgorithm.sha256, "e7184e7a00fe83097dde5b44d3fde0ed8faf1b00573920fb3019498ad1634018"),
        (ChecksumAlgorithm.sha512, "8b8f4ac67667764840efd8778dd81d871889307d5855f9bac6b4c6337f5a391dc24d80d5d63ae62cdce15122d874beb7c56042ac52f2b6ba225bd0b6ec97765d")
    ])
    func calculateChecksum(algorithm: ChecksumAlgorithm, expectedChecksum: String) throws {
        let checksumValidatorFileManager = ChecksumValidatorFileManagerMock(fileManager: .default)
        let calculator = ChecksumCalculator(fileManager: checksumValidatorFileManager)

        let fixture = Fixture(filename: "MockMachO_Universal_Release", type: "zip")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        
        let calculatedChecksum = try calculator.calculateChecksum(for: path, using: algorithm)
        #expect(calculatedChecksum == expectedChecksum)
    }
}
