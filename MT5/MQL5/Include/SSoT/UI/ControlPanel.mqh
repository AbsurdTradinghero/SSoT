//+------------------------------------------------------------------+
//| ControlPanel.mqh - Main SSoT System Control Interface           |
//| Consolidated control panel combining best features from legacy   |
//| test panels into a single, authoritative control interface      |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "2.00"
#property strict

#include <SSoT/Database/DatabaseManager.mqh>
#include <SSoT/UI/StatusDisplay.mqh>
#include <SSoT/Utilities/Logger.mqh>

//+------------------------------------------------------------------+
//| Main Control Panel Class - The Gold Standard Interface          |
//+------------------------------------------------------------------+
class CControlPanel
{
private:
    // Database handles
    int               m_main_db;
    int               m_test_input_db;
    int               m_test_output_db;
    
    // Operating mode
    bool              m_test_mode_active;
    bool              m_initialized;
    
    // Tracked Assets and Timeframes
    string            m_tracked_symbols[];
    ENUM_TIMEFRAMES   m_tracked_timeframes[];
    bool              m_tracking_enabled;
    
    // Display components
    CStatusDisplay*   m_status_display;
    bool              m_visual_panel_enabled;
    datetime          m_last_display_update;
    int               m_display_interval;
    
    // System status
    datetime          m_system_start_time;
    bool              m_auto_update_enabled;
    
public:
    //--- Constructor/Destructor
    CControlPanel(void);
    ~CControlPanel(void);
    
    //--- Core Initialization
    bool              Initialize(bool test_mode, int main_db_handle, 
                                int test_input_handle = INVALID_HANDLE, 
                                int test_output_handle = INVALID_HANDLE);
    bool              InitializeWithTracking(bool test_mode, int main_db_handle, 
                                            string &tracked_symbols[], 
                                            ENUM_TIMEFRAMES &tracked_timeframes[], 
                                            int test_input_handle = INVALID_HANDLE, 
                                            int test_output_handle = INVALID_HANDLE);
    void              Shutdown(void);
    
    //--- Main Control Functions
    void              Update(void);
    void              DisplaySystemStatus(void);
    void              DisplayDatabaseOverview(void);
    void              DisplayChainStatus(void);
    
    //--- Visual Interface
    bool              CreateVisualPanel(void);
    void              UpdateVisualPanel(void);
    void              DestroyVisualPanel(void);
    
    //--- Mode Control
    bool              IsTestMode(void) const { return m_test_mode_active; }
    bool              IsInitialized(void) const { return m_initialized; }
    void              SetDisplayInterval(int seconds) { m_display_interval = seconds; }
    void              EnableAutoUpdate(bool enable) { m_auto_update_enabled = enable; }
    
    //--- Test Mode Operations
    bool              GenerateTestDatabases(void);
    bool              DeleteTestDatabases(void);
    bool              RunTestFlow(void);
    
    //--- Reporting & Export
    string            GenerateSystemReport(void);
    bool              ExportToClipboard(void);
    bool              ExportToFile(const string filename);
    
    //--- Event Handling
    void              HandleChartEvent(const int id, const long &lparam, 
                                     const double &dparam, const string &sparam);
    
