import Foundation
#if canImport(HealthKit)
import HealthKit

/// Reads everything the System needs from Apple Health.
///
/// Because RingConn (sleep, resting HR, HRV, SpO₂, steps) and Eufy Life (body
/// mass, body-fat %, lean mass) both sync *into* Apple Health, this one source
/// transparently aggregates all of them alongside Apple Watch / iPhone data.
final class HealthKitSource: HealthSource {
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: Authorization

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [HKObjectType.workoutType()]
        let quantities: [HKQuantityTypeIdentifier] = [
            .stepCount, .activeEnergyBurned, .appleExerciseTime, .distanceWalkingRunning,
            .restingHeartRate, .heartRateVariabilitySDNN, .vo2Max, .oxygenSaturation,
            .bodyMass, .bodyFatPercentage, .leanBodyMass, .height,
            .dietaryWater, .dietaryCaffeine, .dietaryEnergyConsumed,
        ]
        quantities.compactMap { HKQuantityType.quantityType(forIdentifier: $0) }.forEach { types.insert($0) }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        if let sex = HKObjectType.characteristicType(forIdentifier: .biologicalSex) { types.insert(sex) }
        if let dob = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) { types.insert(dob) }
        return types
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            return true
        } catch {
            return false
        }
    }

    // MARK: Snapshot

    func snapshot() async -> HealthSnapshot {
        guard isAvailable else { return HealthSnapshot() }

        let cal = Calendar.current
        let now = Date()
        let startOfToday = cal.startOfDay(for: now)
        let start30 = cal.date(byAdding: .day, value: -30, to: startOfToday) ?? startOfToday

        var s = HealthSnapshot(date: now)

        // Today
        s.stepsToday = await sum(.stepCount, unit: .count(), from: startOfToday, to: now) ?? 0
        s.activeEnergyToday = await sum(.activeEnergyBurned, unit: .kilocalorie(), from: startOfToday, to: now) ?? 0
        s.exerciseMinutesToday = await sum(.appleExerciseTime, unit: .minute(), from: startOfToday, to: now) ?? 0
        s.strengthMinutesToday = await workoutMinutes(strengthActivities, from: startOfToday, to: now)
        s.sleepHoursLastNight = await sleepHoursLastNight()

        // 30-day rolling daily averages
        s.avgSteps = (await sum(.stepCount, unit: .count(), from: start30, to: startOfToday) ?? 0) / 30
        s.avgActiveEnergy = (await sum(.activeEnergyBurned, unit: .kilocalorie(), from: start30, to: startOfToday) ?? 0) / 30
        s.avgExerciseMinutes = (await sum(.appleExerciseTime, unit: .minute(), from: start30, to: startOfToday) ?? 0) / 30
        s.avgDistanceMeters = (await sum(.distanceWalkingRunning, unit: .meter(), from: start30, to: startOfToday) ?? 0) / 30
        s.avgStrengthMinutes = await workoutMinutes(strengthActivities, from: start30, to: startOfToday) / 30
        s.avgCardioMinutes = await workoutMinutes(cardioActivities, from: start30, to: startOfToday) / 30
        s.workoutStreakDays = await workoutStreak()

        // Latest physiological readings
        s.restingHeartRate = await latest(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        s.hrvSDNN = await latest(.heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli))
        s.vo2Max = await latest(.vo2Max, unit: HKUnit(from: "ml/kg*min"))
        s.spo2 = await latest(.oxygenSaturation, unit: .percent())
        s.bodyMassKg = await latest(.bodyMass, unit: .gramUnit(with: .kilo))
        s.bodyFatPercentage = await latest(.bodyFatPercentage, unit: .percent())
        s.leanBodyMassKg = await latest(.leanBodyMass, unit: .gramUnit(with: .kilo))

        // Average sleep over the window (best-effort, last 30 nights).
        s.avgSleepHours = await averageSleepHours(from: start30, to: now)

        return s
    }

    // MARK: Onboarding prefill

    func bodyPrefill() async -> BodyPrefill {
        guard isAvailable else { return BodyPrefill() }
        var prefill = BodyPrefill()

        // Characteristics are read synchronously and may throw if undisclosed.
        if let sexObj = try? store.biologicalSex() {
            switch sexObj.biologicalSex {
            case .male: prefill.sex = .male
            case .female: prefill.sex = .female
            case .other: prefill.sex = .other
            default: break
            }
        }
        if let dob = try? store.dateOfBirthComponents(), let date = dob.date {
            prefill.birthDate = date
        }
        prefill.heightCm = await latest(.height, unit: .meterUnit(with: .centi))
        prefill.weightKg = await latest(.bodyMass, unit: .gramUnit(with: .kilo))
        return prefill
    }

    // MARK: Workout activity groups

    private var strengthActivities: [HKWorkoutActivityType] {
        [.traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining]
    }
    private var cardioActivities: [HKWorkoutActivityType] {
        [.running, .cycling, .highIntensityIntervalTraining, .rowing, .swimming, .elliptical, .stairClimbing]
    }

    // MARK: Generic query helpers

    private func sum(_ id: HKQuantityTypeIdentifier, unit: HKUnit, from: Date, to: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        return await statistic(type, options: .cumulativeSum, from: from, to: to) { $0.sumQuantity()?.doubleValue(for: unit) }
    }

    private func latest(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        return await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else { return cont.resume(returning: nil) }
                cont.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    private func statistic(_ type: HKQuantityType, options: HKStatisticsOptions, from: Date, to: Date,
                           extract: @escaping (HKStatistics) -> Double?) async -> Double? {
        await withCheckedContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: .strictStartDate)
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: options) { _, stats, _ in
                cont.resume(returning: stats.flatMap(extract))
            }
            store.execute(q)
        }
    }

    private func workoutMinutes(_ activities: [HKWorkoutActivityType], from: Date, to: Date) async -> Double {
        await withCheckedContinuation { cont in
            let datePredicate = HKQuery.predicateForSamples(withStart: from, end: to, options: .strictStartDate)
            let activityPredicates = activities.map { HKQuery.predicateForWorkouts(with: $0) }
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                datePredicate, NSCompoundPredicate(orPredicateWithSubpredicates: activityPredicates),
            ])
            let q = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let minutes = (samples as? [HKWorkout] ?? []).reduce(0.0) { $0 + $1.duration / 60.0 }
                cont.resume(returning: minutes)
            }
            store.execute(q)
        }
    }

    /// Consecutive days (ending today or yesterday) with any workout logged.
    private func workoutStreak() async -> Int {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(byAdding: .day, value: -45, to: cal.startOfDay(for: now)) ?? now
        let workouts: [HKWorkout] = await withCheckedContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)
            let q = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                cont.resume(returning: samples as? [HKWorkout] ?? [])
            }
            store.execute(q)
        }
        let days = Set(workouts.map { cal.startOfDay(for: $0.startDate) })
        var streak = 0
        var cursor = cal.startOfDay(for: now)
        // Allow today to be empty (still mid-day) without breaking the streak.
        if !days.contains(cursor) { cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor }
        while days.contains(cursor) {
            streak += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return streak
    }

    // MARK: Sleep

    private func sleepHoursLastNight() async -> Double? {
        let cal = Calendar.current
        let now = Date()
        // Window: 6pm yesterday → noon today captures a normal night.
        let noonToday = cal.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
        let start = cal.date(byAdding: .hour, value: -18, to: noonToday) ?? now
        let hours = await asleepHours(from: start, to: noonToday)
        return hours > 0 ? hours : nil
    }

    private func averageSleepHours(from: Date, to: Date) async -> Double {
        // Crude: total asleep time over window / number of nights.
        let total = await asleepHours(from: from, to: to)
        let nights = max(1, Calendar.current.dateComponents([.day], from: from, to: to).day ?? 1)
        return total / Double(nights)
    }

    private func asleepHours(from: Date, to: Date) async -> Double {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        return await withCheckedContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: from, end: to, options: [])
            let q = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                ]
                let seconds = (samples as? [HKCategorySample] ?? [])
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                cont.resume(returning: seconds / 3600.0)
            }
            store.execute(q)
        }
    }
}
#endif
