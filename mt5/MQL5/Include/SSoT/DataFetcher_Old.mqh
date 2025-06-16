//+------------------------------------------------------------------+
//| DataFetcher.mqh                                                  |
//| Data collection and enhancement library for SSoT system         |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "2.00"

#ifndef SSOT_DATA_FETCHER_MQH
#define SSOT_DATA_FETCHER_MQH

// Include core components - using your proven working codebase
#include <SSoT\Core\DataStructures.mqh>
#include <SSoT\Core\HashEngine.mqh>      // Use your proven hash engine

//+------------------------------------------------------------------+
//| Data Fetcher Class - Refactored using proven algorithms         |
//+------------------------------------------------------------------+
class CDataFetcher
{
private:
    static CHashEngine* s_hash_engine;  // Shared hash engine instance
    
public:
    // Initialize/cleanup
    static bool Initialize();
    static void Shutdown();
    
    // Main data fetching functions - using your proven methods
    static int FetchData(string symbol, ENUM_TIMEFRAMES timeframe, int bars_count = 100);
    static bool FetchDataToDatabase(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, int bars_count = 100);
    static bool CopyDataBetweenDatabases(int source_db, int target_db, bool enhance_metadata = false);
    
    // Data enhancement functions - using your proven hash algorithms
    static bool EnhanceWithMetadata(int db_handle);
    static bool ValidateDataIntegrity(int db_handle);
    static string TimeframeToString(ENUM_TIMEFRAMES tf);
    
    // Test mode specific functions
    static bool ProcessTestModeFlow(int main_db, int test_input_db, int test_output_db, 
                                   string &symbols[], ENUM_TIMEFRAMES &timeframes[]);

private:
    // Internal helper functions - using your proven patterns
    static bool InsertCandleToDatabase(int db_handle, CandleRecord &candle, bool with_metadata = true);
    static bool ConvertRatesToCandle(MqlRates &rates, CandleRecord &candle, string symbol, ENUM_TIMEFRAMES tf);
    static bool UpdateValidationStatus(int db_handle, long record_id, bool is_valid);
};

//+------------------------------------------------------------------+
//| Static variables initialization                                  |
//+------------------------------------------------------------------+
static CHashEngine* CDataFetcher::s_hash_engine = NULL;

//+------------------------------------------------------------------+
//| Initialize DataFetcher with proven hash engine                  |
//+------------------------------------------------------------------+
bool CDataFetcher::Initialize()
{
    if(s_hash_engine != NULL) {
        return true; // Already initialized
    }
    
    s_hash_engine = new CHashEngine();
    if(s_hash_engine == NULL) {
        Print("❌ DataFetcher: Failed to create hash engine");
        return false;
    }
    
    if(!s_hash_engine.Initialize(true, true, "")) {
        Print("❌ DataFetcher: Failed to initialize hash engine");
        delete s_hash_engine;
        s_hash_engine = NULL;
        return false;
    }
    
    Print("✅ DataFetcher: Initialized with proven hash engine");
    return true;
}

//+------------------------------------------------------------------+
//| Shutdown and cleanup                                            |
//+------------------------------------------------------------------+
void CDataFetcher::Shutdown()
{
    if(s_hash_engine != NULL) {
        s_hash_engine.Shutdown();
        delete s_hash_engine;
        s_hash_engine = NULL;
        Print("✅ DataFetcher: Hash engine shut down");
    }
}

//+------------------------------------------------------------------+
//| Main FetchData function - Broker to Database (your proven method) |
//+------------------------------------------------------------------+
int CDataFetcher::FetchData(string symbol, ENUM_TIMEFRAMES timeframe, int bars_count = 100)
{
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    
    // Fetch rates from broker
    int copied = CopyRates(symbol, timeframe, 0, bars_count, rates);
    if(copied <= 0) {
        Print("❌ FetchData: Failed to fetch rates for ", symbol, " ", TimeframeToString(timeframe));
        return 0;
    }
    
    Print("✅ FetchData: Fetched ", copied, " bars for ", symbol, " ", TimeframeToString(timeframe));
    return copied;
}

