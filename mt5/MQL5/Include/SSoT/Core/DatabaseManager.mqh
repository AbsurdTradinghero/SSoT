//+------------------------------------------------------------------+
//| DatabaseManager.mqh - Database Creation and Management Library  |
//| Extracted from SSoT_Lean for cleaner architecture               |
//+------------------------------------------------------------------+
#ifndef SSOT_DATABASE_MANAGER_MQH
#define SSOT_DATABASE_MANAGER_MQH

#include "DataStructures.mqh"

//+------------------------------------------------------------------+
//| Database Manager Class                                           |
//+------------------------------------------------------------------+
class CDatabaseManager
{
private:
    int             m_main_db;
    int             m_test_input_db;
    int             m_test_output_db;
    bool            m_test_mode_active;
    
public:
    CDatabaseManager();
    ~CDatabaseManager();
    
    // Database initialization
    bool            InitializeDatabases(const string main_db, 
                                      const string test_input_db = "", 
                                      const string test_output_db = "",
                                      bool enable_test_mode = false);
    
    // Database structure creation
    bool            CreateMainDatabaseStructure();
    bool            CreateTestDatabaseStructures();
    
    // Database access
    int             GetMainDatabase() { return m_main_db; }
    int             GetTestInputDatabase() { return m_test_input_db; }
    int             GetTestOutputDatabase() { return m_test_output_db; }
    bool            IsTestModeActive() { return m_test_mode_active; }
    
    // Cleanup
    void            CloseDatabases();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CDatabaseManager::CDatabaseManager()
{
    m_main_db = INVALID_HANDLE;
    m_test_input_db = INVALID_HANDLE;
    m_test_output_db = INVALID_HANDLE;
    m_test_mode_active = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CDatabaseManager::~CDatabaseManager()
{
    CloseDatabases();
}

//+------------------------------------------------------------------+
//| Initialize database connections                                  |
//+------------------------------------------------------------------+
bool CDatabaseManager::InitializeDatabases(const string main_db, 
                                          const string test_input_db = "", 
                                          const string test_output_db = "",
                                          bool enable_test_mode = false)
{
    // Initialize main database
    m_main_db = DatabaseOpen(main_db, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
    if(m_main_db == INVALID_HANDLE) {
        Print("❌ DatabaseManager: Failed to open main database: ", main_db);
        return false;
    }
    
    // Create main database structure
    if(!CreateMainDatabaseStructure()) {
        Print("❌ DatabaseManager: Failed to create main database structure");
        return false;
    }
    
    // Initialize test mode databases if enabled
    if(enable_test_mode && test_input_db != "" && test_output_db != "") {
        m_test_mode_active = true;
        
        // Test input database (OHLCVT data)
        m_test_input_db = DatabaseOpen(test_input_db, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
        if(m_test_input_db == INVALID_HANDLE) {
            Print("❌ DatabaseManager: Failed to open test input database: ", test_input_db);
            return false;
        }
        
        // Test output database (Enhanced metadata)
        m_test_output_db = DatabaseOpen(test_output_db, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
        if(m_test_output_db == INVALID_HANDLE) {
            Print("❌ DatabaseManager: Failed to open test output database: ", test_output_db);
            return false;
        }
        
        // Create test database structures
        if(!CreateTestDatabaseStructures()) {
            Print("❌ DatabaseManager: Failed to create test database structures");
            return false;
        }
        
        Print("✅ DatabaseManager: Test mode databases initialized");
    }
    
    Print("✅ DatabaseManager: Database initialization complete");
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
        Print("❌ DatabaseManager: Failed to create AllCandleData table");
        return false;
    }
    
    // Create DBInfo table
    sql = "CREATE TABLE IF NOT EXISTS DBInfo ("
          "key TEXT PRIMARY KEY,"
          "value TEXT NOT NULL,"
          "updated_at INTEGER DEFAULT (strftime('%s', 'now'))"
          ");";
    
    if(!DatabaseExecute(m_main_db, sql)) {
        Print("❌ DatabaseManager: Failed to create DBInfo table");
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
        Print("❌ DatabaseManager: Failed to create test input table");
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
        Print("❌ DatabaseManager: Failed to create test output table");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Close all database connections                                   |
//+------------------------------------------------------------------+
void CDatabaseManager::CloseDatabases()
{
    if(m_main_db != INVALID_HANDLE) {
        DatabaseClose(m_main_db);
        m_main_db = INVALID_HANDLE;
    }
    
    if(m_test_mode_active) {
        if(m_test_input_db != INVALID_HANDLE) {
            DatabaseClose(m_test_input_db);
            m_test_input_db = INVALID_HANDLE;
        }
        if(m_test_output_db != INVALID_HANDLE) {
            DatabaseClose(m_test_output_db);
            m_test_output_db = INVALID_HANDLE;
        }
        Print("🧪 DatabaseManager: Test mode databases closed");
    }
    
    Print("🔴 DatabaseManager: All databases closed");
}

#endif // SSOT_DATABASE_MANAGER_MQH
