//+------------------------------------------------------------------+
//| TestPanel_Visual.mqh - Visual Chart Panel for Database Monitor  |
//| Displays database info directly on chart as visual panel        |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Visual Test Panel Class - Chart-based GUI                       |
//+------------------------------------------------------------------+
class CTestPanelVisual
{
private:
    // Panel configuration
    bool            m_test_mode;
    int             m_main_db_handle;
    int             m_test_input_handle;
    int             m_test_output_handle;
    
    // Visual elements
    string          m_panel_name;
    int             m_panel_x;
    int             m_panel_y;
    int             m_panel_width;
    int             m_panel_height;
    
    // Update control
    datetime        m_last_update;
    int             m_update_interval;
    
    // Chart object names
    string          m_bg_name;
    string          m_title_name;
    string          m_mode_name;
    string          m_db1_name;
    string          m_db2_name;
    string          m_db3_name;
    string          m_time_name;
    
public:
    // Constructor/Destructor
                    CTestPanelVisual();
                   ~CTestPanelVisual();
    
    // Core methods
    bool            Initialize(bool test_mode, int main_db_handle, int test_input_handle = INVALID_HANDLE, int test_output_handle = INVALID_HANDLE);
    void            DisplayDatabaseOverview(void);
    void            UpdatePanel(void);
    void            DestroyPanel(void);
    
private:
    // Helper methods
    bool            CreatePanelBackground(void);
    bool            CreatePanelLabels(void);
    void            UpdateDatabaseStatus(void);
    string          GetDatabaseStatus(int db_handle, string db_name);
    string          FormatDatabaseInfo(string db_name, int db_handle, int db_number);
    color           GetStatusColor(bool is_available);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTestPanelVisual::CTestPanelVisual()
{
    m_test_mode = false;
    m_main_db_handle = INVALID_HANDLE;
    m_test_input_handle = INVALID_HANDLE;
    m_test_output_handle = INVALID_HANDLE;
    
    m_panel_name = "SSoT_Panel_";
    m_panel_x = 20;
    m_panel_y = 30;
    m_panel_width = 350;
    m_panel_height = 200;
    
    m_last_update = 0;
    m_update_interval = 5; // Update every 5 seconds
    
    // Initialize object names
    m_bg_name = m_panel_name + "BG";
    m_title_name = m_panel_name + "Title";
    m_mode_name = m_panel_name + "Mode";
    m_db1_name = m_panel_name + "DB1";
    m_db2_name = m_panel_name + "DB2";
    m_db3_name = m_panel_name + "DB3";
    m_time_name = m_panel_name + "Time";
}

//+------------------------------------------------------------------+
//| Destructor                                                      |
//+------------------------------------------------------------------+
CTestPanelVisual::~CTestPanelVisual()
{
    DestroyPanel();
}

//+------------------------------------------------------------------+
//| Initialize panel                                                |
//+------------------------------------------------------------------+
bool CTestPanelVisual::Initialize(bool test_mode, int main_db_handle, int test_input_handle = INVALID_HANDLE, int test_output_handle = INVALID_HANDLE)
{
    Print("🎮 Visual TestPanel: Initializing Chart Panel...");
    
    m_test_mode = test_mode;
    m_main_db_handle = main_db_handle;
    m_test_input_handle = test_input_handle;
    m_test_output_handle = test_output_handle;
    
    // Create visual panel
    if(!CreatePanelBackground()) {
        Print("❌ Failed to create panel background");
        return false;
    }
    
    if(!CreatePanelLabels()) {
        Print("❌ Failed to create panel labels");
        return false;
    }
    
    Print("🎮 Visual TestPanel: Chart panel created successfully");
    Print(StringFormat("🎮 Visual TestPanel: Mode: %s", test_mode ? "TEST" : "LIVE"));
    
    // Initial update
    UpdatePanel();
    
    return true;
}

//+------------------------------------------------------------------+
//| Create panel background                                         |
//+------------------------------------------------------------------+
bool CTestPanelVisual::CreatePanelBackground(void)
{
    // Create background rectangle
    if(!ObjectCreate(0, m_bg_name, OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
        if(GetLastError() != ERR_OBJECT_ALREADY_EXISTS) {
            Print("❌ Failed to create panel background: ", GetLastError());
            return false;
        }
    }
    
    // Set background properties
    ObjectSetInteger(0, m_bg_name, OBJPROP_XDISTANCE, m_panel_x);
    ObjectSetInteger(0, m_bg_name, OBJPROP_YDISTANCE, m_panel_y);
    ObjectSetInteger(0, m_bg_name, OBJPROP_XSIZE, m_panel_width);
    ObjectSetInteger(0, m_bg_name, OBJPROP_YSIZE, m_panel_height);
    ObjectSetInteger(0, m_bg_name, OBJPROP_BGCOLOR, clrDarkSlateGray);
    ObjectSetInteger(0, m_bg_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, m_bg_name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, m_bg_name, OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, m_bg_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, m_bg_name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, m_bg_name, OBJPROP_SELECTABLE, false);
    
    return true;
}

//+------------------------------------------------------------------+
//| Create panel labels                                             |
//+------------------------------------------------------------------+
bool CTestPanelVisual::CreatePanelLabels(void)
{
    // Title label
    if(!ObjectCreate(0, m_title_name, OBJ_LABEL, 0, 0, 0)) {
        if(GetLastError() != ERR_OBJECT_ALREADY_EXISTS) return false;
    }
    ObjectSetInteger(0, m_title_name, OBJPROP_XDISTANCE, m_panel_x + 10);
    ObjectSetInteger(0, m_title_name, OBJPROP_YDISTANCE, m_panel_y + 10);
    ObjectSetInteger(0, m_title_name, OBJPROP_COLOR, clrYellow);
    ObjectSetInteger(0, m_title_name, OBJPROP_FONTSIZE, 10);
    ObjectSetString(0, m_title_name, OBJPROP_FONT, "Arial Bold");
    ObjectSetString(0, m_title_name, OBJPROP_TEXT, "📊 SSoT DATABASE MONITOR");
    ObjectSetInteger(0, m_title_name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, m_title_name, OBJPROP_SELECTABLE, false);
    
    // Mode label
    if(!ObjectCreate(0, m_mode_name, OBJ_LABEL, 0, 0, 0)) {
        if(GetLastError() != ERR_OBJECT_ALREADY_EXISTS) return false;
    }
    ObjectSetInteger(0, m_mode_name, OBJPROP_XDISTANCE, m_panel_x + 10);
    ObjectSetInteger(0, m_mode_name, OBJPROP_YDISTANCE, m_panel_y + 30);
    ObjectSetInteger(0, m_mode_name, OBJPROP_COLOR, m_test_mode ? clrLime : clrOrange);
    ObjectSetInteger(0, m_mode_name, OBJPROP_FONTSIZE, 9);
    ObjectSetString(0, m_mode_name, OBJPROP_FONT, "Arial");
    ObjectSetString(0, m_mode_name, OBJPROP_TEXT, m_test_mode ? "🧪 TEST MODE" : "📈 LIVE MODE");
    ObjectSetInteger(0, m_mode_name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, m_mode_name, OBJPROP_SELECTABLE, false);
    
    // Time label
    if(!ObjectCreate(0, m_time_name, OBJ_LABEL, 0, 0, 0)) {
        if(GetLastError() != ERR_OBJECT_ALREADY_EXISTS) return false;
    }
    ObjectSetInteger(0, m_time_name, OBJPROP_XDISTANCE, m_panel_x + 10);
    ObjectSetInteger(0, m_time_name, OBJPROP_YDISTANCE, m_panel_y + 50);
    ObjectSetInteger(0, m_time_name, OBJPROP_COLOR, clrSilver);
    ObjectSetInteger(0, m_time_name, OBJPROP_FONTSIZE, 8);
    ObjectSetString(0, m_time_name, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, m_time_name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, m_time_name, OBJPROP_SELECTABLE, false);
    
    // Database status labels
    if(!ObjectCreate(0, m_db1_name, OBJ_LABEL, 0, 0, 0)) {
        if(GetLastError() != ERR_OBJECT_ALREADY_EXISTS) return false;
    }
    ObjectSetInteger(0, m_db1_name, OBJPROP_XDISTANCE, m_panel_x + 10);
    ObjectSetInteger(0, m_db1_name, OBJPROP_YDISTANCE, m_panel_y + 75);
    ObjectSetInteger(0, m_db1_name, OBJPROP_FONTSIZE, 8);
    ObjectSetString(0, m_db1_name, OBJPROP_FONT, "Courier New");
    ObjectSetInteger(0, m_db1_name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, m_db1_name, OBJPROP_SELECTABLE, false);
    
    if(m_test_mode) {
        // DB2 label (test input)
        if(!ObjectCreate(0, m_db2_name, OBJ_LABEL, 0, 0, 0)) {
            if(GetLastError() != ERR_OBJECT_ALREADY_EXISTS) return false;
        }
        ObjectSetInteger(0, m_db2_name, OBJPROP_XDISTANCE, m_panel_x + 10);
        ObjectSetInteger(0, m_db2_name, OBJPROP_YDISTANCE, m_panel_y + 105);
        ObjectSetInteger(0, m_db2_name, OBJPROP_FONTSIZE, 8);
        ObjectSetString(0, m_db2_name, OBJPROP_FONT, "Courier New");
        ObjectSetInteger(0, m_db2_name, OBJPROP_HIDDEN, true);
        ObjectSetInteger(0, m_db2_name, OBJPROP_SELECTABLE, false);
        
        // DB3 label (test output)
        if(!ObjectCreate(0, m_db3_name, OBJ_LABEL, 0, 0, 0)) {
            if(GetLastError() != ERR_OBJECT_ALREADY_EXISTS) return false;
        }
        ObjectSetInteger(0, m_db3_name, OBJPROP_XDISTANCE, m_panel_x + 10);
        ObjectSetInteger(0, m_db3_name, OBJPROP_YDISTANCE, m_panel_y + 135);
        ObjectSetInteger(0, m_db3_name, OBJPROP_FONTSIZE, 8);
        ObjectSetString(0, m_db3_name, OBJPROP_FONT, "Courier New");
        ObjectSetInteger(0, m_db3_name, OBJPROP_HIDDEN, true);
        ObjectSetInteger(0, m_db3_name, OBJPROP_SELECTABLE, false);
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Display database overview (public interface)                   |
//+------------------------------------------------------------------+
void CTestPanelVisual::DisplayDatabaseOverview(void)
{
    UpdatePanel();
}

//+------------------------------------------------------------------+
//| Update panel content                                            |
//+------------------------------------------------------------------+
void CTestPanelVisual::UpdatePanel(void)
{
    datetime current_time = TimeCurrent();
    
    // Rate limiting - update every 5 seconds
    if(current_time - m_last_update < m_update_interval) {
        return;
    }
    
    m_last_update = current_time;
    
    // Update time
    ObjectSetString(0, m_time_name, OBJPROP_TEXT, "⏰ " + TimeToString(current_time, TIME_DATE|TIME_MINUTES));
    
    // Update database status
    UpdateDatabaseStatus();
    
    // Refresh chart
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Update database status information                              |
//+------------------------------------------------------------------+
void CTestPanelVisual::UpdateDatabaseStatus(void)
{
    if(m_test_mode) {
        // Test mode: Show all 3 databases
        string db1_text = FormatDatabaseInfo("MAIN", m_main_db_handle, 1);
        string db2_text = FormatDatabaseInfo("INPUT", m_test_input_handle, 2);
        string db3_text = FormatDatabaseInfo("OUTPUT", m_test_output_handle, 3);
        
        ObjectSetString(0, m_db1_name, OBJPROP_TEXT, db1_text);
        ObjectSetString(0, m_db2_name, OBJPROP_TEXT, db2_text);
        ObjectSetString(0, m_db3_name, OBJPROP_TEXT, db3_text);
        
        ObjectSetInteger(0, m_db1_name, OBJPROP_COLOR, GetStatusColor(m_main_db_handle != INVALID_HANDLE));
        ObjectSetInteger(0, m_db2_name, OBJPROP_COLOR, GetStatusColor(m_test_input_handle != INVALID_HANDLE));
        ObjectSetInteger(0, m_db3_name, OBJPROP_COLOR, GetStatusColor(m_test_output_handle != INVALID_HANDLE));
    } else {
        // Live mode: Show only main database
        string db1_text = FormatDatabaseInfo("MAIN", m_main_db_handle, 1);
        ObjectSetString(0, m_db1_name, OBJPROP_TEXT, db1_text);
        ObjectSetInteger(0, m_db1_name, OBJPROP_COLOR, GetStatusColor(m_main_db_handle != INVALID_HANDLE));
        
        // Hide test mode labels
        ObjectSetString(0, m_db2_name, OBJPROP_TEXT, "");
        ObjectSetString(0, m_db3_name, OBJPROP_TEXT, "");
    }
}

//+------------------------------------------------------------------+
//| Format database information text                                |
//+------------------------------------------------------------------+
string CTestPanelVisual::FormatDatabaseInfo(string db_name, int db_handle, int db_number)
{
    string status_icon = (db_handle != INVALID_HANDLE) ? "✅" : "❌";
    string status_text = (db_handle != INVALID_HANDLE) ? "Connected" : "Not Available";
    
    return StringFormat("DB%d %s: %s %s", db_number, db_name, status_icon, status_text);
}

//+------------------------------------------------------------------+
//| Get status color based on availability                         |
//+------------------------------------------------------------------+
color CTestPanelVisual::GetStatusColor(bool is_available)
{
    return is_available ? clrLime : clrRed;
}

//+------------------------------------------------------------------+
//| Destroy panel and clean up objects                             |
//+------------------------------------------------------------------+
void CTestPanelVisual::DestroyPanel(void)
{
    ObjectDelete(0, m_bg_name);
    ObjectDelete(0, m_title_name);
    ObjectDelete(0, m_mode_name);
    ObjectDelete(0, m_time_name);
    ObjectDelete(0, m_db1_name);
    ObjectDelete(0, m_db2_name);
    ObjectDelete(0, m_db3_name);
    
    ChartRedraw(0);
}
