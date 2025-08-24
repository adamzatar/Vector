// Sources/App/Support/Base32.swift
//
// RFC 4648 Base32 decoder (lenient):
// - Accepts upper/lowercase
// - Ignores spaces, hyphens, and padding '='
// - Returns nil on any invalid character

import Foundation

private let _b32Alphabet: [Character: UInt8] = {
    let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
    var map: [Character: UInt8] = [:]
    for (i, ch) in letters.enumerated() {
        map[ch] = UInt8(i)
        map[Character(ch.lowercased())] = UInt8(i)
    }
    return map
}()

extension String {
    /// Decode Base32 (RFC 4648). Accepts with/without padding and ignores whitespace/hyphens.
    func base32DecodedData() -> Data? {
        // Strip whitespace, hyphens, and padding
        let cleaned = self.filter { ch in
            ch != "=" && ch != " " && ch != "\t" && ch != "\n" && ch != "\r" && ch != "-" && ch != "_" // allow underscores too
        }
        if cleaned.isEmpty { return Data() }

        var buffer: UInt32 = 0
        var bitsInBuffer: Int = 0
        var out = Data()
        out.reserveCapacity((cleaned.count * 5) / 8 + 2)

        for ch in cleaned {
            guard let val = _b32Alphabet[ch] else { return nil }
            buffer = (buffer << 5) | UInt32(val)
            bitsInBuffer += 5

            while bitsInBuffer >= 8 {
                bitsInBuffer -= 8
                let byte = UInt8((buffer >> UInt32(bitsInBuffer)) & 0xFF)
                out.append(byte)
            }
        }

        // If there are leftover bits that don't make a full byte, they must be zero (padding equivalent).
        if bitsInBuffer > 0 {
            let remaining = UInt8((buffer << (8 - bitsInBuffer)) & 0xFF)
            if remaining != 0 { return nil }
        }

        return out
    }
}
