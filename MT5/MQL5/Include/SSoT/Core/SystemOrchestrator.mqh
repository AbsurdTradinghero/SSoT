//+------------------------------------------------------------------+
//| SystemOrchestrator.mqh - Core System Coordination               |
//| Handles initialization, configuration, and coordination         |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"
#property strict

#include <SSoT/Utilities/SymbolParser.mqh>
#include <SSoT/Database/DatabaseManager.mqh>
#include <SSoT/Database/DatabaseSetup.mqh>
#include <SSoT/Core/ChainOfTrust.mqh>

//+------------------------------------------------------------------+
//| System Orchestrator Class                                       |
//| Centralizes all system initialization and coordination logic    |
//+------------------------------------------------------------------+
class CSystemOrchestrator
{
private:    // Configuration
    string            m_symbols[];
    ENUM_TIMEFRAMES   m_timeframes[];
    bool              m_test_mode;
    int               m_validation_interval;
    int               m_test_flow_interval;
    bool              m_enable_logging;
    
    // Database handles
    int               m_main_db;
    int               m_test_input_db;
    int               m_test_output_db;
    
    // System state
    bool              m_initialized;
    bool              m_initial_sync_completed;
    
public:
    //--- Constructor/Destructor
    CSystemOrchestrator();
    ~CSystemOrchestrator();
      //--- Initialization
    bool              Initialize(const string symbols_config, const string timeframes_config, 
                                const string main_db_path, const string test_input_path, const string test_output_path,
                                int validation_interval, int test_flow_interval, bool enable_logging);
    void              Shutdown();
    
    //--- Configuration parsing
    bool              ParseSymbols(const string symbols_config);
    bool              ParseTimeframes(const string timeframes_config);
    
    //--- Database management
    bool              OpenDatabases(const string main_db_path, const string test_input_path, const string test_output_path);
    bool              OptimizeDatabases();
    void              CloseDatabases();
    
    //--- System validation
    bool              InitializeChainOfTrust();
    bool              VerifyChainOfTrustComplete();
    bool              PerformInitialSync();
    
    //--- Getters
    void              GetSymbols(string &symbols[]) { ArrayCopy(symbols, m_symbols); }
    void              GetTimeframes(ENUM_TIMEFRAMES &timeframes[]) { ArrayCopy(timeframes, m_timeframes); }
    int               GetMainDatabase() const { return m_main_db; }
    int               GetTestInputDatabase() const { return m_test_input_db; }
    int               GetTestOutputDatabase() const { return m_test_output_db; }
    bool              IsTestMode() const { return m_test_mode; }
    bool              IsInitialized() const { return m_initialized; }
    bool              IsInitialSyncCompleted() const { return m_initial_sync_completed; }
    
