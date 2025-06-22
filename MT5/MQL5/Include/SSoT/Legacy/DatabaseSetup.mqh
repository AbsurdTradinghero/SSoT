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
    
    // Comprehensive database validation
    static bool ValidateAllDatabases(int main_db_handle,
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
    
    // Validation helpers
    static bool ValidateDatabaseStructure(int db_handle, string db_type);
    static bool ValidateRequiredTables(int db_handle, string db_type);
    static bool ValidateRequiredIndexes(int db_handle, string db_type);
    static bool ValidateMetadata(int db_handle, string db_type);
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

//+------------------------------------------------------------------+
//| Validate all databases comprehensively                          |
//+------------------------------------------------------------------+
bool CDatabaseSetup::ValidateAllDatabases(int main_db_handle,
                                         int test_input_db_handle = INVALID_HANDLE,
                                         int test_output_db_handle = INVALID_HANDLE,
                                         bool is_test_mode = false)
{
    Print("🔍 DatabaseSetup: Starting comprehensive database validation...");
    
    // Validate main database
    if(main_db_handle == INVALID_HANDLE) {
        Print("❌ DatabaseSetup: Invalid main database handle for validation");
        return false;
    }
    
    if(!ValidateDatabaseStructure(main_db_handle, "sourcedb")) {
        Print("❌ DatabaseSetup: Main database validation failed");
        return false;
    }
    
    // Validate test databases if test mode is enabled
    if(is_test_mode) {
        if(test_input_db_handle != INVALID_HANDLE) {
            if(!ValidateDatabaseStructure(test_input_db_handle, "test_input")) {
                Print("❌ DatabaseSetup: Test input database validation failed");
                return false;
            }
        } else {
            Print("⚠️ DatabaseSetup: Test mode enabled but input database handle is invalid");
        }
        
        if(test_output_db_handle != INVALID_HANDLE) {
            if(!ValidateDatabaseStructure(test_output_db_handle, "test_output")) {
                Print("❌ DatabaseSetup: Test output database validation failed");
                return false;
            }
        } else {
            Print("⚠️ DatabaseSetup: Test mode enabled but output database handle is invalid");
        }
        
        Print("✅ DatabaseSetup: All databases (main + test) validated successfully");
    } else {
        Print("✅ DatabaseSetup: Main database validated successfully");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Validate individual database structure                          |
//+------------------------------------------------------------------+
bool CDatabaseSetup::ValidateDatabaseStructure(int db_handle, string db_type)
{
    Print("🔍 Validating ", db_type, " database structure...");
    
    if(!ValidateRequiredTables(db_handle, db_type)) {
        Print("❌ Required tables validation failed for ", db_type);
        return false;
    }
    
    if(!ValidateRequiredIndexes(db_handle, db_type)) {
        Print("❌ Required indexes validation failed for ", db_type);
        return false;
    }
    
    if(!ValidateMetadata(db_handle, db_type)) {
        Print("❌ Metadata validation failed for ", db_type);
        return false;
    }
    
    Print("✅ Database structure validated: ", db_type);
    return true;
}

//+------------------------------------------------------------------+
//| Validate required tables exist                                  |
//+------------------------------------------------------------------+
bool CDatabaseSetup::ValidateRequiredTables(int db_handle, string db_type)
{
    // Check AllCandleData table exists
    string sql = "SELECT name FROM sqlite_master WHERE type='table' AND name='AllCandleData';";
    int request = DatabasePrepare(db_handle, sql);
    if(request == INVALID_HANDLE) {
        Print("❌ Failed to prepare table validation query for ", db_type);
        return false;
    }
    
    bool table_exists = false;
    if(DatabaseRead(request)) {
        string table_name;
        DatabaseColumnText(request, 0, table_name);
        if(table_name == "AllCandleData") {
            table_exists = true;
        }
    }
    DatabaseFinalize(request);
    
    if(!table_exists) {
        Print("❌ AllCandleData table missing in ", db_type);
        return false;
    }
    
    // Check DBInfo table for non-test_input databases
    if(db_type != "test_input") {
        sql = "SELECT name FROM sqlite_master WHERE type='table' AND name='DBInfo';";
        request = DatabasePrepare(db_handle, sql);
        if(request == INVALID_HANDLE) {
            Print("❌ Failed to prepare DBInfo validation query for ", db_type);
            return false;
        }
        
        bool dbinfo_exists = false;
        if(DatabaseRead(request)) {
            string table_name;
            DatabaseColumnText(request, 0, table_name);
            if(table_name == "DBInfo") {
                dbinfo_exists = true;
            }
        }
        DatabaseFinalize(request);
        
        if(!dbinfo_exists) {
            Print("❌ DBInfo table missing in ", db_type);
            return false;
        }
    }
    
    Print("✅ Required tables validated for ", db_type);
    return true;
}

//+------------------------------------------------------------------+
//| Validate required indexes exist                                 |
//+------------------------------------------------------------------+
bool CDatabaseSetup::ValidateRequiredIndexes(int db_handle, string db_type)
{
    string required_indexes[];
    ArrayResize(required_indexes, 3);
    required_indexes[0] = "idx_symbol_timeframe";
    required_indexes[1] = "idx_timestamp";
    
    // Main database and test output have validation index
    if(db_type == "sourcedb" || db_type == "test_output") {
        ArrayResize(required_indexes, 3);
        required_indexes[2] = "idx_validation";
    } else {
        ArrayResize(required_indexes, 2);
    }
    
    for(int i = 0; i < ArraySize(required_indexes); i++) {
        string index_name = required_indexes[i];
        string sql = StringFormat("SELECT name FROM sqlite_master WHERE type='index' AND name='%s';", index_name);
        
        int request = DatabasePrepare(db_handle, sql);
        if(request == INVALID_HANDLE) {
            Print("❌ Failed to prepare index validation query for ", index_name, " in ", db_type);
            return false;
        }
        
        bool index_exists = false;
        if(DatabaseRead(request)) {
            string found_name;
            DatabaseColumnText(request, 0, found_name);
            if(found_name == index_name) {
                index_exists = true;
            }
        }
        DatabaseFinalize(request);
        
        if(!index_exists) {
            Print("❌ Index ", index_name, " missing in ", db_type);
            return false;
        }
    }
    
    Print("✅ Required indexes validated for ", db_type);
    return true;
}

//+------------------------------------------------------------------+
//| Validate metadata is correct                                    |
//+------------------------------------------------------------------+
bool CDatabaseSetup::ValidateMetadata(int db_handle, string db_type)
{
    // Test input database doesn't have DBInfo table
    if(db_type == "test_input") {
        return true;
    }
    
    string sql = "SELECT value FROM DBInfo WHERE key='database_type';";
    int request = DatabasePrepare(db_handle, sql);
    if(request == INVALID_HANDLE) {
        Print("❌ Failed to prepare metadata validation query for ", db_type);
        return false;
    }
    
    bool metadata_valid = false;
    if(DatabaseRead(request)) {
        string stored_type;
        DatabaseColumnText(request, 0, stored_type);
        if(stored_type == db_type) {
            metadata_valid = true;
        } else {
            Print("❌ Database type mismatch: expected ", db_type, ", found ", stored_type);
        }
    } else {
        Print("❌ No database_type metadata found in ", db_type);
    }
    DatabaseFinalize(request);
    
    if(!metadata_valid) {
        Print("❌ Metadata validation failed for ", db_type);
        return false;
    }
    
    Print("✅ Metadata validated for ", db_type);
    return true;
}