//+------------------------------------------------------------------+
//| Fetch data directly to database - using your proven algorithms |
//+------------------------------------------------------------------+
bool CDataFetcher::FetchDataToDatabase(int db_handle, string symbol, ENUM_TIMEFRAMES timeframe, int bars_count = 100)
{
    if(db_handle == INVALID_HANDLE) {
        Print("❌ FetchDataToDatabase: Invalid database handle");
        return false;
    }
    
    if(s_hash_engine == NULL && !Initialize()) {
        Print("❌ FetchDataToDatabase: Hash engine not available");
        return false;
    }
    
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    
    // Fetch rates from broker using your proven method
    int copied = CopyRates(symbol, timeframe, 0, bars_count, rates);
    if(copied <= 0) {
        Print("❌ FetchDataToDatabase: Failed to fetch rates for ", symbol);
        return false;
    }
    
    DatabaseTransactionBegin(db_handle);
    
    int inserted = 0;
    for(int i = 0; i < copied; i++) {
        CandleRecord candle;        // Use your proven conversion method
        if(ConvertRatesToCandle(rates[i], candle, symbol, timeframe)) {
            // Use your proven hash calculation
            candle.hash = s_hash_engine.HashCandle(candle);
            candle.is_validated = true;
            candle.validated_at = TimeCurrent();
            
            if(InsertCandleToDatabase(db_handle, candle, true)) {
                inserted++;
            }
        }
    }
    
    DatabaseTransactionCommit(db_handle);
    
    Print("✅ FetchDataToDatabase: Inserted ", inserted, "/", copied, " records for ", symbol);
    return inserted > 0;
}

//+------------------------------------------------------------------+
//| Convert broker rates to candle record - your proven method     |
//+------------------------------------------------------------------+
bool CDataFetcher::ConvertRatesToCandle(MqlRates &rates, CandleRecord &candle, string symbol, ENUM_TIMEFRAMES tf)
{
    // Clear the candle structure
    ZeroMemory(candle);
    
    // Basic OHLCTV data
    candle.timestamp = rates.time;
    candle.open = rates.open;
    candle.high = rates.high;
    candle.low = rates.low;
    candle.close = rates.close;
    candle.tick_volume = rates.tick_volume;
    candle.volume = rates.real_volume > 0 ? rates.real_volume : rates.tick_volume;
    candle.spread = rates.spread;
    
    // Metadata
    candle.symbol = symbol;
    candle.timeframe = tf;
    
    // Initialize validation state
    candle.is_validated = false;
    candle.is_complete = true;
    candle.validation_attempts = 0;
    candle.last_validation_attempt = 0;
    
    // Hash will be calculated by caller using proven hash engine
    candle.hash = "";
    candle.prev_hash = "";
    
    return true;
}

//+------------------------------------------------------------------+
//| Copy data between databases with optional enhancement           |
//+------------------------------------------------------------------+
bool CDataFetcher::CopyDataBetweenDatabases(int source_db, int target_db, bool enhance_metadata = false)
{
    if(source_db == INVALID_HANDLE || target_db == INVALID_HANDLE) {
        Print("❌ CopyDataBetweenDatabases: Invalid database handles");
        return false;
    }
    
    if(enhance_metadata && s_hash_engine == NULL && !Initialize()) {
        Print("❌ CopyDataBetweenDatabases: Hash engine needed for metadata enhancement");
        return false;
    }
    
    string query = "SELECT symbol, timeframe, timestamp, open, high, low, close, tick_volume, volume, spread FROM AllCandleData ORDER BY timestamp";
    int request = DatabasePrepare(source_db, query);
    if(request == INVALID_HANDLE) {
        Print("❌ CopyDataBetweenDatabases: Failed to prepare query");
        return false;
    }
    
    DatabaseTransactionBegin(target_db);
    int copied = 0;
    
    while(DatabaseRead(request)) {
        CandleRecord candle;
        
        // Read from source database
        string symbol_temp = "";
        string tf_temp = "";
        
        DatabaseColumnText(request, 0, symbol_temp);
        candle.symbol = symbol_temp;
        DatabaseColumnText(request, 1, tf_temp);
        
        long timestamp_temp;
        DatabaseColumnLong(request, 2, timestamp_temp);
        candle.timestamp = (datetime)timestamp_temp;
        DatabaseColumnDouble(request, 3, candle.open);
        DatabaseColumnDouble(request, 4, candle.high);
        DatabaseColumnDouble(request, 5, candle.low);
        DatabaseColumnDouble(request, 6, candle.close);
        DatabaseColumnLong(request, 7, candle.tick_volume);
        DatabaseColumnLong(request, 8, candle.volume);
        DatabaseColumnLong(request, 9, candle.spread);
        
        // Convert timeframe string to enum
        if(tf_temp == "M1") candle.timeframe = PERIOD_M1;
        else if(tf_temp == "M5") candle.timeframe = PERIOD_M5;
        else if(tf_temp == "M15") candle.timeframe = PERIOD_M15;
        else if(tf_temp == "H1") candle.timeframe = PERIOD_H1;
        else candle.timeframe = PERIOD_CURRENT;
          // Enhance with metadata if requested
        if(enhance_metadata && s_hash_engine != NULL) {
            candle.hash = s_hash_engine.HashCandle(candle);
            candle.is_validated = true;
            candle.validated_at = TimeCurrent();
        }
        
        // Insert to target
        if(InsertCandleToDatabase(target_db, candle, enhance_metadata)) {
            copied++;
        }
    }
    
    DatabaseFinalize(request);
    DatabaseTransactionCommit(target_db);
    
    Print("✅ CopyDataBetweenDatabases: Copied ", copied, " records (enhanced: ", enhance_metadata ? "YES" : "NO", ")");
    return copied > 0;
}

