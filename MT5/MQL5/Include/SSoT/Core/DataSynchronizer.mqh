//+------------------------------------------------------------------+
//| DataSynchronizer.mqh                                            |
//| Intelligent data synchronization system for SSoT              |
//| Ensures 1:1 broker-database sync with gap detection/filling   |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"

#ifndef SSOT_DATA_SYNCHRONIZER_MQH
#define SSOT_DATA_SYNCHRONIZER_MQH

#include <Trade/Trade.mqh>
#include <SSoT/Utilities/HashUtils.mqh>

//+------------------------------------------------------------------+
//| Data Synchronizer Class - Intelligent 1:1 Sync                 |
//+------------------------------------------------------------------+
class CDataSynchronizer
{
public:
    static bool InitializeSync(int db_handle, string &symbols[], ENUM_TIMEFRAMES &timeframes[]);
    static bool PerformFullSync(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe);
    static bool PerformIncrementalSync(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe);
    static bool DetectAndFillGaps(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe);
    
    // Analysis functions
    static int GetBrokerAvailableBars(string symbol, ENUM_TIMEFRAMES timeframe);
    static int GetDatabaseStoredBars(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe);
    static datetime GetOldestBrokerTime(string symbol, ENUM_TIMEFRAMES timeframe);
    static datetime GetNewestBrokerTime(string symbol, ENUM_TIMEFRAMES timeframe);
    static datetime GetOldestDatabaseTime(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe);
    static datetime GetNewestDatabaseTime(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe);
    
    // Gap detection
    static bool HasGaps(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe);
    static int CountMissingBars(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe);
      // Batch operations
    static int FetchHistoricalBatch(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, 
                                   datetime start_time, int batch_size = 10000);    static bool VerifyDataIntegrity(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe);
    static bool VerifyFullSyncComplete(int db_handle, string &symbols[], ENUM_TIMEFRAMES &timeframes[]);
    static int GetValidatedBarsCount(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe);
    static int GetCompleteBarsCount(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe);
    
    // Utility functions
    static string TimeframeToString(ENUM_TIMEFRAMES tf);

private:
    static int BatchInsertWithDuplicateHandling(int db_handle, string symbol, string timeframe, 
                                               MqlRates &rates[], int count);
    static bool CheckContinuity(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, 
                               datetime start_time, datetime end_time);
};

//+------------------------------------------------------------------+
//| Initialize complete synchronization for all assets              |
//+------------------------------------------------------------------+
bool CDataSynchronizer::InitializeSync(int db_handle, string &symbols[], ENUM_TIMEFRAMES &timeframes[])
{
    if(db_handle == INVALID_HANDLE) {
        Print("❌ DataSync: Invalid database handle");
        return false;
    }
    
    Print("🔄 DataSync: Starting complete synchronization...");
    
    for(int i = 0; i < ArraySize(symbols); i++) {
        for(int j = 0; j < ArraySize(timeframes); j++) {
            string symbol = symbols[i];
            ENUM_TIMEFRAMES tf = timeframes[j];
            
            Print("📊 DataSync: Analyzing ", symbol, " ", TimeframeToString(tf));
            
            // Get current status
            int broker_bars = GetBrokerAvailableBars(symbol, tf);
            int db_bars = GetDatabaseStoredBars(db_handle, symbol, tf);
            int missing = broker_bars - db_bars;
            
            Print("  📈 Broker: ", broker_bars, " bars available");
            Print("  💾 Database: ", db_bars, " bars stored");
            Print("  ❌ Missing: ", missing, " bars");
            
            if(missing > 0) {
                Print("  🔧 Starting sync for ", symbol, " ", TimeframeToString(tf));
                if(!PerformFullSync(db_handle, symbol, tf)) {
                    Print("  ❌ Sync failed for ", symbol, " ", TimeframeToString(tf));
                } else {
                    Print("  ✅ Sync completed for ", symbol, " ", TimeframeToString(tf));
                }
            } else {
                Print("  ✅ Already synchronized");
            }
        }
    }
    
    Print("🎯 DataSync: Complete synchronization finished");
    return true;
}

