//
//  WalletService.swift
//  Linio
//
// Generates and signs a .pkpass for the Deutschlandticket.
//
// Setup required before use:
//   1. Register a Pass Type ID at developer.apple.com → Certificates, IDs & Profiles → Identifiers
//   2. Create & download the Pass Type ID certificate, export it as PassCertificate.p12
//   3. Drag PassCertificate.p12 into the Xcode target (check "Add to target")
//   4. Fill in passTypeIdentifier and teamIdentifier below

import Foundation
import PassKit
import Security
import CommonCrypto
import UIKit
import ZXingCpp

// MARK: - Configuration

enum WalletConfig {
    // Pass Type ID and Team ID are loaded from Info.plist (set via Secrets.xcconfig — never commit real values)
    static var passTypeIdentifier: String {
        Bundle.main.object(forInfoDictionaryKey: "WalletPassTypeID") as? String ?? ""
    }
    static var teamIdentifier: String {
        Bundle.main.object(forInfoDictionaryKey: "WalletTeamID") as? String ?? ""
    }
    static var certFileName: String {
        Bundle.main.object(forInfoDictionaryKey: "WalletCertName") as? String ?? "Zertifikat D-Ticket"
    }
    // Password used when exporting the .p12 (empty string if none)
    static let certPassword       = ""
    // Apple WWDR intermediate certificate (required in the CMS signature chain)
    static let wwdrCertFileName   = "AppleWWDRCAG4"
}

// MARK: - Error

enum WalletPassError: LocalizedError {
    case noCertificate
    case importFailed(OSStatus)
    case signingFailed
    case packagingFailed

    var errorDescription: String? {
        switch self {
        case .noCertificate:
            return "Zertifikat-Datei nicht gefunden.\n\nDatei '\(WalletConfig.certFileName).p12' ist nicht im App-Bundle."
        case .importFailed(let status):
            return "Zertifikat konnte nicht importiert werden (OSStatus \(status)).\n\nPasswort prüfen oder .p12 neu exportieren."
        case .signingFailed:
            return "Pass konnte nicht signiert werden. Zertifikat und Team-ID prüfen."
        case .packagingFailed:
            return "Pass konnte nicht erstellt werden."
        }
    }
}

// MARK: - Generator

final class WalletPassGenerator {

    private let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    /// Builds a signed `.pkpass` Data ready for `PKPass(data:)`.
    func generatePass(for ticket: DeutschlandTicket, barcodeImage: UIImage?) throws -> Data {
        let barcodeInfo = barcodeImage.flatMap { decodeBarcode(from: $0) }
        var files: [String: Data] = [:]

        // pass.json
        let passDict = makePassJSON(ticket: ticket, barcodeInfo: barcodeInfo)
        guard let passData = try? JSONSerialization.data(withJSONObject: passDict, options: [.prettyPrinted, .sortedKeys]) else {
            throw WalletPassError.packagingFailed
        }
        files["pass.json"] = passData
        #if DEBUG
        print("📋 [WALLET] pass.json:\n\(String(data: passData, encoding: .utf8) ?? "")")
        #endif

        // icon.png (required by PassKit — must be present)
        if let icon1x = makeIconData(size: 29) { files["icon.png"]    = icon1x }
        if let icon2x = makeIconData(size: 58) { files["icon@2x.png"] = icon2x }
        if let icon3x = makeIconData(size: 87) { files["icon@3x.png"] = icon3x }

        // logo.png (some PassKit implementations require it alongside logoText)
        if let logo = makeLogoImageData() {
            files["logo.png"]    = logo
            files["logo@2x.png"] = logo
        }

        // background.png (optional — shown behind the pass content)
        if let bg = makeBackgroundImageData() {
            files["background.png"]    = bg
            files["background@2x.png"] = bg
            files["background@3x.png"] = bg
        }


        // manifest.json — SHA1 hashes of every other file (PassKit spec)
        let manifest = files.mapValues { sha1Hex($0) }
        guard let manifestData = try? JSONSerialization.data(withJSONObject: manifest, options: .sortedKeys) else {
            throw WalletPassError.packagingFailed
        }
        files["manifest.json"] = manifestData
        #if DEBUG
        print("📋 [WALLET] manifest.json:\n\(String(data: manifestData, encoding: .utf8) ?? "")")
        #endif

        // signature — detached CMS signature of manifest.json
        let signature = try signManifest(manifestData)
        files["signature"] = signature
        #if DEBUG
        print("✅ [WALLET] Signatur erstellt: \(signature.count) Bytes")
        print("📦 [WALLET] Pass enthält \(files.count) Dateien: \(files.keys.sorted().joined(separator: ", "))")
        #endif

        return try packageAsZip(files)
    }

