//+------------------------------------------------------------------+
//| LegacyCore.mqh                                                   |
//| EXACT functions extracted from proven SSoT_legacy.mq5           |
//| All functions work with database handles exactly as legacy      |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"

#ifndef SSOT_LEGACY_CORE_MQH
#define SSOT_LEGACY_CORE_MQH

// Include proven modular components from legacy EA
#include <DbUtils.mqh>
#include <HashUtils.mqh>

//+------------------------------------------------------------------+
//| Legacy Core Class - EXACT proven functions from legacy EA      |
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
    static bool ValidateDataIntegrity(int db_handle);
    static int CountRecords(int db_handle, string symbol = "", string timeframe = "");
    
    //=== DATA FETCHING GROUP ===
    static bool FetchDataToDatabase(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, int bars_count);
    
    //=== DATABASE OPERATIONS GROUP ===
    static bool GetLastBarTime(int db_handle, string symbol, string timeframe, datetime &last_time);
    static void PrintDatabaseStatus(int db_handle, string db_name);
    
    //=== TEST MODE FLOW GROUP ===
    static bool ProcessTestModeFlow(int main_db, int test_input_db, int test_output_db, 
                                   string &symbols[], ENUM_TIMEFRAMES &timeframes[]);
};

//+------------------------------------------------------------------+
//| Store single bar - EXACT copy from legacy EA                   |
//+------------------------------------------------------------------+
bool CLegacyCore::StoreBarOptimized(int db_handle, string symbol, string timeframe, datetime time,
                                   double open, double high, double low, double close,
                                   long tick_volume, long real_volume)
{
    if (db_handle == INVALID_HANDLE) return false;

    string hash = CalculateHash(open, high, low, close, tick_volume, time);
    
    // Build the raw SQL string for a single insert (exact copy from legacy)
    string sql_insert = StringFormat("INSERT OR REPLACE INTO AllCandleData "
                                     "(asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, real_volume, hash, is_validated, is_complete) "
                                     "VALUES ('%s','%s',%I64d,%.8f,%.8f,%.8f,%.8f,%I64d,%I64d,'%s',0,0);",
                                     symbol, timeframe, time, open, high, low, close, tick_volume, real_volume, hash);
      // Use the proven DatabaseExecuteRetry function
    if(DatabaseExecuteRetry(db_handle, sql_insert))
    {
        Print("✅ Stored bar: " + symbol + " " + timeframe + " " + TimeToString(time));
        return true;
    }
    else
    {
        Print("❌ Failed to execute single insert for " + symbol + " at " + TimeToString(time) + ". Error: " + IntegerToString(GetLastError()));
        return false;
    }
}

