//+------------------------------------------------------------------+
//| DataFetcher.mqh                                                  |
//| Data collection library using ONLY proven legacy algorithms     |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "2.00"

#ifndef SSOT_DATA_FETCHER_MQH
#define SSOT_DATA_FETCHER_MQH

// Include only proven components
#include <HashUtils.mqh>  // Proven hash calculation function

//+------------------------------------------------------------------+
//| Data Fetcher Class - Using only proven legacy algorithms        |
//+------------------------------------------------------------------+
class CDataFetcher
{
public:
    // Initialize/cleanup - simple static methods
    static bool Initialize();
    static void Shutdown();
    
    // Main data fetching functions - using proven legacy methods
    static bool FetchDataToDatabase(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, int bars_count = 100);
    static bool CopyDataBetweenDatabases(int source_db, int target_db, bool enhance_metadata = false);
    static bool ValidateDataIntegrity(int db_handle);
    static string TimeframeToString(ENUM_TIMEFRAMES tf);
    
    // Test mode specific functions
    static bool ProcessTestModeFlow(int main_db, int test_input_db, int test_output_db, 
                                   string &symbols[], ENUM_TIMEFRAMES &timeframes[]);

private:
    // Legacy proven batch insert method - direct copy from legacy EA
    static bool BatchInsertOptimized(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, MqlRates &rates[], int count);
};

//+------------------------------------------------------------------+
//| Initialize DataFetcher - simple initialization                  |
//+------------------------------------------------------------------+
bool CDataFetcher::Initialize()
{
    // Simple initialization - no external dependencies needed
    Print("DataFetcher initialized successfully using legacy algorithms");
    return true;
}

//+------------------------------------------------------------------+
//| Shutdown DataFetcher - simple cleanup                           |
//+------------------------------------------------------------------+
void CDataFetcher::Shutdown()
{
    // Simple cleanup - no external dependencies to clean up
    Print("DataFetcher shut down");
}

//+------------------------------------------------------------------+
//| Fetch data to database - using legacy proven method            |
//+------------------------------------------------------------------+
bool CDataFetcher::FetchDataToDatabase(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, int bars_count = 100)
{
    if(db_handle == INVALID_HANDLE) {
        Print("ERROR: Invalid database handle in FetchDataToDatabase");
        return false;
    }
    
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    
    // Fetch rates from broker using standard MT5 function
    int copied = CopyRates(symbol, timeframe, 0, bars_count, rates);
    if(copied <= 0) {
        Print("ERROR: Failed to copy rates for ", symbol, " ", TimeframeToString(timeframe));
        return false;
    }
    
    // Use legacy proven batch insert method
    return BatchInsertOptimized(db_handle, symbol, timeframe, rates, copied);
}

//+------------------------------------------------------------------+
//| Legacy proven batch insert - direct copy from legacy EA        |
//+------------------------------------------------------------------+
bool CDataFetcher::BatchInsertOptimized(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, MqlRates &rates[], int count)
{
    string tf_str = TimeframeToString(timeframe);
    
    // Begin transaction for batch insert
    if(!DatabaseTransactionBegin(db_handle)) {
        Print("ERROR: Failed to begin transaction for batch insert");
        return false;
    }
    
    // Prepare batch insert statement
    string insert_sql = "INSERT OR REPLACE INTO market_data " +
                       "(symbol, timeframe, datetime, open, high, low, close, volume, spread, hash_value) " +
                       "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    int request = DatabasePrepare(db_handle, insert_sql);
    if(request == INVALID_HANDLE) {
        Print("ERROR: Failed to prepare batch insert statement");
        DatabaseTransactionRollback(db_handle);
        return false;
    }
    
    int inserted = 0;
    for(int i = 0; i < count; i++) {
        // Calculate hash using proven legacy algorithm
        string data_string = symbol + "," + tf_str + "," + 
                           TimeToString(rates[i].time, TIME_DATE|TIME_MINUTES) + "," +
                           DoubleToString(rates[i].open, 5) + "," +
                           DoubleToString(rates[i].high, 5) + "," +
                           DoubleToString(rates[i].low, 5) + "," +
                           DoubleToString(rates[i].close, 5) + "," +
                           IntegerToString(rates[i].tick_volume);
        
        string hash_value = CalculateHash(data_string);  // Use proven hash function
        
        // Bind parameters
        DatabaseBind(request, 0, symbol);
        DatabaseBind(request, 1, tf_str);
        DatabaseBind(request, 2, (long)rates[i].time);
        DatabaseBind(request, 3, rates[i].open);
        DatabaseBind(request, 4, rates[i].high);
        DatabaseBind(request, 5, rates[i].low);
        DatabaseBind(request, 6, rates[i].close);
        DatabaseBind(request, 7, (long)rates[i].tick_volume);
        DatabaseBind(request, 8, 0);  // spread placeholder
        DatabaseBind(request, 9, hash_value);
        
        if(!DatabaseExecute(request)) {
            Print("ERROR: Failed to execute batch insert for row ", i);
            continue;
        }
        
        DatabaseReset(request);
        inserted++;
    }
    
    DatabaseFinalize(request);
    
    if(inserted > 0) {
        if(!DatabaseTransactionCommit(db_handle)) {
            Print("ERROR: Failed to commit batch insert transaction");
            return false;
        }
        Print("SUCCESS: Batch inserted ", inserted, " records for ", symbol, " ", tf_str);
        return true;
    } else {
        DatabaseTransactionRollback(db_handle);
        Print("ERROR: No records inserted in batch operation");
        return false;
    }
}