    // MARK: - pass.json

    private func makePassJSON(ticket: DeutschlandTicket, barcodeInfo: (message: String, pkFormat: String, encoding: String)?) -> [String: Any] {
        let serial = "DT-\(ticket.customerNumber.isEmpty ? "dt" : ticket.customerNumber)"

        var dict: [String: Any] = [
            "formatVersion":      1,
            "passTypeIdentifier": WalletConfig.passTypeIdentifier,
            "serialNumber":       serial,
            "teamIdentifier":     WalletConfig.teamIdentifier,
            "organizationName":   "Deutschlandticket",
            "description":        ticket.ticketLabel,
            "logoText":           "Deutschland Ticket",
            "foregroundColor":    "rgb(255, 255, 255)",
            "backgroundColor":    "rgb(44, 44, 44)",
            "labelColor":         "rgb(170, 170, 170)",
        ]

        var primaryFields: [[String: Any]] = []
        if !ticket.holderName.isEmpty {
            primaryFields.append(["key": "holder", "label": "INHABER", "value": ticket.holderName.uppercased()])
        }

        var secondaryFields: [[String: Any]] = [
            ["key": "validFrom",  "label": "GÜLTIG AB",  "value": df.string(from: ticket.validFrom)],
            ["key": "validUntil", "label": "GÜLTIG BIS", "value": df.string(from: ticket.validUntil)],
        ]
        if !ticket.issuer.isEmpty {
            secondaryFields.append(["key": "issuer", "label": "ANBIETER", "value": ticket.issuer])
        }

        var auxiliaryFields: [[String: Any]] = [
            ["key": "scope", "label": "GELTUNGSBEREICH", "value": "Bundesweit im Nahverkehr"],
        ]
        if !ticket.customerNumber.isEmpty {
            auxiliaryFields.append(["key": "customerNumber", "label": "KUNDENNUMMER", "value": ticket.customerNumber])
        }
        if ticket.ticketLabel != "Deutschlandticket" {
            auxiliaryFields.append(["key": "ticketType", "label": "TICKETART", "value": ticket.ticketLabel])
        }

        var backFields: [[String: Any]] = [
            ["key": "backScope",    "label": "Geltungsbereich", "value": "Bundesweit im Nahverkehr (2. Klasse)"],
            ["key": "backValidity", "label": "Gültigkeit",      "value": "\(df.string(from: ticket.validFrom)) – \(df.string(from: ticket.validUntil))"],
        ]
        if !ticket.holderName.isEmpty {
            backFields.append(["key": "backHolder", "label": "Inhaber", "value": ticket.holderName])
        }
        if !ticket.customerNumber.isEmpty {
            backFields.append(["key": "backCustomer", "label": "Kundennummer", "value": ticket.customerNumber])
        }
        if !ticket.issuer.isEmpty {
            backFields.append(["key": "backIssuer", "label": "Verkehrsunternehmen", "value": ticket.issuer])
        }
        backFields.append(contentsOf: [
            ["key": "backTransport",   "label": "Verkehrsmittel",    "value": "S-Bahn, U-Bahn, Bus, Straßenbahn, Regionalbahn (2. Klasse)"],
            ["key": "backExclusions",  "label": "Nicht gültig für",  "value": "IC, ICE, Fernverkehr"],
            ["key": "backMitnahme",    "label": "Mitnahmeregelung",  "value": "Keine kostenlose Mitnahme von Personen"],
            ["key": "backNote",        "label": "Hinweis",           "value": "Nur gültig mit amtlichem Lichtbildausweis. Nicht übertragbar."],
            ["key": "backLink",        "label": "Weitere Informationen",
             "value": "deutschlandticket.de",
             "attributedValue": "<a href='https://www.deutschlandticket.de'>deutschlandticket.de</a>"],
        ])

        dict["generic"] = [
            "primaryFields":   primaryFields,
            "secondaryFields": secondaryFields,
            "auxiliaryFields": auxiliaryFields,
            "backFields":      backFields,
        ] as [String: Any]

        if let info = barcodeInfo {
            let barcode: [String: Any] = [
                "message":         info.message,
                "format":          info.pkFormat,
                "messageEncoding": info.encoding,
            ]
            dict["barcode"]  = barcode
            dict["barcodes"] = [barcode]
        }

        return dict
    }

