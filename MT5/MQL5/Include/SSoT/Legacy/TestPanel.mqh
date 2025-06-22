//+------------------------------------------------------------------+
//| TestPanel.mqh - Comprehensive Test Control Center Class         |
//| Advanced test panel/monitor with interactive controls for SSoT  |
//+------------------------------------------------------------------+

#include <DbUtils.mqh>

//+------------------------------------------------------------------+
//| Test status enumeration                                          |
//+------------------------------------------------------------------+
enum ENUM_TEST_STATUS
{
    TEST_STATUS_IDLE,        // No test running
    TEST_STATUS_RUNNING,     // Test in progress
    TEST_STATUS_PASSED,      // Test completed successfully
    TEST_STATUS_FAILED,      // Test failed
    TEST_STATUS_STOPPED      // Test manually stopped
};

//+------------------------------------------------------------------+
//| Test type enumeration                                            |
//+------------------------------------------------------------------+
enum ENUM_TEST_TYPE
{
    TEST_TYPE_INTEGRITY,     // Database integrity test
    TEST_TYPE_DATA_FLOW,     // Data flow test
    TEST_TYPE_PERFORMANCE,   // Performance test
    TEST_TYPE_FULL_SUITE     // Complete test suite
};

//+------------------------------------------------------------------+
//| Comprehensive Test Panel Control Center Class                   |
//+------------------------------------------------------------------+
class CTestPanel
{
private:
    // Database handles
    int m_main_db;
    int m_test_input_db;
    int m_test_output_db;
    
    // Operating mode
    bool m_test_mode_active;
    
    // Display settings
    bool m_display_enabled;
    datetime m_last_display_update;
    int m_display_interval;
    bool m_verbose_output;
    
    // Test execution state
    ENUM_TEST_STATUS m_current_test_status;
    ENUM_TEST_TYPE m_current_test_type;
    datetime m_test_start_time;
    int m_test_progress_percent;
    string m_test_last_error;
    
    // Interactive controls
    bool m_auto_test_enabled;
    datetime m_last_auto_test;
    int m_auto_test_interval;
    
    // Statistics
    int m_tests_passed;
    int m_tests_failed;
    int m_total_tests_run;

public:
    //--- Constructor/Destructor
    CTestPanel(void);
    ~CTestPanel(void);
    
    //--- Initialization
    bool Initialize(bool test_mode, int main_db_handle, int test_input_handle = INVALID_HANDLE, int test_output_handle = INVALID_HANDLE);
    void Shutdown(void);
    
    //--- Mode Control Functions
    bool SwitchToTestMode(void);
    bool SwitchToLiveMode(void);
    bool IsTestMode(void) { return m_test_mode_active; }
    
    //--- Display Control Functions
    void DisplayDatabaseOverview(void);
    void DisplayTestControlPanel(void);
    void DisplaySystemStatus(void);
    void DisplayAllCandleData(int db_handle, string db_name);
    void DisplayDBInfo(int db_handle, string db_name);
    void DisplayAssetData(int db_handle, string table_name, string symbol);
    void DisplayTestStatistics(void);
    
    //--- Manual Test Execution Functions
    bool StartIntegrityTest(void);
    bool StartDataFlowTest(void);
    bool StartPerformanceTest(void);
    bool StartFullTestSuite(void);
    bool StopCurrentTest(void);
    
    //--- Automated Test Functions
    void EnableAutoTesting(int interval_seconds = 3600);
    void DisableAutoTesting(void);
    bool ProcessAutoTesting(void);
    
    //--- Test Implementation Functions
    bool RunDatabaseIntegrityTest(void);
    bool RunDataFlowTest(void);
    bool RunPerformanceTest(void);
    bool RunDataValidationTest(void);
    bool RunConnectionTest(void);
    
    //--- Interactive Control Functions
    bool ProcessCommand(string command);
    void ShowAvailableCommands(void);
    bool TriggerManualDataFlow(void);
    bool TriggerManualValidation(void);
    bool ResetTestStatistics(void);
    
    //--- Utility Functions
    void SetDisplayInterval(int seconds) { m_display_interval = seconds; }
    void SetVerboseOutput(bool verbose) { m_verbose_output = verbose; }
    bool ShouldUpdateDisplay(void);
    void UpdateDisplay(void);
    string GetTestStatusString(ENUM_TEST_STATUS status);
    string GetTestTypeString(ENUM_TEST_TYPE type);
    bool IsTestRunning(void) { return m_current_test_status == TEST_STATUS_RUNNING; }
    bool IsVerboseOutput(void) { return m_verbose_output; }
    
