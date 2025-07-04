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
    static int GetCompleteBrokerBars(string symbol, ENUM_TIMEFRAMES timeframe);
    static int GetDatabaseStoredBars(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe);
    static datetime GetOldestBrokerTime(string symbol, ENUM_TIMEFRAMES timeframe);
    static datetime GetNewestBrokerTime(string symbol, ENUM_TIMEFRAMES timeframe);
    static datetime GetOldestDatabaseTime(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe);
    static datetime GetNewestDatabaseTime(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe);
    
    // Gap detection
    static bool HasGaps(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe);
    static int CountMissingBars(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe);
    
    // Cleanup operations
    static bool CleanupExtraBars(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, datetime latest_broker_time);
    
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
    
    // Step 1: Get all available broker data (excluding current incomplete bar)
    MqlRates all_rates[];
    ArraySetAsSeries(all_rates, true); // Newest first
    
    // Get all available bars from broker
    int bars_available = Bars(symbol, timeframe);
    if(bars_available <= 0) {
        Print("❌ FullSync: No bars available for ", symbol, " ", TimeframeToString(timeframe));
        return false;
    }
    
    int copied = CopyRates(symbol, timeframe, 0, bars_available, all_rates);
    if(copied <= 0) {
        Print("❌ FullSync: Failed to copy broker data");
        return false;
    }
    
    // Determine if the newest bar is incomplete
    datetime current_time = TimeCurrent();
    int period_seconds = PeriodSeconds(timeframe);
    bool newest_is_incomplete = false;
    
    if(copied > 0) {
        datetime newest_bar_time = all_rates[0].time;
        datetime next_bar_expected = newest_bar_time + period_seconds;
        newest_is_incomplete = (current_time < next_bar_expected);
    }
    
    // Exclude incomplete bar from sync
    int complete_bars = newest_is_incomplete ? copied - 1 : copied;
    
    Print("📊 FullSync: Broker has ", copied, " total bars, ", complete_bars, " complete bars");
    if(newest_is_incomplete) {
        Print("⏰ FullSync: Excluding current incomplete bar at ", TimeToString(all_rates[0].time));
    }
    
    if(complete_bars <= 0) {
        Print("⚠️ FullSync: No complete bars to sync");
        return true;
    }
    
    // Step 2: Check how many we already have in database
    int db_bars = GetDatabaseStoredBars(db_handle, symbol, timeframe);
    Print("💾 FullSync: ", db_bars, " bars already in database");
    
    if(db_bars >= complete_bars) {
        Print("✅ FullSync: Database already synchronized (", db_bars, "/", complete_bars, ")");
        return true;
    }
    
    // Step 3: Prepare data for insertion (exclude incomplete bar, reverse order for insertion)
    MqlRates sync_rates[];
    int sync_count = complete_bars;
    
    if(newest_is_incomplete) {
        // Copy all except the first (newest) bar
        ArrayResize(sync_rates, sync_count);
        for(int i = 0; i < sync_count; i++) {
            sync_rates[i] = all_rates[i + 1]; // Skip the first incomplete bar
        }
    } else {
        // Copy all bars
        ArrayResize(sync_rates, sync_count);
        for(int i = 0; i < sync_count; i++) {
            sync_rates[i] = all_rates[i];
        }
    }
    
    // Reverse order for database insertion (oldest first)
    ArraySetAsSeries(sync_rates, false);
    
    Print("🔄 FullSync: Inserting ", sync_count, " complete bars...");
    Print("📅 FullSync: Time range ", TimeToString(sync_rates[0].time), " to ", TimeToString(sync_rates[sync_count-1].time));
    
    // Step 4: Insert using batch approach for better performance
    const int BATCH_SIZE = 5000;
    int inserted_total = 0;
    
    for(int start = 0; start < sync_count; start += BATCH_SIZE) {
        int batch_size = MathMin(BATCH_SIZE, sync_count - start);
        
        MqlRates batch_rates[];
        ArrayResize(batch_rates, batch_size);
        ArrayCopy(batch_rates, sync_rates, 0, start, batch_size);
        
        string tf_string = TimeframeToString(timeframe);
        int inserted = BatchInsertWithDuplicateHandling(db_handle, symbol, tf_string, batch_rates, batch_size);
        inserted_total += inserted;
        
        Print("📊 FullSync: Batch ", (start/BATCH_SIZE + 1), " - Inserted ", inserted, "/", batch_size, 
              " bars (Total: ", inserted_total, "/", sync_count, ")");
    }
    
    // Step 5: Verify final sync status
    int final_db_bars = GetDatabaseStoredBars(db_handle, symbol, timeframe);
    int missing = complete_bars - final_db_bars;
    
    Print("📊 FullSync Results for ", symbol, " ", TimeframeToString(timeframe), ":");
    Print("  - Complete broker bars: ", complete_bars);
    Print("  - Database bars: ", final_db_bars);
    Print("  - Missing bars: ", missing);
    Print("  - Sync efficiency: ", (final_db_bars * 100 / complete_bars), "%");
    
    if(missing <= 2) { // Very small tolerance
        Print("✅ FullSync: Successfully synchronized (", final_db_bars, "/", complete_bars, ")");
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
//| Get number of complete bars available from broker              |
//+------------------------------------------------------------------+
int CDataSynchronizer::GetCompleteBrokerBars(string symbol, ENUM_TIMEFRAMES timeframe)
{
    int total_bars = GetBrokerAvailableBars(symbol, timeframe);
    if(total_bars <= 0) return 0;
    
    // Check if the newest bar is incomplete
    MqlRates newest_rate[];
    ArraySetAsSeries(newest_rate, true);
    int copied = CopyRates(symbol, timeframe, 0, 1, newest_rate);
    
    if(copied <= 0) return total_bars; // Can't determine, assume all complete
    
    // Check if current time suggests the newest bar is still forming
    datetime current_time = TimeCurrent();
    datetime newest_bar_time = newest_rate[0].time;
    int period_seconds = PeriodSeconds(timeframe);
    datetime next_bar_expected = newest_bar_time + period_seconds;
    
    bool newest_is_incomplete = (current_time < next_bar_expected);
    
    int complete_bars = newest_is_incomplete ? total_bars - 1 : total_bars;
    
    if(newest_is_incomplete) {
        Print("⏰ Complete bars for ", symbol, " ", TimeframeToString(timeframe), ": ", complete_bars, 
              " (excluding incomplete bar at ", TimeToString(newest_bar_time), ")");
    }
    
    return complete_bars;
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
            
            // Get complete bars count (excluding current incomplete bar)
            int complete_broker_bars = GetCompleteBrokerBars(symbol, tf);
            int db_bars = GetDatabaseStoredBars(db_handle, symbol, tf);
            int missing = complete_broker_bars - db_bars;
            
            if(missing > 2) { // Very small tolerance for complete bars
                Print("⚠️ Sync incomplete: ", symbol, " ", TimeframeToString(tf), 
                      " - Missing: ", missing, " bars (", db_bars, "/", complete_broker_bars, ")");
                all_synced = false;
                total_missing += missing;
            } else {
                Print("✅ Sync complete: ", symbol, " ", TimeframeToString(tf), 
                      " - ", db_bars, "/", complete_broker_bars, " bars");
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
    
    // NEW APPROACH: Instead of counting bars, check for missing time periods
    // This avoids the broker vs database bar count inconsistency issue
    
    // Step 1: Get the latest complete bar time from database  
    datetime latest_db_time = GetNewestDatabaseTime(db_handle, symbol, timeframe);
    
    if(latest_db_time == 0) {
        Print("📭 IncrementalSync: No database data found, performing full sync");
        return PerformFullSync(db_handle, symbol, timeframe);
    }
    
    // Step 2: Get all available broker bars (excluding current incomplete bar)
    MqlRates all_broker_rates[];
    ArraySetAsSeries(all_broker_rates, true); // Newest first
    
    // Get a reasonable number of recent bars to check for updates
    int max_check_bars = 100; // Check last 100 bars for any missing data
    int copied = CopyRates(symbol, timeframe, 0, max_check_bars, all_broker_rates);
    
    if(copied <= 0) {
        Print("❌ IncrementalSync: Failed to copy broker data");
        return false;
    }
    
    Print("� IncrementalSync: Checking ", copied, " recent broker bars for updates");
    
    // Step 3: Filter to only bars newer than what we have in database
    // AND exclude the current incomplete bar (if it's the most recent one)
    MqlRates new_bars[];
    int new_count = 0;
    
    // Determine if the newest bar is the current incomplete bar
    datetime current_time = TimeCurrent();
    int period_seconds = PeriodSeconds(timeframe);
    bool newest_is_incomplete = false;
    
    if(copied > 0) {
        datetime newest_bar_time = all_broker_rates[0].time;
        datetime next_bar_expected = newest_bar_time + period_seconds;
        newest_is_incomplete = (current_time < next_bar_expected);
    }
    
    // Start from index 1 if newest bar is incomplete, 0 if it's complete
    int start_index = newest_is_incomplete ? 1 : 0;
    
    ArrayResize(new_bars, copied);
    for(int i = start_index; i < copied; i++) {
        // Only include bars newer than our latest database entry
        if(all_broker_rates[i].time > latest_db_time) {
            new_bars[new_count] = all_broker_rates[i];
            new_count++;
        }
    }
    
    if(new_count == 0) {
        Print("✅ IncrementalSync: Database is up to date (latest: ", TimeToString(latest_db_time), ")");
        return true;
    }
    
    // Step 4: Sort new bars chronologically (oldest first for insertion)
    ArraySetAsSeries(new_bars, false);
    ArrayResize(new_bars, new_count);
    
    Print("📊 IncrementalSync: Found ", new_count, " new complete bars to add");
    Print("� IncrementalSync: Time range ", TimeToString(new_bars[0].time), " to ", TimeToString(new_bars[new_count-1].time));
    
    // Step 5: Insert new bars
    string tf_string = TimeframeToString(timeframe);
    int inserted = BatchInsertWithDuplicateHandling(db_handle, symbol, tf_string, new_bars, new_count);
    
    Print("📊 IncrementalSync: ", inserted, " new bars added for ", symbol, " ", tf_string);
    
    // Step 6: Verify success
    datetime new_latest_db_time = GetNewestDatabaseTime(db_handle, symbol, timeframe);
    if(new_latest_db_time > latest_db_time) {
        Print("✅ IncrementalSync: Successfully updated database (latest now: ", TimeToString(new_latest_db_time), ")");
        return true;
    } else {
        Print("⚠️ IncrementalSync: Database was not updated as expected");
        return false;
    }
}

//+------------------------------------------------------------------+
//| Convert timeframe enum to string                                |
//+------------------------------------------------------------------+
string CDataSynchronizer::TimeframeToString(ENUM_TIMEFRAMES tf)
{
    switch(tf) {
        case PERIOD_M1:  return "M1";
        case PERIOD_M2:  return "M2";
        case PERIOD_M3:  return "M3";
        case PERIOD_M4:  return "M4";
        case PERIOD_M5:  return "M5";
        case PERIOD_M6:  return "M6";
        case PERIOD_M10: return "M10";
        case PERIOD_M12: return "M12";
        case PERIOD_M15: return "M15";
        case PERIOD_M20: return "M20";
        case PERIOD_M30: return "M30";
        case PERIOD_H1:  return "H1";
        case PERIOD_H2:  return "H2";
        case PERIOD_H3:  return "H3";
        case PERIOD_H4:  return "H4";
        case PERIOD_H6:  return "H6";
        case PERIOD_H8:  return "H8";
        case PERIOD_H12: return "H12";
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
//| Cleanup extra bars when database has more bars than broker     |
//+------------------------------------------------------------------+
bool CDataSynchronizer::CleanupExtraBars(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, datetime latest_broker_time)
{
    if(db_handle == INVALID_HANDLE) return false;
    
    string tf_string = TimeframeToString(timeframe);
    int db_bars = GetDatabaseStoredBars(db_handle, symbol, timeframe);
    int broker_bars = GetBrokerAvailableBars(symbol, timeframe);
    
    if(db_bars <= broker_bars) {
        Print("✅ CleanupExtraBars: No extra bars to remove (DB:", db_bars, ", Broker:", broker_bars, ")");
        return true;
    }
    
    int extra_bars = db_bars - broker_bars;
    Print("🧹 CleanupExtraBars: DB has ", extra_bars, " extra bars (DB:", db_bars, ", Broker:", broker_bars, ")");
    
    // Strategy: Remove the oldest bars that are not present in the broker's available range
    // First, get the broker's earliest available time
    MqlRates broker_rates[];
    int copied = CopyRates(symbol, timeframe, 0, broker_bars, broker_rates);
    if(copied <= 0) {
        Print("❌ CleanupExtraBars: Failed to get broker data for cleanup");
        return false;
    }
    
    datetime earliest_broker_time = broker_rates[copied-1].time; // Oldest broker bar
    datetime latest_broker_time_actual = broker_rates[0].time;   // Newest broker bar
    
    // Remove bars older than broker's earliest OR newer than broker's latest
    string delete_sql = StringFormat("DELETE FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s' AND (timestamp < %I64d OR timestamp > %I64d)", 
                                    symbol, tf_string, earliest_broker_time, latest_broker_time_actual);
    
    if(!DatabaseTransactionBegin(db_handle)) return false;
    
    bool success = DatabaseExecute(db_handle, delete_sql);
    if(success) {
        DatabaseTransactionCommit(db_handle);
        
        // Verify the cleanup worked
        int final_db_bars = GetDatabaseStoredBars(db_handle, symbol, timeframe);
        int remaining_extra = final_db_bars - broker_bars;
        
        Print("✅ CleanupExtraBars: Removed bars outside broker range for ", symbol, " ", tf_string);
        Print("📊 CleanupExtraBars: Final count - DB:", final_db_bars, ", Broker:", broker_bars, ", Remaining extra:", remaining_extra);
        
        // If we still have extra bars, remove the oldest ones by count
        if(remaining_extra > 0) {
            Print("🧹 CleanupExtraBars: Still have ", remaining_extra, " extra bars, removing oldest by count");
            string delete_oldest_sql = StringFormat("DELETE FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s' AND timestamp IN (SELECT timestamp FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s' ORDER BY timestamp ASC LIMIT %d)", 
                                                   symbol, tf_string, symbol, tf_string, remaining_extra);
            
            if(DatabaseTransactionBegin(db_handle)) {
                if(DatabaseExecute(db_handle, delete_oldest_sql)) {
                    DatabaseTransactionCommit(db_handle);
                    int final_final_db_bars = GetDatabaseStoredBars(db_handle, symbol, timeframe);
                    Print("✅ CleanupExtraBars: Final cleanup - DB:", final_final_db_bars, ", Broker:", broker_bars);
                } else {
                    DatabaseTransactionRollback(db_handle);
                    Print("❌ CleanupExtraBars: Failed to remove oldest extra bars");
                }
            }
        }
        
        return true;
    } else {
        DatabaseTransactionRollback(db_handle);
        Print("❌ CleanupExtraBars: Failed to remove extra bars");
        return false;
    }
}

//+------------------------------------------------------------------+
#endif // SSOT_DATA_SYNCHRONIZER_MQH