    // MARK: - Signing (manual PKCS7/CMS — CMSEncoder is macOS-only)

    private func signManifest(_ data: Data) throws -> Data {
        let (identity, chain) = try loadSigningIdentity()

        var leafCertRef: SecCertificate?
        var privateKeyRef: SecKey?
        guard SecIdentityCopyCertificate(identity, &leafCertRef) == errSecSuccess, let leafCert = leafCertRef,
              SecIdentityCopyPrivateKey(identity, &privateKeyRef) == errSecSuccess, let privateKey = privateKeyRef
        else { throw WalletPassError.signingFailed }

        let manifestDigest = sha1Data(data)

        let oidContentType   = asnOID([1,2,840,113549,1,9,3])
        let oidMessageDigest = asnOID([1,2,840,113549,1,9,4])
        let oidSigningTime   = asnOID([1,2,840,113549,1,9,5])
        let oidData          = asnOID([1,2,840,113549,1,7,1])
        let signingTime      = asnUTCTime(Date())
        let attrsBody = asnSeq([oidContentType,   asnSet([oidData])]) +
                        asnSeq([oidSigningTime,   asnSet([signingTime])]) +
                        asnSeq([oidMessageDigest, asnSet([asnOctetString(manifestDigest)])])
        let attrsForSigning = asnTLV(0x31, attrsBody)
        let attrsField      = asnTLV(0xa0, attrsBody)

        var cfErr: Unmanaged<CFError>?
        guard let sigBytes = SecKeyCreateSignature(
            privateKey, .rsaSignatureMessagePKCS1v15SHA1, attrsForSigning as CFData, &cfErr
        ) as Data? else { throw WalletPassError.signingFailed }

        let leafDER   = SecCertificateCopyData(leafCert) as Data
        let chainDERs = chain.map { SecCertificateCopyData($0) as Data }

        guard let issuerSeq = SecCertificateCopyNormalizedIssuerSequence(leafCert) as Data? else {
            throw WalletPassError.signingFailed
        }
        var cfErr2: Unmanaged<CFError>?
        guard let serialBytes = SecCertificateCopySerialNumberData(leafCert, &cfErr2) as Data? else {
            throw WalletPassError.signingFailed
        }

        return buildPKCS7(sig: sigBytes, signedAttrs: attrsField, leafDER: leafDER,
                          chainDERs: chainDERs, issuerSeq: issuerSeq, serialBytes: serialBytes)
    }

    private func loadSigningIdentity() throws -> (SecIdentity, [SecCertificate]) {
        guard let url = Bundle.main.url(forResource: WalletConfig.certFileName, withExtension: "p12"),
              let p12Data = try? Data(contentsOf: url) else {
            #if DEBUG
            let bundleContents = (try? FileManager.default.contentsOfDirectory(
                at: Bundle.main.bundleURL, includingPropertiesForKeys: nil
            )) ?? []
            print("❌ [WALLET] '\(WalletConfig.certFileName).p12' nicht gefunden. Bundle-Inhalt:")
            bundleContents.forEach { print("  - \($0.lastPathComponent)") }
            #endif
            throw WalletPassError.noCertificate
        }

        // Always pass the passphrase — even an empty string is different from omitting it.
        // Omitting causes iOS to expect interactive input which fails programmatically.
        let options: [String: Any] = [
            kSecImportExportPassphrase as String: WalletConfig.certPassword
        ]
        var items: CFArray?
        let status = SecPKCS12Import(p12Data as CFData, options as CFDictionary, &items)
        #if DEBUG
        print("🔐 [WALLET] SecPKCS12Import status: \(status)")
        #endif
        guard status == errSecSuccess else {
            throw WalletPassError.importFailed(status)
        }
        guard let itemArray = items as? [[String: Any]],
              let first = itemArray.first,
              let rawIdentity = first[kSecImportItemIdentity as String] else {
            throw WalletPassError.importFailed(-1)
        }
        let identity = rawIdentity as! SecIdentity
        var chain = first[kSecImportItemCertChain as String] as? [SecCertificate] ?? []

        // Apple Wallet requires the WWDR intermediate in the signature chain.
        if let wwdr = loadWWDRCertificate() {
            let wwdrData = SecCertificateCopyData(wwdr) as Data
            let alreadyPresent = chain.contains { SecCertificateCopyData($0) as Data == wwdrData }
            if !alreadyPresent {
                chain.append(wwdr)
            }
        }
        #if DEBUG
        print("🔐 [WALLET] Chain hat \(chain.count) Zertifikat(e)")
        for (i, cert) in chain.enumerated() {
            let summary = SecCertificateCopySubjectSummary(cert) as String? ?? "?"
            print("   [\(i)] \(summary)")
        }
        #endif

        return (identity, chain)
    }

