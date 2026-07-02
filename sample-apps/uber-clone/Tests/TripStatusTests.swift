import Testing
import Foundation
@testable import UberClone

@Suite("Trip lifecycle states")
struct TripStatusTests {
    @Test("Every lifecycle state survives a Codable round trip")
    func statusRawValuesRoundTrip() throws {
        for status in TripStatus.allCases {
            let encoded = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(TripStatus.self, from: encoded)
            #expect(decoded == status)
        }
    }

    @Test("The lifecycle covers request through resolution")
    func lifecycleIsComplete() {
        #expect(TripStatus.allCases.contains(.requested))
        #expect(TripStatus.allCases.contains(.completed))
        #expect(TripStatus.allCases.contains(.cancelled))
    }
}