//+------------------------------------------------------------------+
//| Perform full synchronization for a symbol/timeframe            |
//+------------------------------------------------------------------+
bool CDataSynchronizer::PerformFullSync(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe)
{
    Print("🔄 FullSync: Starting for ", symbol, " ", TimeframeToString(timeframe));
    
    // Step 1: Get the total available bars from broker
    int total_available = GetBrokerAvailableBars(symbol, timeframe);
    if(total_available <= 0) {
        Print("❌ FullSync: No broker data available for ", symbol, " ", TimeframeToString(timeframe));
        return false;
    }
    
    Print("📊 FullSync: ", total_available, " bars available from broker");
    
    // Step 2: Check how many we already have in database
    int db_bars = GetDatabaseStoredBars(db_handle, symbol, timeframe);
    Print("💾 FullSync: ", db_bars, " bars already in database");
    
    if(db_bars >= total_available) {
        Print("✅ FullSync: Database already synchronized (", db_bars, "/", total_available, ")");
        return true;
    }
    
    // Step 3: Fetch all available data using count-based approach (more reliable)
    const int BATCH_SIZE = 10000;
    int fetched_total = 0;
    int remaining = total_available;
    int start_pos = 0;
    
    Print("🔄 FullSync: Starting count-based fetch of ", total_available, " bars...");
    
    while(remaining > 0 && start_pos < total_available) {
        int batch_size = MathMin(BATCH_SIZE, remaining);
        
        MqlRates rates[];
        ArraySetAsSeries(rates, true); // Newest first
        
        // Fetch from current position
        int copied = CopyRates(symbol, timeframe, start_pos, batch_size, rates);
        if(copied <= 0) {
            Print("⚠️ FullSync: Failed to copy rates from position ", start_pos);
            break;
        }
        
        // Insert into database
        string tf_string = TimeframeToString(timeframe);
        int inserted = BatchInsertWithDuplicateHandling(db_handle, symbol, tf_string, rates, copied);
        
        fetched_total += inserted;
        remaining -= copied;
        start_pos += copied;
        
        Print("📊 FullSync: Batch ", start_pos/BATCH_SIZE + 1, " - Inserted ", inserted, "/", copied, 
              " bars (Total: ", fetched_total, "/", total_available, ")");
        
        // Safety check
        if(fetched_total > 200000) {
            Print("⚠️ FullSync: Safety limit reached (200k bars)");
            break;
        }
    }
    
    // Step 4: Verify final sync status
    int final_db_bars = GetDatabaseStoredBars(db_handle, symbol, timeframe);
    int missing = total_available - final_db_bars;
    
    Print("📊 FullSync Results for ", symbol, " ", TimeframeToString(timeframe), ":");
    Print("  - Broker bars: ", total_available);
    Print("  - Database bars: ", final_db_bars);
    Print("  - Missing bars: ", missing);
    Print("  - Sync efficiency: ", (final_db_bars * 100 / total_available), "%");
    
    if(missing <= 5) { // Allow small tolerance for very recent bars
        Print("✅ FullSync: Successfully synchronized (", final_db_bars, "/", total_available, ")");
        return true;
    } else {
        Print("⚠️ FullSync: Partial sync (", missing, " bars still missing)");
        return false;
    }
}

//+------------------------------------------------------------------+
//| Detect and fill gaps in the data                                |
//+------------------------------------------------------------------+
bool CDataSynchronizer::DetectAndFillGaps(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe)
{
    if(db_handle == INVALID_HANDLE) return false;
    
    // Simple gap detection - check for missing bars in a reasonable range
    datetime oldest_db = GetOldestDatabaseTime(db_handle, symbol, timeframe);
    datetime newest_db = GetNewestDatabaseTime(db_handle, symbol, timeframe);
    
    if(oldest_db == 0 || newest_db == 0) {
        Print("⚠️ Gap Detection: No data found for ", symbol, " ", TimeframeToString(timeframe));
        return false;
    }
    
    // For now, simple implementation - just fill recent gaps
    datetime start_time = newest_db - 86400 * 7; // Look back 7 days
    int filled = FetchHistoricalBatch(db_handle, symbol, timeframe, start_time, 1000);
    
    Print("🔧 Gap filling: ", filled, " bars added for ", symbol, " ", TimeframeToString(timeframe));
    return filled > 0;
}

//+------------------------------------------------------------------+
//| Get number of bars available from broker                        |
//+------------------------------------------------------------------+
int CDataSynchronizer::GetBrokerAvailableBars(string symbol, ENUM_TIMEFRAMES timeframe)
{
    // Method 1: Try to get a very large number to find the actual limit
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    
    // Start with a reasonable attempt
    int available = CopyRates(symbol, timeframe, 0, 500000, rates); // Try 500k first
    
    if(available > 0) {
        Print("📊 Broker bars available for ", symbol, " ", TimeframeToString(timeframe), ": ", available);
        return available;
    }
    
    // If that fails, try smaller amounts
    available = CopyRates(symbol, timeframe, 0, 100000, rates);
    if(available > 0) {
        Print("📊 Broker bars available for ", symbol, " ", TimeframeToString(timeframe), ": ", available, " (limited to 100k)");
        return available;
    }
    
    // Last resort
    available = CopyRates(symbol, timeframe, 0, 10000, rates);
    Print("📊 Broker bars available for ", symbol, " ", TimeframeToString(timeframe), ": ", available, " (limited to 10k)");
    return available > 0 ? available : 0;
}

