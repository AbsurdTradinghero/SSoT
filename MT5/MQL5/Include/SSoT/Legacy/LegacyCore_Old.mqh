//+------------------------------------------------------------------+
//| LegacyCore.mqh                                                   |
//| Core functions extracted from proven SSoT_legacy.mq5            |
//| All functions work with database handles as in legacy           |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"

#ifndef SSOT_LEGACY_CORE_MQH
#define SSOT_LEGACY_CORE_MQH

// Include proven modular components from legacy EA
#include <DbUtils.mqh>
#include <HashUtils.mqh>
#include <Logger.mqh>

//+------------------------------------------------------------------+
//| Legacy Core Class - Contains all proven functions               |
//| Functions take database handles as parameters like legacy EA    |
//+------------------------------------------------------------------+
class CLegacyCore
{
public:
    //=== DATA STORAGE GROUP - Core proven functions ===
    static bool StoreBarOptimized(int db_handle, string symbol, string timeframe, datetime time,
                                 double open, double high, double low, double close,
                                 long tick_volume, long real_volume);
    
    static int BatchInsertOptimized(int db_handle, string symbol, string timeframe, 
                                   MqlRates &rates[], int count);
    
    //=== UTILITY GROUP - String/timeframe conversion ===
    static ENUM_TIMEFRAMES StringToTimeframe(string timeframe_str);
    static string TimeframeToString(ENUM_TIMEFRAMES timeframe);
    
    //=== DATA VALIDATION GROUP ===
    static bool ValidateStoredData(int db_handle, string symbol, string timeframe, int batch_size);
    static int CountRecords(int db_handle, string symbol = "", string timeframe = "");
    
    //=== DATABASE OPERATIONS GROUP ===
    static bool GetLastBarTime(int db_handle, string symbol, string timeframe, datetime &last_time);
    static void PrintDatabaseStatus(int db_handle, string db_name);
};
    static bool ValidateCandle(string symbol, string timeframe_str, long timestamp);
    static bool ValidateWithErrorHandling(string symbol, string timeframe, datetime timestamp);
    static void PerformStaggeredValidation();
    static void ValidateSymbolTimeframe(string symbol, ENUM_TIMEFRAMES timeframe);
    
    //=== DATA FETCHING GROUP ===
    // Proven data retrieval and synchronization functions
    static void FetchHistoricalData(string symbol, ENUM_TIMEFRAMES timeframe);
    static void CheckNewBarsOptimized();
    static void PerformBrokerHashAlignment();
    
    //=== UTILITY GROUP ===
    // Proven utility and helper functions
    static string TimeframeToString(ENUM_TIMEFRAMES period);
    static int GetTrackingIndex(string symbol, ENUM_TIMEFRAMES timeframe);
    static void ParseInputs();
    
    //=== MAINTENANCE GROUP ===
    // Proven maintenance and optimization functions
    static void PerformDatabaseMaintenance();
    static void PerformMaintenanceOptimization();
    static void OptimizeUnvalidatedRecordQueries();
    static void PerformPeriodicMaintenanceValidation();
    
    //=== ERROR HANDLING GROUP ===
    // Proven error recovery and handling functions
    static bool ExecuteWithErrorRecovery(string operation_name, string sql_query, int max_retries = 5);
    static bool RecoverDatabaseConnection();
    static bool AttemptDataRepair(string symbol, string timeframe, datetime timestamp, 
                                 double open, double high, double low, double close, long volume);
    static string GetErrorDescription(int error_code);
    
    //=== PERFORMANCE TRACKING GROUP ===
    // Proven performance monitoring and metrics functions
    static void InitializePerformanceStats();
    static void UpdatePerformanceMetrics(ulong operation_time_microseconds, string operation_type);
    static void TrackDatabaseOperation(bool success);
    static void TrackBrokerExtensionActivity(string activity_type, int count = 1);
    static void GeneratePerformanceReport();
    static void ResetDailyStatistics();
    static bool MonitorMemoryUsage();
    
    //=== TEST MODE GROUP ===
    // Proven test mode and reporting functions
    static void PrintTestModeReport();

