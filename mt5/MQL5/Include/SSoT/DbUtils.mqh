//+------------------------------------------------------------------+
//| DbUtils.mqh - Database Utility Functions                        |
//| Contains low-level database helper functions extracted from      |
//| SSoT_EA.mq5 for Phase 1 Code Modularization                     |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.0.0"

// HF-3a: Define PERIOD_EMPTY constant for unknown timeframes (temporary fix)
#define PERIOD_EMPTY ((ENUM_TIMEFRAMES)0)

//+------------------------------------------------------------------+
//| Database Execute with Retry Logic (Phase A4)                    |
//| Extracted from SSoT_EA.mq5 - DatabaseExecuteRetry function      |
//+------------------------------------------------------------------+
bool DatabaseExecuteRetry(int database_handle, string sql, int retries = 3, int delay_ms = 50)
{
    if(database_handle == INVALID_HANDLE)
    {
        Print("❌ DatabaseExecuteRetry: Invalid database handle");
        return false;
    }
    
    for(int attempt = 1; attempt <= retries; attempt++)
    {
        ResetLastError();
        if(DatabaseExecute(database_handle, sql))
        {
            if(attempt > 1)
            {
                Print("✅ DatabaseExecuteRetry: SQL succeeded on attempt ", attempt);
            }
            return true;
        }
        
        int error_code = GetLastError();
        Print("❌ DatabaseExecuteRetry: Attempt ", attempt, "/", retries, " failed. Error: ", error_code, " SQL: ", StringSubstr(sql, 0, 100), "...");
        
        if(attempt < retries)
        {
            Sleep(delay_ms);
            delay_ms *= 2; // Exponential backoff
        }
    }
    
    Print("❌ DatabaseExecuteRetry: All ", retries, " attempts failed for SQL: ", StringSubstr(sql, 0, 100), "...");
    return false;
}