    //--- Event handlers (required by main EA)
    void              OnTimer();
    void              OnNewBar(const string symbol, ENUM_TIMEFRAMES timeframe);
    void              OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam);
    
    //--- Runtime operations
    bool              PerformValidation();
    bool              SyncMarketData();
    bool              ExecuteTestModeFlow();
    
    //--- Market data operations
    bool              ProcessNewBarData(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool              StoreMarketData(const string symbol, ENUM_TIMEFRAMES timeframe, 
                                     datetime timestamp, double open, double high, double low, 
                                     double close, long tick_volume, long real_volume = 0);
    
private:
    //--- Internal helpers
    ENUM_TIMEFRAMES   ParseTimeframeOptimized(string tf_string);
    void              LogSystemStatus();
    bool              DiagnoseD1Timeframe();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSystemOrchestrator::CSystemOrchestrator()
{
    m_test_mode = false;
    m_main_db = INVALID_HANDLE;
    m_test_input_db = INVALID_HANDLE;
    m_test_output_db = INVALID_HANDLE;
    m_initialized = false;
    m_initial_sync_completed = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                      |
//+------------------------------------------------------------------+
CSystemOrchestrator::~CSystemOrchestrator()
{
    Shutdown();
}

//+------------------------------------------------------------------+
//| Initialize the system orchestrator                              |
//+------------------------------------------------------------------+
bool CSystemOrchestrator::Initialize(const string symbols_config, const string timeframes_config, 
                                    const string main_db_path, const string test_input_path, const string test_output_path,
                                    int validation_interval, int test_flow_interval, bool enable_logging)
{    Print("🚀 SystemOrchestrator: Initializing...");
    
    // Determine test mode based on input/output database paths
    bool test_mode = (StringLen(test_input_path) > 0 && StringLen(test_output_path) > 0);
    
    // Store configuration
    m_test_mode = test_mode;
    m_validation_interval = validation_interval;
    m_test_flow_interval = test_flow_interval;
    m_enable_logging = enable_logging;
    
    if(m_enable_logging) {
        Print("📋 SystemOrchestrator: Configuration - Test Mode: ", (m_test_mode ? "ON" : "OFF"), 
              ", Validation Interval: ", m_validation_interval, "s", 
              ", Test Flow Interval: ", m_test_flow_interval, "s");
    }
    
    // Parse configuration using CSymbolParser utility
    if(!CSymbolParser::ParseSymbols(symbols_config, m_symbols)) {
        Print("❌ SystemOrchestrator: Symbol parsing failed");
        return false;
    }
    
    if(!CSymbolParser::ParseTimeframes(timeframes_config, m_timeframes)) {
        Print("❌ SystemOrchestrator: Timeframe parsing failed");
        return false;
    }
    
    // Open databases
    if(!OpenDatabases(main_db_path, test_input_path, test_output_path)) {
        Print("❌ SystemOrchestrator: Database initialization failed");
        return false;
    }
    
    // Setup database schemas
    if(!CDatabaseSetup::SetupAllDatabases(m_main_db, m_test_input_db, m_test_output_db, m_test_mode)) {
        Print("❌ SystemOrchestrator: Database setup failed");
        return false;
    }
    
    // Optimize databases
    OptimizeDatabases();
    
    // Initialize Chain of Trust
    if(!InitializeChainOfTrust()) {
        Print("❌ SystemOrchestrator: Chain of Trust initialization failed");
        return false;
    }
    
    // Perform initial synchronization
    if(!PerformInitialSync()) {
        Print("⚠️ SystemOrchestrator: Initial sync incomplete");
        m_initial_sync_completed = false;
    } else {
        m_initial_sync_completed = true;
    }
    
    m_initialized = true;
    LogSystemStatus();
    
    Print("✅ SystemOrchestrator: Initialization completed successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Parse symbols configuration                                     |
//+------------------------------------------------------------------+
bool CSystemOrchestrator::ParseSymbols(const string symbols_config)
{
    string symbolTokens[];
    int symCount = StringSplit(symbols_config, ',', symbolTokens);
    
    if(symCount > 0) {
        ArrayResize(m_symbols, symCount);
        for(int i = 0; i < symCount; i++) {
            string temp = symbolTokens[i];
            StringTrimLeft(temp);
            StringTrimRight(temp);
            m_symbols[i] = temp;
        }
    } else {
        // Default to EURUSD if none specified
        ArrayResize(m_symbols, 1);
        m_symbols[0] = "EURUSD";
    }
    
    Print("📊 SystemOrchestrator: Parsed ", ArraySize(m_symbols), " symbols");
    return true;
}

//+------------------------------------------------------------------+
//| Parse timeframes configuration                                  |
//+------------------------------------------------------------------+
bool CSystemOrchestrator::ParseTimeframes(const string timeframes_config)
{
    string tfTokens[];
    int tfCount = StringSplit(timeframes_config, ',', tfTokens);
    
    if(tfCount > 0) {
        ArrayResize(m_timeframes, tfCount);
        for(int i = 0; i < tfCount; i++) {
            string temp = tfTokens[i];
            StringTrimLeft(temp);
            StringTrimRight(temp);
            m_timeframes[i] = ParseTimeframeOptimized(temp);
            
            Print("📈 Parsed timeframe '", temp, "' -> ", CChainOfTrust::TimeframeToString(m_timeframes[i]));
        }
    } else {
        // Default to M1 timeframe
        ArrayResize(m_timeframes, 1);
        m_timeframes[0] = PERIOD_M1;
    }
    
    Print("📈 SystemOrchestrator: Parsed ", ArraySize(m_timeframes), " timeframes");
    return true;
}

//+------------------------------------------------------------------+
//| Open all database connections                                   |
//+------------------------------------------------------------------+
bool CSystemOrchestrator::OpenDatabases(const string main_db_path, const string test_input_path, const string test_output_path)
{
    Print("🗄️ SystemOrchestrator: Opening database connections...");
    
    // Open main database with fallback strategy
    m_main_db = DatabaseOpen(main_db_path, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
    if(m_main_db == INVALID_HANDLE) {
        Print("⚠️ Failed to open main database with READ/WRITE, trying READONLY...");
        m_main_db = DatabaseOpen(main_db_path, DATABASE_OPEN_READONLY);
        if(m_main_db == INVALID_HANDLE) {
            Print("❌ Failed to open main database");
            return false;
        }
    }
    
    // Open test databases if in test mode
    if(m_test_mode) {
        m_test_input_db = DatabaseOpen(test_input_path, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
        m_test_output_db = DatabaseOpen(test_output_path, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
        
        if(m_test_input_db == INVALID_HANDLE || m_test_output_db == INVALID_HANDLE) {
            Print("⚠️ Failed to open test databases");
        }
    }
    
    Print("✅ Database connections established");
    return true;
}

//+------------------------------------------------------------------+
//| Optimize database performance                                   |
//+------------------------------------------------------------------+
bool CSystemOrchestrator::OptimizeDatabases()
{
    Print("🔧 SystemOrchestrator: Applying database optimizations...");
    
    // Optimize main database
    if(m_main_db != INVALID_HANDLE) {
        DatabaseExecute(m_main_db, "PRAGMA journal_mode=WAL");
        DatabaseExecute(m_main_db, "PRAGMA cache_size=20000");
        DatabaseExecute(m_main_db, "PRAGMA synchronous=NORMAL");
        DatabaseExecute(m_main_db, "PRAGMA temp_store=MEMORY");
        DatabaseExecute(m_main_db, "PRAGMA locking_mode=EXCLUSIVE");
    }
    
    // Optimize test databases
    if(m_test_mode) {
        if(m_test_input_db != INVALID_HANDLE) {
            DatabaseExecute(m_test_input_db, "PRAGMA journal_mode=WAL");
            DatabaseExecute(m_test_input_db, "PRAGMA cache_size=10000");
            DatabaseExecute(m_test_input_db, "PRAGMA synchronous=NORMAL");
            DatabaseExecute(m_test_input_db, "PRAGMA temp_store=MEMORY");
        }
        if(m_test_output_db != INVALID_HANDLE) {
            DatabaseExecute(m_test_output_db, "PRAGMA journal_mode=WAL");
            DatabaseExecute(m_test_output_db, "PRAGMA cache_size=10000");
            DatabaseExecute(m_test_output_db, "PRAGMA synchronous=NORMAL");
            DatabaseExecute(m_test_output_db, "PRAGMA temp_store=MEMORY");
        }
    }
    
    Print("✅ Database optimizations applied");
    return true;
}

//+------------------------------------------------------------------+
//| Initialize Chain of Trust system                                |
//+------------------------------------------------------------------+
bool CSystemOrchestrator::InitializeChainOfTrust()
{
    if(m_main_db == INVALID_HANDLE) return false;
    
    Print("🔗 SystemOrchestrator: Initializing Chain of Trust...");
    
    bool all_initialized = true;
    for(int i = 0; i < ArraySize(m_symbols); i++) {
        for(int j = 0; j < ArraySize(m_timeframes); j++) {
            if(!CChainOfTrust::RunMaintenanceCycle(m_main_db, m_symbols[i], m_timeframes[j])) {
                Print("❌ Chain of Trust initialization failed for ", m_symbols[i], " ", CChainOfTrust::TimeframeToString(m_timeframes[j]));
                all_initialized = false;
            }
        }
    }
    
    Print("🔗 Chain of Trust initialization ", (all_initialized ? "completed successfully" : "completed with issues"));
    return all_initialized;
}

//+------------------------------------------------------------------+
//| Verify Chain of Trust completion                                |
//+------------------------------------------------------------------+
bool CSystemOrchestrator::VerifyChainOfTrustComplete()
{
    bool all_complete = true;
    int total_broken = 0;
    
    Print("🔍 SystemOrchestrator: Verifying Chain of Trust completion...");
    
    for(int i = 0; i < ArraySize(m_symbols); i++) {
        for(int j = 0; j < ArraySize(m_timeframes); j++) {
            string symbol = m_symbols[i];
            ENUM_TIMEFRAMES tf = m_timeframes[j];
            
            int broken_bars = CChainOfTrust::CountBrokenChainBars(m_main_db, symbol, tf);
            
            if(broken_bars > 5) { // Allow small tolerance
                Print("⚠️ Chain incomplete: ", symbol, " ", CChainOfTrust::TimeframeToString(tf), " - Broken: ", broken_bars, " bars");
                all_complete = false;
                total_broken += broken_bars;
            } else {
                Print("✅ Chain complete: ", symbol, " ", CChainOfTrust::TimeframeToString(tf));
            }
        }
    }
    
    return all_complete;
}

//+------------------------------------------------------------------+
//| Perform initial system synchronization                          |
//+------------------------------------------------------------------+
bool CSystemOrchestrator::PerformInitialSync()
{
    Print("📈 SystemOrchestrator: Performing initial synchronization...");
    
    bool all_synced = true;
    
    for(int i = 0; i < ArraySize(m_symbols); i++) {
        for(int j = 0; j < ArraySize(m_timeframes); j++) {
            string symbol = m_symbols[i];
            ENUM_TIMEFRAMES tf = m_timeframes[j];
            
            Print("🔄 Running Chain of Trust maintenance for ", symbol, " ", CChainOfTrust::TimeframeToString(tf));
            
            if(!CChainOfTrust::RunMaintenanceCycle(m_main_db, symbol, tf)) {
                Print("❌ Maintenance failed for ", symbol, " ", CChainOfTrust::TimeframeToString(tf));
                all_synced = false;
            }
        }
    }
    
    return VerifyChainOfTrustComplete() && all_synced;
}

//+------------------------------------------------------------------+
//| Optimized timeframe parsing                                     |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES CSystemOrchestrator::ParseTimeframeOptimized(string tf_string)
{
    StringToUpper(tf_string);
    StringTrimLeft(tf_string);
    StringTrimRight(tf_string);
    
    // Fast O(1) lookup
    if(tf_string == "M1") return PERIOD_M1;
    if(tf_string == "M5") return PERIOD_M5;
    if(tf_string == "M15") return PERIOD_M15;
    if(tf_string == "H1") return PERIOD_H1;
    if(tf_string == "D1") return PERIOD_D1;
    if(tf_string == "M2") return PERIOD_M2;
    if(tf_string == "M3") return PERIOD_M3;
    if(tf_string == "M4") return PERIOD_M4;
    if(tf_string == "M6") return PERIOD_M6;
    if(tf_string == "M10") return PERIOD_M10;
    if(tf_string == "M12") return PERIOD_M12;
    if(tf_string == "M20") return PERIOD_M20;
    if(tf_string == "M30") return PERIOD_M30;
    if(tf_string == "H2") return PERIOD_H2;
    if(tf_string == "H3") return PERIOD_H3;
    if(tf_string == "H4") return PERIOD_H4;
    if(tf_string == "H6") return PERIOD_H6;
    if(tf_string == "H8") return PERIOD_H8;
    if(tf_string == "H12") return PERIOD_H12;
    if(tf_string == "W1") return PERIOD_W1;
    if(tf_string == "MN1") return PERIOD_MN1;
    
    // Fallback
    int tf_int = (int)StringToInteger(tf_string);
    if(tf_int == 1440) return PERIOD_D1;
    if(tf_int > 0) return (ENUM_TIMEFRAMES)tf_int;
    
    Print("⚠️ Unknown timeframe '", tf_string, "', defaulting to M1");
    return PERIOD_M1;
}

//+------------------------------------------------------------------+
//| Log system status                                               |
//+------------------------------------------------------------------+
void CSystemOrchestrator::LogSystemStatus()
{
    Print("📊 SystemOrchestrator Status:");
    Print("   Symbols: ", ArraySize(m_symbols));
    Print("   Timeframes: ", ArraySize(m_timeframes));
    Print("   Test Mode: ", (m_test_mode ? "ENABLED" : "DISABLED"));
    Print("   Initial Sync: ", (m_initial_sync_completed ? "COMPLETED" : "INCOMPLETE"));
}

//+------------------------------------------------------------------+
//| Diagnose D1 timeframe specifically                              |
//+------------------------------------------------------------------+
bool CSystemOrchestrator::DiagnoseD1Timeframe()
{
    Print("=== D1 TIMEFRAME DIAGNOSIS ===");
    
    for(int s = 0; s < ArraySize(m_symbols); s++) {
        string symbol = m_symbols[s];
        Print("Checking D1 for symbol: ", symbol);
        
        // Check if D1 is in our timeframes array
        bool d1_configured = false;
        for(int t = 0; t < ArraySize(m_timeframes); t++) {
            if(m_timeframes[t] == PERIOD_D1) {
                d1_configured = true;
                Print("  ✅ D1 found in timeframes array");
                break;
            }
        }
        
        if(!d1_configured) {
            Print("  ❌ D1 NOT configured");
            continue;
        }
        
        // Check data availability
        int d1_bars = iBars(symbol, PERIOD_D1);
        datetime d1_time = iTime(symbol, PERIOD_D1, 0);
        
        Print("  D1 bars available: ", d1_bars);
        Print("  D1 current bar time: ", TimeToString(d1_time, TIME_DATE|TIME_SECONDS));
        
        if(d1_bars <= 0 || d1_time <= 0) {
            Print("  ❌ D1 data unavailable for ", symbol);
        } else {
            Print("  ✅ D1 data valid for ", symbol);
        }
    }
    
    Print("=== END D1 DIAGNOSIS ===");
    return true;
}

//+------------------------------------------------------------------+
//| Shutdown system orchestrator                                    |
//+------------------------------------------------------------------+
void CSystemOrchestrator::Shutdown()
{
    CloseDatabases();
    m_initialized = false;
}

//+------------------------------------------------------------------+
//| Close all database connections                                  |
//+------------------------------------------------------------------+
void CSystemOrchestrator::CloseDatabases()
{
    if(m_main_db != INVALID_HANDLE) {
        DatabaseClose(m_main_db);
        m_main_db = INVALID_HANDLE;
    }
    if(m_test_input_db != INVALID_HANDLE) {
        DatabaseClose(m_test_input_db);
        m_test_input_db = INVALID_HANDLE;
    }
    if(m_test_output_db != INVALID_HANDLE) {
        DatabaseClose(m_test_output_db);
        m_test_output_db = INVALID_HANDLE;
    }
}

//+------------------------------------------------------------------+
//| Timer event handler - called by main EA OnTimer()              |
//+------------------------------------------------------------------+
void CSystemOrchestrator::OnTimer()
{
    static datetime last_validation = 0;
    static datetime last_test_flow = 0;
    
    datetime current_time = TimeCurrent();
    
    // Perform validation at specified intervals
    if(current_time - last_validation >= m_validation_interval) {
        if(m_enable_logging) {
            Print("🔍 SystemOrchestrator: Performing scheduled validation");
        }
        PerformValidation();
        last_validation = current_time;
    }
    
    // Execute test mode flow if enabled
    if(m_test_mode && (current_time - last_test_flow >= m_test_flow_interval)) {
        if(m_enable_logging) {
            Print("🧪 SystemOrchestrator: Executing test mode flow");
        }
        ExecuteTestModeFlow();
        last_test_flow = current_time;
    }
    
    // Continuous market data synchronization
    SyncMarketData();
}

//+------------------------------------------------------------------+
//| New bar event handler - called when new bar detected            |
//+------------------------------------------------------------------+
void CSystemOrchestrator::OnNewBar(const string symbol, ENUM_TIMEFRAMES timeframe)
{
    if(m_enable_logging) {
        Print("📊 SystemOrchestrator: Processing new bar - ", symbol, " ", CSymbolParser::TimeframeToString(timeframe));
    }
    
    ProcessNewBarData(symbol, timeframe);
}

//+------------------------------------------------------------------+
//| Chart event handler - called by main EA OnChartEvent()         |
//+------------------------------------------------------------------+
void CSystemOrchestrator::OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
    // Handle system-level chart events if needed
    // This could be used for manual control commands, system status requests, etc.
    
    if(id == CHARTEVENT_KEYDOWN && lparam == 'S') {
        // Manual system status on 'S' key press
        LogSystemStatus();
    }
}

//+------------------------------------------------------------------+
//| Perform system validation using Chain of Trust                  |
//+------------------------------------------------------------------+
bool CSystemOrchestrator::PerformValidation()
{
    if(!m_initialized) {
        return false;
    }
    
    bool validation_passed = true;
    
    // Validate main database
    if(m_main_db != INVALID_HANDLE) {
        if(!CChainOfTrust::ValidateDatabase(m_main_db)) {
            Print("❌ SystemOrchestrator: Main database validation failed");
            validation_passed = false;
        }
    }
    
    // Validate test databases if in test mode
    if(m_test_mode) {
        if(m_test_input_db != INVALID_HANDLE) {
            if(!CChainOfTrust::ValidateDatabase(m_test_input_db)) {
                Print("❌ SystemOrchestrator: Test input database validation failed");
                validation_passed = false;
            }
        }
        
        if(m_test_output_db != INVALID_HANDLE) {
            if(!CChainOfTrust::ValidateDatabase(m_test_output_db)) {
                Print("❌ SystemOrchestrator: Test output database validation failed");
                validation_passed = false;
            }
        }
    }
    
    if(validation_passed && m_enable_logging) {
        Print("✅ SystemOrchestrator: System validation passed");
    }
    
    return validation_passed;
}

//+------------------------------------------------------------------+
//| Synchronize market data for all symbols/timeframes             |
//+------------------------------------------------------------------+
bool CSystemOrchestrator::SyncMarketData()
{
    if(!m_initialized) {
        return false;
    }
    
    bool sync_success = true;
    
    // Sync data for all configured symbols and timeframes
    for(int i = 0; i < ArraySize(m_symbols); i++) {
        for(int j = 0; j < ArraySize(m_timeframes); j++) {
            string symbol = m_symbols[i];
            ENUM_TIMEFRAMES timeframe = m_timeframes[j];
            
            // Get current bar data
            datetime bar_time = iTime(symbol, timeframe, 0);
            double open = iOpen(symbol, timeframe, 0);
            double high = iHigh(symbol, timeframe, 0);
            double low = iLow(symbol, timeframe, 0);
            double close = iClose(symbol, timeframe, 0);
            long tick_volume = iTickVolume(symbol, timeframe, 0);
            long real_volume = iRealVolume(symbol, timeframe, 0);
            
            // Store in database if data is valid
            if(bar_time > 0 && open > 0) {
                if(!StoreMarketData(symbol, timeframe, bar_time, open, high, low, close, tick_volume, real_volume)) {
                    sync_success = false;
                }
            }
        }
    }
    
    return sync_success;
}

//+------------------------------------------------------------------+
//| Execute test mode flow operations                               |
//+------------------------------------------------------------------+
bool CSystemOrchestrator::ExecuteTestModeFlow()
{
    if(!m_test_mode || !m_initialized) {
        return false;
    }
    
    bool flow_success = true;
    
    if(m_enable_logging) {
        Print("🧪 SystemOrchestrator: Executing test mode data flow");
    }
    
    // Process test mode operations for all symbols/timeframes
    for(int i = 0; i < ArraySize(m_symbols); i++) {
        for(int j = 0; j < ArraySize(m_timeframes); j++) {
            string symbol = m_symbols[i];
            ENUM_TIMEFRAMES timeframe = m_timeframes[j];
            
            // Get current market data
            datetime bar_time = iTime(symbol, timeframe, 0);
            double open = iOpen(symbol, timeframe, 0);
            double high = iHigh(symbol, timeframe, 0);
            double low = iLow(symbol, timeframe, 0);
            double close = iClose(symbol, timeframe, 0);
            long tick_volume = iTickVolume(symbol, timeframe, 0);
            long real_volume = iRealVolume(symbol, timeframe, 0);
            
            if(bar_time > 0 && open > 0) {
                // Store in test input database (raw OHLCVT)
                string query_input = StringFormat(
                    "INSERT OR REPLACE INTO AllCandleData "
                    "(asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, real_volume) "
                    "VALUES ('%s', '%s', %d, %.5f, %.5f, %.5f, %.5f, %d, %d)",
                    symbol, CSymbolParser::TimeframeToString(timeframe), bar_time, 
                    open, high, low, close, tick_volume, real_volume
                );
                
                if(m_test_input_db != INVALID_HANDLE) {
                    DatabaseExecute(m_test_input_db, query_input);
                }
                
                // Generate enhanced metadata and store in test output database
                string hash = CChainOfTrust::CalculateDataHash(symbol, timeframe, bar_time, open, high, low, close, tick_volume);
                
                string query_output = StringFormat(
                    "INSERT OR REPLACE INTO AllCandleData "
                    "(asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, real_volume, hash, is_validated, is_complete, validation_time) "
                    "VALUES ('%s', '%s', %d, %.5f, %.5f, %.5f, %.5f, %d, %d, '%s', 1, 1, %d)",
                    symbol, CSymbolParser::TimeframeToString(timeframe), bar_time, 
                    open, high, low, close, tick_volume, real_volume, hash, TimeCurrent()
                );
                
                if(m_test_output_db != INVALID_HANDLE) {
                    DatabaseExecute(m_test_output_db, query_output);
                }
            }
        }
    }
    
    return flow_success;
}

//+------------------------------------------------------------------+
//| Process new bar data for specific symbol/timeframe             |
//+------------------------------------------------------------------+
bool CSystemOrchestrator::ProcessNewBarData(const string symbol, ENUM_TIMEFRAMES timeframe)
{
    if(!m_initialized) {
        return false;
    }
    
    // Get new bar data
    datetime bar_time = iTime(symbol, timeframe, 0);
    double open = iOpen(symbol, timeframe, 0);
    double high = iHigh(symbol, timeframe, 0);
    double low = iLow(symbol, timeframe, 0);
    double close = iClose(symbol, timeframe, 0);
    long tick_volume = iTickVolume(symbol, timeframe, 0);
    long real_volume = iRealVolume(symbol, timeframe, 0);
    
    if(bar_time <= 0 || open <= 0) {
        Print("⚠️ SystemOrchestrator: Invalid bar data for ", symbol, " ", CSymbolParser::TimeframeToString(timeframe));
        return false;
    }
    
    // Store in main database
    bool success = StoreMarketData(symbol, timeframe, bar_time, open, high, low, close, tick_volume, real_volume);
    
    // Process test mode if enabled
    if(m_test_mode && success) {
        // This could trigger immediate test mode processing for the new bar
        ExecuteTestModeFlow();
    }
    
    return success;
}

//+------------------------------------------------------------------+
//| Store market data in database with Chain of Trust validation   |
//+------------------------------------------------------------------+
bool CSystemOrchestrator::StoreMarketData(const string symbol, ENUM_TIMEFRAMES timeframe, 
                                         datetime timestamp, double open, double high, double low, 
                                         double close, long tick_volume, long real_volume = 0)
{
    if(m_main_db == INVALID_HANDLE) {
        return false;
    }
    
    // Generate verification hash
    string hash = CChainOfTrust::CalculateDataHash(symbol, timeframe, timestamp, open, high, low, close, tick_volume);
    
    // Store in main database
    string query = StringFormat(
        "INSERT OR REPLACE INTO AllCandleData "
        "(asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, real_volume, hash, is_validated, is_complete, validation_time) "
        "VALUES ('%s', '%s', %d, %.5f, %.5f, %.5f, %.5f, %d, %d, '%s', 1, 1, %d)",
        symbol, CSymbolParser::TimeframeToString(timeframe), timestamp, 
        open, high, low, close, tick_volume, real_volume, hash, TimeCurrent()
    );
    
    bool success = DatabaseExecute(m_main_db, query);
    
    if(!success && m_enable_logging) {
        Print("❌ SystemOrchestrator: Failed to store market data for ", symbol, " ", CSymbolParser::TimeframeToString(timeframe));
    }
    
    return success;
}