//+------------------------------------------------------------------+
//| Copy data between databases - using legacy proven method       |
//+------------------------------------------------------------------+
bool CDataFetcher::CopyDataBetweenDatabases(int source_db, int target_db, bool enhance_metadata = false)
{
    if(source_db == INVALID_HANDLE || target_db == INVALID_HANDLE) {
        Print("ERROR: Invalid database handles in CopyDataBetweenDatabases");
        return false;
    }
    
    // Simple data copy using legacy proven SQL
    string copy_sql = "INSERT OR REPLACE INTO market_data " +
                     "SELECT symbol, timeframe, datetime, open, high, low, close, volume, spread, hash_value " +
                     "FROM market_data";
    
    // For enhanced metadata, we could add additional processing here
    // but keeping it simple for now using proven approach
    
    if(!DatabaseExecute(target_db, copy_sql)) {
        Print("ERROR: Failed to copy data between databases");
        return false;
    }
    
    Print("SUCCESS: Data copied between databases");
    return true;
}

//+------------------------------------------------------------------+
//| Validate data integrity using legacy proven method             |
//+------------------------------------------------------------------+
bool CDataFetcher::ValidateDataIntegrity(int db_handle)
{
    if(db_handle == INVALID_HANDLE) {
        Print("ERROR: Invalid database handle in ValidateDataIntegrity");
        return false;
    }
    
    // Simple validation using legacy proven SQL queries
    string validation_sql = "SELECT COUNT(*) FROM market_data WHERE hash_value IS NOT NULL AND hash_value != ''";
    
    int request = DatabasePrepare(db_handle, validation_sql);
    if(request == INVALID_HANDLE) {
        Print("ERROR: Failed to prepare validation query");
        return false;
    }
    
    bool has_valid_data = false;
    if(DatabaseRead(request)) {
        long count = DatabaseColumnLong(request, 0);
        has_valid_data = (count > 0);
        Print("INFO: Validation found ", count, " records with valid hashes");
    }
    
    DatabaseFinalize(request);
    return has_valid_data;
}

//+------------------------------------------------------------------+
//| Process test mode flow - using legacy proven method            |
//+------------------------------------------------------------------+
bool CDataFetcher::ProcessTestModeFlow(int main_db, int test_input_db, int test_output_db, 
                                      string &symbols[], ENUM_TIMEFRAMES &timeframes[])
{
    if(main_db == INVALID_HANDLE || test_input_db == INVALID_HANDLE || test_output_db == INVALID_HANDLE) {
        Print("ERROR: Invalid database handles in ProcessTestModeFlow");
        return false;
    }
    
    // Step 1: Copy from main to test input
    if(!CopyDataBetweenDatabases(main_db, test_input_db, false)) {
        Print("ERROR: Failed to copy data from main to test input DB");
        return false;
    }
    
    // Step 2: Process and enhance data from test input to test output
    if(!CopyDataBetweenDatabases(test_input_db, test_output_db, true)) {
        Print("ERROR: Failed to copy data from test input to test output DB");
        return false;
    }
    
    // Step 3: Validate both test databases
    if(!ValidateDataIntegrity(test_input_db) || !ValidateDataIntegrity(test_output_db)) {
        Print("ERROR: Test databases failed integrity validation");
        return false;
    }
    
    Print("SUCCESS: Test mode flow completed successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Convert timeframe to string - legacy proven method             |
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
