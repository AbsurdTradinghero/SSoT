//+------------------------------------------------------------------+
//| SSoT.mq5 - Single Source of Truth EA                            |
//| Truly lean orchestrator with only essential event handlers      |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "4.03"
#property description "Lean SSoT EA - Enhanced Database Diagnostics"
#property strict

//--- Include Files
#include <SSoT/TestPanel_Simple.mqh>  // Main test panel integration
#include <SSoT/DataFetcher.mqh>       // Data fetching functionality

//--- Input Parameters
input group "=== Main Configuration ==="
input string    SystemSymbols = "EURUSD,GBPUSD,USDJPY";        // Symbols to monitor
input string    SystemTimeframes = "M1,M5,M15,H1";             // Timeframes to monitor
input bool      EnableTestMode = true;                        // Enable dual database testing

input group "=== Database Settings ==="
input string    MainDatabase = "sourcedb.sqlite";              // Real-world source database
input string    TestInputDB = "SSoT_input.db";                 // Test mode: OHLCVT data
input string    TestOutputDB = "SSoT_output.db";               // Test mode: Enhanced metadata

input group "=== Processing Settings ==="
input int       MaxBarsToFetch = 1000;                         // Historical bars on startup
input bool      EnableLogging = true;                          // Enable detailed logging
input int       ValidationInterval = 300;                      // Validation interval (seconds)
input int       TestFlowInterval = 3600;                       // Test mode flow interval (seconds)

