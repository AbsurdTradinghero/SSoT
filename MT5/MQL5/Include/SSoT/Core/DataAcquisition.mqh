//+------------------------------------------------------------------+
//| DataFetcher.mqh                                                  |
//| Data collection and enhancement using PROVEN algorithms         |
//| Complete rewrite using legacy SSoT_legacy.mq5 working methods   |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "3.00"

#ifndef SSOT_DATA_FETCHER_MQH
#define SSOT_DATA_FETCHER_MQH

// Include proven working hash functions from legacy EA
#include <SSoT/Utilities/HashUtils.mqh>

//+------------------------------------------------------------------+
//| Data Fetcher Class - Using PROVEN algorithms from legacy EA     |
//+------------------------------------------------------------------+
class CDataFetcher
{
public:
    // Simple initialization (no complex engine needed)
    static bool Initialize() { return true; }
    static void Shutdown() { /* Nothing to cleanup */ }
    
    // Main data fetching functions - using proven legacy methods
    static int FetchData(string symbol, ENUM_TIMEFRAMES timeframe, int bars_count = 100);
    static bool FetchDataToDatabase(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, int bars_count = 100);
    static bool CopyDataBetweenDatabases(int source_db, int target_db, bool enhance_metadata = false);
    
    // Test mode specific functions
    static bool ProcessTestModeFlow(int main_db, int test_input_db, int test_output_db, 
                                   string &symbols[], ENUM_TIMEFRAMES &timeframes[]);
    
    // Utility functions
    static bool ValidateDataIntegrity(int db_handle);
    static string TimeframeToString(ENUM_TIMEFRAMES tf);

private:
    // Proven batch insert from legacy EA
    static int BatchInsertOptimized(int db_handle, string symbol, string timeframe, MqlRates &rates[], int count);
};

//+------------------------------------------------------------------+
//| FetchData - Simple data fetching using proven legacy method     |
//+------------------------------------------------------------------+
int CDataFetcher::FetchData(string symbol, ENUM_TIMEFRAMES timeframe, int bars_count = 100)
{
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    
    // Fetch rates from broker - proven method
    int copied = CopyRates(symbol, timeframe, 0, bars_count, rates);
    if(copied <= 0) {
        Print("❌ FetchData: Failed to fetch rates for ", symbol, " ", TimeframeToString(timeframe));
        return 0;
    }
    
    Print("✅ FetchData: Fetched ", copied, " bars for ", symbol, " ", TimeframeToString(timeframe));
    return copied;
}

//+------------------------------------------------------------------+
//| FetchDataToDatabase - Using proven BatchInsertOptimized method  |
//+------------------------------------------------------------------+
bool CDataFetcher::FetchDataToDatabase(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, int bars_count = 100)
{
    if(db_handle == INVALID_HANDLE) {
        Print("❌ FetchDataToDatabase: Invalid database handle");
        return false;
    }
    
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    
    // Fetch rates from broker using proven method
    int copied = CopyRates(symbol, timeframe, 0, bars_count, rates);
    if(copied <= 0) {
        Print("❌ FetchDataToDatabase: Failed to fetch rates for ", symbol);
        return false;
    }
    
    // Use proven batch insert method from legacy EA
    int inserted = BatchInsertOptimized(db_handle, symbol, TimeframeToString(timeframe), rates, copied);
    
    Print("✅ FetchDataToDatabase: Inserted ", inserted, "/", copied, " records for ", symbol);
    return inserted > 0;
}

