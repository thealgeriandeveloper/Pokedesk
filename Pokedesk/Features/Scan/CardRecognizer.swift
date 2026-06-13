import Vision
import UIKit

/// A candidate card match with a confidence score (0...1).
struct RankedCard: Identifiable, Hashable {
    let card: APICard
    let confidence: Double
    var id: String { card.id }
}

/// Runs on-device Vision OCR on a card photo, then matches the recognized text
/// against the Pokémon TCG API to produce ranked candidates.
struct CardRecognizer {
    let api: PokemonAPIService

    init(apiKey: String? = AppConfig.pokemonAPIKey) {
        self.api = PokemonAPIService(apiKey: apiKey)
    }

    /// Full pipeline: photo → recognized text → ranked API matches (best first).
    func rankedMatches(for image: UIImage) async -> [RankedCard] {
        let lines = await recognizeLines(in: image)
        return await rank(from: lines)
    }

    // MARK: - Vision OCR

    /// Recognized text lines, ordered top-to-bottom on the card.
    func recognizeLines(in image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                // boundingBox origin is bottom-left, so higher maxY = higher on the card.
                let sorted = observations.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }
                let lines = sorted.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: image.cgImagePropertyOrientation,
                options: [:]
            )
            try? handler.perform([request])
        }
    }

    // MARK: - Matching

    /// Query the API using the best name guess and rank results by similarity,
    /// boosting cards whose collector number matches the scanned number.
    func rank(from lines: [String]) async -> [RankedCard] {
        guard let nameGuess = bestNameGuess(in: lines) else { return [] }
        let number = collectorNumber(in: lines)

        guard let results = try? await api.searchCards(matching: nameGuess), !results.isEmpty else {
            return []
        }

        let ranked = results.map { card -> RankedCard in
            var score = similarity(nameGuess, card.name)
            if let number, card.number.replacingOccurrences(of: "#", with: "").hasPrefix(number) {
                score = min(1, score + 0.15)
            }
            return RankedCard(card: card, confidence: score)
        }
        return ranked.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Heuristics

    /// The most likely card name: the first prominent line that's mostly letters.
    private func bestNameGuess(in lines: [String]) -> String? {
        for line in lines {
            let cleaned = clean(line)
            let letters = cleaned.filter { $0.isLetter }
            // A name has at least 3 letters and isn't dominated by digits/keywords.
            if letters.count >= 3, !isNoise(cleaned) {
                return cleaned
            }
        }
        return nil
    }

    /// Extract a collector number like "182/172" or "#182" → "182".
    private func collectorNumber(in lines: [String]) -> String? {
        let joined = lines.joined(separator: " ")
        if let match = joined.range(of: #"(\d{1,3})\s*/\s*\d{1,3}"#, options: .regularExpression) {
            return joined[match].split(separator: "/").first.map { $0.trimmingCharacters(in: .whitespaces) }
        }
        if let match = joined.range(of: #"#\s*(\d{1,3})"#, options: .regularExpression) {
            return joined[match].filter(\.isNumber)
        }
        return nil
    }

    /// Strip trailing HP/energy noise and normalize whitespace.
    private func clean(_ text: String) -> String {
        var t = text
        for keyword in ["HP", "ＨＰ"] {
            if let r = t.range(of: keyword) { t = String(t[..<r.lowerBound]) }
        }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isNoise(_ text: String) -> Bool {
        let lower = text.lowercased()
        let noise = ["basic", "stage", "trainer", "energy", "weakness", "resistance", "ability"]
        return noise.contains { lower.contains($0) }
    }

    /// Token-overlap similarity (Jaccard-ish) between two names, 0...1.
    private func similarity(_ a: String, _ b: String) -> Double {
        let ta = tokens(a), tb = tokens(b)
        guard !ta.isEmpty, !tb.isEmpty else { return 0 }
        let intersection = ta.intersection(tb).count
        let union = ta.union(tb).count
        let jaccard = Double(intersection) / Double(union)
        // Boost when one name fully contains the other (e.g. "Zapdos" in "Galarian Zapdos V").
        let contains = a.lowercased().contains(b.lowercased()) || b.lowercased().contains(a.lowercased())
        return min(1, jaccard + (contains ? 0.3 : 0))
    }

    private func tokens(_ s: String) -> Set<String> {
        Set(s.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 })
    }
}
