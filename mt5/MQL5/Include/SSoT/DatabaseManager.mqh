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
