//+------------------------------------------------------------------+
//| TestPanelRefactored.mqh - Refactored Test Panel                |
//| Main orchestrator class using modular components               |
//+------------------------------------------------------------------+

#include <SSoT/Monitoring/DatabaseOperations.mqh>
#include <SSoT/Monitoring/VisualDisplay.mqh>
#include <SSoT/Monitoring/ReportGenerator.mqh>
#include <SSoT/Testing/TestDatabaseManager.mqh>

//+------------------------------------------------------------------+
//| Refactored Test Panel Class                                    |
//+------------------------------------------------------------------+
class CTestPanelRefactored
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
    
    // Visual panel settings
    bool m_panel_created;
    string m_object_prefix;
    
    // Component instances
    CDatabaseOperations m_db_ops;
    CVisualDisplay m_visual;
    CReportGenerator m_report_gen;
    CTestDatabaseManager m_test_db_mgr;

public:
    //--- Constructor/Destructor
    CTestPanelRefactored(void);
    ~CTestPanelRefactored(void);
    
    //--- Initialization
    bool Initialize(bool test_mode, int main_db_handle, int test_input_handle = INVALID_HANDLE, int test_output_handle = INVALID_HANDLE);
    void Shutdown(void);
    
    //--- Mode Control
    bool IsTestMode(void) { return m_test_mode_active; }
    void SetDisplayInterval(int seconds) { m_display_interval = seconds; }
    bool ShouldUpdateDisplay(void);
    
    //--- Core Display Functions
    void DisplayDatabaseOverview(void);
    void UpdateDisplay(void);
    
    //--- Visual Panel Functions
    bool CreateVisualPanel(void);
    void UpdateVisualPanel(void);
    void CleanupVisualPanel(void);
    void ForceCleanupAllSSoTObjects(void);
    
    //--- Report Functions
    bool CopyToClipboard(void);
    string GenerateReportText(void);
    
    //--- Test Database Functions
    bool GenerateTestDatabases(void);
    bool DeleteTestDatabases(void);    //--- Event Handling
    void HandleChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
      //--- Data Comparison Display (Live Mode Only)
    void CreateBrokerVsDatabaseDisplay(string &symbols[], ENUM_TIMEFRAMES &timeframes[]);
    void UpdateBrokerVsDatabaseDisplay(string &symbols[], ENUM_TIMEFRAMES &timeframes[]);
    
