import Foundation

// S2-03 — Curriculum JSON decode + fallback tests (11 cases)
// Story: production/epics/epic-persistence-tests/story-003-curriculum-tests.md

@MainActor
func curriculumTests(into runner: TestRunner) {
    print("Curriculum tests:")

    runner.add("loadsAllFiftyLevels") {
        XCTestCase.XCTAssertEqual(Curriculum.levels.count, 50,
                                   "Curriculum.levels should contain 50 entries")
    }

    runner.add("levelsInMath") {
        XCTestCase.XCTAssertEqual(Curriculum.levels(in: .math).count, 25,
                                   "Math area should have 25 levels")
    }

    runner.add("levelsInEnglish") {
        XCTestCase.XCTAssertEqual(Curriculum.levels(in: .english).count, 15,
                                   "English area should have 15 levels")
    }

    runner.add("levelsInLifeSkills") {
        XCTestCase.XCTAssertEqual(Curriculum.levels(in: .lifeSkills).count, 10,
                                   "Life Skills area should have 10 levels")
    }

    runner.add("firstLevelIsM01") {
        XCTestCase.XCTAssertEqual(Curriculum.levels.first?.id, "M01",
                                   "first level should be M01")
    }

    runner.add("levelsHaveUniqueIds") {
        let ids = Curriculum.levels.map { $0.id }
        let uniqueIds = Set(ids)
        if ids.count == uniqueIds.count { return .pass }
        return .fail("duplicate level ids found")
    }

    runner.add("difficultyInRange") {
        for lv in Curriculum.levels {
            if lv.difficulty < 1 || lv.difficulty > 5 {
                return .fail("level \(lv.id) has difficulty \(lv.difficulty), out of [1,5]")
            }
        }
        return .pass
    }

    runner.add("vocabularyNonEmpty") {
        for lv in Curriculum.levels {
            if lv.vocabulary.isEmpty {
                return .fail("level \(lv.id) has empty vocabulary")
            }
            for word in lv.vocabulary {
                if word.isEmpty {
                    return .fail("level \(lv.id) has empty word in vocabulary")
                }
            }
        }
        return .pass
    }

    runner.add("everyAreaIsValid") {
        for lv in Curriculum.levels {
            switch lv.area {
            case .math, .english, .lifeSkills: continue
            }
        }
        return .pass
    }

    runner.add("sceneKindsUniqueWithinArea") {
        var seenKinds: [String: Int] = [:]
        for lv in Curriculum.levels {
            seenKinds[String(describing: lv.scene), default: 0] += 1
        }
        for (kind, count) in seenKinds where count > 1 {
            return .fail("scene kind \(kind) appears \(count) times in the curriculum")
        }
        return .pass
    }

    runner.add("areasHaveDistinctSceneKinds") {
        let mathLevels = Curriculum.levels(in: .math).map { String(describing: $0.scene) }
        let engLevels = Curriculum.levels(in: .english).map { String(describing: $0.scene) }
        let lifeLevels = Curriculum.levels(in: .lifeSkills).map { String(describing: $0.scene) }
        let overlapME = Set(mathLevels).intersection(Set(engLevels))
        if !overlapME.isEmpty { return .fail("shared Math↔English: \(overlapME)") }
        let overlapML = Set(mathLevels).intersection(Set(lifeLevels))
        if !overlapML.isEmpty { return .fail("shared Math↔Life: \(overlapML)") }
        let overlapEL = Set(engLevels).intersection(Set(lifeLevels))
        if !overlapEL.isEmpty { return .fail("shared English↔Life: \(overlapEL)") }
        return .pass
    }
}
