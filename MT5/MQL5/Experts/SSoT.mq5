//+------------------------------------------------------------------+
//| SSoT.mq5 - Single Source of Truth EA                            |
//| Truly lean orchestrator with only essential event handlers      |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "4.03"
#property description "Lean SSoT EA - Enhanced Database Diagnostics"
#property strict

//--- Include Files
#include <SSoT/TestPanelRefactored.mqh>  // Refactored modular test panel
#include <SSoT/DataFetcher.mqh>       // Data fetching functionality
#include <SSoT/DatabaseSetup.mqh>     // Add this include for unified DB setup
#include <SSoT/SelfHealing/SimpleSSoTSelfHealingIntegration.mqh>  // Simple self-healing system

//--- Input Parameters
input group "=== Main Configuration ==="
input string    SystemSymbols = "EURUSD";        // Symbols to monitor
input string    SystemTimeframes = "M1,M5,M15,H1";             // Timeframes to monitor
input bool      EnableTestMode = false;                        // Enable dual database testing

input group "=== Database Settings ==="
input string    MainDatabase = "sourcedb.sqlite";              // Real-world source database
input string    TestInputDB = "SSoT_input.db";                 // Test mode: OHLCVT data
input string    TestOutputDB = "SSoT_output.db";               // Test mode: Enhanced metadata

input group "=== Processing Settings ==="
input int       MaxBarsToFetch = 1000;                         // Historical bars on startup
input bool      EnableLogging = true;                          // Enable detailed logging
input int       ValidationInterval = 300;                      // Validation interval (seconds)
input int       TestFlowInterval = 3600;                       // Test mode flow interval (seconds)

input group "=== Self-Healing Settings ==="
input bool      EnableSelfHealing = true;                      // Enable self-healing system
input int       HealthCheckInterval = 600;                     // Health check interval (seconds)
input bool      AggressiveHealing = false;                     // Enable aggressive healing mode
input bool      AutoHealingOnStartup = true;                   // Perform healing on startup

