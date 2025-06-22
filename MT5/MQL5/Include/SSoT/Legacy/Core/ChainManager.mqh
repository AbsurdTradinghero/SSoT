//+------------------------------------------------------------------+
//| SSoT Chain Manager                                               |
//| Chain of Trust validation and integrity management              |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "3.00"

#ifndef SSOT_CHAIN_MANAGER_MQH
#define SSOT_CHAIN_MANAGER_MQH

#include "DataStructures.mqh"
#include "DatabaseEngine.mqh"
#include "HashEngine.mqh"

//+------------------------------------------------------------------+
//| Chain Validator                                                 |
//| Single Responsibility: Validate chain integrity rules           |
//+------------------------------------------------------------------+
class CChainValidator
{
private:
    CHashEngine*        m_hash_engine;
    bool               m_own_hash_engine;
    
    // Validation rules
    bool               m_enforce_sequential_timestamps;
    bool               m_enforce_hash_chain;
    bool               m_allow_duplicate_timestamps;
    
    // Performance tracking
    int                m_validations_performed;
    int                m_chain_breaks_found;
    double             m_total_validation_time;
    
public:
                       CChainValidator(CHashEngine* hash_engine = NULL);
                      ~CChainValidator(void);
    
    // Single candle validation
    bool               ValidateContentIntegrity(CandleRecord &candle);
    bool               ValidateChainPosition(const CandleRecord &candle, const CandleRecord &previous);
    bool               ValidateTimestampSequence(const CandleRecord &candle, const CandleRecord &previous);
    
    // Chain segment validation
    ChainValidationResult ValidateChainSegment(CandleRecord &candles[], int start_index, int count);
    ChainValidationResult ValidateEntireChain(CandleRecord &candles[], int count);
    
    // Gap and break detection
    bool               DetectChainBreaks(const CandleRecord &candles[], int count,
                                       long &break_positions[], int max_breaks = 100);
    bool               DetectTimestampGaps(const CandleRecord &candles[], int count,
                                         datetime &gap_starts[], datetime &gap_ends[], int max_gaps = 100);
    
    // Validation rules configuration
    void               SetEnforceSequentialTimestamps(bool enforce) { m_enforce_sequential_timestamps = enforce; }
    void               SetEnforceHashChain(bool enforce) { m_enforce_hash_chain = enforce; }
    void               SetAllowDuplicateTimestamps(bool allow) { m_allow_duplicate_timestamps = allow; }
    
    bool               GetEnforceSequentialTimestamps(void) const { return m_enforce_sequential_timestamps; }
    bool               GetEnforceHashChain(void) const { return m_enforce_hash_chain; }
    bool               GetAllowDuplicateTimestamps(void) const { return m_allow_duplicate_timestamps; }
    
    // Performance metrics
    struct ValidationMetrics
    {
        int            validations_performed;
        int            chain_breaks_found;
        double         average_validation_time_ms;
        double         success_rate;
        datetime       last_validation;
    };
    
    ValidationMetrics  GetValidationMetrics(void);
    void               ResetValidationMetrics(void);
    
private:
    bool               ValidateTimestampLogic(datetime current, datetime previous, ENUM_TIMEFRAMES timeframe);
    bool               ValidateHashLink(const CandleRecord &current, const CandleRecord &previous);
    void               UpdateValidationStats(bool success, double time_ms);
    datetime           CalculateExpectedNextTimestamp(datetime current, ENUM_TIMEFRAMES timeframe);
};

//+------------------------------------------------------------------+
//| Chain Repairer                                                  |
//| Single Responsibility: Repair broken chain segments             |
//+------------------------------------------------------------------+
class CChainRepairer
{
private:
    CDatabaseEngine*   m_database;
    CHashEngine*       m_hash_engine;
    bool              m_own_components;
    
    // Repair statistics
    int               m_repairs_attempted;
    int               m_repairs_successful;
    int               m_candles_repaired;
    
public:
                      CChainRepairer(CDatabaseEngine* database = NULL, CHashEngine* hash_engine = NULL);
                     ~CChainRepairer(void);
    
