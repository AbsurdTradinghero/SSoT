//+------------------------------------------------------------------+
//| DatabaseManager.mqh                                             |
//| Handles all database operations for SSoT system                 |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Database Manager Class                                           |
//+------------------------------------------------------------------+
class CDatabaseManager
{
private:
    int     m_main_db;
    int     m_test_input_db;
    int     m_test_output_db;
    bool    m_test_mode_active;
    
public:
    // Constructor/Destructor
    CDatabaseManager() : m_main_db(INVALID_HANDLE), 
                        m_test_input_db(INVALID_HANDLE), 
                        m_test_output_db(INVALID_HANDLE),
                        m_test_mode_active(false) {}
    ~CDatabaseManager() { CloseAllDatabases(); }
    
    // Main initialization
    bool Initialize(string main_db_name, bool enable_test_mode = false, 
                   string test_input_db = "", string test_output_db = "");
    
    // Database operations
    bool CreateMainDatabaseStructure();
    bool CreateTestDatabaseStructures();
    void CloseAllDatabases();
    
    // Getters
    int GetMainHandle() const { return m_main_db; }
    int GetTestInputHandle() const { return m_test_input_db; }
    int GetTestOutputHandle() const { return m_test_output_db; }
    bool IsTestModeActive() const { return m_test_mode_active; }
    
    // Data insertion methods
    bool InsertMarketData(const string symbol, ENUM_TIMEFRAMES timeframe, 
                         datetime timestamp, double open, double high, double low, 
                         double close, long tick_volume, long real_volume = 0,
                         const string verification_hash = "");
    
    // Data retrieval methods
    bool GetLastBarTime(const string symbol, ENUM_TIMEFRAMES timeframe, datetime &last_time);
    bool GetMarketData(const string symbol, ENUM_TIMEFRAMES timeframe, 
                      datetime from_time, datetime to_time, 
                      double &opens[], double &highs[], double &lows[], 
                      double &closes[], long &volumes[], datetime &times[]);
    
    // Validation methods
    bool ValidateDatabaseIntegrity();
    bool ValidateDataRange(const string symbol, ENUM_TIMEFRAMES timeframe, 
                          datetime from_time, datetime to_time);
    
    // Utility methods
    bool OptimizeDatabases();
    string GetDatabaseStats();
    bool ExecuteQuery(const string query, int database_handle = INVALID_HANDLE);
    
    // Test mode specific methods
    bool InsertTestInputData(const string symbol, ENUM_TIMEFRAMES timeframe,
                           datetime timestamp, double open, double high, double low,
                           double close, long tick_volume, long real_volume = 0);
    bool InsertTestOutputData(const string symbol, ENUM_TIMEFRAMES timeframe,
                            datetime timestamp, double open, double high, double low,
                            double close, long tick_volume, long real_volume,
                            const string hash, bool is_validated, bool is_complete);
};

