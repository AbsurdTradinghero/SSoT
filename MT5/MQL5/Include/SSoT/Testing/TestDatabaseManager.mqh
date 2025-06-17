//+------------------------------------------------------------------+
//| TestDatabaseManager.mqh - Test Database Management             |
//| Handles creation and deletion of test databases                 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Test Database Manager Class                                     |
//+------------------------------------------------------------------+
class CTestDatabaseManager
{
public:
    //--- Constructor
    CTestDatabaseManager(void) {}
    ~CTestDatabaseManager(void) {}
    
    //--- Test Database Operations
    bool GenerateTestDatabases(void);
    bool DeleteTestDatabases(void);
    bool CreateTestInputDatabase(void);
    bool CreateTestOutputDatabase(void);
    
    //--- Validation
    bool ValidateTestDatabase(string filename);
    bool TestDatabaseExists(string filename);
    
private:
    //--- Helper Methods
    bool CreateEmptyDatabase(string filename);
    bool SetupDatabaseSchema(int db_handle);
    bool PopulateTestData(int db_handle, string db_type);
    void LogDatabaseOperation(string operation, string filename, bool success);
};

//+------------------------------------------------------------------+
//| Generate test databases                                         |
//+------------------------------------------------------------------+
bool CTestDatabaseManager::GenerateTestDatabases(void)
{
    Print("[TESTDB] Starting test database generation...");
    
    bool input_success = CreateTestInputDatabase();
    bool output_success = CreateTestOutputDatabase();
    
    if(input_success && output_success) {
        Print("[TESTDB] SUCCESS: All test databases created successfully");
        return true;
    } else {
        Print("[TESTDB] ERROR: Failed to create some test databases");
        Print("[TESTDB] Input DB: " + (input_success ? "SUCCESS" : "FAILED"));
        Print("[TESTDB] Output DB: " + (output_success ? "SUCCESS" : "FAILED"));
        return false;
    }
}

//+------------------------------------------------------------------+
//| Delete test databases                                           |
//+------------------------------------------------------------------+
bool CTestDatabaseManager::DeleteTestDatabases(void)
{
    Print("[TESTDB] Starting test database deletion...");
    
    string input_file = "SSoT_input.db";
    string output_file = "SSoT_output.db";
    
    bool input_deleted = false;
    bool output_deleted = false;
    
    // Delete input database
    if(TestDatabaseExists(input_file)) {
        if(FileDelete(input_file)) {
            Print("[TESTDB] SUCCESS: Deleted " + input_file);
            input_deleted = true;
        } else {
            Print("[TESTDB] ERROR: Failed to delete " + input_file);
        }
    } else {
        Print("[TESTDB] INFO: " + input_file + " does not exist");
        input_deleted = true; // Consider it successful if it doesn't exist
    }
    
    // Delete output database
    if(TestDatabaseExists(output_file)) {
        if(FileDelete(output_file)) {
            Print("[TESTDB] SUCCESS: Deleted " + output_file);
            output_deleted = true;
        } else {
            Print("[TESTDB] ERROR: Failed to delete " + output_file);
        }
    } else {
        Print("[TESTDB] INFO: " + output_file + " does not exist");
        output_deleted = true; // Consider it successful if it doesn't exist
    }
    
    bool success = input_deleted && output_deleted;
    
    if(success) {
        Print("[TESTDB] SUCCESS: All test databases cleaned up");
    } else {
        Print("[TESTDB] ERROR: Failed to clean up some test databases");
    }
    
    return success;
}

//+------------------------------------------------------------------+
//| Create test input database                                      |
//+------------------------------------------------------------------+
bool CTestDatabaseManager::CreateTestInputDatabase(void)
{
    string filename = "SSoT_input.db";
    
    Print("[TESTDB] Creating test input database: " + filename);
    
    // Delete existing file if it exists
    if(TestDatabaseExists(filename)) {
        if(!FileDelete(filename)) {
            Print("[TESTDB] WARNING: Could not delete existing " + filename);
        }
    }
    
    // Create empty database
    if(!CreateEmptyDatabase(filename)) {
        LogDatabaseOperation("Create Input DB", filename, false);
        return false;
    }
    
    // Open database for setup
    int db_handle = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
    if(db_handle == INVALID_HANDLE) {
        Print("[TESTDB] ERROR: Cannot open " + filename + " for setup");
        LogDatabaseOperation("Open Input DB", filename, false);
        return false;
    }
    
    // Setup schema
    bool schema_success = SetupDatabaseSchema(db_handle);
    
    // Populate with test data
    bool data_success = false;
    if(schema_success) {
        data_success = PopulateTestData(db_handle, "INPUT");
    }
    
    // Close database
    DatabaseClose(db_handle);
    
    bool success = schema_success && data_success;
    LogDatabaseOperation("Create Input DB", filename, success);
    
    return success;
}