//--- Global Variables
CTestPanel      *g_test_panel = NULL;                           // Test panel instance
int             g_main_db = INVALID_HANDLE;                     // Main database handle
int             g_test_input_db = INVALID_HANDLE;               // Test input database
int             g_test_output_db = INVALID_HANDLE;              // Test output database
string          g_symbols[];                                    // Parsed symbols array
ENUM_TIMEFRAMES g_timeframes[];                                 // Parsed timeframes array
bool            g_test_mode_active = false;                     // Test mode flag
datetime        g_last_validation = 0;                         // Last validation time
datetime        g_last_test_flow = 0;                          // Last test flow execution

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("🚀 SSoT EA v4.10 - Enhanced Database Diagnostics Initializing...");
      // Parse configured symbols into g_symbols array
    string symbolTokens[];
    int symCount = StringSplit(SystemSymbols, ',', symbolTokens);
    if(symCount > 0)
    {
        ArrayResize(g_symbols, symCount);
        for(int i = 0; i < symCount; i++)
        {
            string temp = symbolTokens[i];
            StringTrimLeft(temp);
            StringTrimRight(temp);
            g_symbols[i] = temp;
        }
    }
    else
    {
        // Default to EURUSD if none specified
        ArrayResize(g_symbols, 1);
        g_symbols[0] = "EURUSD";
    }

    // Parse configured timeframes into g_timeframes array
    string tfTokens[];
    int tfCount = StringSplit(SystemTimeframes, ',', tfTokens);
    if(tfCount > 0)
    {        ArrayResize(g_timeframes, tfCount);
        for(int i = 0; i < tfCount; i++)
        {
            string temp = tfTokens[i];
            StringTrimLeft(temp);
            StringTrimRight(temp);
            string tfStr = temp;
            if(tfStr == "M1") g_timeframes[i] = PERIOD_M1;
            else if(tfStr == "M5") g_timeframes[i] = PERIOD_M5;
            else if(tfStr == "M15") g_timeframes[i] = PERIOD_M15;
            else if(tfStr == "H1") g_timeframes[i] = PERIOD_H1;
            else if(tfStr == "H4") g_timeframes[i] = PERIOD_H4;
            else g_timeframes[i] = (ENUM_TIMEFRAMES)StringToInteger(tfStr);
        }
    }    else
    {
        // Default to M1 timeframe
        ArrayResize(g_timeframes, 1);
        g_timeframes[0] = PERIOD_M1;
    }
    
    g_test_mode_active = EnableTestMode;
    
    // Open database connections
    Print("[DB] Opening database connections...");    Print("[DB] Terminal Data Path: " + TerminalInfoString(TERMINAL_DATA_PATH));
    Print("[DB] Common Files Path: " + TerminalInfoString(TERMINAL_COMMONDATA_PATH));
    
    // Reset last error before attempting connections
    ResetLastError();
    
    // Open main database
    string main_db_path = MainDatabase;
    Print("[DB] Attempting to open main database: " + main_db_path);
    
    g_main_db = DatabaseOpen(main_db_path, DATABASE_OPEN_READWRITE | DATABASE_OPEN_COMMON);
    int main_error = GetLastError();
    
    if(g_main_db == INVALID_HANDLE) {
        Print("[DB] WARNING: Could not open main database with READ/WRITE, Error: ", main_error);
        ResetLastError();
        g_main_db = DatabaseOpen(main_db_path, DATABASE_OPEN_READONLY | DATABASE_OPEN_COMMON);
        main_error = GetLastError();
        
        if(g_main_db == INVALID_HANDLE) {
            Print("[DB] ERROR: Could not open main database with READONLY, Error: ", main_error);
            // Try without COMMON flag
            ResetLastError();
            g_main_db = DatabaseOpen(main_db_path, DATABASE_OPEN_READONLY);
            main_error = GetLastError();                if(g_main_db == INVALID_HANDLE) {
                    Print("[DB] CRITICAL: Main database failed all connection attempts, Error: ", main_error);                } else {
                    Print("[DB] SUCCESS: Main database connected (READONLY, local): ", main_db_path);
                    
                    // Try to create DBInfo even for READONLY database (will fail gracefully if not possible)
                    Print("[DB] Attempting to check/create DBInfo for main database...");
                    CreateDBInfoForExistingDatabase(g_main_db, "MAIN");
                }} else {
            Print("[DB] SUCCESS: Main database connected (READONLY, common): ", main_db_path);
            
            // Try to create DBInfo even for READONLY database (will fail gracefully if not possible)
            Print("[DB] Attempting to check/create DBInfo for main database...");
            CreateDBInfoForExistingDatabase(g_main_db, "MAIN");
        }} else {
        Print("[DB] SUCCESS: Main database connected (READ/WRITE, common): ", main_db_path);
        
        // Initialize database schema and DBInfo if needed
        if(!InitializeDatabase(main_db_path, g_main_db)) {
            Print("[DB] WARNING: Failed to initialize main database schema");
        } else {
            // Ensure DBInfo is properly set up
            CreateDBInfoForExistingDatabase(g_main_db, "MAIN");
        }
    }
    
    if(g_test_mode_active) {        // Open test input database (ensure it exists and has data)
        string test_input_path = TestInputDB;
        Print("[DB] Attempting to open test input database: ", test_input_path);
        ResetLastError();
        
        // First try to create/open with write access
        g_test_input_db = DatabaseOpen(test_input_path, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
        int input_error = GetLastError();
        
        if(g_test_input_db == INVALID_HANDLE) {
            Print("[DB] WARNING: Test input DB CREATE/RW failed, Error: ", input_error);
            // Try existing database with write access
            ResetLastError();
            g_test_input_db = DatabaseOpen(test_input_path, DATABASE_OPEN_READWRITE | DATABASE_OPEN_COMMON);
            input_error = GetLastError();
            
            if(g_test_input_db == INVALID_HANDLE) {
                Print("[DB] WARNING: Test input DB READ/WRITE failed, Error: ", input_error);
                ResetLastError();
                g_test_input_db = DatabaseOpen(test_input_path, DATABASE_OPEN_READONLY | DATABASE_OPEN_COMMON);
                input_error = GetLastError();
                
                if(g_test_input_db == INVALID_HANDLE) {
                    Print("[DB] WARNING: Test input DB READONLY/COMMON failed, Error: ", input_error);
                    ResetLastError();
                    g_test_input_db = DatabaseOpen(test_input_path, DATABASE_OPEN_READONLY);
                    input_error = GetLastError();
                    
                    if(g_test_input_db == INVALID_HANDLE) {
                        Print("[DB] ERROR: Test input database failed all attempts, Error: ", input_error);
                    } else {
                        Print("[DB] SUCCESS: Test input database connected (READONLY, local): ", test_input_path);
                        Print("[DB] WARNING: Cannot copy data - database opened in READONLY mode");
                    }
                } else {
                    Print("[DB] SUCCESS: Test input database connected (READONLY, common): ", test_input_path);
                    Print("[DB] WARNING: Cannot copy data - database opened in READONLY mode");
                }
            } else {                Print("[DB] SUCCESS: Test input database connected (READ/WRITE, common): ", test_input_path);
                
                // Initialize database schema and DBInfo if needed
                if(!SetupDatabaseSchema(g_test_input_db, "TEST_INPUT")) {
                    Print("[DB] WARNING: Failed to setup schema for test input database");
                }
                
                // Copy data from main database to test input database
                Print("[DB] Copying data from sourcedb.sqlite to SSoT_input.db...");
                CopyMainDataToTestInput("sourcedb.sqlite", g_test_input_db);
                
                // Verify data was copied
                int verify_request = DatabasePrepare(g_test_input_db, "SELECT COUNT(*) FROM AllCandleData");
                if(verify_request != INVALID_HANDLE && DatabaseRead(verify_request)) {
                    int record_count = 0;
                    DatabaseColumnInteger(verify_request, 0, record_count);
                    Print("[DB] ✅ Data copy verification: ", record_count, " records in SSoT_input.db");
                    DatabaseFinalize(verify_request);
                }
            }
        } else {            Print("[DB] SUCCESS: Test input database created/opened (READ/WRITE, common): ", test_input_path);
            
            // Initialize database schema and DBInfo if needed
            if(!SetupDatabaseSchema(g_test_input_db, "TEST_INPUT")) {
                Print("[DB] WARNING: Failed to setup schema for test input database");
            }
            
            // Copy data from main database to test input database
            Print("[DB] Copying data from sourcedb.sqlite to SSoT_input.db...");
            CopyMainDataToTestInput("sourcedb.sqlite", g_test_input_db);
            
            // Verify data was copied
            int verify_request = DatabasePrepare(g_test_input_db, "SELECT COUNT(*) FROM AllCandleData");
            if(verify_request != INVALID_HANDLE && DatabaseRead(verify_request)) {
                int record_count = 0;
                DatabaseColumnInteger(verify_request, 0, record_count);
                Print("[DB] ✅ Data copy verification: ", record_count, " records in SSoT_input.db");
                DatabaseFinalize(verify_request);
            }
        }
        
        // Open test output database
        string test_output_path = TestOutputDB;
        Print("[DB] Attempting to open test output database: ", test_output_path);
        ResetLastError();
        
        g_test_output_db = DatabaseOpen(test_output_path, DATABASE_OPEN_READWRITE | DATABASE_OPEN_COMMON);
        int output_error = GetLastError();
        
        if(g_test_output_db == INVALID_HANDLE) {
            Print("[DB] WARNING: Test output DB READ/WRITE failed, Error: ", output_error);
            ResetLastError();
            g_test_output_db = DatabaseOpen(test_output_path, DATABASE_OPEN_READONLY | DATABASE_OPEN_COMMON);
            output_error = GetLastError();
            
            if(g_test_output_db == INVALID_HANDLE) {
                Print("[DB] WARNING: Test output DB READONLY/COMMON failed, Error: ", output_error);
                ResetLastError();
                g_test_output_db = DatabaseOpen(test_output_path, DATABASE_OPEN_READONLY);
                output_error = GetLastError();
                
                if(g_test_output_db == INVALID_HANDLE) {
                    Print("[DB] ERROR: Test output database failed all attempts, Error: ", output_error);
                } else {
                    Print("[DB] SUCCESS: Test output database connected (READONLY, local): ", test_output_path);
                }
            } else {
                Print("[DB] SUCCESS: Test output database connected (READONLY, common): ", test_output_path);
            }        } else {
            Print("[DB] SUCCESS: Test output database connected (READ/WRITE, common): ", test_output_path);
            
            // Initialize database schema and DBInfo if needed
            if(!SetupDatabaseSchema(g_test_output_db, "TEST_OUTPUT")) {
                Print("[DB] WARNING: Failed to setup schema for test output database");
            }
        }
    }    
    Print("[DB] Database connection summary - Main: ", (g_main_db != INVALID_HANDLE ? "CONNECTED" : "FAILED"), 
          ", Input: ", (g_test_input_db != INVALID_HANDLE ? "CONNECTED" : "FAILED"),
          ", Output: ", (g_test_output_db != INVALID_HANDLE ? "CONNECTED" : "FAILED"));
    
    // Initialize test panel
    g_test_panel = new CTestPanel();
    if(g_test_panel == NULL) {
        Print("❌ ERROR: Failed to create test panel");
        return INIT_FAILED;
    }
    
    // Initialize test panel with real database handles
    if(!g_test_panel.Initialize(g_test_mode_active, g_main_db, g_test_input_db, g_test_output_db)) {
        Print("❌ ERROR: Failed to initialize test panel");
        delete g_test_panel;
        g_test_panel = NULL;
        return INIT_FAILED;
    }    // Show the visual test panel immediately
    g_test_panel.CreateVisualPanel();
    g_test_panel.UpdateVisualPanel();
    ChartRedraw();

    // Initialize data fetcher
    if(!CDataFetcher::Initialize())
    {
        Print("⚠️ Warning: Data fetcher initialization failed");
    }

    // Perform initial data population if main database is writable
    if(g_main_db != INVALID_HANDLE)
    {
        Print("📈 Performing initial data population...");
        
        for(int i = 0; i < ArraySize(g_symbols); i++)
        {
            for(int j = 0; j < ArraySize(g_timeframes); j++)
            {
                string symbol = g_symbols[i];
                ENUM_TIMEFRAMES tf = g_timeframes[j];
                
                // Initial fetch of historical data
                int fetched_count = CDataFetcher::FetchData(symbol, tf, MaxBarsToFetch);
                if(fetched_count > 0)
                {
                    Print("✅ Initial fetch: ", fetched_count, " bars for ", symbol, " ", CDataFetcher::TimeframeToString(tf));
                    
                    // Store to database
                    if(!CDataFetcher::FetchDataToDatabase(g_main_db, symbol, tf, MaxBarsToFetch))
                    {
                        Print("⚠️ Warning: Failed to store initial data for ", symbol, " ", CDataFetcher::TimeframeToString(tf));
                    }
                }
            }
        }
        
        Print("📊 Initial data population completed");
    }

    // Start monitoring
    EventSetTimer(1);
    Print("✅ SSoT EA v4.10 initialized successfully");
    Print(StringFormat("📊 Monitoring: %d symbols, %d timeframes", 
          ArraySize(g_symbols), ArraySize(g_timeframes)));
    Print(StringFormat("🧪 Test Mode: %s", EnableTestMode ? "ENABLED" : "DISABLED"));
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{    EventKillTimer();    // Clean up test panel with comprehensive cleanup
    if(g_test_panel != NULL) {
        Print("🧹 Starting comprehensive panel cleanup...");
        g_test_panel.CleanupVisualPanel();  // Clean up all visual objects first
        Sleep(50);  // Small delay to ensure cleanup completes
        g_test_panel.ForceCleanupAllSSoTObjects();  // Emergency cleanup as safety net
        Sleep(50);  // Another brief pause
        delete g_test_panel;
        g_test_panel = NULL;
        Print("🧪 Test panel cleaned up and deleted");
    } else {
        // If panel object doesn't exist, still try to clean up chart objects
        Print("🧹 Panel object not found, performing direct chart cleanup...");
        for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
            string obj_name = ObjectName(0, i, -1, -1);
            if(StringFind(obj_name, "SSoT") == 0) {
                Print("[CLEANUP] Removing orphaned object: ", obj_name);
                ObjectDelete(0, obj_name);
            }
        }
    }
    
    // Force additional cleanup - remove any lingering SSoT objects
    Print("🧹 Performing final chart object cleanup...");
    for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
        string obj_name = ObjectName(0, i, -1, -1);
        if(StringFind(obj_name, "SSoT_") == 0) {
            Print("[CLEANUP] Removing final residual object: ", obj_name);
            ObjectDelete(0, obj_name);
        }
    }
    
    // Force final chart redraw
    ChartRedraw(0);
    Sleep(50);  // Brief pause to ensure redraw completes
    
    // Close databases
    if(g_main_db != INVALID_HANDLE) {
        DatabaseClose(g_main_db);
        g_main_db = INVALID_HANDLE;
    }
    
    if(g_test_mode_active) {
        if(g_test_input_db != INVALID_HANDLE) {
            DatabaseClose(g_test_input_db);
            g_test_input_db = INVALID_HANDLE;
        }
        if(g_test_output_db != INVALID_HANDLE) {
            DatabaseClose(g_test_output_db);
            g_test_output_db = INVALID_HANDLE;
        }
        Print("🧪 Test mode databases closed");
    }
    
    Print("🔴 SSoT EA v4.10 - Comprehensive Shutdown Complete");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Minimal tick processing - main logic in timer
    // Reserved for future high-frequency operations
}

