//+------------------------------------------------------------------+
//| DatabaseSetup.mqh                                                |
//| Database structure creation and setup for SSoT system           |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Database Setup Class                                             |
//+------------------------------------------------------------------+
class CDatabaseSetup
{
public:
    // Main setup function - handles both main and test databases
    static bool SetupAllDatabases(int main_db_handle, 
                                 int test_input_db_handle = INVALID_HANDLE,
                                 int test_output_db_handle = INVALID_HANDLE,
                                 bool is_test_mode = false);
    
private:
    // Individual database structure creators
    static bool CreateMainDatabaseStructure(int db_handle);
    static bool CreateTestInputStructure(int db_handle);
    static bool CreateTestOutputStructure(int db_handle);
    static bool CreateIndexes(int db_handle, bool is_main_db = true);
    static bool InsertMetadata(int db_handle, string db_type);
};

//+------------------------------------------------------------------+
//| Setup all databases with single function call                    |
//+------------------------------------------------------------------+
bool CDatabaseSetup::SetupAllDatabases(int main_db_handle, 
                                       int test_input_db_handle = INVALID_HANDLE,
                                       int test_output_db_handle = INVALID_HANDLE,
                                       bool is_test_mode = false)
{
    // Setup main database
    if(main_db_handle == INVALID_HANDLE) {
        Print("❌ DatabaseSetup: Invalid main database handle");
        return false;
    }
    
    if(!CreateMainDatabaseStructure(main_db_handle)) {
        Print("❌ DatabaseSetup: Failed to create main database structure");
        return false;
    }
    
    // Setup test databases if test mode is enabled
    if(is_test_mode) {
        if(test_input_db_handle != INVALID_HANDLE) {
            if(!CreateTestInputStructure(test_input_db_handle)) {
                Print("❌ DatabaseSetup: Failed to create test input database structure");
                return false;
            }
        }
        
        if(test_output_db_handle != INVALID_HANDLE) {
            if(!CreateTestOutputStructure(test_output_db_handle)) {
                Print("❌ DatabaseSetup: Failed to create test output database structure");
                return false;
            }
        }
        
        Print("✅ DatabaseSetup: All databases (main + test) configured successfully");
    } else {
        Print("✅ DatabaseSetup: Main database configured successfully");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Create main database structure                                   |
//+------------------------------------------------------------------+
bool CDatabaseSetup::CreateMainDatabaseStructure(int db_handle)
{
    string sql = 
        "CREATE TABLE IF NOT EXISTS AllCandleData ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "asset_symbol TEXT NOT NULL,"
        "timeframe TEXT NOT NULL,"
        "timestamp INTEGER NOT NULL,"
        "open REAL NOT NULL,"
        "high REAL NOT NULL,"
        "low REAL NOT NULL,"
        "close REAL NOT NULL,"
        "tick_volume INTEGER NOT NULL,"
        "real_volume INTEGER NOT NULL,"
        "hash TEXT NOT NULL,"
        "is_validated INTEGER DEFAULT 0,"
        "is_complete INTEGER DEFAULT 0,"
        "validation_time INTEGER DEFAULT 0,"
        "UNIQUE(asset_symbol, timeframe, timestamp)"
        ");";
    
    if(!DatabaseExecute(db_handle, sql)) {
        Print("❌ DatabaseSetup: Failed to create AllCandleData table");
        return false;
    }
    
    // Create DBInfo table
    sql = "CREATE TABLE IF NOT EXISTS DBInfo ("
          "key TEXT PRIMARY KEY,"
          "value TEXT NOT NULL,"
          "updated_at INTEGER DEFAULT (strftime('%s', 'now'))"
          ");";
    
    if(!DatabaseExecute(db_handle, sql)) {
        Print("❌ DatabaseSetup: Failed to create DBInfo table");
        return false;
    }
    
    // Create indexes and insert metadata
    CreateIndexes(db_handle, true);
    InsertMetadata(db_handle, "sourcedb");
    
    return true;
}

//+------------------------------------------------------------------+
//| Create test input database structure (OHLCVT only)              |
//+------------------------------------------------------------------+
bool CDatabaseSetup::CreateTestInputStructure(int db_handle)
{
    string sql = 
        "CREATE TABLE IF NOT EXISTS AllCandleData ("
        "asset_symbol TEXT NOT NULL,"
        "timeframe TEXT NOT NULL,"
        "timestamp INTEGER NOT NULL,"
        "open REAL NOT NULL,"
        "high REAL NOT NULL,"
        "low REAL NOT NULL,"
        "close REAL NOT NULL,"
        "tick_volume INTEGER NOT NULL,"
        "real_volume INTEGER NOT NULL,"
        "UNIQUE(asset_symbol, timeframe, timestamp)"
        ");";
    
    if(!DatabaseExecute(db_handle, sql)) {
        Print("❌ DatabaseSetup: Failed to create test input table");
        return false;
    }
    
    CreateIndexes(db_handle, false);
    InsertMetadata(db_handle, "test_input");
    
    return true;
}

//+------------------------------------------------------------------+
//| Create test output database structure (Enhanced with metadata)   |
//+------------------------------------------------------------------+
bool CDatabaseSetup::CreateTestOutputStructure(int db_handle)
{
    string sql = 
        "CREATE TABLE IF NOT EXISTS AllCandleData ("
        "asset_symbol TEXT NOT NULL,"
        "timeframe TEXT NOT NULL,"
        "timestamp INTEGER NOT NULL,"
        "open REAL NOT NULL,"
        "high REAL NOT NULL,"
        "low REAL NOT NULL,"
        "close REAL NOT NULL,"
        "tick_volume INTEGER NOT NULL,"
        "real_volume INTEGER NOT NULL,"
        "hash TEXT NOT NULL,"
        "is_validated INTEGER DEFAULT 0,"
        "is_complete INTEGER DEFAULT 0,"
        "validation_time INTEGER DEFAULT 0,"
        "UNIQUE(asset_symbol, timeframe, timestamp)"
        ");";
    
    if(!DatabaseExecute(db_handle, sql)) {
        Print("❌ DatabaseSetup: Failed to create test output table");
        return false;
    }
    // Ensure DBInfo table exists before inserting metadata
    string dbinfo_sql = "CREATE TABLE IF NOT EXISTS DBInfo ("
                        "key TEXT PRIMARY KEY,"
                        "value TEXT NOT NULL,"
                        "updated_at INTEGER DEFAULT (strftime('%s', 'now'))"
                        ");";
    if(!DatabaseExecute(db_handle, dbinfo_sql)) {
        Print("❌ DatabaseSetup: Failed to create DBInfo table for test output");
        return false;
    }
    CreateIndexes(db_handle, true);
    InsertMetadata(db_handle, "test_output");
    
    return true;
}

//+------------------------------------------------------------------+
//| Create database indexes                                          |
//+------------------------------------------------------------------+
bool CDatabaseSetup::CreateIndexes(int db_handle, bool is_main_db = true)
{
    DatabaseExecute(db_handle, "CREATE INDEX IF NOT EXISTS idx_symbol_timeframe ON AllCandleData(asset_symbol, timeframe);");
    DatabaseExecute(db_handle, "CREATE INDEX IF NOT EXISTS idx_timestamp ON AllCandleData(timestamp);");
    
    if(is_main_db) {
        DatabaseExecute(db_handle, "CREATE INDEX IF NOT EXISTS idx_validation ON AllCandleData(is_validated, validation_time);");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Insert database metadata                                         |
//+------------------------------------------------------------------+
bool CDatabaseSetup::InsertMetadata(int db_handle, string db_type)
{
    string sql = StringFormat(
        "INSERT OR REPLACE INTO DBInfo (key, value) VALUES "
        "('database_version', '4.00'),"
        "('database_type', '%s'),"
        "('created_at', strftime('%%s', 'now')),"
        "('setup_by', 'CDatabaseSetup');",
        db_type
    );
    
    return DatabaseExecute(db_handle, sql);
}