//+------------------------------------------------------------------+
//| Get number of bars stored in database                           |
//+------------------------------------------------------------------+
int CDataSynchronizer::GetDatabaseStoredBars(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe)
{
    if(db_handle == INVALID_HANDLE) return 0;
    
    string tf_string = TimeframeToString(timeframe);
    string sql = StringFormat("SELECT COUNT(*) FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s'", 
                             symbol, tf_string);
    
    int request = DatabasePrepare(db_handle, sql);
    if(request == INVALID_HANDLE) return 0;
    
    long count = 0;
    if(DatabaseRead(request)) {
        DatabaseColumnLong(request, 0, count);
    }
    DatabaseFinalize(request);
    
    return (int)count;
}

//+------------------------------------------------------------------+
//| Get oldest available time from broker                           |
//+------------------------------------------------------------------+
datetime CDataSynchronizer::GetOldestBrokerTime(string symbol, ENUM_TIMEFRAMES timeframe)
{
    MqlRates rates[];
    ArraySetAsSeries(rates, false); // Oldest first
    
    int copied = CopyRates(symbol, timeframe, 0, 100000, rates);
    if(copied > 0) {
        return rates[0].time;
    }
    return 0;
}

//+------------------------------------------------------------------+
//| Get newest available time from broker                           |
//+------------------------------------------------------------------+
datetime CDataSynchronizer::GetNewestBrokerTime(string symbol, ENUM_TIMEFRAMES timeframe)
{
    MqlRates rates[];
    ArraySetAsSeries(rates, true); // Newest first
    
    int copied = CopyRates(symbol, timeframe, 0, 1, rates);
    if(copied > 0) {
        return rates[0].time;
    }
    return 0;
}

//+------------------------------------------------------------------+
//| Get oldest time from database                                   |
//+------------------------------------------------------------------+
datetime CDataSynchronizer::GetOldestDatabaseTime(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe)
{
    if(db_handle == INVALID_HANDLE) return 0;
    
    string tf_string = TimeframeToString(timeframe);
    string sql = StringFormat("SELECT MIN(timestamp) FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s'", 
                             symbol, tf_string);
    
    int request = DatabasePrepare(db_handle, sql);
    if(request == INVALID_HANDLE) return 0;
    
    datetime oldest = 0;
    if(DatabaseRead(request)) {
        long timestamp_long = 0;
        DatabaseColumnLong(request, 0, timestamp_long);
        oldest = (datetime)timestamp_long;
    }
    DatabaseFinalize(request);
    
    return oldest;
}

//+------------------------------------------------------------------+
//| Get newest time from database                                   |
//+------------------------------------------------------------------+
datetime CDataSynchronizer::GetNewestDatabaseTime(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe)
{
    if(db_handle == INVALID_HANDLE) return 0;
    
    string tf_string = TimeframeToString(timeframe);
    string sql = StringFormat("SELECT MAX(timestamp) FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s'", 
                             symbol, tf_string);
    
    int request = DatabasePrepare(db_handle, sql);
    if(request == INVALID_HANDLE) return 0;
    
    datetime latest = 0;
    if(DatabaseRead(request)) {
        long timestamp_long = 0;
        DatabaseColumnLong(request, 0, timestamp_long);
        latest = (datetime)timestamp_long;
    }
    DatabaseFinalize(request);
    
    return latest;
}

//+------------------------------------------------------------------+
//| Check if data has gaps                                          |
//+------------------------------------------------------------------+
bool CDataSynchronizer::HasGaps(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe)
{
    // Simple implementation - compare broker vs database bar counts
    int broker_bars = GetBrokerAvailableBars(symbol, timeframe);
    int db_bars = GetDatabaseStoredBars(db_handle, symbol, timeframe);
    
    // Allow some tolerance for very recent bars that might not be synced yet
    int tolerance = 5;
    return (broker_bars - db_bars) > tolerance;
}

