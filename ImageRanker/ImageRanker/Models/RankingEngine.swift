import SwiftUI

/// Determines the top 3 images using the minimum number of pairwise comparisons
/// via a queue-based tournament:
///
/// Phase 1 — tournament (N-1 comparisons): the front two leaders are compared;
/// the loser is appended to the winner's directLosses list and the winner goes
/// to the back of the queue. After N-1 rounds one leader remains (#1).
///
/// Phase 2 — search for #2 (≤ log₂N comparisons): #2 must be one of the images
/// that #1 directly beat. A linear search finds it.
///
/// Phase 3 — search for #3 (≤ 2·log₂N comparisons): #3 must be one of #1's
/// remaining direct victims OR one of #2's direct victims.
final class RankingEngine: ObservableObject {
    enum Phase: Equatable { case idle, comparing, done }
    struct Pair: Equatable { let left: Int; let right: Int }

    @Published private(set) var currentPair: Pair?
    @Published private(set) var progress: (done: Int, total: Int) = (0, 1)
    @Published private(set) var result: [Int] = []
    @Published private(set) var phase: Phase = .idle

    private(set) var images: [UIImage] = []

    private var tournamentLeaders: [Int] = []
    // directLosses[i] = indices of images that image i directly beat in the tournament
    private var directLosses: [[Int]] = []

    private var finalist = -1
    private var secondPlace = -1

    private var searchLeader = -1
    private var searchQueue: [Int] = []
    private var searchDone: (() -> Void)?

    private var comparisonsCompleted = 0
    private var estimatedTotal = 1

    func load(images: [UIImage]) {
        self.images = images
        start()
    }

    /// Releases all decoded images and resets to idle. Call this when the user
    /// starts over so the old batch is freed before the next selection is loaded.
    func clear() {
        images = []
        result = []
        phase = .idle
        currentPair = nil
        progress = (0, 1)
        directLosses = []
        tournamentLeaders = []
        comparisonsCompleted = 0
        estimatedTotal = 1
        searchDone = nil
        searchLeader = -1
        searchQueue = []
        finalist = -1
        secondPlace = -1
    }

    func pick(winner: Int, loser: Int) {
        guard phase == .comparing, currentPair != nil else { return }
        currentPair = nil
        comparisonsCompleted += 1
        progress = (comparisonsCompleted, estimatedTotal)

        if searchDone == nil {
            applyTournament(winner: winner, loser: loser)
            nextTournamentStep()
        } else {
            if winner != searchLeader { searchLeader = winner }
            nextSearchStep()
        }
    }

    // MARK: - Setup

    private func start() {
        comparisonsCompleted = 0
        searchDone = nil
        secondPlace = -1
        finalist = -1
        result = []

        let n = images.count
        guard n > 0 else { phase = .done; return }
        if n == 1 { result = [0]; phase = .done; return }
        if n == 2 {
            estimatedTotal = 1
            progress = (0, estimatedTotal)
            directLosses = Array(repeating: [], count: 2)
            tournamentLeaders = [0, 1]
            phase = .comparing
            nextTournamentStep()
            return
        }

        let logN = Int(ceil(log2(Double(n))))
        estimatedTotal = max(1, (n - 1) + 2 * logN - 1)
        progress = (0, estimatedTotal)
        directLosses = Array(repeating: [], count: n)
        tournamentLeaders = Array(0..<n)
        phase = .comparing
        nextTournamentStep()
    }

    // MARK: - Phase 1: tournament

    private func nextTournamentStep() {
        guard tournamentLeaders.count > 1 else {
            finalist = tournamentLeaders[0]
            let victims = directLosses[finalist]

            // Only the n==2 path (handled above) should produce an empty victims list.
            // For n>=3 always enter the search so #3 can be found among the victim's
            // own direct losses even when the finalist has just one direct victim.
            if victims.isEmpty { result = [finalist]; phase = .done; return }

            beginSearch(candidates: victims, onDone: finishSecondSearch)
            return
        }
        currentPair = Pair(left: tournamentLeaders[0], right: tournamentLeaders[1])
    }

    private func applyTournament(winner: Int, loser: Int) {
        directLosses[winner].append(loser)
        tournamentLeaders.removeFirst(2)
        tournamentLeaders.append(winner)
    }

    // MARK: - Phase 2 & 3: linear search

    private func beginSearch(candidates: [Int], onDone: @escaping () -> Void) {
        searchLeader = candidates[0]
        searchQueue = Array(candidates.dropFirst())
        searchDone = onDone
        guard !searchQueue.isEmpty else { searchDone = nil; onDone(); return }
        currentPair = Pair(left: searchLeader, right: searchQueue.removeFirst())
    }

    private func nextSearchStep() {
        guard !searchQueue.isEmpty else {
            let done = searchDone; searchDone = nil; done?()
            return
        }
        currentPair = Pair(left: searchLeader, right: searchQueue.removeFirst())
    }

    private func finishSecondSearch() {
        secondPlace = searchLeader
        let remaining = directLosses[finalist].filter { $0 != secondPlace }
                      + directLosses[secondPlace]
        guard !remaining.isEmpty else { result = [finalist, secondPlace]; phase = .done; return }
        if remaining.count == 1 { result = [finalist, secondPlace, remaining[0]]; phase = .done; return }
        beginSearch(candidates: remaining, onDone: finishThirdSearch)
    }

    private func finishThirdSearch() {
        result = [finalist, secondPlace, searchLeader]
        phase = .done
    }
}