//+------------------------------------------------------------------+
//| Timer function - Main processing loop                            |
//+------------------------------------------------------------------+
void OnTimer()
{
    datetime current_time = TimeCurrent();
    
    // Data validation and fetching logic
    if(current_time - g_last_validation > ValidationInterval)
    {
        g_last_validation = current_time;
        
        // Fetch fresh data for configured symbols and timeframes
        if(g_main_db != INVALID_HANDLE)
        {
            Print("📈 Fetching fresh market data...");
            
            for(int i = 0; i < ArraySize(g_symbols); i++)
            {
                for(int j = 0; j < ArraySize(g_timeframes); j++)
                {
                    string symbol = g_symbols[i];
                    ENUM_TIMEFRAMES tf = g_timeframes[j];
                    
                    // Fetch data to main database
                    if(!CDataFetcher::FetchDataToDatabase(g_main_db, symbol, tf, MaxBarsToFetch))
                    {
                        Print("⚠️ Warning: Failed to fetch data for ", symbol, " ", CDataFetcher::TimeframeToString(tf));
                    }
                    else
                    {
                        Print("✅ Fetched data for ", symbol, " ", CDataFetcher::TimeframeToString(tf));
                    }
                }
            }
            
            Print("📊 Data fetch cycle completed");
        }
    }
    
    // Test mode flow processing
    if(g_test_mode_active && current_time - g_last_test_flow > TestFlowInterval)
    {
        g_last_test_flow = current_time;
        
        if(g_main_db != INVALID_HANDLE && g_test_input_db != INVALID_HANDLE && g_test_output_db != INVALID_HANDLE)
        {
            Print("🧪 Running test mode data flow...");
            
            if(!CDataFetcher::ProcessTestModeFlow(g_main_db, g_test_input_db, g_test_output_db, g_symbols, g_timeframes))
            {
                Print("⚠️ Warning: Test mode flow processing failed");
            }
            else
            {
                Print("✅ Test mode flow processed successfully");
            }
        }
    }
    
    // Display update logic
    static datetime last_display = 0;
    
    if(current_time - last_display > 30) 
    {
        Print("📊 SSoT Monitor - Mode: ", g_test_mode_active ? "TEST" : "LIVE");
        
        // Use test panel to display info
        if(g_test_panel != NULL) {
            g_test_panel.DisplayDatabaseOverview();
        }
        
        last_display = current_time;
    }
}

//+------------------------------------------------------------------+
//| Chart event function                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    // Forward chart events to test panel for button handling
    if(g_test_panel != NULL) {
        g_test_panel.HandleChartEvent(id, lparam, dparam, sparam);
    }
}
