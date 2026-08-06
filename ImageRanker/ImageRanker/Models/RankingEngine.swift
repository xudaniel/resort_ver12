import SwiftUI

/// Determines the top 3 images from a set using the minimum number of pairwise
/// comparisons via a merge-sort tournament:
///
/// Phase 1 (tournament): repeatedly pair up the current "group leaders" and merge
/// the loser's group behind the winner's. After N-1 comparisons the overall winner
/// (#1) is known, along with the list of images it personally beat (its "victims").
///
/// Phase 2 (search for #2): #2 must be one of #1's direct victims (anyone else lost
/// to someone who isn't #1). A linear "current leader vs next challenger" search over
/// those victims finds #2 in at most ceil(log2(victims)) comparisons.
///
/// Phase 3 (search for #3): search the remaining victims of #1 (excluding #2).
///
/// Total comparisons: (N-1) + ceil(log2 N) + ceil(log2 N) - 1.
final class RankingEngine: ObservableObject {
    enum Phase: Equatable { case idle, comparing, done }

    struct Pair: Equatable { let left: Int; let right: Int }

    @Published private(set) var currentPair: Pair?
    @Published private(set) var progress: (done: Int, total: Int) = (0, 1)
    @Published private(set) var result: [Int] = []
    @Published private(set) var phase: Phase = .idle

    private(set) var images: [UIImage] = []

    private var groups: [[Int]] = []
    private var finalist = -1
    private var finalistVictims: [Int] = []
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

    private func start() {
        comparisonsCompleted = 0
        searchDone = nil
        secondPlace = -1
        finalist = -1
        finalistVictims = []
        result = []

        let n = images.count
        guard n > 0 else { phase = .done; return }

        if n == 1 { result = [0]; phase = .done; return }

        if n == 2 {
            estimatedTotal = 1
            progress = (0, estimatedTotal)
            groups = [[0], [1]]
            phase = .comparing
            nextTournamentStep()
            return
        }

        let logN = Int(ceil(log2(Double(n))))
        estimatedTotal = max(1, (n - 1) + 2 * logN - 1)
        progress = (0, estimatedTotal)
        groups = (0..<n).map { [$0] }
        phase = .comparing
        nextTournamentStep()
    }

    private func nextTournamentStep() {
        guard groups.count > 1 else {
            finalist = groups[0][0]
            finalistVictims = Array(groups[0].dropFirst())

            if finalistVictims.isEmpty { result = [finalist]; phase = .done; return }
            if finalistVictims.count == 1 { result = [finalist, finalistVictims[0]]; phase = .done; return }

            beginSearch(candidates: finalistVictims, onDone: finishSecondSearch)
            return
        }
        currentPair = Pair(left: groups[0][0], right: groups[1][0])
    }

    private func applyTournament(winner: Int, loser: Int) {
        let g0 = groups[0], g1 = groups[1]
        let winGroup  = (g0[0] == winner) ? g0 : g1
        let loseGroup = (g0[0] == winner) ? g1 : g0
        groups.removeFirst(2)
        groups.append(winGroup + loseGroup)
    }

    private func beginSearch(candidates: [Int], onDone: @escaping () -> Void) {
        searchLeader = candidates[0]
        searchQueue = Array(candidates.dropFirst())
        searchDone = onDone
        guard !searchQueue.isEmpty else { searchDone = nil; onDone(); return }
        currentPair = Pair(left: searchLeader, right: searchQueue.removeFirst())
    }

    private func nextSearchStep() {
        guard !searchQueue.isEmpty else { let done = searchDone; searchDone = nil; done?(); return }
        currentPair = Pair(left: searchLeader, right: searchQueue.removeFirst())
    }

    private func finishSecondSearch() {
        secondPlace = searchLeader
        let remaining = finalistVictims.filter { $0 != secondPlace }
        guard !remaining.isEmpty else { result = [finalist, secondPlace]; phase = .done; return }
        if remaining.count == 1 { result = [finalist, secondPlace, remaining[0]]; phase = .done; return }
        beginSearch(candidates: remaining, onDone: finishThirdSearch)
    }

    private func finishThirdSearch() {
        result = [finalist, secondPlace, searchLeader]
        phase = .done
    }
}