    // Chain repair operations
    bool              RepairChainBreak(const string symbol, ENUM_TIMEFRAMES timeframe,
                                     long break_position);
    bool              RepairChainSegment(const string symbol, ENUM_TIMEFRAMES timeframe,
                                       long start_position, long end_position);
    bool              RepairEntireChain(const string symbol, ENUM_TIMEFRAMES timeframe);
    
    // Hash recalculation
    bool              RecalculateChainHashes(CandleRecord &candles[], int count);
    bool              RecalculateFromPosition(const string symbol, ENUM_TIMEFRAMES timeframe,
                                            long start_position);
    
    // Data restoration
    bool              RestoreFromBroker(const string symbol, ENUM_TIMEFRAMES timeframe,
                                      datetime start_time, datetime end_time);
    bool              RestoreMissingCandles(const string symbol, ENUM_TIMEFRAMES timeframe,
                                          const datetime missing_times[], int count);
    
    // Validation state repair
    bool              ResetValidationFlags(const string symbol, ENUM_TIMEFRAMES timeframe,
                                         long start_position, long end_position);
    bool              RevalidateChainSegment(const string symbol, ENUM_TIMEFRAMES timeframe,
                                           long start_position, long end_position);
    
    // Repair reporting
    struct RepairReport
    {
        int           repairs_attempted;
        int           repairs_successful;
        int           candles_repaired;
        int           candles_revalidated;
        double        repair_success_rate;
        double        total_repair_time_ms;
        datetime      repair_timestamp;
    };
    
    RepairReport      GetRepairReport(void);
    void              ResetRepairStats(void);
    
private:
    bool              FetchBrokerDataRange(const string symbol, ENUM_TIMEFRAMES timeframe,
                                         datetime start_time, datetime end_time,
                                         MqlRates &broker_data[]);
    bool              ConvertBrokerDataToCandles(const MqlRates &broker_data[], int count,
                                               CandleRecord &candles[], const string symbol,
                                               ENUM_TIMEFRAMES timeframe);
    void              UpdateRepairStats(bool success);
};

//+------------------------------------------------------------------+
//| Chain Maintenance Engine                                        |
//| Single Responsibility: Automated chain maintenance and healing  |
//+------------------------------------------------------------------+
class CChainMaintenance
{
private:
    CDatabaseEngine*   m_database;
    CChainValidator*   m_validator;
    CChainRepairer*    m_repairer;
    bool              m_own_components;
    
    // Maintenance configuration
    bool              m_auto_repair_enabled;
    bool              m_continuous_validation;
    int               m_validation_batch_size;
    int               m_maintenance_interval_ms;
    datetime          m_last_maintenance;
    
    // Maintenance state
    bool              m_maintenance_running;
    ENUM_SSOT_STATUS  m_current_status;
    string            m_current_symbol;
    ENUM_TIMEFRAMES   m_current_timeframe;
    
public:
                      CChainMaintenance(CDatabaseEngine* database = NULL,
                                       CChainValidator* validator = NULL,
                                       CChainRepairer* repairer = NULL);
                     ~CChainMaintenance(void);
    