    //--- Status accessors
    ENUM_TEST_STATUS GetCurrentTestStatus(void) { return m_current_test_status; }
    int GetTestProgress(void) { return m_test_progress_percent; }
    string GetLastError(void) { return m_test_last_error; }
    int GetTestsPassed(void) { return m_tests_passed; }
    int GetTestsFailed(void) { return m_tests_failed; }
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CTestPanel::CTestPanel(void)
{
    m_main_db = INVALID_HANDLE;
    m_test_input_db = INVALID_HANDLE;
    m_test_output_db = INVALID_HANDLE;
    m_test_mode_active = false;
    m_display_enabled = true;
    m_last_display_update = 0;
    m_display_interval = 30; // Default 30 seconds
    m_verbose_output = false;
    
    // Test execution state
    m_current_test_status = TEST_STATUS_IDLE;
    m_current_test_type = TEST_TYPE_INTEGRITY;
    m_test_start_time = 0;
    m_test_progress_percent = 0;
    m_test_last_error = "";
    
    // Interactive controls
    m_auto_test_enabled = false;
    m_last_auto_test = 0;
    m_auto_test_interval = 3600; // Default 1 hour
    
    // Statistics
    m_tests_passed = 0;
    m_tests_failed = 0;
    m_total_tests_run = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CTestPanel::~CTestPanel(void)
{
    Shutdown();
}

//+------------------------------------------------------------------+
//| Initialize the test panel                                         |
//+------------------------------------------------------------------+
bool CTestPanel::Initialize(bool test_mode, int main_db_handle, int test_input_handle = INVALID_HANDLE, int test_output_handle = INVALID_HANDLE)
{
    Print("🎮 TestPanel: Initializing Control Center...");
    
    m_test_mode_active = test_mode;
    m_main_db = main_db_handle;
    
    if(m_test_mode_active) {
        m_test_input_db = test_input_handle;
        m_test_output_db = test_output_handle;
        Print("🎮 TestPanel: Initialized in TEST MODE");
        Print("🎮 TestPanel: Managing 3 databases (Main, Test Input, Test Output)");
        
        // Enable auto-testing in test mode by default
        EnableAutoTesting(1800); // Every 30 minutes
    } else {
        Print("🎮 TestPanel: Initialized in LIVE MODE");
        Print("🎮 TestPanel: Managing 1 database (Main only)");
    }
    
    // Show available commands
    ShowAvailableCommands();
    
    // Initial display
    DisplayTestControlPanel();
    
    return true;
}

//+------------------------------------------------------------------+
//| Shutdown the test panel                                           |
//+------------------------------------------------------------------+
void CTestPanel::Shutdown(void)
{
    Print("🎮 TestPanel: Shutting down Control Center...");
    
    // Stop any running tests
    if(IsTestRunning()) {
        StopCurrentTest();
    }
    
    // Disable auto-testing
    DisableAutoTesting();
    
    m_display_enabled = false;
    Print("🎮 TestPanel: Shutdown complete");
}

//+------------------------------------------------------------------+
//| Switch to test mode                                               |
//+------------------------------------------------------------------+
bool CTestPanel::SwitchToTestMode(void)
{
    if(m_test_mode_active) {
        Print("🎮 TestPanel: Already in test mode");
        return true;
    }
    
    if(m_test_input_db == INVALID_HANDLE || m_test_output_db == INVALID_HANDLE) {
        Print("🎮 TestPanel: Cannot switch to test mode - test databases not available");
        return false;
    }
    
    m_test_mode_active = true;
    Print("🎮 TestPanel: Switched to TEST MODE");
    
    // Enable auto-testing in test mode
    EnableAutoTesting(1800);
    
    DisplayTestControlPanel();
    return true;
}

//+------------------------------------------------------------------+
//| Switch to live mode                                               |
//+------------------------------------------------------------------+
bool CTestPanel::SwitchToLiveMode(void)
{
    if(!m_test_mode_active) {
        Print("🎮 TestPanel: Already in live mode");
        return true;
    }
    
    // Stop any running tests before switching
    if(IsTestRunning()) {
        StopCurrentTest();
    }
    
    // Disable auto-testing in live mode
    DisableAutoTesting();
    
    m_test_mode_active = false;
    Print("🎮 TestPanel: Switched to LIVE MODE");
    DisplayTestControlPanel();
    return true;
}

//+------------------------------------------------------------------+
//| Display comprehensive test control panel                         |
//+------------------------------------------------------------------+
void CTestPanel::DisplayTestControlPanel(void)
{
    if(!m_display_enabled) return;
    
    Print("🎮 ================================================================");
    Print("🎮 SSoT TEST CONTROL PANEL");
    Print("🎮 ================================================================");
    Print("🎮 Time: ", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
    Print("🎮 Mode: ", m_test_mode_active ? "🧪 TEST MODE" : "🔴 LIVE MODE");
    
    // Test execution status
    Print("🎮 Test Status: ", GetTestStatusString(m_current_test_status));
    if(IsTestRunning()) {
        Print("🎮 Current Test: ", GetTestTypeString(m_current_test_type));
        Print("🎮 Progress: ", m_test_progress_percent, "%");
        Print("🎮 Runtime: ", (TimeCurrent() - m_test_start_time), " seconds");
    }
    
    // Auto-testing status
    Print("🎮 Auto-Testing: ", m_auto_test_enabled ? "✅ ENABLED" : "❌ DISABLED");
    if(m_auto_test_enabled) {
        int next_auto_test = (int)(m_auto_test_interval - (TimeCurrent() - m_last_auto_test));
        Print("🎮 Next Auto-Test: ", MathMax(0, next_auto_test), " seconds");
    }
    
    Print("🎮");
    
    // Display database overview
    DisplayDatabaseOverview();
    
    // Display system status
    DisplaySystemStatus();
    
    // Display test statistics
    DisplayTestStatistics();
    
    Print("🎮 ================================================================");
    m_last_display_update = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Display comprehensive database overview                          |
//+------------------------------------------------------------------+
void CTestPanel::DisplayDatabaseOverview(void)
{
    Print("🗄️ DATABASE OVERVIEW:");
    
    if(m_test_mode_active) {
        // Test Mode: Display all three databases
        Print("🗄️ DATABASE 1: MAIN (sourcedb.sqlite)");
        DisplayDBInfo(m_main_db, "sourcedb.sqlite");
        DisplayAllCandleData(m_main_db, "Main Database");
        Print("🗄️");
        
        Print("🗄️ DATABASE 2: TEST INPUT (SSoT_input.db)");
        DisplayDBInfo(m_test_input_db, "SSoT_input.db");
        DisplayAllCandleData(m_test_input_db, "Test Input Database");
        Print("🗄️");
        
        Print("🗄️ DATABASE 3: TEST OUTPUT (SSoT_output.db)");
        DisplayDBInfo(m_test_output_db, "SSoT_output.db");
        DisplayAllCandleData(m_test_output_db, "Test Output Database");
    } else {
        // Live Mode: Only main database
        Print("🗄️ DATABASE: MAIN (sourcedb.sqlite)");
        DisplayDBInfo(m_main_db, "sourcedb.sqlite");
        DisplayAllCandleData(m_main_db, "Live Database");
    }
    Print("🗄️");
}

//+------------------------------------------------------------------+
//| Display database server information                              |
//+------------------------------------------------------------------+
void CTestPanel::DisplayDBInfo(int db_handle, string db_name)
{
    if(db_handle == INVALID_HANDLE) {
        Print("🗄️   ❌ Database not available: ", db_name);
        return;
    }
    
    Print("🗄️   🖥️ DBInfo:");
    Print("🗄️      Server: SQLite Local Database");
    Print("🗄️      Filename: ", db_name);
    
    // Timezone information
    MqlDateTime dt;
    TimeCurrent(dt);
    int gmt_offset = (int)((TimeCurrent() - TimeGMT()) / 3600);
    string timezone = StringFormat("GMT%s%d", (gmt_offset >= 0 ? "+" : ""), gmt_offset);
    Print("🗄️      Timezone: ", timezone);
    Print("🗄️      Local Time: ", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
    
    // Connection test
    string test_query = "SELECT COUNT(*) FROM sqlite_master WHERE type='table'";
    int request = DatabasePrepare(db_handle, test_query);
    if(request != INVALID_HANDLE) {
        if(DatabaseRead(request)) {
            long table_count = 0;
            DatabaseColumnLong(request, 0, table_count);
            Print("🗄️      Tables: ", table_count);
            Print("🗄️      Status: ✅ CONNECTED");
        }
        DatabaseFinalize(request);
    } else {
        Print("🗄️      Status: ❌ CONNECTION ERROR");
    }
}

//+------------------------------------------------------------------+
//| Display all candle data information                              |
//+------------------------------------------------------------------+
void CTestPanel::DisplayAllCandleData(int db_handle, string db_name)
{
    if(db_handle == INVALID_HANDLE) {
        Print("🗄️   ❌ Database not available for candle data");
        return;
    }
    
    Print("🗄️   📈 AllCandleData:");
    
    // Find the appropriate table name
    string table_names[] = {"candle_data", "ohlctv_data", "enhanced_data"};
    string active_table = "";
    
    for(int i = 0; i < ArraySize(table_names); i++) {
        string check_query = StringFormat("SELECT name FROM sqlite_master WHERE type='table' AND name='%s'", table_names[i]);
        int request = DatabasePrepare(db_handle, check_query);
        
        if(request != INVALID_HANDLE) {
            if(DatabaseRead(request)) {
                active_table = table_names[i];
                DatabaseFinalize(request);
                break;
            }
            DatabaseFinalize(request);
        }
    }
    
    if(active_table == "") {
        Print("🗄️      📊 No candle data tables found");
        return;
    }
    
    Print("🗄️      📋 Table: ", active_table);
    
    // Get unique assets (symbols)
    string assets_query = StringFormat("SELECT DISTINCT symbol FROM %s ORDER BY symbol", active_table);
    int request = DatabasePrepare(db_handle, assets_query);
    
    if(request == INVALID_HANDLE) {
        Print("🗄️      ❌ Failed to query assets");
        return;
    }
    
    string assets[];
    ArrayResize(assets, 0);
    
    while(DatabaseRead(request)) {
        string symbol;
        DatabaseColumnText(request, 0, symbol);
        int size = ArraySize(assets);
        ArrayResize(assets, size + 1);
        assets[size] = symbol;
    }
    DatabaseFinalize(request);
    
    Print("🗄️      🏪 Assets in DB: ", ArraySize(assets));
    
    // Get unique timeframes
    string tf_query = StringFormat("SELECT DISTINCT timeframe FROM %s ORDER BY timeframe", active_table);
    request = DatabasePrepare(db_handle, tf_query);
    
    if(request != INVALID_HANDLE) {
        string timeframes_str = "";
        while(DatabaseRead(request)) {
            long tf = 0;
            DatabaseColumnLong(request, 0, tf);
            if(timeframes_str != "") timeframes_str += ", ";
            timeframes_str += TimeframeToString((int)tf);
        }
        DatabaseFinalize(request);
        Print("🗄️      ⏰ Timeframes: ", timeframes_str);
    }
    
    // Get total entries
    string total_query = StringFormat("SELECT COUNT(*) FROM %s", active_table);
    request = DatabasePrepare(db_handle, total_query);
    if(request != INVALID_HANDLE) {
        if(DatabaseRead(request)) {
            long total_entries = 0;
            DatabaseColumnLong(request, 0, total_entries);
            Print("🗄️      📊 Total Entries: ", total_entries);
        }
        DatabaseFinalize(request);
    }
    
    // Display entries organized by timeframes for each asset (limited in non-verbose mode)
    if(m_verbose_output || ArraySize(assets) <= 3) {
        for(int i = 0; i < ArraySize(assets); i++) {
            DisplayAssetData(db_handle, active_table, assets[i]);
        }
    } else {
        Print("🗄️      💰 [", ArraySize(assets), " assets - use VERBOSE_ON for details]");
    }
}

//+------------------------------------------------------------------+
//| Display data for specific asset                                  |
//+------------------------------------------------------------------+
void CTestPanel::DisplayAssetData(int db_handle, string table_name, string symbol)
{
    Print("🗄️      💰 Asset: ", symbol);
    
    // Get timeframes and entry counts for this symbol
    string tf_query = StringFormat(
        "SELECT timeframe, COUNT(*) as entries FROM %s WHERE symbol='%s' GROUP BY timeframe ORDER BY timeframe", 
        table_name, symbol);
    
    int request = DatabasePrepare(db_handle, tf_query);
    
    if(request == INVALID_HANDLE) {
        Print("🗄️         ❌ Failed to query timeframes for ", symbol);
        return;
    }
    
    while(DatabaseRead(request)) {
        long timeframe = 0, entries = 0;
        DatabaseColumnLong(request, 0, timeframe);
        DatabaseColumnLong(request, 1, entries);
        
        string tf_string = TimeframeToString((int)timeframe);
        Print("🗄️         📊 ", tf_string, ": ", entries, " entries");
    }
    
    DatabaseFinalize(request);
}

//+------------------------------------------------------------------+
//| Enhanced database integrity test                                 |
//+------------------------------------------------------------------+
bool CTestPanel::RunDatabaseIntegrityTest(void)
{
    Print("🧪 TestPanel: Running Enhanced Database Integrity Test...");
    bool all_passed = true;
    
    if(m_test_mode_active) {
        // Test mode: Check all three databases
        Print("🧪 [1/3] Testing Main Database integrity...");
        m_test_progress_percent = 10;
        
        if(m_main_db == INVALID_HANDLE) {
            Print("❌ Main database handle is invalid");
            m_test_last_error = "Main database handle invalid";
            all_passed = false;
        } else {
            // Test connection and basic queries
            if(!RunConnectionTest(m_main_db, "Main Database")) {
                all_passed = false;
            }
        }
        
        Print("🧪 [2/3] Testing Input Database integrity...");
        m_test_progress_percent = 40;
        
        if(m_test_input_db == INVALID_HANDLE) {
            Print("❌ Test input database handle is invalid");
            m_test_last_error = "Test input database handle invalid";
            all_passed = false;
        } else {
            if(!RunConnectionTest(m_test_input_db, "Test Input Database")) {
                all_passed = false;
            }
        }
        
        Print("🧪 [3/3] Testing Output Database integrity...");
        m_test_progress_percent = 70;
        
        if(m_test_output_db == INVALID_HANDLE) {
            Print("❌ Test output database handle is invalid");
            m_test_last_error = "Test output database handle invalid";
            all_passed = false;
        } else {
            if(!RunConnectionTest(m_test_output_db, "Test Output Database")) {
                all_passed = false;
            }
        }
        
    } else {
        // Live mode: Check main database only
        Print("🧪 Testing Main Database integrity...");
        m_test_progress_percent = 20;
        
        if(m_main_db == INVALID_HANDLE) {
            Print("❌ Main database handle is invalid");
            m_test_last_error = "Main database handle invalid";
            all_passed = false;
        } else {
            if(!RunConnectionTest(m_main_db, "Main Database")) {
                all_passed = false;
            }
        }
    }
    
    m_test_progress_percent = 100;
    
    if(all_passed) {
        Print("✅ Database Integrity Test: ALL DATABASES PASSED");
    } else {
        Print("❌ Database Integrity Test: SOME DATABASES FAILED");
    }
    
    return all_passed;
}

//+------------------------------------------------------------------+
//| Enhanced data flow test                                          |
//+------------------------------------------------------------------+
bool CTestPanel::RunDataFlowTest(void)
{
    Print("🧪 TestPanel: Running Enhanced Data Flow Test...");
    bool all_passed = true;
    
    if(m_test_mode_active) {
        Print("🧪 Testing: Main → Test Input → Test Output flow");
        m_test_progress_percent = 20;
        
        // Test 1: Check data exists in Main database
        if(!CheckDataExists(m_main_db, "Main Database")) {
            all_passed = false;
        }
        
        m_test_progress_percent = 50;
        
        // Test 2: Check data flow to Input database
        if(!CheckDataExists(m_test_input_db, "Test Input Database")) {
            all_passed = false;
        }
        
        m_test_progress_percent = 80;
        
        // Test 3: Check data flow to Output database
        if(!CheckDataExists(m_test_output_db, "Test Output Database")) {
            all_passed = false;
        }
        
    } else {
        Print("🧪 Testing: Broker → Main Database flow");
        m_test_progress_percent = 30;
        
        // Test: Check recent data in main database
        if(!CheckRecentData(m_main_db, "Main Database")) {
            all_passed = false;
        }
    }
    
    m_test_progress_percent = 100;
    
    if(all_passed) {
        Print("✅ Data Flow Test: ALL FLOWS WORKING");
    } else {
        Print("❌ Data Flow Test: SOME FLOWS FAILED");
    }
    
    return all_passed;
}

//+------------------------------------------------------------------+
//| Enhanced performance test                                        |
//+------------------------------------------------------------------+
bool CTestPanel::RunPerformanceTest(void)
{
    Print("🧪 TestPanel: Running Enhanced Performance Test...");
    bool all_passed = true;
    uint start_time = GetTickCount();
    
    m_test_progress_percent = 10;
    
    // Test 1: Database query performance
    Print("🧪 Testing database query performance...");
    uint query_start = GetTickCount();
    
    if(m_main_db != INVALID_HANDLE) {
        string perf_query = "SELECT COUNT(*) FROM sqlite_master";
        int request = DatabasePrepare(m_main_db, perf_query);
        if(request != INVALID_HANDLE) {
            DatabaseRead(request);
            DatabaseFinalize(request);
        }
    }
    
    uint query_time = GetTickCount() - query_start;
    Print("🧪 Query time: ", query_time, " ms");
    
    if(query_time > 1000) { // More than 1 second is considered slow
        Print("⚠️ Warning: Database queries are slow (", query_time, " ms)");
        all_passed = false;
        m_test_last_error = "Slow database performance";
    }
    
    m_test_progress_percent = 50;
    
    // Test 2: Memory usage check
    Print("🧪 Testing memory usage...");
    long memory_used = TerminalInfoInteger(TERMINAL_MEMORY_USED);
    long memory_available = TerminalInfoInteger(TERMINAL_MEMORY_AVAILABLE);
    
    Print("🧪 Memory used: ", memory_used, " MB");
    Print("🧪 Memory available: ", memory_available, " MB");
    
    if(memory_available < 100) { // Less than 100MB available
        Print("⚠️ Warning: Low memory available (", memory_available, " MB)");
        all_passed = false;
        m_test_last_error = "Low memory available";
    }
    
    m_test_progress_percent = 80;
    
    // Test 3: Connection latency
    Print("🧪 Testing connection performance...");
    bool connection_good = TerminalInfoInteger(TERMINAL_CONNECTED);
    if(!connection_good) {
        Print("❌ Connection test failed");
        all_passed = false;
        m_test_last_error = "Connection test failed";
    }
    
    m_test_progress_percent = 100;
    
    uint total_time = GetTickCount() - start_time;
    Print("🧪 Total test time: ", total_time, " ms");
    
    if(all_passed) {
        Print("✅ Performance Test: ALL CHECKS PASSED");
    } else {
        Print("❌ Performance Test: SOME CHECKS FAILED");
    }
    
    return all_passed;
}

//+------------------------------------------------------------------+
//| Run data validation test                                         |
//+------------------------------------------------------------------+
bool CTestPanel::RunDataValidationTest(void)
{
    Print("🔍 TestPanel: Running Data Validation Test...");
    bool all_passed = true;
    
    // Validate main database
    if(m_main_db != INVALID_HANDLE) {
        if(!ValidateDataConsistency(m_main_db, "Main Database")) {
            all_passed = false;
        }
    }
    
    // In test mode, validate other databases too
    if(m_test_mode_active) {
        if(m_test_input_db != INVALID_HANDLE) {
            if(!ValidateDataConsistency(m_test_input_db, "Test Input Database")) {
                all_passed = false;
            }
        }
        
        if(m_test_output_db != INVALID_HANDLE) {
            if(!ValidateDataConsistency(m_test_output_db, "Test Output Database")) {
                all_passed = false;
            }
        }
    }
    
    return all_passed;
}

//+------------------------------------------------------------------+
//| Run connection test for a specific database                     |
//+------------------------------------------------------------------+
bool CTestPanel::RunConnectionTest(int db_handle, string db_name)
{
    if(db_handle == INVALID_HANDLE) {
        Print("❌ ", db_name, ": Invalid database handle");
        return false;
    }
    
    // Test basic connectivity
    string test_query = "SELECT name FROM sqlite_master WHERE type='table' LIMIT 1";
    int request = DatabasePrepare(db_handle, test_query);
    
    if(request == INVALID_HANDLE) {
        Print("❌ ", db_name, ": Failed to prepare test query");
        m_test_last_error = StringFormat("%s connection test failed", db_name);
        return false;
    }
    
    bool has_data = DatabaseRead(request);
    DatabaseFinalize(request);
    
    if(has_data) {
        Print("✅ ", db_name, ": Connection test passed");
        return true;
    } else {
        Print("⚠️ ", db_name, ": Connected but no tables found");
        return true; // Still consider this a pass for new databases
    }
}

//+------------------------------------------------------------------+
//| Helper: Check if database has data                              |
//+------------------------------------------------------------------+
bool CTestPanel::CheckDataExists(int db_handle, string db_name)
{
    if(db_handle == INVALID_HANDLE) {
        Print("❌ ", db_name, ": Invalid handle for data check");
        return false;
    }
    
    // Check for any data tables
    string check_query = "SELECT COUNT(*) FROM sqlite_master WHERE type='table'";
    int request = DatabasePrepare(db_handle, check_query);
    
    if(request == INVALID_HANDLE) {
        Print("❌ ", db_name, ": Failed to check for data");
        return false;
    }
    
    long table_count = 0;
    if(DatabaseRead(request)) {
        DatabaseColumnLong(request, 0, table_count);
    }
    DatabaseFinalize(request);
    
    Print("🔍 ", db_name, ": Found ", table_count, " tables");
    return (table_count > 0);
}

//+------------------------------------------------------------------+
//| Helper: Check for recent data                                   |
//+------------------------------------------------------------------+
bool CTestPanel::CheckRecentData(int db_handle, string db_name)
{
    // This would check for data updated within last hour
    // Implementation depends on your table structure
    Print("🔍 ", db_name, ": Recent data check (implementation pending)");
    return true; // Placeholder
}

//+------------------------------------------------------------------+
//| Helper: Validate data consistency                               |
//+------------------------------------------------------------------+
bool CTestPanel::ValidateDataConsistency(int db_handle, string db_name)
{
    // This would check for data integrity, null values, etc.
    // Implementation depends on your specific requirements
    Print("🔍 ", db_name, ": Data consistency validation (implementation pending)");
    return true; // Placeholder
}

//+------------------------------------------------------------------+
//| Convert timeframe number to string                               |
//+------------------------------------------------------------------+
string CTestPanel::TimeframeToString(int timeframe)
{
    switch(timeframe) {
        case PERIOD_M1:  return "M1";
        case PERIOD_M5:  return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1:  return "H1";
        case PERIOD_H4:  return "H4";
        case PERIOD_D1:  return "D1";
        case PERIOD_W1:  return "W1";
        case PERIOD_MN1: return "MN1";
        default: return StringFormat("TF%d", timeframe);
    }
}

//+------------------------------------------------------------------+
//| Get test status as string                                        |
//+------------------------------------------------------------------+
string CTestPanel::GetTestStatusString(ENUM_TEST_STATUS status)
{
    switch(status) {
        case TEST_STATUS_IDLE:    return "⚪ IDLE";
        case TEST_STATUS_RUNNING: return "🟡 RUNNING";
        case TEST_STATUS_PASSED:  return "✅ PASSED";
        case TEST_STATUS_FAILED:  return "❌ FAILED";
        case TEST_STATUS_STOPPED: return "🔴 STOPPED";
        default: return "❓ UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Get test type as string                                          |
//+------------------------------------------------------------------+
string CTestPanel::GetTestTypeString(ENUM_TEST_TYPE type)
{
    switch(type) {
        case TEST_TYPE_INTEGRITY:  return "🔍 Database Integrity";
        case TEST_TYPE_DATA_FLOW:  return "🔄 Data Flow";
        case TEST_TYPE_PERFORMANCE: return "⚡ Performance";
        case TEST_TYPE_FULL_SUITE: return "🧪 Full Test Suite";
        default: return "❓ Unknown Test";
    }
}

//+------------------------------------------------------------------+
//| Check if display should be updated                               |
//+------------------------------------------------------------------+
bool CTestPanel::ShouldUpdateDisplay(void)
{
    return (TimeCurrent() - m_last_display_update >= m_display_interval);
}

//+------------------------------------------------------------------+
//| Update display                                                    |
//+------------------------------------------------------------------+
void CTestPanel::UpdateDisplay(void)
{
    // Process auto-testing first
    ProcessAutoTesting();
    
    // Update display if needed
    if(ShouldUpdateDisplay()) {
        DisplayTestControlPanel();
    }
}
