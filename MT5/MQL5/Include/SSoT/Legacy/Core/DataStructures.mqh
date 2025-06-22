//+------------------------------------------------------------------+
//| SSoT Core Data Structures                                        |
//| Foundation classes for Chain of Trust system                    |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "3.00"

#ifndef SSOT_DATA_STRUCTURES_MQH
#define SSOT_DATA_STRUCTURES_MQH

#ifndef SSOT_DATA_STRUCTURES_MQH
#define SSOT_DATA_STRUCTURES_MQH

//+------------------------------------------------------------------+
#define SSOT_DATA_STRUCTURES_MQH

//+------------------------------------------------------------------+
//| Candle Data Structure with Chain of Trust metadata              |
//+------------------------------------------------------------------+
struct CandleRecord
{
    // Core OHLCV data
    datetime    timestamp;
    double      open;
    double      high;
    double      low;
    double      close;
    long        volume;
    long        tick_volume;
    int         spread;
    
    // Chain of Trust metadata
    string      hash;               // SHA-256 hash of OHLCV data
    bool        is_validated;       // Content matches broker SSoT
    bool        is_complete;        // Chain integrity verified
    datetime    created_at;         // Local record creation time
    datetime    validated_at;       // Last validation timestamp
    
    // Position in chain
    long        chain_position;     // Sequential position in database
    string      prev_hash;          // Hash of previous candle (blockchain-style)
    
    // Metadata
    string      symbol;
    ENUM_TIMEFRAMES timeframe;
    
    // Validation state
    int         validation_attempts;
    datetime    last_validation_attempt;
};

//+------------------------------------------------------------------+
//| Database Configuration Structure                                 |
//+------------------------------------------------------------------+
struct DatabaseConfig
{
    string      database_name;
    string      table_prefix;
    bool        enable_wal_mode;
    bool        enable_foreign_keys;
    int         cache_size_mb;
    int         timeout_ms;
    bool        auto_vacuum;
    
    // Connection pooling
    int         max_connections;
    int         connection_timeout;
    
    // Performance settings
    int         batch_size;
    bool        use_transactions;
    int         transaction_size;
};

//+------------------------------------------------------------------+
//| Chain Validation Result                                         |
//+------------------------------------------------------------------+
struct ChainValidationResult
{
    bool        is_valid;
    long        first_invalid_position;
    string      error_message;
    int         total_records_checked;
    int         invalid_records_found;
    datetime    validation_timestamp;
    double      validation_duration_ms;
};

//+------------------------------------------------------------------+
//| Performance Metrics Structure                                   |
//+------------------------------------------------------------------+
struct PerformanceMetrics
{
    // Throughput metrics
    double      records_per_second;
    double      validations_per_second;
    double      hash_calculations_per_second;
    
    // Database performance
    double      db_insert_avg_ms;
    double      db_select_avg_ms;
    double      db_update_avg_ms;
    
    // Memory usage
    long        memory_usage_bytes;
    long        peak_memory_bytes;
    
    // Error rates
    double      error_rate_percent;
    int         total_operations;
    int         failed_operations;
    
    // Session tracking
    datetime    session_start;
    datetime    last_update;
    long        uptime_seconds;
};

//+------------------------------------------------------------------+
//| System Status Enumeration                                       |
//+------------------------------------------------------------------+
enum ENUM_SSOT_STATUS
{
    SSOT_STATUS_INITIALIZING,
    SSOT_STATUS_RUNNING,
    SSOT_STATUS_VALIDATING,
    SSOT_STATUS_BACKFILLING,
    SSOT_STATUS_MAINTENANCE,
    SSOT_STATUS_ERROR,
    SSOT_STATUS_STOPPED,
    SSOT_STATUS_TEST_MODE
};

//+------------------------------------------------------------------+
//| Operation Result Structure                                       |
//+------------------------------------------------------------------+
struct OperationResult
{
    bool        success;
    string      error_message;
    int         error_code;
    long        affected_records;
    double      execution_time_ms;
    datetime    timestamp;
};

//+------------------------------------------------------------------+
//| Test Mode Configuration                                          |
//+------------------------------------------------------------------+
struct TestModeConfig
{
    bool        enabled;
    string      input_database;     // Simulated broker database
    string      output_database;    // Our Chain of Trust database
    bool        verbose_logging;
    bool        performance_tracking;
    bool        auto_validation;
    int         test_data_size;
    datetime    test_start_time;
    datetime    test_end_time;
};

//+------------------------------------------------------------------+
//| Gap Detection Result                                             |
//+------------------------------------------------------------------+
struct GapDetectionResult
{
    bool        gaps_found;
    int         gap_count;
    datetime    gap_start_times[];
    datetime    gap_end_times[];
    int         missing_records_count;
    string      symbol;
    ENUM_TIMEFRAMES timeframe;
};

#endif // SSOT_DATA_STRUCTURES_MQH