    private func loadWWDRCertificate() -> SecCertificate? {
        guard let url = Bundle.main.url(forResource: WalletConfig.wwdrCertFileName, withExtension: "cer"),
              let data = try? Data(contentsOf: url),
              let cert = SecCertificateCreateWithData(nil, data as CFData) else {
            #if DEBUG
            print("⚠️ [WALLET] WWDR-Zertifikat '\(WalletConfig.wwdrCertFileName).cer' nicht gefunden")
            #endif
            return nil
        }
        return cert
    }

    // MARK: - PKCS7 SignedData builder (DER)

    private func buildPKCS7(sig: Data, signedAttrs: Data, leafDER: Data, chainDERs: [Data],
                            issuerSeq: Data, serialBytes: Data) -> Data {
        let oidSignedData = asnOID([1,2,840,113549,1,7,2])
        let oidData       = asnOID([1,2,840,113549,1,7,1])
        let oidSHA1       = asnOID([1,3,14,3,2,26])
        let oidRSASHA1    = asnOID([1,2,840,113549,1,1,5])
        let null          = Data([0x05, 0x00])

        let digestAlgos     = asnSet([asnSeq([oidSHA1, null])])
        let encapContent    = asnSeq([oidData])  // detached — no eContent
        let allCerts        = asnTagImplicit(0xa0, ([leafDER] + chainDERs).reduce(Data(), +))
        let issuerAndSerial = asnSeq([issuerSeq, asnIntBytes(serialBytes)])
        let signerInfo      = asnSeq([
            asnIntVal(1),
            issuerAndSerial,
            asnSeq([oidSHA1, null]),      // digestAlgorithm
            signedAttrs,                   // [0] IMPLICIT signedAttrs
            asnSeq([oidRSASHA1, null]),   // signatureAlgorithm
            asnOctetString(sig),
        ])
        let signedData = asnSeq([asnIntVal(1), digestAlgos, encapContent, allCerts, asnSet([signerInfo])])
        return asnSeq([oidSignedData, asnTagExplicit(0, signedData)])
    }

    // MARK: - ASN.1/DER helpers

    private func asnLen(_ n: Int) -> Data {
        guard n >= 128 else { return Data([UInt8(n)]) }
        var bytes = [UInt8](); var v = n
        while v > 0 { bytes.insert(UInt8(v & 0xff), at: 0); v >>= 8 }
        return Data([UInt8(0x80 | bytes.count)] + bytes)
    }
    private func asnTLV(_ tag: UInt8, _ body: Data) -> Data { Data([tag]) + asnLen(body.count) + body }
    private func asnSeq(_ parts: [Data]) -> Data { asnTLV(0x30, parts.reduce(Data(), +)) }
    private func asnSet(_ parts: [Data]) -> Data { asnTLV(0x31, parts.reduce(Data(), +)) }
    private func asnOctetString(_ d: Data) -> Data { asnTLV(0x04, d) }
    private func asnTagImplicit(_ tag: UInt8, _ body: Data) -> Data { asnTLV(tag, body) }
    private func asnTagExplicit(_ tag: Int, _ body: Data) -> Data { asnTLV(UInt8(0xa0 | tag), body) }