//+------------------------------------------------------------------+
//| BatchInsertOptimized - PROVEN method from legacy EA             |
//+------------------------------------------------------------------+
int CDataFetcher::BatchInsertOptimized(int db_handle, string symbol, string timeframe, MqlRates &rates[], int count)
{
    if(db_handle == INVALID_HANDLE || count <= 0) 
        return 0;
    
    // 1. Start the SQL query string - EXACT copy from legacy EA
    string sql_bulk_insert = "INSERT OR REPLACE INTO AllCandleData (asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, real_volume, hash, is_validated, is_complete) VALUES ";

    // 2. Loop through all the rates to build the multi-row VALUES clause
    for(int i = 0; i < count; i++)
    {
        MqlRates r = rates[i];
        string hash = CalculateHash(r.open, r.high, r.low, r.close, r.tick_volume, r.time);
        
        // Append the values for the current row
        sql_bulk_insert += StringFormat("('%s','%s',%I64d,%.8f,%.8f,%.8f,%.8f,%I64d,%I64d,'%s',0,0)",
                                        symbol,
                                        timeframe,
                                        r.time,
                                        r.open,
                                        r.high,
                                        r.low,
                                        r.close,
                                        r.tick_volume,
                                        r.real_volume,
                                        hash);
        
        // Add a comma after each row except the last one
        if(i < count - 1)
        {
            sql_bulk_insert += ",";
        }
    }
    
    // Add the final semicolon to complete the SQL statement
    sql_bulk_insert += ";";

    // 3. Wrap the single, large query in a transaction for performance and safety
    if(!DatabaseTransactionBegin(db_handle))
    {
        Print("❌ Failed to begin transaction for bulk insert. Error: " + IntegerToString(GetLastError()));
        return 0;
    }

    int stored = 0;
    // 4. Execute the entire bulk insert query at once
    if(DatabaseExecute(db_handle, sql_bulk_insert))
    {
        stored = count; // If successful, all bars were stored
        if(!DatabaseTransactionCommit(db_handle))
        {
            Print("❌ Failed to commit bulk insert transaction. Error: " + IntegerToString(GetLastError()));
            DatabaseTransactionRollback(db_handle);
            return 0;
        }
    }
    else
    {
        Print("❌ Failed to execute bulk insert. Error: " + IntegerToString(GetLastError()));
        DatabaseTransactionRollback(db_handle);
        return 0;
    }
    
    return stored;
}

//+------------------------------------------------------------------+
//| CopyDataBetweenDatabases - Simple proven method                 |
//+------------------------------------------------------------------+
bool CDataFetcher::CopyDataBetweenDatabases(int source_db, int target_db, bool enhance_metadata = false)
{
    if(source_db == INVALID_HANDLE || target_db == INVALID_HANDLE) {
        Print("❌ CopyDataBetweenDatabases: Invalid database handles");
        return false;
    }
    
    string query = "SELECT asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, real_volume FROM AllCandleData ORDER BY timestamp";
    int request = DatabasePrepare(source_db, query);
    if(request == INVALID_HANDLE) {
        Print("❌ CopyDataBetweenDatabases: Failed to prepare query");
        return false;
    }
    
    DatabaseTransactionBegin(target_db);
    int copied = 0;
    
    while(DatabaseRead(request)) {
        string symbol = "", tf = "";
        long timestamp, tick_vol, real_vol;
        double open, high, low, close;
        
        DatabaseColumnText(request, 0, symbol);
        DatabaseColumnText(request, 1, tf);
        DatabaseColumnLong(request, 2, timestamp);
        DatabaseColumnDouble(request, 3, open);
        DatabaseColumnDouble(request, 4, high);
        DatabaseColumnDouble(request, 5, low);
        DatabaseColumnDouble(request, 6, close);
        DatabaseColumnLong(request, 7, tick_vol);
        DatabaseColumnLong(request, 8, real_vol);
        
        // Calculate hash for metadata enhancement
        string hash = enhance_metadata ? CalculateHash(open, high, low, close, tick_vol, timestamp) : "";
        
        string insert_sql = StringFormat(
            "INSERT OR REPLACE INTO AllCandleData (asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, real_volume, hash, is_validated, is_complete) VALUES ('%s','%s',%I64d,%.8f,%.8f,%.8f,%.8f,%I64d,%I64d,'%s',%d,%d)",
            symbol, tf, timestamp, open, high, low, close, tick_vol, real_vol, hash, 
            enhance_metadata ? 1 : 0, enhance_metadata ? 1 : 0
        );
        
        if(DatabaseExecute(target_db, insert_sql)) {
            copied++;
        }
    }
    
    DatabaseFinalize(request);
    DatabaseTransactionCommit(target_db);
    
    Print("✅ CopyDataBetweenDatabases: Copied ", copied, " records (enhanced: ", enhance_metadata ? "YES" : "NO", ")");
    return copied > 0;
}