//+------------------------------------------------------------------+
//| Create test output database                                     |
//+------------------------------------------------------------------+
bool CTestDatabaseManager::CreateTestOutputDatabase(void)
{
    string filename = "SSoT_output.db";
    
    Print("[TESTDB] Creating test output database: " + filename);
    
    // Delete existing file if it exists
    if(TestDatabaseExists(filename)) {
        if(!FileDelete(filename)) {
            Print("[TESTDB] WARNING: Could not delete existing " + filename);
        }
    }
    
    // Create empty database
    if(!CreateEmptyDatabase(filename)) {
        LogDatabaseOperation("Create Output DB", filename, false);
        return false;
    }
    
    // Open database for setup
    int db_handle = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
    if(db_handle == INVALID_HANDLE) {
        Print("[TESTDB] ERROR: Cannot open " + filename + " for setup");
        LogDatabaseOperation("Open Output DB", filename, false);
        return false;
    }
    
    // Setup schema
    bool schema_success = SetupDatabaseSchema(db_handle);
    
    // Populate with test data (different data for output)
    bool data_success = false;
    if(schema_success) {
        data_success = PopulateTestData(db_handle, "OUTPUT");
    }
    
    // Close database
    DatabaseClose(db_handle);
    
    bool success = schema_success && data_success;
    LogDatabaseOperation("Create Output DB", filename, success);
    
    return success;
}

//+------------------------------------------------------------------+
//| Create empty database file                                      |
//+------------------------------------------------------------------+
bool CTestDatabaseManager::CreateEmptyDatabase(string filename)
{
    // Try to create/open the database
    int db_handle = DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
    
    if(db_handle == INVALID_HANDLE) {
        Print("[TESTDB] ERROR: Cannot create database file: " + filename);
        return false;
    }
    
    // Close immediately to create empty file
    DatabaseClose(db_handle);
    
    Print("[TESTDB] Empty database file created: " + filename);
    return true;
}