    private func asnUTCTime(_ date: Date) -> Data {
        let f = DateFormatter()
        f.dateFormat = "yyMMddHHmmss"
        f.timeZone = TimeZone(identifier: "UTC")
        let str = f.string(from: date) + "Z"
        return asnTLV(0x17, Data(str.utf8))
    }

    private func asnIntVal(_ v: Int) -> Data {
        var bytes = [UInt8](); var n = v
        repeat { bytes.insert(UInt8(n & 0xff), at: 0); n >>= 8 } while n != 0
        if bytes[0] & 0x80 != 0 { bytes.insert(0, at: 0) }
        return asnTLV(0x02, Data(bytes))
    }
    private func asnIntBytes(_ raw: Data) -> Data {
        var b = raw
        while b.count > 1 && b[0] == 0 { b = b.dropFirst() }
        if b[0] & 0x80 != 0 { b = Data([0]) + b }
        return asnTLV(0x02, b)
    }
    private func asnOID(_ parts: [Int]) -> Data {
        var bytes = [UInt8(40 * parts[0] + parts[1])]
        for c in parts.dropFirst(2) {
            var n = c; var enc = [UInt8(n & 0x7f)]; n >>= 7
            while n > 0 { enc.insert(UInt8(0x80 | (n & 0x7f)), at: 0); n >>= 7 }
            bytes.append(contentsOf: enc)
        }
        return asnTLV(0x06, Data(bytes))
    }

    // MARK: - Barcode Decoding

    private func decodeBarcode(from image: UIImage) -> (message: String, pkFormat: String, encoding: String)? {
        guard let cgImage = normalizedOrientation(image).cgImage else { return nil }
        let options = ZXIReaderOptions()
        options.formats = [
            NSNumber(value: ZXIFormat.AZTEC.rawValue),
            NSNumber(value: ZXIFormat.QR_CODE.rawValue),
            NSNumber(value: ZXIFormat.DATA_MATRIX.rawValue),
        ]
        options.tryRotate    = true
        options.tryDownscale = true
        let reader = ZXIBarcodeReader(options: options)
        guard let results = try? reader.read(cgImage), let result = results.first else { return nil }

        switch result.format {
        case .QR_CODE:
            // QR codes are text-based — UTF-8 is correct
            return (message: result.text, pkFormat: "PKBarcodeFormatQR", encoding: "utf-8")
        default:
            // VDV Aztec: ZXingCpp returns bytes that are UTF-8 encoded binary data.
            // fix_zxing equivalent (see github.com/rumpeltux/onlineticket):
            //   decode the UTF-8 bytes back to a Unicode string,
            //   then re-encode as latin1 to recover the original raw bytes.
            let originalBytes: Data
            if let utf8String = String(data: result.bytes, encoding: .utf8),
               let latin1Data = utf8String.data(using: .isoLatin1) {
                originalBytes = latin1Data
            } else {
                originalBytes = result.bytes
            }
            let message = String(data: originalBytes, encoding: .isoLatin1) ?? result.text
            return (message: message, pkFormat: "PKBarcodeFormatAztec", encoding: "iso-8859-1")
        }
    }