//+------------------------------------------------------------------+
//| Initialize database connections                                  |
//+------------------------------------------------------------------+
bool CDatabaseManager::Initialize(string main_db_name, bool enable_test_mode = false,
                                 string test_input_db = "", string test_output_db = "")
{
    // Initialize main database
    m_main_db = DatabaseOpen(main_db_name, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
    if(m_main_db == INVALID_HANDLE) {
        Print("❌ Failed to open main database: ", main_db_name);
        return false;
    }
    
    // Create main database structure
    if(!CreateMainDatabaseStructure()) {
        Print("❌ Failed to create main database structure");
        return false;
    }
    
    // Initialize test mode databases if enabled
    if(enable_test_mode) {
        m_test_mode_active = true;
        
        // Test input database (OHLCVT data)
        m_test_input_db = DatabaseOpen(test_input_db, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
        if(m_test_input_db == INVALID_HANDLE) {
            Print("❌ Failed to open test input database: ", test_input_db);
            return false;
        }
        
        // Test output database (Enhanced metadata)
        m_test_output_db = DatabaseOpen(test_output_db, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
        if(m_test_output_db == INVALID_HANDLE) {
            Print("❌ Failed to open test output database: ", test_output_db);
            return false;
        }
        
        // Create test database structures
        if(!CreateTestDatabaseStructures()) {
            Print("❌ Failed to create test database structures");
            return false;
        }
        
        Print("✅ Test mode databases initialized");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Create main database structure                                   |
//+------------------------------------------------------------------+
bool CDatabaseManager::CreateMainDatabaseStructure()
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
    
    if(!DatabaseExecute(m_main_db, sql)) {
        Print("❌ Failed to create AllCandleData table");
        return false;
    }
    
    // Create DBInfo table
    sql = "CREATE TABLE IF NOT EXISTS DBInfo ("
          "key TEXT PRIMARY KEY,"
          "value TEXT NOT NULL,"
          "updated_at INTEGER DEFAULT (strftime('%s', 'now'))"
          ");";
    
    if(!DatabaseExecute(m_main_db, sql)) {
        Print("❌ Failed to create DBInfo table");
        return false;
    }
    
    // Insert initial metadata
    sql = "INSERT OR REPLACE INTO DBInfo (key, value) VALUES "
          "('database_version', '3.10'),"
          "('database_type', 'sourcedb'),"
          "('created_at', strftime('%s', 'now'));";
    
    DatabaseExecute(m_main_db, sql);
    
    // Create indexes
    DatabaseExecute(m_main_db, "CREATE INDEX IF NOT EXISTS idx_symbol_timeframe ON AllCandleData(asset_symbol, timeframe);");
    DatabaseExecute(m_main_db, "CREATE INDEX IF NOT EXISTS idx_timestamp ON AllCandleData(timestamp);");
    
    return true;
}

//+------------------------------------------------------------------+
//| Create test database structures                                  |
//+------------------------------------------------------------------+
bool CDatabaseManager::CreateTestDatabaseStructures()
{
    // Test input database - OHLCVT data only
    string sql_input = 
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
    
    if(!DatabaseExecute(m_test_input_db, sql_input)) {
        Print("❌ Failed to create test input table");
        return false;
    }
    
    // Test output database - Enhanced with metadata
    string sql_output = 
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
    
    if(!DatabaseExecute(m_test_output_db, sql_output)) {
        Print("❌ Failed to create test output table");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Close all database connections                                   |
//+------------------------------------------------------------------+
void CDatabaseManager::CloseAllDatabases()
{
    // Close main database
    if(m_main_db != INVALID_HANDLE) {
        DatabaseClose(m_main_db);
        m_main_db = INVALID_HANDLE;
    }
    
    // Close test databases
    if(m_test_mode_active) {
        if(m_test_input_db != INVALID_HANDLE) {
            DatabaseClose(m_test_input_db);
            m_test_input_db = INVALID_HANDLE;
        }
        if(m_test_output_db != INVALID_HANDLE) {
            DatabaseClose(m_test_output_db);
            m_test_output_db = INVALID_HANDLE;
        }
        Print("🧪 Test mode databases closed");
    }
}

//+------------------------------------------------------------------+
//| Insert market data into main database                           |
//+------------------------------------------------------------------+
bool CDatabaseManager::InsertMarketData(const string symbol, ENUM_TIMEFRAMES timeframe, 
                                       datetime timestamp, double open, double high, double low, 
                                       double close, long tick_volume, long real_volume = 0,
                                       const string verification_hash = "")
{
    if(m_main_db == INVALID_HANDLE) {
        Print("❌ ERROR: Main database not initialized");
        return false;
    }
    
    string tf_string = "";
    switch(timeframe) {
        case PERIOD_M1: tf_string = "M1"; break;
        case PERIOD_M5: tf_string = "M5"; break;
        case PERIOD_M15: tf_string = "M15"; break;
        case PERIOD_H1: tf_string = "H1"; break;
        case PERIOD_D1: tf_string = "D1"; break;
        default: tf_string = "M1"; break;
    }
    
    string query = StringFormat(
        "INSERT OR REPLACE INTO AllCandleData "
        "(asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, real_volume, hash, is_validated, is_complete, validation_time) "
        "VALUES ('%s', '%s', %d, %.5f, %.5f, %.5f, %.5f, %d, %d, '%s', 1, 1, %d)",
        symbol, tf_string, timestamp, open, high, low, close, tick_volume, real_volume, 
        verification_hash, TimeCurrent()
    );
    
    return DatabaseExecute(m_main_db, query);
}

//+------------------------------------------------------------------+
//| Get last bar time for symbol/timeframe                          |
//+------------------------------------------------------------------+
bool CDatabaseManager::GetLastBarTime(const string symbol, ENUM_TIMEFRAMES timeframe, datetime &last_time)
{
    if(m_main_db == INVALID_HANDLE) {
        last_time = 0;
        return false;
    }
    
    string tf_string = "";
    switch(timeframe) {
        case PERIOD_M1: tf_string = "M1"; break;
        case PERIOD_M5: tf_string = "M5"; break;
        case PERIOD_M15: tf_string = "M15"; break;
        case PERIOD_H1: tf_string = "H1"; break;
        case PERIOD_D1: tf_string = "D1"; break;
        default: tf_string = "M1"; break;
    }
    
    string query = StringFormat(
        "SELECT MAX(timestamp) FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s'",
        symbol, tf_string
    );
    
    int request = DatabasePrepare(m_main_db, query);
    if(request == INVALID_HANDLE) {
        last_time = 0;
        return false;
    }
      if(DatabaseRead(request)) {
        long timestamp_value;
        if(DatabaseColumnLong(request, 0, timestamp_value)) {
            last_time = (datetime)timestamp_value;
        } else {
            last_time = 0;
        }
    } else {
        last_time = 0;
    }
    
    DatabaseFinalize(request);
    return (last_time > 0);
}

//+------------------------------------------------------------------+
//| Validate database integrity                                     |
//+------------------------------------------------------------------+
bool CDatabaseManager::ValidateDatabaseIntegrity()
{
    if(m_main_db == INVALID_HANDLE) {
        Print("❌ ERROR: Main database not initialized");
        return false;
    }
    
    // Check if main table exists
    string query = "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='AllCandleData'";
    int request = DatabasePrepare(m_main_db, query);
    if(request == INVALID_HANDLE) {
        Print("❌ ERROR: Failed to prepare integrity check query");
        return false;
    }
      bool result = false;
    if(DatabaseRead(request)) {
        long table_count_value;
        if(DatabaseColumnLong(request, 0, table_count_value)) {
            result = (table_count_value > 0);
        }
    }
    
    DatabaseFinalize(request);
    
    if(!result) {
        Print("❌ ERROR: Main database table missing");
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Optimize database performance                                   |
//+------------------------------------------------------------------+
bool CDatabaseManager::OptimizeDatabases()
{
    bool success = true;
    
    // Optimize main database
    if(m_main_db != INVALID_HANDLE) {
        if(!DatabaseExecute(m_main_db, "VACUUM")) {
            Print("⚠️ WARNING: Failed to vacuum main database");
            success = false;
        }
        if(!DatabaseExecute(m_main_db, "ANALYZE")) {
            Print("⚠️ WARNING: Failed to analyze main database");
            success = false;
        }
    }
    
    // Optimize test databases if active
    if(m_test_mode_active) {
        if(m_test_input_db != INVALID_HANDLE) {
            DatabaseExecute(m_test_input_db, "VACUUM");
            DatabaseExecute(m_test_input_db, "ANALYZE");
        }
        if(m_test_output_db != INVALID_HANDLE) {
            DatabaseExecute(m_test_output_db, "VACUUM");
            DatabaseExecute(m_test_output_db, "ANALYZE");
        }
    }
    
    if(success) {
        Print("✅ Database optimization completed");
    }
    
    return success;
}

//+------------------------------------------------------------------+
//| Execute query on specified database                             |
//+------------------------------------------------------------------+
bool CDatabaseManager::ExecuteQuery(const string query, int database_handle = INVALID_HANDLE)
{
    int db_handle = (database_handle == INVALID_HANDLE) ? m_main_db : database_handle;
    
    if(db_handle == INVALID_HANDLE) {
        Print("❌ ERROR: Invalid database handle for query execution");
        return false;
    }
    
    return DatabaseExecute(db_handle, query);
}

//+------------------------------------------------------------------+
//| Insert test input data                                          |
//+------------------------------------------------------------------+
bool CDatabaseManager::InsertTestInputData(const string symbol, ENUM_TIMEFRAMES timeframe,
                                          datetime timestamp, double open, double high, double low,
                                          double close, long tick_volume, long real_volume = 0)
{
    if(!m_test_mode_active || m_test_input_db == INVALID_HANDLE) {
        return false;
    }
    
    string tf_string = "";
    switch(timeframe) {
        case PERIOD_M1: tf_string = "M1"; break;
        case PERIOD_M5: tf_string = "M5"; break;
        case PERIOD_M15: tf_string = "M15"; break;
        case PERIOD_H1: tf_string = "H1"; break;
        case PERIOD_D1: tf_string = "D1"; break;
        default: tf_string = "M1"; break;
    }
    
    string query = StringFormat(
        "INSERT OR REPLACE INTO AllCandleData "
        "(asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, real_volume) "
        "VALUES ('%s', '%s', %d, %.5f, %.5f, %.5f, %.5f, %d, %d)",
        symbol, tf_string, timestamp, open, high, low, close, tick_volume, real_volume
    );
    
    return DatabaseExecute(m_test_input_db, query);
}

//+------------------------------------------------------------------+
//| Insert test output data with metadata                          |
//+------------------------------------------------------------------+
bool CDatabaseManager::InsertTestOutputData(const string symbol, ENUM_TIMEFRAMES timeframe,
                                           datetime timestamp, double open, double high, double low,
                                           double close, long tick_volume, long real_volume,
                                           const string hash, bool is_validated, bool is_complete)
{
    if(!m_test_mode_active || m_test_output_db == INVALID_HANDLE) {
        return false;
    }
    
    string tf_string = "";
    switch(timeframe) {
        case PERIOD_M1: tf_string = "M1"; break;
        case PERIOD_M5: tf_string = "M5"; break;
        case PERIOD_M15: tf_string = "M15"; break;
        case PERIOD_H1: tf_string = "H1"; break;
        case PERIOD_D1: tf_string = "D1"; break;
        default: tf_string = "M1"; break;
    }
    
    string query = StringFormat(
        "INSERT OR REPLACE INTO AllCandleData "
        "(asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, real_volume, hash, is_validated, is_complete, validation_time) "
        "VALUES ('%s', '%s', %d, %.5f, %.5f, %.5f, %.5f, %d, %d, '%s', %d, %d, %d)",
        symbol, tf_string, timestamp, open, high, low, close, tick_volume, real_volume, 
        hash, is_validated ? 1 : 0, is_complete ? 1 : 0, TimeCurrent()
    );
    
    return DatabaseExecute(m_test_output_db, query);
}

//+------------------------------------------------------------------+
//| Get database statistics                                         |
//+------------------------------------------------------------------+
string CDatabaseManager::GetDatabaseStats()
{
    string stats = "📊 Database Statistics:\n";
    
    if(m_main_db != INVALID_HANDLE) {
        string query = "SELECT COUNT(*) FROM AllCandleData";
        int request = DatabasePrepare(m_main_db, query);        if(request != INVALID_HANDLE) {
            if(DatabaseRead(request)) {
                long record_count_value;
                if(DatabaseColumnLong(request, 0, record_count_value)) {
                    stats += StringFormat("Main DB: %d records\n", record_count_value);
                }
            }
            DatabaseFinalize(request);
        }
    }
    
    if(m_test_mode_active) {
        if(m_test_input_db != INVALID_HANDLE) {
            string query = "SELECT COUNT(*) FROM AllCandleData";
            int request = DatabasePrepare(m_test_input_db, query);            if(request != INVALID_HANDLE) {
                if(DatabaseRead(request)) {
                    long record_count_value;
                    if(DatabaseColumnLong(request, 0, record_count_value)) {
                        stats += StringFormat("Test Input DB: %d records\n", record_count_value);
                    }
                }
                DatabaseFinalize(request);
            }
        }
        
        if(m_test_output_db != INVALID_HANDLE) {
            string query = "SELECT COUNT(*) FROM AllCandleData";
            int request = DatabasePrepare(m_test_output_db, query);
            if(request != INVALID_HANDLE) {                if(DatabaseRead(request)) {
                    long record_count_value;
                    if(DatabaseColumnLong(request, 0, record_count_value)) {
                        stats += StringFormat("Test Output DB: %d records\n", record_count_value);
                    }
                }
                DatabaseFinalize(request);
            }
        }
    }
    
    return stats;
}
