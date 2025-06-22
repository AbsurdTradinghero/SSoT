//+------------------------------------------------------------------+
//| TestPanel_Clean.mqh - SSoT Test Monitor (Clean Version)         |
//| Minimal working version for compilation                          |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Simple Test Panel Monitor Class                                  |
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
    bool m_display_enabled;
    datetime m_last_display_update;
    int m_display_interval;
    
    // Visual panel settings
    bool m_panel_created;
    string m_object_prefix;

public:
    //--- Constructor/Destructor
    CTestPanel(void);
    ~CTestPanel(void);
    
    //--- Initialization
    bool Initialize(bool test_mode, int main_db_handle, int test_input_handle = INVALID_HANDLE, int test_output_handle = INVALID_HANDLE);
    void Shutdown(void);
    
    //--- Mode Control
    bool IsTestMode(void) { return m_test_mode_active; }
    
    //--- Display Functions
    void DisplayDatabaseOverview(void);
    
    //--- Chart Events
    void HandleChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CTestPanel::CTestPanel(void)
{
    m_object_prefix = "SSoT_";
    m_main_db = INVALID_HANDLE;
    m_test_input_db = INVALID_HANDLE;
    m_test_output_db = INVALID_HANDLE;
    m_test_mode_active = false;
    m_display_enabled = true;
    m_last_display_update = 0;
    m_display_interval = 30;
    m_panel_created = false;
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
bool CTestPanel::Initialize(bool test_mode, int main_db_handle, int test_input_handle, int test_output_handle)
{
    Print("[PANEL] TestPanel: Initializing Monitor...");
    
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
    
    // Initial display
    DisplayDatabaseOverview();
    
    return true;
}

//+------------------------------------------------------------------+
//| Shutdown the test panel                                           |
//+------------------------------------------------------------------+
void CTestPanel::Shutdown(void)
{
    Print("[PANEL] TestPanel: Shutting down...");
    m_display_enabled = false;
}

//+------------------------------------------------------------------+
//| Display comprehensive database overview                          |
//+------------------------------------------------------------------+
void CTestPanel::DisplayDatabaseOverview(void)
{
    if(!m_display_enabled) return;
    
    Print("[DATA] ================================================================");
    Print("[DATA] SSoT TEST PANEL - DATABASE MONITOR");
    Print("[DATA] ================================================================");
    Print("[DATA] Time: ", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
    Print("[DATA] Mode: ", m_test_mode_active ? "[TEST] TEST MODE" : "[LIVE] LIVE MODE");
    Print("[DATA]");
    
    if(m_test_mode_active) {
        // Test Mode: Display all three databases
        Print("[DATA] DATABASE 1: MAIN (sourcedb.sqlite)");
        if(m_main_db == INVALID_HANDLE) {
            Print("[DATA]   ERROR: Database not available");
        } else {
            Print("[DATA]   Status: Connected");
        }
        Print("[DATA]");
        
        Print("[DATA] DATABASE 2: TEST INPUT (SSoT_input.db)");
        if(m_test_input_db == INVALID_HANDLE) {
            Print("[DATA]   ERROR: Database not available");
        } else {
            Print("[DATA]   Status: Connected");
        }
        Print("[DATA]");
        
        Print("[DATA] DATABASE 3: TEST OUTPUT (SSoT_output.db)");
        if(m_test_output_db == INVALID_HANDLE) {
            Print("[DATA]   ERROR: Database not available");
        } else {
            Print("[DATA]   Status: Connected");
        }
    } else {
        // Live Mode: Only main database
        Print("[DATA] DATABASE: MAIN (sourcedb.sqlite)");
        if(m_main_db == INVALID_HANDLE) {
            Print("[DATA]   ERROR: Database not available");
        } else {
            Print("[DATA]   Status: Connected");
        }
    }
    
    Print("[DATA] ================================================================");
    
    m_last_display_update = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Chart event function                                             |
//+------------------------------------------------------------------+
void CTestPanel::HandleChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    // Minimal chart event handling
    if(id == CHARTEVENT_OBJECT_CLICK) {
        Print("[PANEL] Chart event: ", sparam);
    }
}