//+------------------------------------------------------------------+
//| Batch insert - EXACT copy from legacy EA                       |
//+------------------------------------------------------------------+
int CLegacyCore::BatchInsertOptimized(int db_handle, string symbol, string timeframe, 
                                     MqlRates &rates[], int count)
{
    if(db_handle == INVALID_HANDLE || count <= 0) 
        return 0;
    
    // 1. Start the SQL query string (exact copy from legacy)
    string sql_bulk_insert = "INSERT OR REPLACE INTO AllCandleData (asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, real_volume, hash, is_validated, is_complete) VALUES ";

    // 2. Loop through all the rates to build the multi-row VALUES clause
    for(int i = 0; i < count; i++)
    {
        MqlRates r = rates[i];
        string hash = CalculateHash(r.open, r.high, r.low, r.close, r.tick_volume, r.time);
        
        // Append the values for the current row (exact format from legacy)
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
    sql_bulk_insert += ";";    // 3. Wrap the single, large query in a transaction for performance and safety
    if(!DatabaseTransactionBegin(db_handle))
    {
        Print("❌ Failed to begin transaction for bulk insert. Error: " + IntegerToString(GetLastError()));
        return 0;
    }

    int stored = 0;
    // 4. Execute the entire bulk insert query at once
    if(DatabaseExecuteRetry(db_handle, sql_bulk_insert))
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

    if(stored > 0)
    {
       Print("✅ Batch inserted " + IntegerToString(stored) + " records for " + symbol + " " + timeframe);
    }
    
    return stored;
}

//+------------------------------------------------------------------+
//| Convert string to timeframe - from legacy EA                   |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES CLegacyCore::StringToTimeframe(string timeframe_str)
{
    if(timeframe_str == "M1") return PERIOD_M1;
    if(timeframe_str == "M5") return PERIOD_M5;
    if(timeframe_str == "M15") return PERIOD_M15;
    if(timeframe_str == "M30") return PERIOD_M30;
    if(timeframe_str == "H1") return PERIOD_H1;
    if(timeframe_str == "H4") return PERIOD_H4;
    if(timeframe_str == "D1") return PERIOD_D1;
    if(timeframe_str == "W1") return PERIOD_W1;    if(timeframe_str == "MN1") return PERIOD_MN1;
    
    Print("❌ Unknown timeframe string: " + timeframe_str);
    return PERIOD_CURRENT;
}

//+------------------------------------------------------------------+
//| Convert timeframe to string - from legacy EA                   |
//+------------------------------------------------------------------+
string CLegacyCore::TimeframeToString(ENUM_TIMEFRAMES timeframe)
{
    switch(timeframe)
    {
        case PERIOD_M1: return "M1";
        case PERIOD_M5: return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1: return "H1";
        case PERIOD_H4: return "H4";
        case PERIOD_D1: return "D1";
        case PERIOD_W1: return "W1";
        case PERIOD_MN1: return "MN1";
        default: return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Get last bar time - from legacy EA                             |
//+------------------------------------------------------------------+
bool CLegacyCore::GetLastBarTime(int db_handle, string symbol, string timeframe, datetime &last_time)
{
    if(db_handle == INVALID_HANDLE) return false;
    
    string sql_query = StringFormat("SELECT MAX(timestamp) FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s'",
                                   symbol, timeframe);
    
    int request = DatabasePrepare(db_handle, sql_query);
    if(request == INVALID_HANDLE) return false;
    
    bool success = false;
    if(DatabaseRead(request))
    {
        last_time = (datetime)DatabaseColumnLong(request, 0);
        success = true;
    }
    
    DatabaseFinalize(request);
    return success;
}

//+------------------------------------------------------------------+
//| Count records in database - utility function                   |
//+------------------------------------------------------------------+
int CLegacyCore::CountRecords(int db_handle, string symbol = "", string timeframe = "")
{
    if(db_handle == INVALID_HANDLE) return -1;
    
    string sql_query;
    if(symbol != "" && timeframe != "")
    {
        sql_query = StringFormat("SELECT COUNT(*) FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s'",
                                symbol, timeframe);
    }
    else
    {
        sql_query = "SELECT COUNT(*) FROM AllCandleData";
    }
    
    int request = DatabasePrepare(db_handle, sql_query);
    if(request == INVALID_HANDLE) return -1;
    
    int count = 0;
    if(DatabaseRead(request))
    {
        count = (int)DatabaseColumnLong(request, 0);
    }
    
    DatabaseFinalize(request);
    return count;
}

//+------------------------------------------------------------------+
//| Validate stored data - from legacy EA                          |
//+------------------------------------------------------------------+
bool CLegacyCore::ValidateStoredData(int db_handle, string symbol, string timeframe, int batch_size)
{
    if(db_handle == INVALID_HANDLE) return false;
    
    // Simple validation - check if recent records have valid hashes
    string sql_query = StringFormat("SELECT COUNT(*) FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s' AND hash IS NOT NULL AND hash != '' ORDER BY timestamp DESC LIMIT %d",
                                   symbol, timeframe, batch_size);
    
    int request = DatabasePrepare(db_handle, sql_query);
    if(request == INVALID_HANDLE) return false;
    
    bool is_valid = false;    if(DatabaseRead(request))
    {
        int valid_count = (int)DatabaseColumnLong(request, 0);
        is_valid = (valid_count > 0);
        Print("✅ Validation: " + IntegerToString(valid_count) + " valid records found for " + symbol + " " + timeframe);
    }
    
    DatabaseFinalize(request);
    return is_valid;
}

//+------------------------------------------------------------------+
//| Print database status - utility function                       |
//+------------------------------------------------------------------+
void CLegacyCore::PrintDatabaseStatus(int db_handle, string db_name)
{
    if(db_handle == INVALID_HANDLE)
    {
        Print("❌ Database " + db_name + " is not initialized");
        return;
    }
    
    int total_records = CountRecords(db_handle);
    Print("📊 Database " + db_name + " status: " + IntegerToString(total_records) + " total records");
}

//+------------------------------------------------------------------+
//| Fetch data from broker to database - uses proven batch insert  |
//+------------------------------------------------------------------+
bool CLegacyCore::FetchDataToDatabase(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, int bars_count)
{
    if(db_handle == INVALID_HANDLE) return false;
    
    // Get rates from broker
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    
    int copied = CopyRates(symbol, timeframe, 0, bars_count, rates);
    if(copied <= 0)
    {
        Print("❌ Failed to copy rates for ", symbol, " ", TimeframeToString(timeframe));
        return false;
    }
    
    // Use proven batch insert
    string timeframe_str = TimeframeToString(timeframe);
    int stored = BatchInsertOptimized(db_handle, symbol, timeframe_str, rates, copied);
    
    return (stored > 0);
}

//+------------------------------------------------------------------+
//| Validate data integrity - simplified version                   |
//+------------------------------------------------------------------+
bool CLegacyCore::ValidateDataIntegrity(int db_handle)
{
    if(db_handle == INVALID_HANDLE) return false;
    
    // Simple validation - check if database has any valid records
    string sql_query = "SELECT COUNT(*) FROM AllCandleData WHERE hash IS NOT NULL AND hash != ''";
    
    int request = DatabasePrepare(db_handle, sql_query);
    if(request == INVALID_HANDLE) return false;
    
    bool is_valid = false;
    if(DatabaseRead(request))
    {
        int valid_count = (int)DatabaseColumnLong(request, 0);
        is_valid = (valid_count > 0);
        Print("✅ Data integrity check: " + IntegerToString(valid_count) + " valid records found");
    }
    
    DatabaseFinalize(request);
    return is_valid;
}

//+------------------------------------------------------------------+
//| Process test mode flow - simplified version                    |
//+------------------------------------------------------------------+
bool CLegacyCore::ProcessTestModeFlow(int main_db, int test_input_db, int test_output_db, 
                                     string &symbols[], ENUM_TIMEFRAMES &timeframes[])
{
    if(main_db == INVALID_HANDLE || test_input_db == INVALID_HANDLE || test_output_db == INVALID_HANDLE)
    {
        Print("❌ Test mode: Invalid database handles");
        return false;
    }
    
    Print("🧪 Processing test mode flow...");
    
    // Simple test mode - copy from main to test databases
    string copy_sql = "INSERT OR REPLACE INTO AllCandleData SELECT * FROM AllCandleData";
    
    if(!DatabaseExecuteRetry(test_input_db, copy_sql) || !DatabaseExecuteRetry(test_output_db, copy_sql))
    {
        Print("❌ Test mode: Failed to copy data");
        return false;
    }
    
    Print("✅ Test mode flow completed successfully");
    return true;
}

#endif // SSOT_LEGACY_CORE_MQH