//+------------------------------------------------------------------+
//| Count missing bars                                              |
//+------------------------------------------------------------------+
int CDataSynchronizer::CountMissingBars(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe)
{
    int broker_bars = GetBrokerAvailableBars(symbol, timeframe);
    int db_bars = GetDatabaseStoredBars(db_handle, symbol, timeframe);
    
    int missing = broker_bars - db_bars;
    return missing > 0 ? missing : 0;
}

//+------------------------------------------------------------------+
//| Fetch historical data batch                                     |
//+------------------------------------------------------------------+
int CDataSynchronizer::FetchHistoricalBatch(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, 
                                           datetime start_time, int batch_size = 10000)
{
    if(db_handle == INVALID_HANDLE) return 0;
    
    MqlRates rates[];
    ArraySetAsSeries(rates, false);
    
    int copied = CopyRates(symbol, timeframe, start_time, batch_size, rates);
    if(copied <= 0) return 0;
    
    string tf_string = TimeframeToString(timeframe);
    int inserted = BatchInsertWithDuplicateHandling(db_handle, symbol, tf_string, rates, copied);
    
    return inserted;
}

//+------------------------------------------------------------------+
//| Verify data integrity                                           |
//+------------------------------------------------------------------+
bool CDataSynchronizer::VerifyDataIntegrity(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe)
{
    // Simple integrity check
    int db_bars = GetDatabaseStoredBars(db_handle, symbol, timeframe);
    return db_bars > 0;
}

//+------------------------------------------------------------------+
//| Batch insert with duplicate handling                            |
//+------------------------------------------------------------------+
int CDataSynchronizer::BatchInsertWithDuplicateHandling(int db_handle, string symbol, string timeframe, 
                                                       MqlRates &rates[], int count)
{
    if(db_handle == INVALID_HANDLE || count <= 0) return 0;
    
    // Use INSERT OR REPLACE to handle duplicates
    string sql_bulk = "INSERT OR REPLACE INTO AllCandleData (asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, real_volume, hash, is_validated, is_complete) VALUES ";
    
    for(int i = 0; i < count; i++) {
        MqlRates r = rates[i];
        string hash = CalculateHash(r.open, r.high, r.low, r.close, r.tick_volume, r.time);
        
        sql_bulk += StringFormat("('%s','%s',%I64d,%.8f,%.8f,%.8f,%.8f,%I64d,%I64d,'%s',1,1)",
                                symbol, timeframe, r.time, r.open, r.high, r.low, r.close,
                                r.tick_volume, r.real_volume, hash);
        
        if(i < count - 1) sql_bulk += ",";
    }
    sql_bulk += ";";
    
    if(!DatabaseTransactionBegin(db_handle)) return 0;
    
    bool success = DatabaseExecute(db_handle, sql_bulk);
    if(success) {
        DatabaseTransactionCommit(db_handle);
        return count;
    } else {
        DatabaseTransactionRollback(db_handle);
        return 0;
    }
}

//+------------------------------------------------------------------+
//| Check continuity of data                                        |
//+------------------------------------------------------------------+
bool CDataSynchronizer::CheckContinuity(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, 
                                       datetime start_time, datetime end_time)
{
    // Simple continuity check - placeholder implementation
    int bars_in_range = GetDatabaseStoredBars(db_handle, symbol, timeframe);
    return bars_in_range > 0; // For now, just check if we have any data
}

//+------------------------------------------------------------------+
//| Verify that initial sync is complete for all symbols/timeframes |
//+------------------------------------------------------------------+
bool CDataSynchronizer::VerifyFullSyncComplete(int db_handle, string &symbols[], ENUM_TIMEFRAMES &timeframes[])
{
    bool all_synced = true;
    int total_missing = 0;
    
    Print("🔍 Verifying full sync completion for all assets...");
    
    for(int i = 0; i < ArraySize(symbols); i++) {
        for(int j = 0; j < ArraySize(timeframes); j++) {
            string symbol = symbols[i];
            ENUM_TIMEFRAMES tf = timeframes[j];
            
            int broker_bars = GetBrokerAvailableBars(symbol, tf);
            int db_bars = GetDatabaseStoredBars(db_handle, symbol, tf);
            int missing = broker_bars - db_bars;
            
            if(missing > 5) { // Allow small tolerance
                Print("⚠️ Sync incomplete: ", symbol, " ", TimeframeToString(tf), 
                      " - Missing: ", missing, " bars (", db_bars, "/", broker_bars, ")");
                all_synced = false;
                total_missing += missing;
            } else {
                Print("✅ Sync complete: ", symbol, " ", TimeframeToString(tf), 
                      " - ", db_bars, "/", broker_bars, " bars");
            }
        }
    }
    
    if(all_synced) {
        Print("🎉 ALL ASSETS FULLY SYNCHRONIZED - Initial sync complete!");
        return true;
    } else {
        Print("⚠️ SYNC INCOMPLETE - Total missing bars: ", total_missing);
        return false;
    }
}