    // Maintenance operations
    bool              StartMaintenance(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool              StopMaintenance(void);
    bool              RunMaintenanceCycle(void);
    
    // Automated validation
    bool              ValidateUnvalidatedCandles(const string symbol, ENUM_TIMEFRAMES timeframe,
                                                int max_candles = 100);
    bool              CompleteIncompleteCandles(const string symbol, ENUM_TIMEFRAMES timeframe,
                                              int max_candles = 100);
    
    // Gap detection and repair
    GapDetectionResult DetectAndRepairGaps(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool              BackfillMissingData(const string symbol, ENUM_TIMEFRAMES timeframe,
                                        datetime start_time, datetime end_time);
    
    // Health monitoring
    struct ChainHealth
    {
        double        completion_percentage;
        double        validation_percentage;
        long          total_records;
        long          validated_records;
        long          completed_records;
        long          broken_chain_segments;
        long          missing_candles;
        datetime      oldest_record;
        datetime      newest_record;
        datetime      health_check_time;
    };
    
    ChainHealth       GetChainHealth(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool              IsChainHealthy(const string symbol, ENUM_TIMEFRAMES timeframe,
                                   double min_completion_rate = 0.95);
    
    // Maintenance configuration
    void              SetAutoRepairEnabled(bool enabled) { m_auto_repair_enabled = enabled; }
    void              SetContinuousValidation(bool enabled) { m_continuous_validation = enabled; }
    void              SetValidationBatchSize(int size) { m_validation_batch_size = size; }
    void              SetMaintenanceInterval(int interval_ms) { m_maintenance_interval_ms = interval_ms; }
    
    bool              GetAutoRepairEnabled(void) const { return m_auto_repair_enabled; }
    bool              GetContinuousValidation(void) const { return m_continuous_validation; }
    int               GetValidationBatchSize(void) const { return m_validation_batch_size; }
    int               GetMaintenanceInterval(void) const { return m_maintenance_interval_ms; }
    
    // Status monitoring
    ENUM_SSOT_STATUS  GetMaintenanceStatus(void) const { return m_current_status; }
    bool              IsMaintenanceRunning(void) const { return m_maintenance_running; }
    datetime          GetLastMaintenanceTime(void) const { return m_last_maintenance; }
    
private:
    bool              CreateComponents(void);
    void              DestroyComponents(void);
    bool              ProcessValidationBatch(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool              ProcessCompletionBatch(const string symbol, ENUM_TIMEFRAMES timeframe);
    void              UpdateMaintenanceStatus(ENUM_SSOT_STATUS status);
};

//+------------------------------------------------------------------+
//| Chain Manager - Main Coordinator                               |
//| Single Responsibility: Coordinate all chain management         |
//+------------------------------------------------------------------+
class CChainManager
{
private:
    CDatabaseEngine*    m_database;
    CHashEngine*        m_hash_engine;
    CChainValidator*    m_validator;
    CChainRepairer*     m_repairer;
    CChainMaintenance*  m_maintenance;
    
    bool               m_initialized;
    bool               m_own_components;
    
    // Configuration
    string             m_current_symbol;
    ENUM_TIMEFRAMES    m_current_timeframe;
    bool               m_auto_maintenance;
    
public:
                       CChainManager(void);
                      ~CChainManager(void);
    
    // Initialization
    bool               Initialize(CDatabaseEngine* database, CHashEngine* hash_engine,
                                const string symbol, ENUM_TIMEFRAMES timeframe);
    bool               Shutdown(void);
    bool               IsInitialized(void) const { return m_initialized; }
    
    // High-level chain operations
    bool               ValidateNewCandle(CandleRecord &candle);
    bool               InsertCandleToChain(CandleRecord &candle);
    bool               UpdateCandleValidation(long position, bool is_validated, bool is_complete);
    
    // Chain integrity operations
    ChainValidationResult ValidateChainIntegrity(void);
    bool               RepairChainIntegrity(void);
    GapDetectionResult DetectGaps(void);
    bool               FillGaps(void);
    
    // Real-time operations
    bool               ProcessNewCandleFromBroker(const MqlRates &broker_candle);
    bool               SynchronizeWithBroker(datetime start_time, datetime end_time);
    bool               StartRealTimeMonitoring(void);
    bool               StopRealTimeMonitoring(void);
    
    // Maintenance operations
    bool               StartAutomaticMaintenance(void);
    bool               StopAutomaticMaintenance(void);
    bool               RunManualMaintenance(void);
    
    // Status and reporting
    CChainMaintenance::ChainHealth GetChainHealth(void);
    PerformanceMetrics GetPerformanceMetrics(void);
    
    struct ChainStatus
    {
        ENUM_SSOT_STATUS current_status;
        string          current_operation;
        double          progress_percentage;
        datetime        last_update;
        long            total_records;
        long            validated_records;
        long            completed_records;
        bool            chain_healthy;
        bool            maintenance_running;
    };
    
    ChainStatus        GetChainStatus(void);
    
    // Configuration
    void               SetAutoMaintenance(bool enabled) { m_auto_maintenance = enabled; }
    bool               GetAutoMaintenance(void) const { return m_auto_maintenance; }
    
    string             GetCurrentSymbol(void) const { return m_current_symbol; }
    ENUM_TIMEFRAMES    GetCurrentTimeframe(void) const { return m_current_timeframe; }
    
    // Component access (for advanced usage)
    CChainValidator*   GetValidator(void) { return m_validator; }
    CChainRepairer*    GetRepairer(void) { return m_repairer; }
    CChainMaintenance* GetMaintenance(void) { return m_maintenance; }
    
private:
    bool               CreateComponents(void);
    void               DestroyComponents(void);
    bool               ValidateConfiguration(void);
    CandleRecord       ConvertBrokerCandle(const MqlRates &broker_candle);
};

//+------------------------------------------------------------------+
//| Implementation: CChainValidator                                 |
//+------------------------------------------------------------------+
CChainValidator::CChainValidator(CHashEngine* hash_engine) :
    m_hash_engine(hash_engine),
    m_own_hash_engine(false),
    m_enforce_sequential_timestamps(true),
    m_enforce_hash_chain(true),
    m_allow_duplicate_timestamps(false),
    m_validations_performed(0),
    m_chain_breaks_found(0),
    m_total_validation_time(0.0)
{
    if(m_hash_engine == NULL)
    {
        m_hash_engine = new CHashEngine();
        m_hash_engine.Initialize();
        m_own_hash_engine = true;
    }
}

CChainValidator::~CChainValidator(void)
{
    if(m_own_hash_engine && m_hash_engine != NULL)
    {
        m_hash_engine.Shutdown();
        delete m_hash_engine;
    }
}

bool CChainValidator::ValidateContentIntegrity(CandleRecord &candle)
{
    uint start_tick = GetTickCount();
    
    // Validate hash
    bool hash_valid = m_hash_engine.ValidateCandle(candle);
    
    // Update validation flag
    candle.is_validated = hash_valid;
    candle.validated_at = TimeCurrent();
    candle.validation_attempts++;
    
    double elapsed = (double)(GetTickCount() - start_tick);
    UpdateValidationStats(hash_valid, elapsed);
    
    return hash_valid;
}

bool CChainValidator::ValidateChainPosition(const CandleRecord &candle, const CandleRecord &previous)
{
    if(!m_enforce_hash_chain)
        return true;
    
    // Check if previous hash matches
    if(StringCompare(candle.prev_hash, previous.hash, false) != 0)
        return false;
    
    // Validate timestamp sequence
    if(m_enforce_sequential_timestamps)
        return ValidateTimestampSequence(candle, previous);
    
    return true;
}

bool CChainValidator::ValidateTimestampSequence(const CandleRecord &candle, const CandleRecord &previous)
{
    // Check for valid progression
    datetime expected_next = CalculateExpectedNextTimestamp(previous.timestamp, candle.timeframe);
    
    if(!m_allow_duplicate_timestamps && candle.timestamp == previous.timestamp)
        return false;
    
    if(candle.timestamp < previous.timestamp)
        return false;
    
    return (candle.timestamp == expected_next);
}

datetime CChainValidator::CalculateExpectedNextTimestamp(datetime current, ENUM_TIMEFRAMES timeframe)
{
    switch(timeframe)
    {
        case PERIOD_M1:  return current + 60;
        case PERIOD_M5:  return current + 300;
        case PERIOD_M15: return current + 900;
        case PERIOD_M30: return current + 1800;
        case PERIOD_H1:  return current + 3600;
        case PERIOD_H4:  return current + 14400;
        case PERIOD_D1:  return current + 86400;
        case PERIOD_W1:  return current + 604800;
        case PERIOD_MN1: return current + 2592000; // Approximate
        default:         return current + 60;
    }
}

void CChainValidator::UpdateValidationStats(bool success, double time_ms)
{
    m_validations_performed++;
    m_total_validation_time += time_ms;
    
    if(!success)
        m_chain_breaks_found++;
}

#endif // SSOT_CHAIN_MANAGER_MQH