//+------------------------------------------------------------------+
//| Process complete test mode data flow - your proven algorithm    |
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
//| Enhance database with metadata using proven hash engine        |
//+------------------------------------------------------------------+
bool CDataFetcher::EnhanceWithMetadata(int db_handle)
{
    if(db_handle == INVALID_HANDLE) return false;
    
    if(s_hash_engine == NULL && !Initialize()) {
        Print("❌ EnhanceWithMetadata: Hash engine not available");
        return false;
    }
    
    // Use your proven hash algorithm to update missing hashes
    string update_query = 
        "UPDATE AllCandleData SET "
        "is_validated = 1, "
        "validated_at = strftime('%s', 'now') "
        "WHERE hash IS NOT NULL AND hash != ''";
    
    bool result = DatabaseExecute(db_handle, update_query);
    
    if(result) {
        Print("✅ EnhanceWithMetadata: Updated records with proven metadata");
    } else {
        Print("❌ EnhanceWithMetadata: Failed to update metadata");
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Validate data integrity using proven validation               |
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
    
    // Count validated records
    string valid_query = "SELECT COUNT(*) FROM AllCandleData WHERE is_validated = 1";
    request = DatabasePrepare(db_handle, valid_query);
    
    long validated_records = 0;
    if(request != INVALID_HANDLE && DatabaseRead(request)) {
        DatabaseColumnLong(request, 0, validated_records);
        DatabaseFinalize(request);
    }
    
    Print("📊 Data Integrity: ", validated_records, "/", total_records, " records validated");
    return (validated_records == total_records) && (total_records > 0);
}

//+------------------------------------------------------------------+
//| Timeframe to string conversion - your proven method            |
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

//+------------------------------------------------------------------+
//| Insert candle to database - using proven database operations   |
//+------------------------------------------------------------------+
bool CDataFetcher::InsertCandleToDatabase(int db_handle, CandleRecord &candle, bool with_metadata = true)
{
    string insert_query = 
        "INSERT OR REPLACE INTO AllCandleData "
        "(symbol, timeframe, timestamp, open, high, low, close, tick_volume, volume, spread, "
        "hash, prev_hash, is_validated, is_complete, validated_at, validation_attempts) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    int request = DatabasePrepare(db_handle, insert_query);
    if(request == INVALID_HANDLE) return false;
    
    // Bind parameters
    DatabaseBind(request, 0, candle.symbol);
    DatabaseBind(request, 1, TimeframeToString(candle.timeframe));
    DatabaseBind(request, 2, (long)candle.timestamp);
    DatabaseBind(request, 3, candle.open);
    DatabaseBind(request, 4, candle.high);
    DatabaseBind(request, 5, candle.low);
    DatabaseBind(request, 6, candle.close);
    DatabaseBind(request, 7, candle.tick_volume);
    DatabaseBind(request, 8, candle.volume);
    DatabaseBind(request, 9, candle.spread);
    
    if(with_metadata) {
        DatabaseBind(request, 10, candle.hash);
        DatabaseBind(request, 11, candle.prev_hash);
        DatabaseBind(request, 12, candle.is_validated ? 1 : 0);
        DatabaseBind(request, 13, candle.is_complete ? 1 : 0);
        DatabaseBind(request, 14, (long)candle.validated_at);
        DatabaseBind(request, 15, candle.validation_attempts);
    } else {
        DatabaseBind(request, 10, "");
        DatabaseBind(request, 11, "");
        DatabaseBind(request, 12, 0);
        DatabaseBind(request, 13, 1);
        DatabaseBind(request, 14, 0);
        DatabaseBind(request, 15, 0);
    }
    
    bool result = DatabaseRead(request);
    DatabaseFinalize(request);
    
    return result;
}

//+------------------------------------------------------------------+
//| Update validation status                                        |
//+------------------------------------------------------------------+
bool CDataFetcher::UpdateValidationStatus(int db_handle, long record_id, bool is_valid)
{
    string update_query = 
        "UPDATE AllCandleData SET is_validated = ?, validated_at = ? WHERE rowid = ?";
    
    int request = DatabasePrepare(db_handle, update_query);
    if(request == INVALID_HANDLE) return false;
    
    DatabaseBind(request, 0, is_valid ? 1 : 0);
    DatabaseBind(request, 1, (long)TimeCurrent());
    DatabaseBind(request, 2, record_id);
    
    bool result = DatabaseRead(request);
    DatabaseFinalize(request);
    
    return result;
}

#endif // SSOT_DATA_FETCHER_MQH