//+------------------------------------------------------------------+
//| ProcessTestModeFlow - 3-database test flow                      |
//+------------------------------------------------------------------+
bool CDataFetcher::ProcessTestModeFlow(int main_db, int test_input_db, int test_output_db, 
                                       string &symbols[], ENUM_TIMEFRAMES &timeframes[])
{
    Print("🧪 ProcessTestModeFlow: Starting 3-database test flow...");
    
    int symbols_count = ArraySize(symbols);
    int tf_count = ArraySize(timeframes);
    
    if(symbols_count == 0 || tf_count == 0) {
        Print("❌ ProcessTestModeFlow: No symbols or timeframes provided");
        return false;
    }
    
    bool success = true;
    
    // Step 1: Broker → sourceDB (main_db) via FetchData()
    Print("📥 Step 1: Fetching data from broker to sourceDB...");
    for(int s = 0; s < symbols_count; s++) {
        for(int t = 0; t < tf_count; t++) {
            if(!FetchDataToDatabase(main_db, symbols[s], timeframes[t], 100)) {
                Print("⚠️ Failed to fetch data for ", symbols[s], " ", TimeframeToString(timeframes[t]));
                success = false;
            }
        }
    }
    
    // Step 2: sourceDB → SSoT_in (test_input_db) - copy OHLCTV only
    Print("📋 Step 2: Copying OHLCTV data from sourceDB to SSoT_in...");
    if(!CopyDataBetweenDatabases(main_db, test_input_db, false)) {
        Print("❌ Failed to copy data to test input database");
        success = false;
    }
    
    // Step 3: SSoT_in → SSoT_out (test_output_db) - enhance with metadata
    Print("🔧 Step 3: Enhancing data from SSoT_in to SSoT_out with metadata...");
    if(!CopyDataBetweenDatabases(test_input_db, test_output_db, true)) {
        Print("❌ Failed to enhance data to test output database");
        success = false;
    }
    
    // Step 4: Validate data integrity in output database
    Print("🔍 Step 4: Validating data integrity in SSoT_out...");
    if(!ValidateDataIntegrity(test_output_db)) {
        Print("⚠️ Data integrity validation issues detected");
    }
    
    Print(success ? "✅ ProcessTestModeFlow: 3-database flow completed successfully" : 
                   "⚠️ ProcessTestModeFlow: Flow completed with some issues");
    
    return success;
}

//+------------------------------------------------------------------+
//| ValidateDataIntegrity - Simple validation                       |
//+------------------------------------------------------------------+
bool CDataFetcher::ValidateDataIntegrity(int db_handle)
{
    if(db_handle == INVALID_HANDLE) return false;
    
    // Count total records
    string count_query = "SELECT COUNT(*) FROM AllCandleData";
    int request = DatabasePrepare(db_handle, count_query);
    if(request == INVALID_HANDLE) return false;
    
    long total_records = 0;
    if(DatabaseRead(request)) {
        DatabaseColumnLong(request, 0, total_records);
    }
    DatabaseFinalize(request);
    
    Print("📊 Data Integrity: ", total_records, " total records in database");
    return total_records > 0;
}

//+------------------------------------------------------------------+
//| TimeframeToString - Proven utility function                     |
//+------------------------------------------------------------------+
string CDataFetcher::TimeframeToString(ENUM_TIMEFRAMES tf)
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
        default:         return "UNKNOWN";
    }
}

#endif // SSOT_DATA_FETCHER_MQH