private:
    // Database handle (to be set by calling code)
    static int s_db_handle;
    
    // Performance tracking variables
    static ulong s_total_operations;
    static ulong s_successful_operations;
    static ulong s_failed_operations;
    static datetime s_last_stats_reset;
};

// Static variable initialization
static int CLegacyCore::s_db_handle = INVALID_HANDLE;
static ulong CLegacyCore::s_total_operations = 0;
static ulong CLegacyCore::s_successful_operations = 0;
static ulong CLegacyCore::s_failed_operations = 0;
static datetime CLegacyCore::s_last_stats_reset = 0;

//+------------------------------------------------------------------+
//| DATA STORAGE GROUP - IMPLEMENTATION                             |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Store single bar using raw SQL string (PROVEN)                  |
//+------------------------------------------------------------------+
bool CLegacyCore::StoreBarOptimized(string symbol, string timeframe, datetime time,
                                   double open, double high, double low, double close,
                                   long tick_volume, long real_volume)
{
    if(s_db_handle == INVALID_HANDLE) {
        Print("ERROR: Database handle not set in LegacyCore");
        return false;
    }
    
    // Calculate hash using proven method
    string hash_value = CalculateHash(open, high, low, close, tick_volume, time);
    
    // Build optimized SQL string
    string sql = StringFormat(
        "INSERT OR REPLACE INTO market_data "
        "(symbol, timeframe, datetime, open, high, low, close, volume, spread, hash_value) "
        "VALUES ('%s','%s',%I64d,%.5f,%.5f,%.5f,%.5f,%I64d,0,'%s')",
        symbol, timeframe, (long)time, open, high, low, close, tick_volume, hash_value
    );
    
    bool success = DatabaseExecute(s_db_handle, sql);
    TrackDatabaseOperation(success);
    
    if(!success) {
        Print("ERROR: Failed to store bar - ", symbol, " ", timeframe, " ", TimeToString(time));
    }
    
    return success;
}

//+------------------------------------------------------------------+
//| Batch insert with transaction (PROVEN DEFINITIVE FIX)           |
//+------------------------------------------------------------------+
int CLegacyCore::BatchInsertOptimized(string symbol, string timeframe, MqlRates &rates[], int count)
{
    if(s_db_handle == INVALID_HANDLE) {
        Print("ERROR: Database handle not set in LegacyCore");
        return 0;
    }
    
    if(!DatabaseTransactionBegin(s_db_handle)) {
        Print("ERROR: Failed to begin transaction for batch insert");
        return 0;
    }
    
    int successful_inserts = 0;
    
    for(int i = 0; i < count; i++) {
        if(StoreBarOptimized(symbol, timeframe, rates[i].time,
                           rates[i].open, rates[i].high, rates[i].low, rates[i].close,
                           rates[i].tick_volume, rates[i].real_volume)) {
            successful_inserts++;
        }
    }
    
    if(successful_inserts > 0) {
        if(DatabaseTransactionCommit(s_db_handle)) {
            Print("SUCCESS: Batch inserted ", successful_inserts, " records for ", symbol, " ", timeframe);
        } else {
            Print("ERROR: Failed to commit batch transaction");
            successful_inserts = 0;
        }
    } else {
        DatabaseTransactionRollback(s_db_handle);
        Print("ERROR: No records inserted, transaction rolled back");
    }
    
    return successful_inserts;
}

