package com.virgax.arise.health

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.aggregate.AggregateMetric
import androidx.health.connect.client.aggregate.AggregationResult
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.DistanceRecord
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.RestingHeartRateRecord
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.WeightRecord
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import com.virgax.arise.domain.HealthSnapshot
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.ChronoUnit

/**
 * Reads real fitness data from Health Connect — the Android hub that Google Fit,
 * Samsung Health, Fitbit and rings (RingConn) sync into — and maps it onto the
 * source-agnostic [HealthSnapshot] the System engine already consumes.
 */
class HealthConnectManager(private val context: Context) {

    val permissions: Set<String> = setOf(
        HealthPermission.getReadPermission(StepsRecord::class),
        HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class),
        HealthPermission.getReadPermission(ExerciseSessionRecord::class),
        HealthPermission.getReadPermission(DistanceRecord::class),
        HealthPermission.getReadPermission(SleepSessionRecord::class),
        HealthPermission.getReadPermission(RestingHeartRateRecord::class),
        HealthPermission.getReadPermission(WeightRecord::class),
    )

    fun status(): Int = HealthConnectClient.getSdkStatus(context)
    val isAvailable: Boolean get() = status() == HealthConnectClient.SDK_AVAILABLE
    val needsProviderUpdate: Boolean get() = status() == HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED

    private val client: HealthConnectClient get() = HealthConnectClient.getOrCreate(context)

    suspend fun hasPermissions(): Boolean =
        runCatching { client.permissionController.getGrantedPermissions().containsAll(permissions) }
            .getOrDefault(false)

    suspend fun readSnapshot(): HealthSnapshot {
        val zone = ZoneId.systemDefault()
        val now = Instant.now()
        val startToday = LocalDate.now(zone).atStartOfDay(zone).toInstant()
        val start7 = startToday.minus(7, ChronoUnit.DAYS)
        val lastNight = LocalDate.now(zone).minusDays(1).atTime(18, 0).atZone(zone).toInstant()

        val today = aggregate(
            setOf(
                StepsRecord.COUNT_TOTAL,
                ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL,
                ExerciseSessionRecord.EXERCISE_DURATION_TOTAL,
            ),
            startToday, now,
        )
        val week = aggregate(
            setOf(
                StepsRecord.COUNT_TOTAL,
                ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL,
                ExerciseSessionRecord.EXERCISE_DURATION_TOTAL,
                DistanceRecord.DISTANCE_TOTAL,
                SleepSessionRecord.SLEEP_DURATION_TOTAL,
            ),
            start7, now,
        )
        val sleepNight = aggregate(setOf(SleepSessionRecord.SLEEP_DURATION_TOTAL), lastNight, now)

        fun kcal(r: AggregationResult?, m: AggregateMetric<androidx.health.connect.client.units.Energy>) =
            r?.get(m)?.inKilocalories ?: 0.0
        fun minutes(r: AggregationResult?, m: AggregateMetric<java.time.Duration>) =
            r?.get(m)?.toMinutes()?.toDouble() ?: 0.0

        return HealthSnapshot(
            stepsToday = today?.get(StepsRecord.COUNT_TOTAL)?.toDouble() ?: 0.0,
            activeEnergyToday = kcal(today, ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL),
            exerciseMinutesToday = minutes(today, ExerciseSessionRecord.EXERCISE_DURATION_TOTAL),
            strengthMinutesToday = 0.0,
            sleepHoursLastNight = sleepNight?.get(SleepSessionRecord.SLEEP_DURATION_TOTAL)?.toMinutes()?.div(60.0),
            avgSteps = (week?.get(StepsRecord.COUNT_TOTAL)?.toDouble() ?: 0.0) / 7.0,
            avgActiveEnergy = kcal(week, ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL) / 7.0,
            avgExerciseMinutes = minutes(week, ExerciseSessionRecord.EXERCISE_DURATION_TOTAL) / 7.0,
            avgCardioMinutes = minutes(week, ExerciseSessionRecord.EXERCISE_DURATION_TOTAL) / 7.0,
            avgDistanceMeters = (week?.get(DistanceRecord.DISTANCE_TOTAL)?.inMeters ?: 0.0) / 7.0,
            avgSleepHours = (week?.get(SleepSessionRecord.SLEEP_DURATION_TOTAL)?.toMinutes()?.div(60.0) ?: 0.0) / 7.0,
            restingHeartRate = latestRestingHr(start7, now),
            bodyMassKg = latestWeight(start7, now),
        )
    }

    private suspend fun aggregate(metrics: Set<AggregateMetric<*>>, start: Instant, end: Instant): AggregationResult? =
        runCatching { client.aggregate(AggregateRequest(metrics, TimeRangeFilter.between(start, end))) }.getOrNull()

    private suspend fun latestRestingHr(start: Instant, end: Instant): Double? = runCatching {
        client.readRecords(ReadRecordsRequest(RestingHeartRateRecord::class, TimeRangeFilter.between(start, end)))
            .records.maxByOrNull { it.time }?.beatsPerMinute?.toDouble()
    }.getOrNull()

    private suspend fun latestWeight(start: Instant, end: Instant): Double? = runCatching {
        client.readRecords(ReadRecordsRequest(WeightRecord::class, TimeRangeFilter.between(start, end)))
            .records.maxByOrNull { it.time }?.weight?.inKilograms
    }.getOrNull()
}