    //--- Status Queries
    string            GetSystemHealth(void);
    string            GetDatabaseStatus(void);
    string            GetOperationalMode(void);
    datetime          GetUptime(void);
    
private:
    //--- Internal helpers
    bool              ShouldUpdateDisplay(void);
    void              LogSystemEvent(const string event, const string details);
    void              UpdateDisplayTimestamp(void);
    bool              ValidateDatabaseHandles(void);
    void              InitializeDisplayComponents(void);
    void              CleanupResources(void);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CControlPanel::CControlPanel(void)
{
    m_main_db = INVALID_HANDLE;
    m_test_input_db = INVALID_HANDLE;
    m_test_output_db = INVALID_HANDLE;
    m_test_mode_active = false;
    m_initialized = false;
    m_tracking_enabled = false;
    m_status_display = NULL;
    m_visual_panel_enabled = true;
    m_last_display_update = 0;
    m_display_interval = 30; // 30 seconds default
    m_system_start_time = TimeCurrent();
    m_auto_update_enabled = true;
    
    ArrayResize(m_tracked_symbols, 0);
    ArrayResize(m_tracked_timeframes, 0);
    
    Log(LOG_INFO, "ControlPanel: Constructor completed");
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CControlPanel::~CControlPanel(void)
{
    Shutdown();
}

//+------------------------------------------------------------------+
//| Initialize control panel with basic parameters                  |
//+------------------------------------------------------------------+
bool CControlPanel::Initialize(bool test_mode, int main_db_handle, int test_input_handle, int test_output_handle)
{
    if(m_initialized) {
        Log(LOG_WARNING, "ControlPanel: Already initialized");
        return true;
    }
    
    Log(LOG_INFO, "ControlPanel: Initializing system control interface...");
    
    m_test_mode_active = test_mode;
    m_main_db = main_db_handle;
    m_test_input_db = test_input_handle;
    m_test_output_db = test_output_handle;
    
    // Validate database handles
    if(!ValidateDatabaseHandles()) {
        // // CLogger::Error("ControlPanel: Database handle validation failed");
        return false;
    }
    
    // Initialize display components
    InitializeDisplayComponents();
    
    // Create visual interface
    if(m_visual_panel_enabled) {
        if(!CreateVisualPanel()) {
            // CLogger::Warning("ControlPanel: Visual panel creation failed, continuing console-only");
            m_visual_panel_enabled = false;
        }
    }
    
    m_initialized = true;
    m_system_start_time = TimeCurrent();
    
    string mode = m_test_mode_active ? "TEST MODE (3 databases)" : "LIVE MODE (1 database)";
    // CLogger::Info(StringFormat("ControlPanel: Initialized successfully in %s", mode));
    
    // Initial status display
    DisplaySystemStatus();
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize with symbol/timeframe tracking                       |
//+------------------------------------------------------------------+
bool CControlPanel::InitializeWithTracking(bool test_mode, int main_db_handle, string &tracked_symbols[], ENUM_TIMEFRAMES &tracked_timeframes[], int test_input_handle, int test_output_handle)
{
    // First, standard initialization
    if(!Initialize(test_mode, main_db_handle, test_input_handle, test_output_handle)) {
        return false;
    }
    
    // Set up tracking
    ArrayCopy(m_tracked_symbols, tracked_symbols);
    ArrayCopy(m_tracked_timeframes, tracked_timeframes);
    m_tracking_enabled = true;
    
    // CLogger::Info(StringFormat("ControlPanel: Tracking enabled for %d symbols and %d timeframes", 
                              ArraySize(m_tracked_symbols), ArraySize(m_tracked_timeframes)));
    
    return true;
}

//+------------------------------------------------------------------+
//| Main update function - call regularly from OnTimer             |
//+------------------------------------------------------------------+
void CControlPanel::Update(void)
{
    if(!m_initialized || !m_auto_update_enabled) {
        return;
    }
    
    if(ShouldUpdateDisplay()) {
        DisplaySystemStatus();
        UpdateVisualPanel();
        UpdateDisplayTimestamp();
    }
}

//+------------------------------------------------------------------+
//| Display comprehensive system status                             |
//+------------------------------------------------------------------+
void CControlPanel::DisplaySystemStatus(void)
{
    if(!m_initialized) return;
    
    Print("================================================================");
    Print("SSoT CONTROL PANEL v2.00 - SYSTEM STATUS");
    Print("================================================================");
    Print("Mode: [", (m_test_mode_active ? "TEST" : "LIVE"), "] ", GetOperationalMode());
    Print("Uptime: ", TimeToString(GetUptime(), TIME_SECONDS));
    Print("Database Status: ", GetDatabaseStatus());
    Print("System Health: ", GetSystemHealth());
    
    if(m_tracking_enabled) {
        Print("Tracking: ", ArraySize(m_tracked_symbols), " symbols, ", 
              ArraySize(m_tracked_timeframes), " timeframes");
    }
    
    DisplayDatabaseOverview();
    Print("================================================================");
}

//+------------------------------------------------------------------+
//| Display database overview with detailed statistics              |
//+------------------------------------------------------------------+
void CControlPanel::DisplayDatabaseOverview(void)
{
    if(m_main_db != INVALID_HANDLE) {
        Print("DATABASE 1: MAIN (sourcedb.sqlite)");
        // Implementation will use DatabaseManager to get statistics
        Print("  Status: Connected");
        Print("  Tables: ", "Multiple symbol/timeframe combinations");
    }
    
    if(m_test_mode_active) {
        if(m_test_input_db != INVALID_HANDLE) {
            Print("DATABASE 2: TEST INPUT (SSoT_input.db)");
            Print("  Status: Connected");
        }
        
        if(m_test_output_db != INVALID_HANDLE) {
            Print("DATABASE 3: TEST OUTPUT (SSoT_output.db)");
            Print("  Status: Connected");
        }
    }
}

//+------------------------------------------------------------------+
//| Check if display should be updated                              |
//+------------------------------------------------------------------+
bool CControlPanel::ShouldUpdateDisplay(void)
{
    return (TimeCurrent() - m_last_display_update) >= m_display_interval;
}

//+------------------------------------------------------------------+
//| Validate database handles                                       |
//+------------------------------------------------------------------+
bool CControlPanel::ValidateDatabaseHandles(void)
{
    if(m_main_db == INVALID_HANDLE) {
        // CLogger::Error("ControlPanel: Main database handle is invalid");
        return false;
    }
    
    if(m_test_mode_active) {
        if(m_test_input_db == INVALID_HANDLE || m_test_output_db == INVALID_HANDLE) {
            // CLogger::Error("ControlPanel: Test mode requires valid input and output database handles");
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize display components                                    |
//+------------------------------------------------------------------+
void CControlPanel::InitializeDisplayComponents(void)
{
    if(m_status_display == NULL) {
        m_status_display = new CStatusDisplay();
        if(m_status_display != NULL) {
            // CLogger::Info("ControlPanel: Status display component initialized");
        }
    }
}

//+------------------------------------------------------------------+
//| Shutdown and cleanup                                            |
//+------------------------------------------------------------------+
void CControlPanel::Shutdown(void)
{
    if(!m_initialized) return;
    
    // CLogger::Info("ControlPanel: Shutting down...");
    
    DestroyVisualPanel();
    CleanupResources();
    
    m_initialized = false;
    
    // CLogger::Info("ControlPanel: Shutdown complete");
}

//+------------------------------------------------------------------+
//| Create visual panel interface                                   |
//+------------------------------------------------------------------+
bool CControlPanel::CreateVisualPanel(void)
{
    // Visual panel creation logic will be implemented here
    // For now, return true as placeholder
    return true;
}

//+------------------------------------------------------------------+
//| Update visual panel display                                     |
//+------------------------------------------------------------------+
void CControlPanel::UpdateVisualPanel(void)
{
    if(!m_visual_panel_enabled || m_status_display == NULL) return;
    
    // Visual panel update logic
}

//+------------------------------------------------------------------+
//| Get system health status                                        |
//+------------------------------------------------------------------+
string CControlPanel::GetSystemHealth(void)
{
    if(!m_initialized) return "NOT_INITIALIZED";
    
    // Comprehensive health check
    bool db_healthy = ValidateDatabaseHandles();
    bool tracking_healthy = !m_tracking_enabled || (ArraySize(m_tracked_symbols) > 0);
    
    if(db_healthy && tracking_healthy) {
        return "HEALTHY";
    } else if(db_healthy) {
        return "DEGRADED";
    } else {
        return "CRITICAL";
    }
}

//+------------------------------------------------------------------+
//| Update display timestamp                                        |
//+------------------------------------------------------------------+
void CControlPanel::UpdateDisplayTimestamp(void)
{
    m_last_display_update = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Cleanup resources                                               |
//+------------------------------------------------------------------+
void CControlPanel::CleanupResources(void)
{
    if(m_status_display != NULL) {
        delete m_status_display;
        m_status_display = NULL;
    }
}