//+------------------------------------------------------------------+
//| DATA VALIDATION GROUP - IMPLEMENTATION                          |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Validate candle data (PROVEN)                                   |
//+------------------------------------------------------------------+
bool CLegacyCore::ValidateCandle(string symbol, string timeframe_str, long timestamp)
{
    if(s_db_handle == INVALID_HANDLE) {
        return false;
    }
    
    string validation_sql = StringFormat(
        "SELECT COUNT(*) FROM market_data WHERE symbol='%s' AND timeframe='%s' AND datetime=%I64d AND hash_value IS NOT NULL",
        symbol, timeframe_str, timestamp
    );
    
    int request = DatabasePrepare(s_db_handle, validation_sql);
    if(request == INVALID_HANDLE) {
        return false;
    }
    
    bool validation_result = false;
    if(DatabaseRead(request)) {
        long count = DatabaseColumnLong(request, 0);
        validation_result = (count > 0);
    }
    
    DatabaseFinalize(request);
    return validation_result;
}

//+------------------------------------------------------------------+
//| UTILITY GROUP - IMPLEMENTATION                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Convert timeframe to string (PROVEN)                            |
//+------------------------------------------------------------------+
string CLegacyCore::TimeframeToString(ENUM_TIMEFRAMES period)
{
    switch(period) {
        case PERIOD_M1:  return "M1";
        case PERIOD_M5:  return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1:  return "H1";
        case PERIOD_H4:  return "H4";
        case PERIOD_D1:  return "D1";
        case PERIOD_W1:  return "W1";
        case PERIOD_MN1: return "MN1";
        default:         return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| ERROR HANDLING GROUP - IMPLEMENTATION                           |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Execute with error recovery (PROVEN)                            |
//+------------------------------------------------------------------+
bool CLegacyCore::ExecuteWithErrorRecovery(string operation_name, string sql_query, int max_retries = 5)
{
    if(s_db_handle == INVALID_HANDLE) {
        return false;
    }
    
    for(int retry = 0; retry < max_retries; retry++) {
        bool success = DatabaseExecute(s_db_handle, sql_query);
        
        if(success) {
            TrackDatabaseOperation(true);
            return true;
        }
        
        Print("WARNING: ", operation_name, " failed, retry ", retry + 1, "/", max_retries);
        Sleep(100); // Brief delay before retry
    }
    
    TrackDatabaseOperation(false);
    Print("ERROR: ", operation_name, " failed after ", max_retries, " retries");
    return false;
}

//+------------------------------------------------------------------+
//| PERFORMANCE TRACKING GROUP - IMPLEMENTATION                     |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Track database operation (PROVEN)                               |
//+------------------------------------------------------------------+
void CLegacyCore::TrackDatabaseOperation(bool success)
{
    s_total_operations++;
    if(success) {
        s_successful_operations++;
    } else {
        s_failed_operations++;
    }
}

//+------------------------------------------------------------------+
//| Initialize performance stats (PROVEN)                           |
//+------------------------------------------------------------------+
void CLegacyCore::InitializePerformanceStats()
{
    s_total_operations = 0;
    s_successful_operations = 0;
    s_failed_operations = 0;
    s_last_stats_reset = TimeCurrent();
    Print("Performance statistics initialized");
}

//+------------------------------------------------------------------+
//| Generate performance report (PROVEN)                            |
//+------------------------------------------------------------------+
void CLegacyCore::GeneratePerformanceReport()
{
    double success_rate = (s_total_operations > 0) ? 
        (double)s_successful_operations / s_total_operations * 100.0 : 0.0;
    
    Print("=== PERFORMANCE REPORT ===");
    Print("Total Operations: ", s_total_operations);
    Print("Successful: ", s_successful_operations);
    Print("Failed: ", s_failed_operations);
    Print("Success Rate: ", DoubleToString(success_rate, 2), "%");
    Print("Report Period: ", TimeToString(s_last_stats_reset), " - ", TimeToString(TimeCurrent()));
    Print("========================");
}

//+------------------------------------------------------------------+
//| Set database handle for all operations                          |
//+------------------------------------------------------------------+
static void SetDatabaseHandle(int db_handle)
{
    CLegacyCore::s_db_handle = db_handle;
}

//+------------------------------------------------------------------+
//| Get database handle                                              |
//+------------------------------------------------------------------+
static int GetDatabaseHandle()
{
    return CLegacyCore::s_db_handle;
}

#endif // SSOT_LEGACY_CORE_MQH