    private func normalizedOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: image.size)) }
    }

    private func makeBackgroundImageData() -> Data? {
        guard let url = Bundle.main.url(forResource: "dticket_wallet_background", withExtension: "png"),
              let data = try? Data(contentsOf: url) else {
            #if DEBUG
            print("⚠️ [WALLET] dticket_wallet_background.png nicht im Bundle gefunden")
            #endif
            return nil
        }
        return data
    }

    // MARK: - Icon & Logo (DTicket bars — mirrors DTicketLogoView in TicketView.swift)

    private func makeIconData(size: CGFloat) -> Data? {
        let scale = size / 58
        return renderDTicketBars(
            canvasSize: CGSize(width: size, height: size),
            vPadding: 7 * scale,
            cornerRadius: 13 * scale,
            xOrigin: nil,
            background: UIColor(red: 17/255, green: 17/255, blue: 17/255, alpha: 1)
        )?.pngData()
    }

    private func makeLogoImageData() -> Data? {
        renderDTicketBars(
            canvasSize: CGSize(width: 320, height: 100),
            vPadding: 12,
            cornerRadius: 0,
            xOrigin: 20,
            background: .clear
        )?.pngData()
    }

    /// Renders the nine DTicket gradient bars. Bar specs match DTicketLogoView exactly.
    private func renderDTicketBars(
        canvasSize: CGSize,
        vPadding: CGFloat,
        cornerRadius: CGFloat,
        xOrigin: CGFloat?,
        background: UIColor = .white
    ) -> UIImage? {
        struct Bar { let relW, xOff, gL, gR, gLX, gRX: CGFloat; let lHex, rHex: String }
        let bars: [Bar] = [
            Bar(relW:0.33, xOff:20, gL:0.50, gR:0.68, gLX:-16, gRX: 50, lHex:"111111", rHex:"111111"),
            Bar(relW:0.91, xOff: 9, gL:0.15, gR:0.68, gLX: -3, gRX: 66, lHex:"111111", rHex:"111111"),
            Bar(relW:1.00, xOff: 7, gL:0.60, gR:1.00, gLX:-38, gRX: 85, lHex:"111111", rHex:"111111"),
            Bar(relW:1.20, xOff: 3, gL:0.28, gR:1.00, gLX:-26, gRX: 77, lHex:"5E0000", rHex:"CC1A00"),
            Bar(relW:1.30, xOff: 0, gL:0.80, gR:0.15, gLX:-50, gRX: 95, lHex:"5E0000", rHex:"CC1A00"),
            Bar(relW:0.90, xOff: 3, gL:0.15, gR:0.85, gLX:-14, gRX: 70, lHex:"5E0000", rHex:"C01800"),
            Bar(relW:1.00, xOff: 7, gL:0.50, gR:0.15, gLX:-24, gRX: 81, lHex:"DE4400", rHex:"F8CC00"),
            Bar(relW:0.95, xOff:20, gL:0.28, gR:0.00, gLX: -4, gRX: 91, lHex:"DE4400", rHex:"F8CC00"),
            Bar(relW:0.80, xOff:16, gL:0.38, gR:0.50, gLX:-19, gRX: 76, lHex:"E04800", rHex:"F8CC00"),
        ]

        let availH = canvasSize.height - 2 * vPadding
        let s      = availH / (CGFloat(bars.count) * 9.0 + CGFloat(bars.count - 1) * 3.5)
        let barH   = 9.0 * s
        let gap    = 3.5 * s
        let W      = 70.0 * s

        let ox: CGFloat
        if let fixed = xOrigin {
            ox = fixed
        } else {
            let rightEdge = bars.map { $0.xOff * s + W * $0.relW }.max() ?? 0
            let leftEdge  = bars.map { $0.xOff * s }.min() ?? 0
            ox = (canvasSize.width - (rightEdge - leftEdge)) / 2 - leftEdge
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)
        return renderer.image { ctx in
            let cgCtx = ctx.cgContext
            cgCtx.clip(to: CGRect(origin: .zero, size: canvasSize))
            background.setFill()
            if cornerRadius > 0 {
                UIBezierPath(roundedRect: CGRect(origin: .zero, size: canvasSize), cornerRadius: cornerRadius).fill()
            } else {
                UIBezierPath(rect: CGRect(origin: .zero, size: canvasSize)).fill()
            }

            func cgColor(_ hex: String, alpha: CGFloat = 1) -> CGColor {
                var v: UInt64 = 0
                Scanner(string: hex).scanHexInt64(&v)
                return UIColor(
                    red:   CGFloat((v >> 16) & 0xff) / 255,
                    green: CGFloat((v >>  8) & 0xff) / 255,
                    blue:  CGFloat( v        & 0xff) / 255,
                    alpha: alpha
                ).cgColor
            }

            func drawPill(x: CGFloat, y: CGFloat, w: CGFloat, lHex: String, rHex: String, alpha: CGFloat = 1) {
                guard w > 0 else { return }
                let rect = CGRect(x: x, y: y, width: w, height: barH)
                cgCtx.saveGState()
                cgCtx.addPath(CGPath(roundedRect: rect, cornerWidth: barH / 2, cornerHeight: barH / 2, transform: nil))
                cgCtx.clip()
                if let grad = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [cgColor(lHex, alpha: alpha), cgColor(rHex, alpha: alpha)] as CFArray,
                    locations: [0.0, 1.0] as [CGFloat]
                ) {
                    cgCtx.drawLinearGradient(
                        grad,
                        start: CGPoint(x: rect.minX, y: rect.midY),
                        end:   CGPoint(x: rect.maxX, y: rect.midY),
                        options: []
                    )
                }
                cgCtx.restoreGState()
            }

            var y = vPadding
            for bar in bars {
                if bar.gL > 0 { drawPill(x: ox + bar.gLX * s, y: y, w: W * bar.gL, lHex: bar.lHex, rHex: bar.rHex, alpha: 0.22) }
                drawPill(x: ox + bar.xOff * s, y: y, w: W * bar.relW, lHex: bar.lHex, rHex: bar.rHex)
                if bar.gR > 0 { drawPill(x: ox + bar.gRX * s, y: y, w: W * bar.gR, lHex: bar.lHex, rHex: bar.rHex, alpha: 0.22) }
                y += barH + gap
            }
        }
    }

    // MARK: - SHA1 (PassKit manifest spec requires SHA1)

    private func sha1Hex(_ data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes { _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest) }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func sha1Data(_ data: Data) -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes { _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest) }
        return Data(digest)
    }

    // MARK: - ZIP (stored, no compression — PassKit only needs a valid ZIP structure)

    private func packageAsZip(_ files: [String: Data]) throws -> Data {
        var localSection = Data()
        var centralDir   = Data()

        struct Entry { let nameData: Data; let crc: UInt32; let size: UInt32; let offset: UInt32 }
        var entries: [Entry] = []

        for name in files.keys.sorted() {
            guard let content = files[name], let nameData = name.data(using: .utf8) else { continue }
            let crc    = crc32(content)
            let size   = UInt32(content.count)
            let offset = UInt32(localSection.count)
            entries.append(Entry(nameData: nameData, crc: crc, size: size, offset: offset))

            localSection += u32(0x04034B50)              // local file header signature
            localSection += u16(20)                      // version needed: 2.0
            localSection += u16(0)                       // general purpose flags
            localSection += u16(0)                       // compression: stored
            localSection += u16(0) + u16(0)              // last mod time + date
            localSection += u32(crc)
            localSection += u32(size) + u32(size)        // compressed + uncompressed size
            localSection += u16(UInt16(nameData.count))
            localSection += u16(0)                       // extra field length
            localSection += nameData
            localSection += content
        }

        let cdOffset = UInt32(localSection.count)

        for e in entries {
            centralDir += u32(0x02014B50)                // central dir signature
            centralDir += u16(20) + u16(20)              // version made / version needed
            centralDir += u16(0)                         // flags
            centralDir += u16(0)                         // compression
            centralDir += u16(0) + u16(0)                // mod time + date
            centralDir += u32(e.crc)
            centralDir += u32(e.size) + u32(e.size)      // compressed + uncompressed
            centralDir += u16(UInt16(e.nameData.count))
            centralDir += u16(0) + u16(0)                // extra + comment length
            centralDir += u16(0)                         // disk number start
            centralDir += u16(0) + u32(0)                // internal + external attrs
            centralDir += u32(e.offset)                  // offset of local header
            centralDir += e.nameData
        }

        var eocd = Data()
        eocd += u32(0x06054B50)                          // end of central dir signature
        eocd += u16(0) + u16(0)                          // disk + start disk
        eocd += u16(UInt16(entries.count)) + u16(UInt16(entries.count))
        eocd += u32(UInt32(centralDir.count))
        eocd += u32(cdOffset)
        eocd += u16(0)                                   // comment length

        return localSection + centralDir + eocd
    }

    // MARK: - CRC-32 (ISO 3309 / ZIP standard)

    private func crc32(_ data: Data) -> UInt32 {
        let table: [UInt32] = (0..<256).map { i -> UInt32 in
            (0..<8).reduce(UInt32(i)) { c, _ in (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1 }
        }
        return data.reduce(0xFFFFFFFF) { crc, byte in
            table[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        } ^ 0xFFFFFFFF
    }

    private func u16(_ v: UInt16) -> Data { withUnsafeBytes(of: v.littleEndian) { Data($0) } }
    private func u32(_ v: UInt32) -> Data { withUnsafeBytes(of: v.littleEndian) { Data($0) } }
}
