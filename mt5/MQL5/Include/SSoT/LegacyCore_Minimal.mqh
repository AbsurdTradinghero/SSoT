//+------------------------------------------------------------------+
//| LegacyCore.mqh                                                   |
//| Minimal working version with core proven functions              |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"

#ifndef SSOT_LEGACY_CORE_MINIMAL_MQH
#define SSOT_LEGACY_CORE_MINIMAL_MQH

// Include proven modular components from legacy EA
#include <DbUtils.mqh>
#include <HashUtils.mqh>

//+------------------------------------------------------------------+
//| Legacy Core Class - Minimal working version                    |
//+------------------------------------------------------------------+
class CLegacyCore
{
public:
    //=== CORE DATA STORAGE FUNCTIONS ===
    static bool StoreBarOptimized(int db_handle, string symbol, string timeframe, datetime time,
                                 double open, double high, double low, double close,
                                 long tick_volume, long real_volume);
    
    static int BatchInsertOptimized(int db_handle, string symbol, string timeframe, 
                                   MqlRates &rates[], int count);
    
    //=== UTILITY FUNCTIONS ===
    static ENUM_TIMEFRAMES StringToTimeframe(string timeframe_str);
    static string TimeframeToString(ENUM_TIMEFRAMES timeframe);
    
    //=== SIMPLE DATA FUNCTIONS ===
    static bool FetchDataToDatabase(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, int bars_count);
    static bool ValidateDataIntegrity(int db_handle);
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
    
    string sql_insert = StringFormat("INSERT OR REPLACE INTO AllCandleData "
                                     "(asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, real_volume, hash, is_validated, is_complete) "
                                     "VALUES ('%s','%s',%I64d,%.8f,%.8f,%.8f,%.8f,%I64d,%I64d,'%s',0,0);",
                                     symbol, timeframe, time, open, high, low, close, tick_volume, real_volume, hash);
    
    if(DatabaseExecuteRetry(db_handle, sql_insert))
    {
        Print("✅ Stored bar: " + symbol + " " + timeframe + " " + TimeToString(time));
        return true;
    }
    else
    {
        Print("❌ Failed to store bar for " + symbol + " at " + TimeToString(time));
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
    
    string sql_bulk_insert = "INSERT OR REPLACE INTO AllCandleData (asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, real_volume, hash, is_validated, is_complete) VALUES ";

    for(int i = 0; i < count; i++)
    {
        MqlRates r = rates[i];
        string hash = CalculateHash(r.open, r.high, r.low, r.close, r.tick_volume, r.time);
        
        sql_bulk_insert += StringFormat("('%s','%s',%I64d,%.8f,%.8f,%.8f,%.8f,%I64d,%I64d,'%s',0,0)",
                                        symbol, timeframe, r.time, r.open, r.high, r.low, r.close,
                                        r.tick_volume, r.real_volume, hash);
        
        if(i < count - 1) sql_bulk_insert += ",";
    }
    sql_bulk_insert += ";";

    if(!DatabaseTransactionBegin(db_handle))
    {
        Print("❌ Failed to begin transaction for bulk insert");
        return 0;
    }

    int stored = 0;
    if(DatabaseExecuteRetry(db_handle, sql_bulk_insert))
    {
        stored = count;
        if(!DatabaseTransactionCommit(db_handle))
        {
            Print("❌ Failed to commit bulk insert transaction");
            DatabaseTransactionRollback(db_handle);
            return 0;
        }
    }
    else
    {
        Print("❌ Failed to execute bulk insert");
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
//| Convert timeframe to string                                     |
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
//| Convert string to timeframe                                     |
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
    if(timeframe_str == "W1") return PERIOD_W1;
    if(timeframe_str == "MN1") return PERIOD_MN1;
    
    Print("❌ Unknown timeframe string: " + timeframe_str);
    return PERIOD_CURRENT;
}

//+------------------------------------------------------------------+
//| Fetch data from broker to database                             |
//+------------------------------------------------------------------+
bool CLegacyCore::FetchDataToDatabase(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, int bars_count)
{
    if(db_handle == INVALID_HANDLE) return false;
    
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    
    int copied = CopyRates(symbol, timeframe, 0, bars_count, rates);
    if(copied <= 0)
    {
        Print("❌ Failed to copy rates for ", symbol, " ", TimeframeToString(timeframe));
        return false;
    }
    
    string timeframe_str = TimeframeToString(timeframe);
    int stored = BatchInsertOptimized(db_handle, symbol, timeframe_str, rates, copied);
    
    return (stored > 0);
}

//+------------------------------------------------------------------+
//| Simple data integrity validation                               |
//+------------------------------------------------------------------+
bool CLegacyCore::ValidateDataIntegrity(int db_handle)
{
    if(db_handle == INVALID_HANDLE) return false;
    
    string sql_query = "SELECT COUNT(*) FROM AllCandleData WHERE hash IS NOT NULL";
    
    int request = DatabasePrepare(db_handle, sql_query);
    if(request == INVALID_HANDLE) return false;
    
    bool is_valid = false;
    if(DatabaseRead(request))
    {
        int valid_count = (int)DatabaseColumnLong(request, 0);
        is_valid = (valid_count > 0);
        Print("✅ Data integrity: " + IntegerToString(valid_count) + " valid records found");
    }
    
    DatabaseFinalize(request);
    return is_valid;
}

//+------------------------------------------------------------------+
//| Simple test mode flow                                          |
//+------------------------------------------------------------------+
bool CLegacyCore::ProcessTestModeFlow(int main_db, int test_input_db, int test_output_db, 
                                     string &symbols[], ENUM_TIMEFRAMES &timeframes[])
{
    Print("🧪 Processing test mode flow...");
    
    // Simple implementation - just validate all databases
    bool success = ValidateDataIntegrity(main_db) && 
                  ValidateDataIntegrity(test_input_db) && 
                  ValidateDataIntegrity(test_output_db);
    
    if(success)
        Print("✅ Test mode flow completed successfully");
    else
        Print("❌ Test mode flow failed validation");
        
    return success;
}

#endif // SSOT_LEGACY_CORE_MINIMAL_MQH