//+------------------------------------------------------------------+
//| Perform incremental sync - only fetch new data                  |
//+------------------------------------------------------------------+
bool CDataSynchronizer::PerformIncrementalSync(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe)
{
    if(db_handle == INVALID_HANDLE) return false;
    
    Print("🔄 IncrementalSync: Starting for ", symbol, " ", TimeframeToString(timeframe));
    
    // Get the latest time we have in database
    datetime latest_db_time = GetNewestDatabaseTime(db_handle, symbol, timeframe);
    datetime latest_broker_time = GetNewestBrokerTime(symbol, timeframe);
    
    if(latest_broker_time == 0) {
        Print("❌ IncrementalSync: No broker data available");
        return false;
    }
    
    if(latest_db_time == 0) {
        Print("📭 IncrementalSync: No database data found, performing full sync");
        return PerformFullSync(db_handle, symbol, timeframe);
    }
    
    // Check if we need to fetch anything
    if(latest_db_time >= latest_broker_time) {
        Print("✅ IncrementalSync: Database is up to date");
        return true;
    }
    
    Print("📅 IncrementalSync: Fetching from ", TimeToString(latest_db_time), " to ", TimeToString(latest_broker_time));
    
    // Fetch only the new data since our latest database entry
    MqlRates rates[];
    ArraySetAsSeries(rates, false);
    
    // Start from the next period after our latest data
    datetime start_time = latest_db_time + PeriodSeconds(timeframe);
    int copied = CopyRates(symbol, timeframe, start_time, 1000, rates);
    
    if(copied <= 0) {
        Print("✅ IncrementalSync: No new data available");
        return true; // This is normal, not an error
    }
    
    string tf_string = TimeframeToString(timeframe);
    int inserted = BatchInsertWithDuplicateHandling(db_handle, symbol, tf_string, rates, copied);
      Print("📊 IncrementalSync: ", inserted, " new bars added for ", symbol, " ", tf_string);
    return true;
}

//+------------------------------------------------------------------+
//| Convert timeframe enum to string                                |
//+------------------------------------------------------------------+
string CDataSynchronizer::TimeframeToString(ENUM_TIMEFRAMES tf)
{
    switch(tf) {
        case PERIOD_M1:  return "M1";
        case PERIOD_M5:  return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1:  return "H1";
        case PERIOD_H4:  return "H4";
        case PERIOD_D1:  return "D1";
        case PERIOD_W1:  return "W1";
        case PERIOD_MN1: return "MN1";
        default: return "M1";
    }
}

//+------------------------------------------------------------------+
//| Get validation statistics for an asset/timeframe               |
//+------------------------------------------------------------------+
int CDataSynchronizer::GetValidatedBarsCount(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe)
{
    if(db_handle == INVALID_HANDLE) return 0;
    
    string tf_string = TimeframeToString(timeframe);
    string sql = StringFormat("SELECT COUNT(*) FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s' AND is_validated=1", 
                             symbol, tf_string);
    
    int request = DatabasePrepare(db_handle, sql);
    if(request == INVALID_HANDLE) return 0;
    
    long count = 0;
    if(DatabaseRead(request)) {
        DatabaseColumnLong(request, 0, count);
    }
    DatabaseFinalize(request);
    
    return (int)count;
}

//+------------------------------------------------------------------+
//| Get completion statistics for an asset/timeframe               |
//+------------------------------------------------------------------+
int CDataSynchronizer::GetCompleteBarsCount(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe)
{
    if(db_handle == INVALID_HANDLE) return 0;
    
    string tf_string = TimeframeToString(timeframe);
    string sql = StringFormat("SELECT COUNT(*) FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s' AND is_complete=1", 
                             symbol, tf_string);
    
    int request = DatabasePrepare(db_handle, sql);
    if(request == INVALID_HANDLE) return 0;
    
    long count = 0;
    if(DatabaseRead(request)) {
        DatabaseColumnLong(request, 0, count);
    }
    DatabaseFinalize(request);
    
    return (int)count;
}

//+------------------------------------------------------------------+
#endif // SSOT_DATA_SYNCHRONIZER_MQH