//+------------------------------------------------------------------+
//| Setup database schema                                           |
//+------------------------------------------------------------------+
bool CTestDatabaseManager::SetupDatabaseSchema(int db_handle)
{
    Print("[TESTDB] Setting up database schema...");
    
    // Create DBInfo table
    string create_dbinfo = "CREATE TABLE IF NOT EXISTS DBInfo ("
                          "key TEXT PRIMARY KEY, "
                          "value TEXT)";
    
    if(!DatabaseExecute(db_handle, create_dbinfo)) {
        Print("[TESTDB] ERROR: Failed to create DBInfo table");
        return false;
    }
    
    // Create AllCandleData table
    string create_candles = "CREATE TABLE IF NOT EXISTS AllCandleData ("
                           "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                           "symbol TEXT, "
                           "timeframe INTEGER, "
                           "datetime INTEGER, "
                           "open REAL, "
                           "high REAL, "
                           "low REAL, "
                           "close REAL, "
                           "volume INTEGER, "
                           "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)";
    
    if(!DatabaseExecute(db_handle, create_candles)) {
        Print("[TESTDB] ERROR: Failed to create AllCandleData table");
        return false;
    }
    
    Print("[TESTDB] Database schema created successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Populate database with test data                               |
//+------------------------------------------------------------------+
bool CTestDatabaseManager::PopulateTestData(int db_handle, string db_type)
{
    Print("[TESTDB] Populating " + db_type + " database with test data...");
    
    // Insert DBInfo entries
    string insert_broker = "INSERT OR REPLACE INTO DBInfo (key, value) VALUES ('broker_name', 'Test Broker')";
    string insert_timezone = "INSERT OR REPLACE INTO DBInfo (key, value) VALUES ('timezone', 'UTC')";
    string insert_schema = "INSERT OR REPLACE INTO DBInfo (key, value) VALUES ('schema_version', '1.0.0')";
    string insert_type = "INSERT OR REPLACE INTO DBInfo (key, value) VALUES ('database_type', '" + db_type + " Test Database')";
    string insert_created = "INSERT OR REPLACE INTO DBInfo (key, value) VALUES ('created_at', '" + TimeToString(TimeCurrent()) + "')";
    string insert_setup = "INSERT OR REPLACE INTO DBInfo (key, value) VALUES ('setup_by', 'SSoT Test Panel')";
    
    if(!DatabaseExecute(db_handle, insert_broker) ||
       !DatabaseExecute(db_handle, insert_timezone) ||
       !DatabaseExecute(db_handle, insert_schema) ||
       !DatabaseExecute(db_handle, insert_type) ||
       !DatabaseExecute(db_handle, insert_created) ||
       !DatabaseExecute(db_handle, insert_setup)) {
        Print("[TESTDB] ERROR: Failed to insert DBInfo data");
        return false;
    }
    
    // Insert sample candle data
    string symbols[] = {"EURUSD", "GBPUSD", "USDJPY"};
    int timeframes[] = {PERIOD_M1, PERIOD_M5, PERIOD_H1, PERIOD_D1};
    
    datetime base_time = TimeCurrent() - (db_type == "INPUT" ? 3600 : 1800); // Different times for input/output
    
    for(int s = 0; s < ArraySize(symbols); s++) {
        for(int t = 0; t < ArraySize(timeframes); t++) {
            // Create 5 candles per symbol/timeframe combination
            for(int c = 0; c < 5; c++) {
                datetime candle_time = base_time + (c * timeframes[t] * 60);
                
                // Generate sample OHLC data
                double base_price = 1.1000 + (s * 0.1000); // Different base prices per symbol
                double open = base_price + (MathRand() % 100) * 0.0001;
                double close = open + ((MathRand() % 200) - 100) * 0.0001;
                double high = MathMax(open, close) + (MathRand() % 50) * 0.0001;
                double low = MathMin(open, close) - (MathRand() % 50) * 0.0001;
                long volume = 1000 + (MathRand() % 9000);
                
                string insert_candle = StringFormat(
                    "INSERT INTO AllCandleData (symbol, timeframe, datetime, open, high, low, close, volume) "
                    "VALUES ('%s', %d, %d, %.5f, %.5f, %.5f, %.5f, %d)",
                    symbols[s], timeframes[t], candle_time, open, high, low, close, volume
                );
                
                if(!DatabaseExecute(db_handle, insert_candle)) {
                    Print("[TESTDB] ERROR: Failed to insert candle data for " + symbols[s]);
                    return false;
                }
            }
        }
    }
    
    Print("[TESTDB] Test data populated successfully");
    Print("[TESTDB] - Symbols: " + IntegerToString(ArraySize(symbols)));
    Print("[TESTDB] - Timeframes: " + IntegerToString(ArraySize(timeframes)));
    Print("[TESTDB] - Total candles: " + IntegerToString(ArraySize(symbols) * ArraySize(timeframes) * 5));
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if test database exists                                   |
//+------------------------------------------------------------------+
bool CTestDatabaseManager::TestDatabaseExists(string filename)
{
    // Try to open the file in read mode
    int handle = FileOpen(filename, FILE_READ | FILE_BIN);
    if(handle == INVALID_HANDLE) {
        return false;
    }
    
    FileClose(handle);
    return true;
}

//+------------------------------------------------------------------+
//| Validate test database                                          |
//+------------------------------------------------------------------+
bool CTestDatabaseManager::ValidateTestDatabase(string filename)
{
    if(!TestDatabaseExists(filename)) {
        Print("[TESTDB] VALIDATION: " + filename + " does not exist");
        return false;
    }
    
    // Try to open database
    int db_handle = DatabaseOpen(filename, DATABASE_OPEN_READONLY);
    if(db_handle == INVALID_HANDLE) {
        Print("[TESTDB] VALIDATION: Cannot open " + filename);
        return false;
    }
    
    // Check if required tables exist
    bool dbinfo_exists = false;
    bool candles_exists = false;
    
    int request = DatabasePrepare(db_handle, "SELECT name FROM sqlite_master WHERE type='table'");
    if(request != INVALID_HANDLE) {
        while(DatabaseRead(request)) {
            string table_name;
            DatabaseColumnText(request, 0, table_name);
            if(table_name == "DBInfo") dbinfo_exists = true;
            if(table_name == "AllCandleData") candles_exists = true;
        }
        DatabaseFinalize(request);
    }
    
    DatabaseClose(db_handle);
    
    bool valid = dbinfo_exists && candles_exists;
    
    Print("[TESTDB] VALIDATION: " + filename + " - " + (valid ? "VALID" : "INVALID"));
    if(!valid) {
        Print("[TESTDB] - DBInfo table: " + (dbinfo_exists ? "EXISTS" : "MISSING"));
        Print("[TESTDB] - AllCandleData table: " + (candles_exists ? "EXISTS" : "MISSING"));
    }
    
    return valid;
}

//+------------------------------------------------------------------+
//| Log database operation                                          |
//+------------------------------------------------------------------+
void CTestDatabaseManager::LogDatabaseOperation(string operation, string filename, bool success)
{
    string status = success ? "SUCCESS" : "FAILED";
    Print("[TESTDB] " + operation + ": " + filename + " - " + status);
}
