import Foundation
import HealthKit

enum SyncError: Error, LocalizedError {
    case notConfigured
    case noHealthKit
    case nightscoutError(Error)
    case healthKitError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Nightscout is not configured"
        case .noHealthKit:
            return "HealthKit is not available"
        case .nightscoutError(let error):
            return "Nightscout error: \(error.localizedDescription)"
        case .healthKitError(let error):
            return "HealthKit error: \(error.localizedDescription)"
        }
    }
}

struct SyncResult {
    var treatmentsProcessed: Int = 0
    var treatmentsSynced: Int = 0
    var glucoseProcessed: Int = 0
    var glucoseSynced: Int = 0
    var insulinSynced: Int = 0
    var carbsSynced: Int = 0
    // Items found on Nightscout not yet in HealthKit at time of this sync
    var pendingGlucose: Int = 0
    var pendingInsulin: Int = 0
    var pendingCarbs: Int = 0
    var errors: [String] = []
}

actor SyncService {
    static let shared = SyncService()
    
    private init() {}
    
    func syncAll() async throws -> SyncResult {
        guard let healthKit = HealthKitService.shared else {
            throw SyncError.noHealthKit
        }

        let settings = UserSettings.shared
        guard await settings.nightscoutURL != nil, await settings.nightscoutAPISecret != nil else {
            throw SyncError.notConfigured
        }

        var result = SyncResult()

        let lookbackDays = await settings.lookbackDays
        let since = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: Date()) ?? Date.distantPast
        let now = Date()

        let doCarbs = await settings.syncCarbs
        let doInsulin = await settings.syncInsulin
        let doGlucose = await settings.syncGlucose

        do {
            let nightscout = try await NightscoutService.shared

            if doCarbs || doInsulin {
                // Fetch existing HealthKit samples for the lookback window
                let existingCarbDates = doCarbs ? await healthKit.existingCarbsDates(from: since, to: now) : []
                let existingInsulinDates = doInsulin ? await healthKit.existingInsulinDates(from: since, to: now) : []

                let treatments = try await nightscout.fetchTreatments(since: since)
                result.treatmentsProcessed = treatments.count

                for treatment in treatments {
                    guard let date = treatment.treatmentDate else { continue }

                    if doCarbs, let carbs = treatment.carbs, carbs > 0 {
                        result.pendingCarbs += 1
                        if !healthKit.isDateAlreadySynced(date, in: existingCarbDates) {
                            do {
                                try await healthKit.saveCarbohydrates(grams: carbs, date: date)
                                result.carbsSynced += 1
                                result.treatmentsSynced += 1
                            } catch {
                                result.errors.append("Failed to save carbs: \(error.localizedDescription)")
                            }
                        }
                    }

                    if doInsulin, let insulin = treatment.insulin, insulin > 0 {
                        result.pendingInsulin += 1
                        if !healthKit.isDateAlreadySynced(date, in: existingInsulinDates) {
                            let isBasal = treatment.eventType?.lowercased().contains("basal") ?? false
                            do {
                                try await healthKit.saveInsulin(units: insulin, date: date, isBasal: isBasal)
                                result.insulinSynced += 1
                                result.treatmentsSynced += 1
                            } catch {
                                result.errors.append("Failed to save insulin: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }

            if doGlucose {
                let existingGlucoseDates = await healthKit.existingGlucoseDates(from: since, to: now)
                let glucoseEntries = try await nightscout.fetchGlucoseEntries(since: since)
                result.glucoseProcessed = glucoseEntries.count

                let unit = await settings.glucoseUnit

                for entry in glucoseEntries {
                    result.pendingGlucose += 1
                    if healthKit.isDateAlreadySynced(entry.timestamp, in: existingGlucoseDates) { continue }

                    let value: Double
                    let hkUnit: HKUnit

                    switch unit {
                    case .mgdl:
                        value = entry.mgDlValue
                        hkUnit = HKUnit(from: "mg/dL")
                    case .mmol:
                        value = entry.mmolValue
                        hkUnit = HKUnit(from: "mmol/L")
                    }

                    do {
                        try await healthKit.saveBloodGlucose(value: value, unit: hkUnit, date: entry.timestamp)
                        result.glucoseSynced += 1
                    } catch {
                        result.errors.append("Failed to save glucose: \(error.localizedDescription)")
                    }
                }
            }

            await settings.setLastSyncDate(now)
            let log = SyncLog(
                date: now,
                pendingGlucose: result.pendingGlucose,
                pendingInsulin: result.pendingInsulin,
                pendingCarbs: result.pendingCarbs,
                glucoseSynced: result.glucoseSynced,
                insulinSynced: result.insulinSynced,
                carbsSynced: result.carbsSynced,
                errors: result.errors
            )
            await settings.appendSyncLog(log)

        } catch let error as NightscoutError {
            throw SyncError.nightscoutError(error)
        } catch let error as HealthKitError {
            throw SyncError.healthKitError(error)
        }

        return result
    }
    
    func testConnection() async throws -> Bool {
        let nightscout = try await NightscoutService.shared
        return try await nightscout.testConnection()
    }
    
    func getLastSyncDate() async -> Date? {
        return await UserSettings.shared.lastSyncDate
    }
}