//+------------------------------------------------------------------+
//| Initialize database with all optimizations                       |
//| Extracted from SSoT_EA.mq5 - InitializeDatabase function        |
//| Enhanced with automatic test mode database fallback logic       |
//+------------------------------------------------------------------+
bool InitializeDatabase(string database_name, int &db_handle)
{
    string actual_database_name = database_name;
    
    // Simple database initialization - no auto-fallback logic
    Print("Initializing database: ", actual_database_name);
    db_handle = DatabaseOpen(actual_database_name, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
    
    if(db_handle == INVALID_HANDLE)
    {
        Print("❌ Failed to open database: ", actual_database_name, ". Error: ", GetLastError());
        return false;
    }
    
    // Enable WAL mode and optimizations
    if(!DatabaseExecuteRetry(db_handle, "PRAGMA journal_mode=WAL;"))
        Print("⚠️ Failed to enable WAL mode, continuing with default journaling");
    else
        Print("✅ WAL mode enabled");
    
    DatabaseExecuteRetry(db_handle, "PRAGMA synchronous=NORMAL;");
    DatabaseExecuteRetry(db_handle, "PRAGMA cache_size=10000;");
    DatabaseExecuteRetry(db_handle, "PRAGMA temp_store=MEMORY;");
    
    // Database integrity check
    int integrity_request = DatabasePrepare(db_handle, "PRAGMA integrity_check;");
    if(integrity_request != INVALID_HANDLE)
    {
        if(DatabaseRead(integrity_request))
        {
            string integrity_result;
            DatabaseColumnText(integrity_request, 0, integrity_result);
            if(integrity_result != "ok")
            {
                Print("❌ Database integrity check failed: ", integrity_result);
                DatabaseFinalize(integrity_request);
                return false;
            }
            Print("✅ Database integrity check passed");
        }
        DatabaseFinalize(integrity_request);
    }
    
    // Create main schema
    string sql_create = 
        "CREATE TABLE IF NOT EXISTS AllCandleData ("
        "asset_symbol TEXT NOT NULL, "
        "timeframe TEXT NOT NULL, "
        "timestamp INTEGER NOT NULL, "
        "open REAL NOT NULL, "
        "high REAL NOT NULL, "
        "low REAL NOT NULL, "
        "close REAL NOT NULL, "
        "tick_volume INTEGER NOT NULL, "
        "real_volume INTEGER NOT NULL, "
        "hash TEXT NOT NULL, "
        "is_validated INTEGER DEFAULT 0, "
        "is_complete INTEGER DEFAULT 0, "        "validation_time INTEGER DEFAULT 0, "
        "PRIMARY KEY (asset_symbol, timeframe, timestamp)"
        ");";
    if(!DatabaseExecuteRetry(db_handle, sql_create))
    {
        Print("❌ Failed to create database schema, error: ", GetLastError());
        return false;
    }
      // Create DBInfo table for database metadata
    Print("🔧 Creating DBInfo table...");
    string sql_dbinfo = 
        "CREATE TABLE IF NOT EXISTS DBInfo ("
        "id INTEGER PRIMARY KEY, "
        "broker_name TEXT NOT NULL, "
        "timezone TEXT NOT NULL, "
        "schema_version TEXT NOT NULL, "
        "created_at INTEGER NOT NULL, "
        "last_updated INTEGER NOT NULL"
        ");";
    
    Print("📝 DBInfo SQL: ", sql_dbinfo);
    if(!DatabaseExecuteRetry(db_handle, sql_dbinfo))
    {
        Print("❌ Failed to create DBInfo table, error: ", GetLastError());
        return false;
    }
    Print("✅ DBInfo table created successfully");
    
    // Initialize DBInfo record
    Print("🔧 Initializing DBInfo record...");
    string broker_name = AccountInfoString(ACCOUNT_COMPANY);
    string timezone = "Server Time";
    string schema_version = "2.20";
    datetime current_time = TimeCurrent();
    
    Print("📊 Broker: ", broker_name, ", Time: ", current_time);
    
    string sql_insert_dbinfo = StringFormat(
        "INSERT OR REPLACE INTO DBInfo (id, broker_name, timezone, schema_version, created_at, last_updated) "
        "VALUES (1, '%s', '%s', '%s', %d, %d);", 
        broker_name, timezone, schema_version, current_time, current_time
    );
    
    Print("📝 Insert SQL: ", sql_insert_dbinfo);
    if(!DatabaseExecuteRetry(db_handle, sql_insert_dbinfo))
    {
        Print("❌ Failed to initialize DBInfo record, error: ", GetLastError());
        return false;
    }
    Print("✅ DBInfo record initialized successfully");
    
    Print("✅ Database initialized with all optimizations");
    return true;
}

//+------------------------------------------------------------------+
//| Database maintenance operations                                  |
//| Extracted from SSoT_EA.mq5 - PerformDatabaseMaintenance         |
//+------------------------------------------------------------------+
void PerformDatabaseMaintenance(int db_handle, datetime &last_maintenance_time, int maintenance_interval)
{
    datetime current_time = TimeCurrent();
    
    if(current_time - last_maintenance_time < maintenance_interval)
        return;
    
    last_maintenance_time = current_time;
    
    Print("🔧 Starting database maintenance...");
    
    if(!DatabaseExecuteRetry(db_handle, "PRAGMA optimize;"))
    {
        Print("⚠️ PRAGMA optimize failed. Error: ", GetLastError());
    }
    
    static datetime last_vacuum = 0;
    if(current_time - last_vacuum > 86400) // 24 hours
    {
        if(!DatabaseExecuteRetry(db_handle, "VACUUM;"))
        {
            Print("⚠️ VACUUM failed. Error: ", GetLastError());
        }
        else
        {
            Print("✅ VACUUM completed");
        }
        last_vacuum = current_time;
    }
    
    Print("✅ Database maintenance completed");
}

//+------------------------------------------------------------------+
//| Database transaction helpers                                     |
//+------------------------------------------------------------------+
bool DatabaseTransactionSafe(int db_handle, string operation_name = "Transaction")
{
    if(!DatabaseTransactionBegin(db_handle))
    {
        Print("❌ Failed to begin ", operation_name, ". Error: ", GetLastError());
        return false;
    }
    return true;
}

bool DatabaseCommitSafe(int db_handle, string operation_name = "Transaction")
{
    if(!DatabaseTransactionCommit(db_handle))
    {
        Print("❌ Failed to commit ", operation_name, ". Error: ", GetLastError());
        DatabaseTransactionRollback(db_handle);
        return false;
    }
    return true;
}

void DatabaseRollbackSafe(int db_handle, string operation_name = "Transaction")
{
    if(!DatabaseTransactionRollback(db_handle))
    {
        Print("❌ Failed to rollback ", operation_name, ". Error: ", GetLastError());
    }
    else
    {
        Print("🔄 Rolled back ", operation_name);
    }
}

//+------------------------------------------------------------------+
//| Initialize Test Database Environment                             |
//| Creates test_input_sourceDB.sqlite and test_output_sourceDB.sqlite|
//| when InpTestMode = true                                          |
//+------------------------------------------------------------------+
bool InitializeTestDatabases(string main_db_name, string input_db_name, string output_db_name)
{
    Print("🧪 TEST MODE: Initializing test database environment...");
    
    // Create test input database with sample data
    int input_handle = DatabaseOpen(input_db_name, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
    if(input_handle == INVALID_HANDLE)
    {
        Print("❌ Failed to create test input database: ", input_db_name);
        return false;
    }
    
    // Initialize input database with same schema and optimizations
    if(!SetupDatabaseSchema(input_handle, "TEST_INPUT"))
    {
        DatabaseClose(input_handle);
        return false;
    }
    
    // Copy some data from main database if it exists
    CopyMainDataToTestInput(main_db_name, input_handle);
    
    DatabaseClose(input_handle);
    Print("✅ Test input database created: ", input_db_name);
    
    // Create test output database (where EA will write results)
    int output_handle = DatabaseOpen(output_db_name, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
    if(output_handle == INVALID_HANDLE)
    {
        Print("❌ Failed to create test output database: ", output_db_name);
        return false;
    }
    
    // Initialize output database with same schema
    if(!SetupDatabaseSchema(output_handle, "TEST_OUTPUT"))
    {
        DatabaseClose(output_handle);
        return false;
    }
    
    DatabaseClose(output_handle);
    Print("✅ Test output database created: ", output_db_name);
    Print("🧪 TEST MODE: Database environment ready for testing");
    
    return true;
}

//+------------------------------------------------------------------+
//| Setup database schema and optimizations                          |
//+------------------------------------------------------------------+
bool SetupDatabaseSchema(int db_handle, string db_type)
{
    // Enable WAL mode and optimizations
    if(!DatabaseExecuteRetry(db_handle, "PRAGMA journal_mode=WAL;"))
        Print("⚠️ Failed to enable WAL mode for ", db_type);
    
    DatabaseExecuteRetry(db_handle, "PRAGMA synchronous=NORMAL;");
    DatabaseExecuteRetry(db_handle, "PRAGMA cache_size=10000;");
    DatabaseExecuteRetry(db_handle, "PRAGMA temp_store=MEMORY;");
    
    // Create main schema
    string sql_create = 
        "CREATE TABLE IF NOT EXISTS AllCandleData ("
        "asset_symbol TEXT NOT NULL, "
        "timeframe TEXT NOT NULL, "
        "timestamp INTEGER NOT NULL, "
        "open REAL NOT NULL, "
        "high REAL NOT NULL, "
        "low REAL NOT NULL, "
        "close REAL NOT NULL, "
        "tick_volume INTEGER NOT NULL, "
        "real_volume INTEGER NOT NULL, "
        "hash TEXT NOT NULL, "
        "is_validated INTEGER DEFAULT 0, "
        "is_complete INTEGER DEFAULT 0, "
        "validation_time INTEGER DEFAULT 0, "
        "PRIMARY KEY (asset_symbol, timeframe, timestamp)"
        ");";
    
    if(!DatabaseExecuteRetry(db_handle, sql_create))
    {
        Print("❌ Failed to create schema for ", db_type);
        return false;
    }
    
    // Create DBInfo table
    string sql_dbinfo = 
        "CREATE TABLE IF NOT EXISTS DBInfo ("
        "id INTEGER PRIMARY KEY, "
        "broker_name TEXT NOT NULL, "
        "timezone TEXT NOT NULL, "
        "schema_version TEXT NOT NULL, "
        "created_at INTEGER NOT NULL, "
        "last_updated INTEGER NOT NULL"
        ");";
    
    if(!DatabaseExecuteRetry(db_handle, sql_dbinfo))
    {
        Print("❌ Failed to create DBInfo table for ", db_type);
        return false;
    }    // Initialize DBInfo record with proper timezone information
    string broker_name = AccountInfoString(ACCOUNT_COMPANY);
    string schema_version = "2.20";
    
    // Get actual server timezone information - ALL databases use same timezone
    string timezone = "";
    MqlDateTime server_time;
    TimeCurrent(server_time);
    timezone = "GMT" + StringFormat("%+d", (int)((TimeCurrent() - TimeGMT()) / 3600));
    
    datetime current_time = TimeCurrent();
      string sql_insert_dbinfo = StringFormat(
        "INSERT OR REPLACE INTO DBInfo (id, broker_name, timezone, schema_version, created_at, last_updated) "
        "VALUES (1, '%s', '%s', '%s', %d, %d);", 
        broker_name, timezone, schema_version, current_time, current_time
    );
    
    if(!DatabaseExecuteRetry(db_handle, sql_insert_dbinfo))
    {
        Print("❌ Failed to initialize DBInfo for ", db_type);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Copy sample data from main database to test input database      |
//+------------------------------------------------------------------+
void CopyMainDataToTestInput(string main_db_name, int test_input_handle)
{
    int main_handle = DatabaseOpen(main_db_name, DATABASE_OPEN_READONLY);
    if(main_handle == INVALID_HANDLE)
    {
        Print("📊 No main database found, creating sample test data...");
        CreateSampleTestData(test_input_handle);
        return;
    }
      // Copy more recent data (last 1000 bars) for better testing coverage
    string copy_sql = 
        "SELECT asset_symbol, timeframe, timestamp, open, high, low, close, "
        "tick_volume, real_volume, hash, is_validated, is_complete, validation_time "
        "FROM AllCandleData ORDER BY timestamp DESC LIMIT 1000;";
    
    int request = DatabasePrepare(main_handle, copy_sql);
    if(request == INVALID_HANDLE)
    {
        DatabaseClose(main_handle);
        CreateSampleTestData(test_input_handle);
        return;
    }
    
    int copied_count = 0;
    while(DatabaseRead(request))
    {
        string asset_symbol, timeframe, hash;
        long timestamp, tick_volume, real_volume, is_validated, is_complete, validation_time;
        double open, high, low, close;
        
        DatabaseColumnText(request, 0, asset_symbol);
        DatabaseColumnText(request, 1, timeframe);
        DatabaseColumnLong(request, 2, timestamp);
        DatabaseColumnDouble(request, 3, open);
        DatabaseColumnDouble(request, 4, high);
        DatabaseColumnDouble(request, 5, low);
        DatabaseColumnDouble(request, 6, close);
        DatabaseColumnLong(request, 7, tick_volume);
        DatabaseColumnLong(request, 8, real_volume);
        DatabaseColumnText(request, 9, hash);
        DatabaseColumnLong(request, 10, is_validated);
        DatabaseColumnLong(request, 11, is_complete);
        DatabaseColumnLong(request, 12, validation_time);
        
        string insert_sql = StringFormat(
            "INSERT OR REPLACE INTO AllCandleData "
            "(asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, real_volume, hash, is_validated, is_complete, validation_time) "
            "VALUES ('%s','%s',%I64d,%.8f,%.8f,%.8f,%.8f,%I64d,%I64d,'%s',%d,%d,%I64d);",
            asset_symbol, timeframe, timestamp, open, high, low, close, 
            tick_volume, real_volume, hash, is_validated, is_complete, validation_time
        );
        
        if(DatabaseExecuteRetry(test_input_handle, insert_sql))
            copied_count++;
    }
    
    DatabaseFinalize(request);
    DatabaseClose(main_handle);
    
    Print("📊 Copied ", copied_count, " records to test input database");
}

//+------------------------------------------------------------------+
//| Create sample test data when no main database exists             |
//+------------------------------------------------------------------+
void CreateSampleTestData(int db_handle)
{
    Print("📊 Creating sample test data...");
    
    datetime current_time = TimeCurrent();
    int sample_count = 50;
    
    for(int i = 0; i < sample_count; i++)
    {
        datetime bar_time = current_time - (i * 60); // 1-minute bars
        double base_price = 1.1000 + (MathRand() % 1000) * 0.0001;
        double open = base_price;
        double high = open + (MathRand() % 50) * 0.0001;
        double low = open - (MathRand() % 50) * 0.0001;
        double close = low + (MathRand() % (int)((high - low) * 10000)) * 0.0001;
        long volume = 100 + MathRand() % 900;
        
        // Create a simple hash for test data
        string test_hash = StringFormat("TEST_%I64d_%d", bar_time, i);
        
        string insert_sql = StringFormat(
            "INSERT INTO AllCandleData "
            "(asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, real_volume, hash, is_validated, is_complete) "
            "VALUES ('BTCUSD','M1',%I64d,%.5f,%.5f,%.5f,%.5f,%d,%d,'%s',0,0);",
            bar_time, open, high, low, close, volume, volume, test_hash
        );
        
        DatabaseExecuteRetry(db_handle, insert_sql);
    }
    
    Print("✅ Created ", sample_count, " sample test records");
}

//+------------------------------------------------------------------+
//| Create DBInfo table for existing database (if possible)          |
//+------------------------------------------------------------------+
bool CreateDBInfoForExistingDatabase(int db_handle, string db_type)
{
    Print("🔧 Checking/updating DBInfo schema for ", db_type, "...");
    
    // First, check if DBInfo table exists at all
    int check_request = DatabasePrepare(db_handle, "SELECT name FROM sqlite_master WHERE type='table' AND name='DBInfo'");
    bool dbinfo_exists = false;
    if(check_request != INVALID_HANDLE && DatabaseRead(check_request)) {
        dbinfo_exists = true;
        DatabaseFinalize(check_request);
    } else if(check_request != INVALID_HANDLE) {
        DatabaseFinalize(check_request);
    }
    
    if(dbinfo_exists) {
        Print("📋 DBInfo table exists, checking schema for ", db_type);
        
        // Check if the table has the new schema (id and broker_name columns)
        check_request = DatabasePrepare(db_handle, "PRAGMA table_info(DBInfo)");
        bool has_id_column = false;
        bool has_broker_name_column = false;
        
        if(check_request != INVALID_HANDLE) {
            while(DatabaseRead(check_request)) {
                string column_name;
                DatabaseColumnText(check_request, 1, column_name); // Column name is in index 1
                if(column_name == "id") has_id_column = true;
                if(column_name == "broker_name") has_broker_name_column = true;
            }
            DatabaseFinalize(check_request);
        }
        
        if(has_id_column && has_broker_name_column) {
            Print("✅ DBInfo schema is current for ", db_type);
            
            // Check if it has data
            check_request = DatabasePrepare(db_handle, "SELECT COUNT(*) FROM DBInfo WHERE id=1");
            if(check_request != INVALID_HANDLE && DatabaseRead(check_request)) {
                int count = 0;
                DatabaseColumnInteger(check_request, 0, count);
                DatabaseFinalize(check_request);
                
                if(count > 0) {
                    Print("✅ DBInfo data already exists for ", db_type);
                    return true;
                }
            }
        } else {
            Print("🔄 DBInfo schema needs migration for ", db_type);
              // Backup existing data if any
            string old_timezone = "", old_schema_version = "";
            datetime old_created_at = 0, old_last_updated = 0;
            
            check_request = DatabasePrepare(db_handle, "SELECT timezone, schema_version, created_at, last_updated FROM DBInfo LIMIT 1");
            if(check_request != INVALID_HANDLE && DatabaseRead(check_request)) {
                DatabaseColumnText(check_request, 0, old_timezone);
                DatabaseColumnText(check_request, 1, old_schema_version);
                
                // Use temporary int variables for DatabaseColumnInteger
                int temp_created_at = 0, temp_last_updated = 0;
                DatabaseColumnInteger(check_request, 2, temp_created_at);
                DatabaseColumnInteger(check_request, 3, temp_last_updated);
                old_created_at = (datetime)temp_created_at;
                old_last_updated = (datetime)temp_last_updated;
                
                DatabaseFinalize(check_request);
                Print("📤 Backed up existing DBInfo data: ", old_timezone, ", ", old_schema_version);
            } else if(check_request != INVALID_HANDLE) {
                DatabaseFinalize(check_request);
            }
            
            // Drop and recreate table with new schema
            if(!DatabaseExecuteRetry(db_handle, "DROP TABLE IF EXISTS DBInfo_backup")) {
                Print("⚠️ Warning: Could not create backup table for ", db_type);
            }
            
            if(!DatabaseExecuteRetry(db_handle, "ALTER TABLE DBInfo RENAME TO DBInfo_backup")) {
                Print("⚠️ Warning: Could not rename old DBInfo table for ", db_type);
            }
            
            // Create new table with proper schema
            string sql_dbinfo = 
                "CREATE TABLE IF NOT EXISTS DBInfo ("
                "id INTEGER PRIMARY KEY, "
                "broker_name TEXT NOT NULL, "
                "timezone TEXT NOT NULL, "
                "schema_version TEXT NOT NULL, "
                "created_at INTEGER NOT NULL, "
                "last_updated INTEGER NOT NULL"
                ");";
            
            if(!DatabaseExecuteRetry(db_handle, sql_dbinfo)) {
                Print("❌ Failed to create new DBInfo table for ", db_type);
                return false;
            }
            
            // Restore data with new schema
            string broker_name = AccountInfoString(ACCOUNT_COMPANY);
            string timezone = old_timezone != "" ? old_timezone : "GMT+0";
            string schema_version = "2.20";
            datetime current_time = TimeCurrent();
            datetime created_at = old_created_at > 0 ? old_created_at : current_time;
            
            string sql_insert = StringFormat(
                "INSERT OR REPLACE INTO DBInfo (id, broker_name, timezone, schema_version, created_at, last_updated) "
                "VALUES (1, '%s', '%s', '%s', %d, %d);", 
                broker_name, timezone, schema_version, created_at, current_time
            );
            
            if(!DatabaseExecuteRetry(db_handle, sql_insert)) {
                Print("❌ Failed to migrate DBInfo data for ", db_type);
                return false;
            }
            
            Print("✅ DBInfo schema migrated successfully for ", db_type);
            return true;
        }
    }    
    // Try to create DBInfo table (this handles the case where table doesn't exist)
    string sql_dbinfo = 
        "CREATE TABLE IF NOT EXISTS DBInfo ("
        "id INTEGER PRIMARY KEY, "
        "broker_name TEXT NOT NULL, "
        "timezone TEXT NOT NULL, "
        "schema_version TEXT NOT NULL, "
        "created_at INTEGER NOT NULL, "
        "last_updated INTEGER NOT NULL"
        ");";
    
    if(!DatabaseExecuteRetry(db_handle, sql_dbinfo)) {
        Print("❌ Failed to create DBInfo table for ", db_type, " (may be READONLY)");
        return false;
    }
      
    // Initialize DBInfo record
    string broker_name = AccountInfoString(ACCOUNT_COMPANY);
    string schema_version = "2.20";
    
    // Get actual server timezone - ALL databases use same timezone
    string timezone = "";
    MqlDateTime server_time;
    TimeCurrent(server_time);
    timezone = "GMT" + StringFormat("%+d", (int)((TimeCurrent() - TimeGMT()) / 3600));
    
    datetime current_time = TimeCurrent();
    
    string sql_insert_dbinfo = StringFormat(
        "INSERT OR REPLACE INTO DBInfo (id, broker_name, timezone, schema_version, created_at, last_updated) "
        "VALUES (1, '%s', '%s', '%s', %d, %d);", 
        broker_name, timezone, schema_version, current_time, current_time
    );
    
    if(!DatabaseExecuteRetry(db_handle, sql_insert_dbinfo)) {
        Print("❌ Failed to initialize DBInfo for ", db_type, " (may be READONLY)");
        return false;
    }
    
    Print("✅ Created/updated DBInfo for ", db_type);
    return true;
}