private:
    //--- Helper Methods
    void PrintDatabaseStatus(void);
    void UpdateLastDisplayTime(void);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTestPanelRefactored::CTestPanelRefactored(void) : m_visual("SSoT_")
{
    m_object_prefix = "SSoT_";
    m_main_db = INVALID_HANDLE;
    m_test_input_db = INVALID_HANDLE;
    m_test_output_db = INVALID_HANDLE;
    m_test_mode_active = false;
    m_display_enabled = true;
    m_last_display_update = 0;
    m_display_interval = 30; // Default 30 seconds
    m_panel_created = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTestPanelRefactored::~CTestPanelRefactored(void)
{
    CleanupVisualPanel();
    Shutdown();
}

//+------------------------------------------------------------------+
//| Initialize the test panel                                        |
//+------------------------------------------------------------------+
bool CTestPanelRefactored::Initialize(bool test_mode, int main_db_handle, int test_input_handle, int test_output_handle)
{
    Print("[PANEL] TestPanel Refactored: Initializing Monitor...");
    
    m_test_mode_active = test_mode;
    m_main_db = main_db_handle;
    
    if(m_test_mode_active) {
        m_test_input_db = test_input_handle;
        m_test_output_db = test_output_handle;
        Print("[PANEL] TestPanel: Initialized in TEST MODE");
        Print("[PANEL] TestPanel: Monitoring 3 databases (Main, Test Input, Test Output)");
    } else {
        Print("[PANEL] TestPanel: Initialized in LIVE MODE");
        Print("[PANEL] TestPanel: Monitoring 1 database (Main only)");
    }
    
    // Create visual panel
    if(!CreateVisualPanel()) {
        Print("[WARN] Visual panel creation failed, continuing with console only");
    }
    
    // Initial display
    DisplayDatabaseOverview();
    
    return true;
}

//+------------------------------------------------------------------+
//| Shutdown the test panel                                          |
//+------------------------------------------------------------------+
void CTestPanelRefactored::Shutdown(void)
{
    Print("[PANEL] TestPanel Refactored: Shutting down...");
    m_display_enabled = false;
}

//+------------------------------------------------------------------+
//| Check if display should be updated                              |
//+------------------------------------------------------------------+
bool CTestPanelRefactored::ShouldUpdateDisplay(void)
{
    if(!m_display_enabled) return false;
    return (TimeCurrent() - m_last_display_update) >= m_display_interval;
}

//+------------------------------------------------------------------+
//| Display comprehensive database overview                         |
//+------------------------------------------------------------------+
void CTestPanelRefactored::DisplayDatabaseOverview(void)
{
    if(!m_display_enabled) return;
    
    Print("[DATA] ================================================================");
    Print("[DATA] SSoT TEST PANEL REFACTORED v1.0 - DATABASE MONITOR");
    Print("[DATA] ================================================================");
    Print("[DATA] Time: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
    Print("[DATA] Mode: " + (m_test_mode_active ? "[TEST] TEST MODE" : "[LIVE] LIVE MODE"));
    Print("[DATA]");
    
    if(m_test_mode_active) {
        // Test Mode: Display all three databases
        Print("[DATA] DATABASE 1: MAIN (sourcedb.sqlite)");
        m_db_ops.DisplayDBInfo(m_main_db, "sourcedb.sqlite");
        m_db_ops.DisplayAllCandleData(m_main_db, "Main Database");
        Print("[DATA]");
        
        Print("[DATA] DATABASE 2: TEST INPUT (SSoT_input.db)");
        m_db_ops.DisplayDBInfo(m_test_input_db, "SSoT_input.db");
        m_db_ops.DisplayAllCandleData(m_test_input_db, "Test Input Database");
        Print("[DATA]");
        
        Print("[DATA] DATABASE 3: TEST OUTPUT (SSoT_output.db)");
        m_db_ops.DisplayDBInfo(m_test_output_db, "SSoT_output.db");
        m_db_ops.DisplayAllCandleData(m_test_output_db, "Test Output Database");
    } else {
        // Live Mode: Only main database
        Print("[DATA] DATABASE: MAIN (sourcedb.sqlite)");
        m_db_ops.DisplayDBInfo(m_main_db, "sourcedb.sqlite");
        m_db_ops.DisplayAllCandleData(m_main_db, "Live Database");
    }
    
    Print("[DATA] ================================================================");
    
    // Update visual panel
    UpdateVisualPanel();
    UpdateLastDisplayTime();
}

//+------------------------------------------------------------------+
//| Update display if needed                                        |
//+------------------------------------------------------------------+
void CTestPanelRefactored::UpdateDisplay(void)
{
    if(ShouldUpdateDisplay()) {
        DisplayDatabaseOverview();
    }
}

//+------------------------------------------------------------------+
//| Create visual panel                                             |
//+------------------------------------------------------------------+
bool CTestPanelRefactored::CreateVisualPanel(void)
{
    Print("[VISUAL] Creating refactored visual panel...");
    
    bool success = m_visual.CreateVisualPanel();
    if(success) {
        m_panel_created = true;
        // Create the full database display
        m_visual.CreateFullDatabaseDisplay(m_test_mode_active, m_main_db, m_test_input_db, m_test_output_db);
    }
    
    return success;
}

//+------------------------------------------------------------------+
//| Update visual panel                                             |
//+------------------------------------------------------------------+
void CTestPanelRefactored::UpdateVisualPanel(void)
{
    if(!m_panel_created) return;
    
    // Update the full database display with current data
    m_visual.CreateFullDatabaseDisplay(m_test_mode_active, m_main_db, m_test_input_db, m_test_output_db);
    m_visual.UpdateVisualPanel();
}

//+------------------------------------------------------------------+
//| Cleanup visual panel                                            |
//+------------------------------------------------------------------+
void CTestPanelRefactored::CleanupVisualPanel(void)
{
    m_visual.CleanupVisualPanel();
    m_panel_created = false;
}

//+------------------------------------------------------------------+
//| Force cleanup all SSoT objects                                 |
//+------------------------------------------------------------------+
void CTestPanelRefactored::ForceCleanupAllSSoTObjects(void)
{
    m_visual.ForceCleanupAllSSoTObjects();
    m_panel_created = false;
}

//+------------------------------------------------------------------+
//| Generate report text                                            |
//+------------------------------------------------------------------+
string CTestPanelRefactored::GenerateReportText(void)
{
    return m_report_gen.GenerateReportText(m_test_mode_active, m_main_db, m_test_input_db, m_test_output_db);
}

//+------------------------------------------------------------------+
//| Copy report to clipboard                                        |
//+------------------------------------------------------------------+
bool CTestPanelRefactored::CopyToClipboard(void)
{
    Print("[PANEL] Generating comprehensive report for clipboard...");
    
    string report = m_report_gen.GenerateComprehensiveReport(m_test_mode_active, m_main_db, m_test_input_db, m_test_output_db);
    
    if(StringLen(report) == 0) {
        Print("[PANEL] ERROR: Report generation failed");
        return false;
    }
    
    return m_report_gen.CopyToClipboard(report);
}

//+------------------------------------------------------------------+
//| Generate test databases                                          |
//+------------------------------------------------------------------+
bool CTestPanelRefactored::GenerateTestDatabases(void)
{
    Print("[PANEL] Requesting test database generation...");
    return m_test_db_mgr.GenerateTestDatabases();
}

//+------------------------------------------------------------------+
//| Delete test databases                                           |
//+------------------------------------------------------------------+
bool CTestPanelRefactored::DeleteTestDatabases(void)
{
    Print("[PANEL] Requesting test database deletion...");
    return m_test_db_mgr.DeleteTestDatabases();
}

//+------------------------------------------------------------------+
//| Handle chart events                                             |
//+------------------------------------------------------------------+
void CTestPanelRefactored::HandleChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    Print("[EVENT] Chart event received - ID: ", id, ", sparam: ", sparam);
    
    if(id == CHARTEVENT_OBJECT_CLICK) {
        Print("[EVENT] Object click detected: ", sparam);
        Print("[EVENT] Looking for button: ", m_object_prefix + "CopyButton");
        
        if(sparam == m_object_prefix + "CopyButton") {
            Print("[EVENT] ✅ Copy button clicked - generating report...");
            Print("[EVENT] Test mode: ", m_test_mode_active ? "TEST" : "LIVE");
            Print("[EVENT] Main DB handle: ", m_main_db);
            
            if(CopyToClipboard()) {
                Print("[EVENT] ✅ Report copied to clipboard successfully");
            } else {
                Print("[EVENT] ❌ Failed to copy report to clipboard");
            }
        }
        else if(sparam == m_object_prefix + "GenerateButton") {
            Print("[EVENT] Generate test databases button clicked");
            if(GenerateTestDatabases()) {
                Print("[EVENT] Test databases generated successfully");
                // Update display to show new databases
                UpdateVisualPanel();
            } else {
                Print("[EVENT] Failed to generate test databases");
            }
        }
        else if(sparam == m_object_prefix + "DeleteButton") {
            Print("[EVENT] Delete test databases button clicked");
            if(DeleteTestDatabases()) {
                Print("[EVENT] Test databases deleted successfully");
                // Update display to reflect deletion
                UpdateVisualPanel();
            } else {
                Print("[EVENT] Failed to delete test databases");
            }
        }
    }
    
    // Forward event to visual component
    m_visual.HandleChartEvent(id, lparam, dparam, sparam);
}

//+------------------------------------------------------------------+
//| Print database status                                           |
//+------------------------------------------------------------------+
void CTestPanelRefactored::PrintDatabaseStatus(void)
{
    Print("[STATUS] Database Connections:");
    Print("[STATUS] - Main DB: " + (m_main_db != INVALID_HANDLE ? "CONNECTED" : "DISCONNECTED"));
    if(m_test_mode_active) {
        Print("[STATUS] - Test Input DB: " + (m_test_input_db != INVALID_HANDLE ? "CONNECTED" : "DISCONNECTED"));
        Print("[STATUS] - Test Output DB: " + (m_test_output_db != INVALID_HANDLE ? "CONNECTED" : "DISCONNECTED"));
    }
}

//+------------------------------------------------------------------+
//| Update last display time                                        |
//+------------------------------------------------------------------+
void CTestPanelRefactored::UpdateLastDisplayTime(void)
{    m_last_display_update = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Create Broker vs Database Display (Live Mode Only)             |
//+------------------------------------------------------------------+
void CTestPanelRefactored::CreateBrokerVsDatabaseDisplay(string &symbols[], ENUM_TIMEFRAMES &timeframes[])
{
    if(m_test_mode_active) {
        Print("[PANEL] Broker vs Database comparison only available in Live Mode");
        return;
    }
    
    if(m_main_db == INVALID_HANDLE) {
        Print("[PANEL] Cannot create comparison - main database not connected");
        return;
    }
    
    Print("[PANEL] Creating Broker vs Database comparison display...");
    m_visual.CreateBrokerVsDatabaseComparison(symbols, timeframes, m_main_db);
}

//+------------------------------------------------------------------+
//| Update Broker vs Database Display                               |
//+------------------------------------------------------------------+
void CTestPanelRefactored::UpdateBrokerVsDatabaseDisplay(string &symbols[], ENUM_TIMEFRAMES &timeframes[])
{
    if(m_test_mode_active) {
        return; // Only show in live mode
    }
    
    if(m_main_db == INVALID_HANDLE) {
        return;
    }
      m_visual.UpdateDataComparisonDisplay(symbols, timeframes, m_main_db);
    UpdateLastDisplayTime();
}