//--- Global Variables
CTestPanelRefactored      *g_test_panel = NULL;                           // Test panel instance
CSimpleSSoTSelfHealingIntegration *g_self_healing = NULL;                // Simple self-healing system
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
    Print("[DB] Opening database connections...");
    Print("[DB] Terminal Data Path: " + TerminalInfoString(TERMINAL_DATA_PATH));
    Print("[DB] Common Files Path: " + TerminalInfoString(TERMINAL_COMMONDATA_PATH));
    
    // Reset last error before attempting connections
    ResetLastError();
      // Open main database (LOCAL, not COMMON for portable setup)
    string main_db_path = MainDatabase;
    g_main_db = DatabaseOpen(main_db_path, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
    int main_error = GetLastError();
    
    if(g_main_db == INVALID_HANDLE) {
        Print("[DB] WARNING: Could not open main database with READ/WRITE, Error: ", main_error);
        ResetLastError();        g_main_db = DatabaseOpen(main_db_path, DATABASE_OPEN_READONLY);
        main_error = GetLastError();
        
        if(g_main_db == INVALID_HANDLE) {
            Print("[DB] ERROR: Could not open main database with READONLY, Error: ", main_error);
            // Try without COMMON flag
            ResetLastError();
            g_main_db = DatabaseOpen(main_db_path, DATABASE_OPEN_READONLY);
            main_error = GetLastError();                if(g_main_db == INVALID_HANDLE) {
                    Print("[DB] CRITICAL: Main database failed all connection attempts, Error: ", main_error);                } else {
                    Print("[DB] SUCCESS: Main database connected (READONLY, local): ", main_db_path);
                }} else {
            Print("[DB] SUCCESS: Main database connected (READONLY, common): ", main_db_path);
        }} else {
        Print("[DB] SUCCESS: Main database connected (READ/WRITE, common): ", main_db_path);
    }
    
    if(g_test_mode_active) {
        string test_input_path = TestInputDB;
        g_test_input_db = DatabaseOpen(test_input_path, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
        string test_output_path = TestOutputDB;
        g_test_output_db = DatabaseOpen(test_output_path, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
    }
    // --- Unified DB structure setup ---
    if(!CDatabaseSetup::SetupAllDatabases(g_main_db, g_test_input_db, g_test_output_db, g_test_mode_active)) {
        Print("❌ ERROR: Unified database setup failed");
        return INIT_FAILED;
    }
    
    // Diagnostic: Print all DB handles and their intended file paths
    Print("[DEBUG] DB Handles: Main=", g_main_db, " (", main_db_path, ") | TestInput=", g_test_input_db, " (", TestInputDB, ") | TestOutput=", g_test_output_db, " (", TestOutputDB, ")");
    
    Print("[DB] Database connection summary - Main: ", (g_main_db != INVALID_HANDLE ? "CONNECTED" : "FAILED"), 
          ", Input: ", (g_test_input_db != INVALID_HANDLE ? "CONNECTED" : "FAILED"),
          ", Output: ", (g_test_output_db != INVALID_HANDLE ? "CONNECTED" : "FAILED"));
    
    // Initialize test panel
    g_test_panel = new CTestPanelRefactored();
    if(g_test_panel == NULL) {
        Print("❌ ERROR: Failed to create test panel");
        return INIT_FAILED;
    }    // Initialize test panel with real database handles and tracked assets/timeframes
    if(!g_test_panel.InitializeWithTracking(g_test_mode_active, g_main_db, g_symbols, g_timeframes, g_test_input_db, g_test_output_db)) {
        Print("❌ ERROR: Failed to initialize test panel with tracking");
        delete g_test_panel;
        g_test_panel = NULL;
        return INIT_FAILED;
    }// Show the visual test panel immediately
    g_test_panel.CreateVisualPanel();
    g_test_panel.UpdateVisualPanel();    ChartRedraw();
    
    // Initialize simplified self-healing system
    if(EnableSelfHealing) {
        g_self_healing = new CSimpleSSoTSelfHealingIntegration();
        if(g_self_healing == NULL) {
            Print("❌ ERROR: Failed to create simple self-healing system");
            return INIT_FAILED;
        }
        
        if(!g_self_healing.Initialize(g_main_db, g_test_input_db, g_test_output_db)) {
            Print("❌ ERROR: Failed to initialize simple self-healing system");
            delete g_self_healing;
            g_self_healing = NULL;
            return INIT_FAILED;
        }
        
        // Configure self-healing system
        g_self_healing.SetAutoCheckInterval(HealthCheckInterval);
        g_self_healing.EnableAutoHealing(true);
        
        // Perform initial health validation if enabled
        if(AutoHealingOnStartup) {
            g_self_healing.OnInitCheck();
        }
          Print("🔧 Simple self-healing system: ", g_self_healing.GetQuickHealthStatus());
    } else {
        Print("🔧 Simple self-healing system: DISABLED");
    }
    
    // Create broker vs database comparison display (Live Mode Only)
    if(!g_test_mode_active && g_test_panel != NULL) {
        Print("📊 Creating Broker vs Database comparison display...");
        g_test_panel.CreateBrokerVsDatabaseDisplay(g_symbols, g_timeframes);
    }

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
        }    }
    
    // Clean up simple self-healing system
    if(g_self_healing != NULL) {
        g_self_healing.OnDeinitCheck();
        delete g_self_healing;
        g_self_healing = NULL;
        Print("🔧 Simple self-healing system cleaned up");
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
    
    // Simple self-healing system check
    if(g_self_healing != NULL) {
        g_self_healing.OnTimerCheck();
    }
    
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
    static datetime last_display = 0;    if(current_time - last_display > 30) 
    {
        Print("📊 SSoT Monitor - Mode: ", g_test_mode_active ? "TEST" : "LIVE");
        
        // Display self-healing status (TODO: Re-enable when classes are fixed)
        /*
        if(g_self_healing != NULL) {
            Print("🔧 ", g_self_healing.GetHealthSummary());
        }
        */
          // Use test panel to display info
        if(g_test_panel != NULL) {
            g_test_panel.DisplayDatabaseOverview();
            
            // Update broker vs database comparison in live mode
            if(!g_test_mode_active) {
                g_test_panel.UpdateBrokerVsDatabaseDisplay(g_symbols, g_timeframes);
            }
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
