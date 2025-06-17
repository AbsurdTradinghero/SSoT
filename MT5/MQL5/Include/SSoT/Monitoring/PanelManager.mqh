//+------------------------------------------------------------------+
//| PanelManager.mqh - Core Panel Management                        |
//| Handles initialization, state management, and mode control      |
//+------------------------------------------------------------------+

#include <SSoT/DbUtils.mqh>
#include <SSoT/HashUtils.mqh>

//+------------------------------------------------------------------+
//| Panel Manager Base Class                                        |
//+------------------------------------------------------------------+
class CPanelManager
{
protected:
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

public:
    //--- Constructor/Destructor
    CPanelManager(void);
    ~CPanelManager(void);
    
    //--- Initialization
    bool Initialize(bool test_mode, int main_db_handle, int test_input_handle = INVALID_HANDLE, int test_output_handle = INVALID_HANDLE);
    void Shutdown(void);
    
    //--- Mode Control
    bool IsTestMode(void) { return m_test_mode_active; }
    void SetDisplayInterval(int seconds) { m_display_interval = seconds; }
    bool ShouldUpdateDisplay(void);
    
    //--- Database Access
    int GetMainDB(void) { return m_main_db; }
    int GetTestInputDB(void) { return m_test_input_db; }
    int GetTestOutputDB(void) { return m_test_output_db; }
    
    //--- Display Control
    bool IsDisplayEnabled(void) { return m_display_enabled; }
    void EnableDisplay(bool enable) { m_display_enabled = enable; }
    
    //--- Object Management
    string GetObjectPrefix(void) { return m_object_prefix; }
    bool IsPanelCreated(void) { return m_panel_created; }
    void SetPanelCreated(bool created) { m_panel_created = created; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPanelManager::CPanelManager(void)
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
CPanelManager::~CPanelManager(void)
{
    Shutdown();
}

//+------------------------------------------------------------------+
//| Initialize the panel manager                                     |
//+------------------------------------------------------------------+
bool CPanelManager::Initialize(bool test_mode, int main_db_handle, int test_input_handle, int test_output_handle)
{
    Print("[PANEL] PanelManager: Initializing...");
    
    m_test_mode_active = test_mode;
    m_main_db = main_db_handle;
    
    if(m_test_mode_active) {
        m_test_input_db = test_input_handle;
        m_test_output_db = test_output_handle;
        Print("[PANEL] PanelManager: Initialized in TEST MODE");
        Print("[PANEL] PanelManager: Monitoring 3 databases (Main, Test Input, Test Output)");
    } else {
        Print("[PANEL] PanelManager: Initialized in LIVE MODE");
        Print("[PANEL] PanelManager: Monitoring 1 database (Main only)");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Shutdown the panel manager                                       |
//+------------------------------------------------------------------+
void CPanelManager::Shutdown(void)
{
    Print("[PANEL] PanelManager: Shutting down...");
    m_display_enabled = false;
}

//+------------------------------------------------------------------+
//| Check if display should be updated                              |
//+------------------------------------------------------------------+
bool CPanelManager::ShouldUpdateDisplay(void)
{
    if(!m_display_enabled) return false;
    return (TimeCurrent() - m_last_display_update) >= m_display_interval;
}
