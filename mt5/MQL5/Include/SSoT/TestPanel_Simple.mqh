//+------------------------------------------------------------------+
//| TestPanel_Simple.mqh - SSoT Test Monitor with Visual Panel      |
//| Phase 1: Display databases according to mode with clipboard     |
//+------------------------------------------------------------------+

#include <SSoT/DbUtils.mqh>  // was <DbUtils.mqh>
#include <SSoT/HashUtils.mqh> // was <HashUtils.mqh>

// Windows API imports for clipboard functionality
#import "shell32.dll"
int ShellExecuteW(int hwnd, string lpOperation, string lpFile, string lpParameters, string lpDirectory, int nShowCmd);
#import

#define SW_HIDE 0

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
      // Display settings
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
    
    //--- Display Functions - Core Phase 1 Functionality
    void DisplayDatabaseOverview(void);
    void DisplayAllCandleData(int db_handle, string db_name);
    void DisplayDBInfo(int db_handle, string db_name);
    void DisplayAssetData(int db_handle, string table_name, string symbol);    //--- Panel Display Enhancements
    void CreateDatabaseInfoDisplay(void);   // New: show DBInfo on chart
    void CreateCandleCountDisplay(void);    // New: show AllCandleData counts on chart
    void CreateFullDatabaseDisplay(void);   // Full database display with all info
    
    //--- Update Functions    void SetDisplayInterval(int seconds) { m_display_interval = seconds; }
    bool ShouldUpdateDisplay(void);
    void UpdateDisplay(void);    //--- Visual Panel Functions
    bool CreateVisualPanel(void);
    void UpdateVisualPanel(void);
    void CleanupVisualPanel(void);
    void ForceCleanupAllSSoTObjects(void);  // Emergency cleanup for all SSoT objects    //--- Clipboard Functions
    bool CopyToClipboard(void);
    bool CopyExpertLogToClipboard(void);  // New: Copy Expert tab logs to clipboard
    string GenerateReportText(void);
    bool CopyTextToClipboard(string text);
    void HandleChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
      //--- Log Buffer Functions (temporarily disabled)
    // void AddLogEntry(string message);       // Add message to internal log buffer
    // void LogPrint(string message);          // Replace Print() calls with this to capture output
    // string GetLogBuffer(void);              // Get all log entries as formatted string
    // void ClearLogBuffer(void);              // Clear the log buffer
    
    //--- Helper Functions
    string TimeframeToString(int timeframe);
    string GetDatabaseInfo(int db_handle, string db_name);
    string GetCandleDataInfo(int db_handle, string db_name);
    string GetDetailedBreakdown(int db_handle, string db_name);
    string GetComprehensiveBreakdown(int db_handle, string db_name);// New method for comprehensive breakdown

private:
    //--- Visual Panel Helper Methods
    void CreateDatabaseStatusDisplay(void);
    void CreateModeDisplay(void);
    void CreateCopyButton(void);
    void CreateExpertLogButton(void);  // New: Copy Expert tab logs to clipboard
    void CreateProgressDisplay(void);
    
    //--- Enhanced Database Display Methods  
    void CreatePanelHeader(int y_pos);
    void CreateDatabaseColumn(string title, int db_handle, string db_name, int x_pos, int y_pos, color header_color);
    void CreateColumnLine(string text, int x_pos, int y_pos, color text_color, bool bold = false);
    void ParseDatabaseInfo(int db_handle, string db_name, string &info_lines[]);
    void ClearDatabaseDisplayObjects(void);
      //--- Legacy methods (for cleanup)
    void CreateDatabaseSection(string title, int y_pos, color header_color);
    void CreateDatabaseDetails(string details, int y_pos);
    int CountLines(string text);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CTestPanel::CTestPanel(void)
{
    m_object_prefix = "SSoT_";
    m_main_db = INVALID_HANDLE;
    m_test_input_db = INVALID_HANDLE;    m_test_output_db = INVALID_HANDLE;
    m_test_mode_active = false;
    m_display_enabled = true;
    m_last_display_update = 0;
    m_display_interval = 30; // Default 30 seconds
    m_panel_created = false;
}
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CTestPanel::~CTestPanel(void)
{
    CleanupVisualPanel();
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
    
    // Create visual panel    if(!CreateVisualPanel()) {
        Print("[WARN] Visual panel creation failed, continuing with console only");
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
//| Display comprehensive database overview - CORE PHASE 1 FEATURE  |
//+------------------------------------------------------------------+
void CTestPanel::DisplayDatabaseOverview(void)
{
    if(!m_display_enabled) return;    Print("[DATA] ================================================================");
    Print("[DATA] SSoT TEST PANEL v4.06 - DATABASE MONITOR");
    Print("[DATA] ================================================================");
    Print("[DATA] Time: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
    Print("[DATA] Mode: " + (m_test_mode_active ? "[TEST] TEST MODE" : "[LIVE] LIVE MODE"));
    Print("[DATA]");
    
    if(m_test_mode_active) {
        // Test Mode: Display all three databases        Print("[DATA] DATABASE 1: MAIN (sourcedb.sqlite)");
        DisplayDBInfo(m_main_db, "sourcedb.sqlite");
        DisplayAllCandleData(m_main_db, "Main Database");
        Print("[DATA]");
        
        Print("[DATA] DATABASE 2: TEST INPUT (SSoT_input.db)");
        DisplayDBInfo(m_test_input_db, "SSoT_input.db");
        DisplayAllCandleData(m_test_input_db, "Test Input Database");
        Print("[DATA]");
        
        Print("[DATA] DATABASE 3: TEST OUTPUT (SSoT_output.db)");
        DisplayDBInfo(m_test_output_db, "SSoT_output.db");
        DisplayAllCandleData(m_test_output_db, "Test Output Database");
    } else {
        // Live Mode: Only main database
        Print("[DATA] DATABASE: MAIN (sourcedb.sqlite)");
        DisplayDBInfo(m_main_db, "sourcedb.sqlite");
        DisplayAllCandleData(m_main_db, "Live Database");    }
    
    Print("[DATA] ================================================================");
    
    // Update visual panel
    UpdateVisualPanel();
    
    m_last_display_update = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Display database server information - DBInfo                     |
//+------------------------------------------------------------------+
void CTestPanel::DisplayDBInfo(int db_handle, string db_name)
{    if(db_handle == INVALID_HANDLE) {
        Print("[DATA]   ERROR: Database not available: " + db_name);
        return;
    }
    
    Print("[DATA]   DBInfo:");
    Print("[DATA]      Server: SQLite Local Database");
    Print("[DATA]      Filename: " + db_name);
    
    // Timezone information
    MqlDateTime dt;
    TimeCurrent(dt);
    int gmt_offset = (int)((TimeCurrent() - TimeGMT()) / 3600);
    string timezone = StringFormat("GMT%s%d", (gmt_offset >= 0 ? "+" : ""), gmt_offset);    Print("[DATA]      Timezone: " + timezone);
    Print("[DATA]      Local Time: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
}

//+------------------------------------------------------------------+
//| Display all candle data information - AllCandleData              |
//+------------------------------------------------------------------+
void CTestPanel::DisplayAllCandleData(int db_handle, string db_name)
{    if(db_handle == INVALID_HANDLE) {
        Print("[DATA]   ERROR: Database not available for candle data");
        return;
    }
    
    Print("[DATA]   AllCandleData:");
    
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
        Print("[DATA]      INFO: No candle data tables found");
        return;
    }
    
    Print("[DATA]      Table: " + active_table);
    
    // Get unique assets (symbols)
    string assets_query = StringFormat("SELECT DISTINCT symbol FROM %s ORDER BY symbol", active_table);
    int request = DatabasePrepare(db_handle, assets_query);
    
    if(request == INVALID_HANDLE) {
        Print("[DATA]      ERROR: Failed to query assets");
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
    
    Print("[DATA]      ASSETS: Assets in DB: " + IntegerToString(ArraySize(assets)));
    
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
        Print("[DATA]      TIMEFRAMES: Timeframes: " + timeframes_str);
    }
    
    // Get total entries
    string total_query = StringFormat("SELECT COUNT(*) FROM %s", active_table);
    request = DatabasePrepare(db_handle, total_query);
    if(request != INVALID_HANDLE) {
        if(DatabaseRead(request)) {
            long total_entries = 0;
            DatabaseColumnLong(request, 0, total_entries);
            Print("[DATA]      [DATA] Total Entries: " + IntegerToString(total_entries));
        }
        DatabaseFinalize(request);
    }
    
    // Overall candle counts by timeframe
    string tf_count_str = "";
    string tf_query2 = StringFormat("SELECT timeframe, COUNT(*) FROM %s GROUP BY timeframe ORDER BY timeframe", active_table);
    int req2 = DatabasePrepare(db_handle, tf_query2);
    if(req2 != INVALID_HANDLE) {
        while(DatabaseRead(req2)) {
            long tf=0, cnt=0;
            DatabaseColumnLong(req2, 0, tf);
            DatabaseColumnLong(req2, 1, cnt);
            if(tf_count_str != "") tf_count_str += ", ";
            tf_count_str += TimeframeToString((int)tf) + ": " + IntegerToString(cnt);
        }
        DatabaseFinalize(req2);
        Print("[DATA]      Candle Counts by Timeframe: " + tf_count_str);
    }

    // Display entries organized by timeframes for each asset
    for(int i = 0; i < ArraySize(assets); i++) {
        DisplayAssetData(db_handle, active_table, assets[i]);
    }
}

//+------------------------------------------------------------------+
//| Display data for specific asset - Entries by timeframe/asset     |
//+------------------------------------------------------------------+
void CTestPanel::DisplayAssetData(int db_handle, string table_name, string symbol)
{
    Print("[DATA]      ASSET: Asset: " + symbol);
    
    // Get timeframes and entry counts for this symbol
    string tf_query = StringFormat(
        "SELECT timeframe, COUNT(*) as entries FROM %s WHERE symbol='%s' GROUP BY timeframe ORDER BY timeframe", 
        table_name, symbol);
    
    int request = DatabasePrepare(db_handle, tf_query);
    
    if(request == INVALID_HANDLE) {
        Print("[DATA]         ERROR: Failed to query timeframes for " + symbol);
        return;
    }
    
    while(DatabaseRead(request)) {
        long timeframe = 0, entries = 0;
        DatabaseColumnLong(request, 0, timeframe);
        DatabaseColumnLong(request, 1, entries);
        
        string tf_string = TimeframeToString((int)timeframe);
        Print("[DATA]         [DATA] " + tf_string + ": " + IntegerToString(entries) + " entries");
    }
    
    DatabaseFinalize(request);
}

//+------------------------------------------------------------------+
//| Convert timeframe number to string                               |
//+------------------------------------------------------------------+
string CTestPanel::TimeframeToString(int timeframe)
{
    // Handle MT5 period constants
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
    }
    
    // Handle database minute values (common in stored data)
    if(timeframe == 1) return "M1";
    if(timeframe == 5) return "M5";
    if(timeframe == 15) return "M15";
    if(timeframe == 30) return "M30";
    if(timeframe == 60) return "H1";
    if(timeframe == 240) return "H4";
    if(timeframe == 1440) return "D1";
    if(timeframe == 10080) return "W1";
    if(timeframe == 43200) return "MN1";
    
    // Fallback for unknown values
    return StringFormat("TF%d", timeframe);
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
    if(ShouldUpdateDisplay()) {
        DisplayDatabaseOverview();
    }
}

//+------------------------------------------------------------------+
//| Create Visual Panel                                             |
//+------------------------------------------------------------------+
bool CTestPanel::CreateVisualPanel(void)
{
    if(m_panel_created) return true;
    
    // Create larger background panel for better readability
    string panel_name = m_object_prefix + "Panel";
    if(ObjectCreate(0, panel_name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, panel_name, OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, panel_name, OBJPROP_YDISTANCE, 20);        ObjectSetInteger(0, panel_name, OBJPROP_XSIZE, 1200); // Even wider panel for better readability
        ObjectSetInteger(0, panel_name, OBJPROP_YSIZE, 450);  // Same height
        ObjectSetInteger(0, panel_name, OBJPROP_BGCOLOR, C'20,20,30');  // Dark background
        ObjectSetInteger(0, panel_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, panel_name, OBJPROP_COLOR, C'100,150,200'); // Blue border
        ObjectSetInteger(0, panel_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, panel_name, OBJPROP_BACK, false);
        ObjectSetInteger(0, panel_name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, panel_name, OBJPROP_HIDDEN, false);
        
        m_panel_created = true;
        Print("[OK] Enhanced visual panel created successfully");
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Update Visual Panel                                             |
//+------------------------------------------------------------------+
void CTestPanel::UpdateVisualPanel(void)
{
    if(!m_panel_created) return;
    
    // Update mode display
    CreateModeDisplay();    // Show combined database info and candle counts on chart
    CreateFullDatabaseDisplay();
    
    // Create copy button
    CreateCopyButton();
    
    // Create expert log button
    CreateExpertLogButton();
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Display full database info in organized layout                  |
//+------------------------------------------------------------------+
void CTestPanel::CreateFullDatabaseDisplay(void)
{
    // Clear any existing database display objects first
    ClearDatabaseDisplayObjects();    int start_y = 70;  // Safe position well below header  
    int column_width = 380;  // Better spacing for 1200px panel (1200/3 = 400, minus margins)
    int line_height = 18;
    
    // Create header
    CreatePanelHeader(start_y);
    start_y += 40;  // More space below header
      if(m_test_mode_active) {
        // Three-column layout for test mode with better spacing
        int col1_x = 40;   // First column
        int col2_x = 420;  // Second column (40 + 380)
        int col3_x = 800;  // Third column (40 + 380*2)
        
        Print("[PANEL] Creating columns at x positions: " + IntegerToString(col1_x) + ", " + IntegerToString(col2_x) + ", " + IntegerToString(col3_x));
        
        CreateDatabaseColumn("MAIN DATABASE", m_main_db, "sourcedb.sqlite", 
                           col1_x, start_y, clrLimeGreen);
        CreateDatabaseColumn("INPUT DATABASE", m_test_input_db, "SSoT_input.db", 
                           col2_x, start_y, clrGold);
        CreateDatabaseColumn("OUTPUT DATABASE", m_test_output_db, "SSoT_output.db", 
                           col3_x, start_y, clrOrange);
    } else {
        // Single column layout for live mode
        CreateDatabaseColumn("LIVE DATABASE", m_main_db, "sourcedb.sqlite", 
                           40, start_y, clrLimeGreen);
    }      // Create copy buttons at bottom
    CreateCopyButton();
    CreateExpertLogButton();
    
    // Force chart redraw to ensure objects are visible
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Create panel header with title and status                       |
//+------------------------------------------------------------------+
void CTestPanel::CreatePanelHeader(int y_pos)
{
    // Title
    string title_obj = m_object_prefix + "Title";
    if(ObjectFind(0, title_obj) < 0)
        ObjectCreate(0, title_obj, OBJ_LABEL, 0, 0, 0);
    
    ObjectSetInteger(0, title_obj, OBJPROP_XDISTANCE, 30);
    ObjectSetInteger(0, title_obj, OBJPROP_YDISTANCE, y_pos);
    ObjectSetInteger(0, title_obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, title_obj, OBJPROP_FONTSIZE, 12);
    ObjectSetInteger(0, title_obj, OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, title_obj, OBJPROP_FONT, "Arial Bold");
    ObjectSetString(0, title_obj, OBJPROP_TEXT, "SSoT Database Monitor");
    ObjectSetInteger(0, title_obj, OBJPROP_BACK, false);
    ObjectSetInteger(0, title_obj, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, title_obj, OBJPROP_HIDDEN, false);    // Mode and timestamp
    string status_obj = m_object_prefix + "Status";
    if(ObjectFind(0, status_obj) < 0)
        ObjectCreate(0, status_obj, OBJ_LABEL, 0, 0, 0);
    
    string status_text = "Mode: " + (m_test_mode_active ? "TEST" : "LIVE") + 
                        " | Updated: " + TimeToString(TimeCurrent(), TIME_SECONDS);
    
    ObjectSetInteger(0, status_obj, OBJPROP_XDISTANCE, 350);
    ObjectSetInteger(0, status_obj, OBJPROP_YDISTANCE, y_pos + 3);
    ObjectSetInteger(0, status_obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, status_obj, OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, status_obj, OBJPROP_COLOR, clrSilver);
    ObjectSetString(0, status_obj, OBJPROP_FONT, "Arial");
    ObjectSetString(0, status_obj, OBJPROP_TEXT, status_text);
    ObjectSetInteger(0, status_obj, OBJPROP_BACK, false);
    ObjectSetInteger(0, status_obj, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, status_obj, OBJPROP_HIDDEN, false);
}

//+------------------------------------------------------------------+
//| Create database column with organized information               |
//+------------------------------------------------------------------+
void CTestPanel::CreateDatabaseColumn(string title, int db_handle, string db_name, 
                                     int x_pos, int y_pos, color header_color)
{
    Print("[PANEL] Creating database column: " + title + " at position (" + IntegerToString(x_pos) + "," + IntegerToString(y_pos) + ")");
    
    // Validate position is within panel bounds
    if(x_pos < 20 || x_pos > 1000 || y_pos < 50 || y_pos > 400) {
        Print("[PANEL] ERROR: Invalid position for column " + title + " - skipping");
        return;
    }
    
    int line_height = 16;
    int current_y = y_pos;
      // Column header
    string header_obj = m_object_prefix + "Header_" + IntegerToString(x_pos);
    if(ObjectFind(0, header_obj) < 0)
        ObjectCreate(0, header_obj, OBJ_LABEL, 0, 0, 0);
    
    // Validate header object was created
    if(ObjectFind(0, header_obj) >= 0) {
        ObjectSetInteger(0, header_obj, OBJPROP_XDISTANCE, x_pos);
        ObjectSetInteger(0, header_obj, OBJPROP_YDISTANCE, current_y);
        ObjectSetInteger(0, header_obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, header_obj, OBJPROP_FONTSIZE, 10);
        ObjectSetInteger(0, header_obj, OBJPROP_COLOR, header_color);
        ObjectSetString(0, header_obj, OBJPROP_FONT, "Arial Bold");
        ObjectSetString(0, header_obj, OBJPROP_TEXT, title);
        ObjectSetInteger(0, header_obj, OBJPROP_BACK, false);
        ObjectSetInteger(0, header_obj, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, header_obj, OBJPROP_HIDDEN, false);        Print("[PANEL] Created header: " + header_obj + " with title: " + title);
    } else {
        Print("[PANEL] ERROR: Failed to create header object: " + header_obj);
    }
    
    current_y += 25;
    
    // Connection status
    string status_text = (db_handle != INVALID_HANDLE) ? "Status: CONNECTED" : "Status: DISCONNECTED";
    color status_color = (db_handle != INVALID_HANDLE) ? clrLime : clrRed;
    
    CreateColumnLine(status_text, x_pos, current_y, status_color, true);
    current_y += line_height;
    
    if(db_handle != INVALID_HANDLE) {
        // Database information
        string info_lines[];
        ParseDatabaseInfo(db_handle, db_name, info_lines);
        
        for(int i = 0; i < ArraySize(info_lines); i++) {
            if(StringLen(info_lines[i]) > 0) {
                CreateColumnLine(info_lines[i], x_pos, current_y, clrSilver, false);
                current_y += line_height;
            }
        }
    } else {
        CreateColumnLine("Database not available", x_pos, current_y, clrGray, false);
    }
}

//+------------------------------------------------------------------+
//| Create a single line in database column                         |
//+------------------------------------------------------------------+
void CTestPanel::CreateColumnLine(string text, int x_pos, int y_pos, color text_color, bool bold = false)
{
    string line_obj = m_object_prefix + "Line_" + IntegerToString(x_pos) + "_" + IntegerToString(y_pos);
    if(ObjectFind(0, line_obj) < 0)
        ObjectCreate(0, line_obj, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, line_obj, OBJPROP_XDISTANCE, x_pos + 15);  // More offset from edge
    ObjectSetInteger(0, line_obj, OBJPROP_YDISTANCE, y_pos);
    ObjectSetInteger(0, line_obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, line_obj, OBJPROP_FONTSIZE, 9);  // Slightly larger font
    ObjectSetInteger(0, line_obj, OBJPROP_COLOR, text_color);
    ObjectSetString(0, line_obj, OBJPROP_FONT, bold ? "Arial Bold" : "Arial");  // Use Arial for better visibility
    ObjectSetString(0, line_obj, OBJPROP_TEXT, text);
    ObjectSetInteger(0, line_obj, OBJPROP_BACK, false);
    ObjectSetInteger(0, line_obj, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, line_obj, OBJPROP_HIDDEN, false);
}

//+------------------------------------------------------------------+
//| Parse database info into organized lines                        |
//+------------------------------------------------------------------+
void CTestPanel::ParseDatabaseInfo(int db_handle, string db_name, string &info_lines[])
{
    ArrayResize(info_lines, 0);
    
    if(db_handle == INVALID_HANDLE) {
        ArrayResize(info_lines, 1);
        info_lines[0] = "No data available";
        return;
    }
    
    // Get database info
    string db_info = GetDatabaseInfo(db_handle, db_name);
    string candle_info = GetCandleDataInfo(db_handle, db_name);
    
    // Parse and format the information
    string combined_info = db_info + "\n" + candle_info;
    
    // Split into lines and clean up
    string temp_lines[];
    int line_count = StringSplit(combined_info, '\n', temp_lines);
    
    ArrayResize(info_lines, 0);
    for(int i = 0; i < line_count; i++) {
        string line = temp_lines[i];
        StringTrimLeft(line);
        StringTrimRight(line);
        
        if(StringLen(line) > 0 && line != "-") {
            // Format lines for better readability
            if(StringFind(line, "- ") == 0) {
                line = StringSubstr(line, 2); // Remove "- " prefix
            }
            
            // Truncate very long lines
            if(StringLen(line) > 35) {
                line = StringSubstr(line, 0, 32) + "...";
            }
            
            int new_size = ArraySize(info_lines) + 1;
            ArrayResize(info_lines, new_size);
            info_lines[new_size - 1] = line;
        }
    }
}

//+------------------------------------------------------------------+
//| Clear all database display objects                              |
//+------------------------------------------------------------------+
void CTestPanel::ClearDatabaseDisplayObjects(void)
{
    Print("[CLEANUP] Starting ClearDatabaseDisplayObjects...");
    
    // Clear header objects for the three columns at actual positions
    int header_positions[] = {40, 420, 800};  // Actual positions used in CreateDatabaseColumn
    for(int i = 0; i < ArraySize(header_positions); i++) {
        ObjectDelete(0, m_object_prefix + "Header_" + IntegerToString(header_positions[i]));
    }
    
    // Clear title and status
    ObjectDelete(0, m_object_prefix + "Title");
    ObjectDelete(0, m_object_prefix + "Status");
    ObjectDelete(0, m_object_prefix + "FullDBInfo");
    
    // Clear all line objects that were created by CreateColumnLine
    for(int i = 0; i < ArraySize(header_positions); i++) {
        int x_pos = header_positions[i];
        for(int y_pos = 70; y_pos <= 450; y_pos += 1) {  // Cover full range
            string line_obj = m_object_prefix + "Line_" + IntegerToString(x_pos) + "_" + IntegerToString(y_pos);
            ObjectDelete(0, line_obj);
        }
    }
    
    // Force chart redraw
    ChartRedraw(0);
    
    Print("[CLEANUP] ClearDatabaseDisplayObjects completed");
}

//+------------------------------------------------------------------+
//| Display detailed database info visually                         |
//+------------------------------------------------------------------+
void CTestPanel::CreateDatabaseInfoDisplay(void)
{
    int y = 50;
    int count = m_test_mode_active ? 3 : 1;
    for(int i=0; i<count; i++) {
        int db = (i==0?m_main_db:(i==1?m_test_input_db:m_test_output_db));
        string name = (i==0?"sourcedb.sqlite":(i==1?"SSoT_input.db":"SSoT_output.db"));
        string info = GetDatabaseInfo(db, name);
        string obj = m_object_prefix + "DBInfo" + IntegerToString(i+1);
        if(ObjectFind(0, obj)<0)
            ObjectCreate(0, obj, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, obj, OBJPROP_XDISTANCE, 20);
        ObjectSetInteger(0, obj, OBJPROP_YDISTANCE, y + i*60);
        ObjectSetInteger(0, obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, obj, OBJPROP_FONTSIZE, 8);
        ObjectSetInteger(0, obj, OBJPROP_COLOR, clrSilver);
        ObjectSetString(0, obj, OBJPROP_TEXT, info);
        ObjectSetInteger(0, obj, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, obj, OBJPROP_BACK, false);
        ObjectSetInteger(0, obj, OBJPROP_HIDDEN, false);
    }
}

//+------------------------------------------------------------------+
//| Display candle counts visually                                   |
//+------------------------------------------------------------------+
void CTestPanel::CreateCandleCountDisplay(void)
{
    int y = 70;
    int count = m_test_mode_active ? 3 : 1;
    for(int i=0; i<count; i++) {
        int db = (i==0?m_main_db:(i==1?m_test_input_db:m_test_output_db));
        string name = (i==0?"sourcedb.sqlite":(i==1?"SSoT_input.db":"SSoT_output.db"));
        string counts = GetCandleDataInfo(db, name);
        string obj = m_object_prefix + "DBCandles" + IntegerToString(i+1);
        if(ObjectFind(0, obj)<0)
            ObjectCreate(0, obj, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, obj, OBJPROP_XDISTANCE, 20);
        ObjectSetInteger(0, obj, OBJPROP_YDISTANCE, y + i*60 + 20);
        ObjectSetInteger(0, obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, obj, OBJPROP_FONTSIZE, 8);
        ObjectSetInteger(0, obj, OBJPROP_COLOR, clrWhite);
        ObjectSetString(0, obj, OBJPROP_TEXT, counts);
        ObjectSetInteger(0, obj, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, obj, OBJPROP_BACK, false);
        ObjectSetInteger(0, obj, OBJPROP_HIDDEN, false);
    }
}

//+------------------------------------------------------------------+
//| Create Mode Display                                             |
//+------------------------------------------------------------------+
void CTestPanel::CreateModeDisplay(void)
{
    string mode_name = m_object_prefix + "Mode";
    
    if(ObjectFind(0, mode_name) < 0)
        ObjectCreate(0, mode_name, OBJ_LABEL, 0, 0, 0);
    
    string mode_text = "SSoT Monitor v4.06 - " + (m_test_mode_active ? "[TEST MODE]" : "[LIVE MODE");
    
    ObjectSetInteger(0, mode_name, OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, mode_name, OBJPROP_YDISTANCE, 45);
    ObjectSetInteger(0, mode_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, mode_name, OBJPROP_COLOR, m_test_mode_active ? clrLime : clrOrange);
    ObjectSetInteger(0, mode_name, OBJPROP_FONTSIZE, 10);
    ObjectSetString(0, mode_name, OBJPROP_FONT, "Arial Bold");
    ObjectSetString(0, mode_name, OBJPROP_TEXT, mode_text);
    ObjectSetInteger(0, mode_name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, mode_name, OBJPROP_HIDDEN, false);
    ObjectSetInteger(0, mode_name, OBJPROP_BACK, false);
}

//+------------------------------------------------------------------+
//| Create Database Status Display                                  |
//+------------------------------------------------------------------+
void CTestPanel::CreateDatabaseStatusDisplay(void)
{
    int y_offset = 70;
    if(m_test_mode_active)
    {
        // Test mode: display three databases
        string db_names[] = {"Main DB","Test Input","Test Output"};
        int db_handles[] = {m_main_db,m_test_input_db,m_test_output_db};
        for(int idx=0; idx<3; idx++)
        {
            string label = m_object_prefix + "DB" + IntegerToString(idx+1);
            if(ObjectFind(0,label) < 0)
                ObjectCreate(0,label,OBJ_LABEL,0,0,0);
            string icon = (db_handles[idx]!=INVALID_HANDLE)?"[OK]":"[ERR]";
            string text = db_names[idx] + ": " + icon;
            ObjectSetInteger(0,label,OBJPROP_XDISTANCE,30);
            ObjectSetInteger(0,label,OBJPROP_YDISTANCE,y_offset + idx*20);
            ObjectSetInteger(0,label,OBJPROP_CORNER,CORNER_LEFT_UPPER);
            ObjectSetInteger(0,label,OBJPROP_COLOR,(db_handles[idx]!=INVALID_HANDLE)?clrLime:clrRed);
            ObjectSetInteger(0,label,OBJPROP_FONTSIZE,9);
            ObjectSetString(0,label,OBJPROP_FONT,"Consolas");
            ObjectSetString(0,label,OBJPROP_TEXT,text);
            ObjectSetInteger(0,label,OBJPROP_SELECTABLE,false);
            ObjectSetInteger(0,label,OBJPROP_BACK,false);
            ObjectSetInteger(0,label,OBJPROP_HIDDEN, false);
        }
    }
    else
    {
        // Live mode: only main database
        string label = m_object_prefix + "DB1";
        if(ObjectFind(0,label) < 0)
            ObjectCreate(0,label,OBJ_LABEL,0,0,0);
        string icon = (m_main_db!=INVALID_HANDLE)?"[OK]":"[ERR]";
        string text = "Main DB: " + icon;
        ObjectSetInteger(0,label,OBJPROP_XDISTANCE,30);
        ObjectSetInteger(0,label,OBJPROP_YDISTANCE,y_offset);
        ObjectSetInteger(0,label,OBJPROP_CORNER,CORNER_LEFT_UPPER);
        ObjectSetInteger(0,label,OBJPROP_COLOR,(m_main_db!=INVALID_HANDLE)?clrLime:clrRed);
        ObjectSetInteger(0,label,OBJPROP_FONTSIZE,9);
        ObjectSetString(0,label,OBJPROP_FONT,"Consolas");
        ObjectSetString(0,label,OBJPROP_TEXT,text);
        ObjectSetInteger(0,label,OBJPROP_SELECTABLE,false);
        ObjectSetInteger(0,label,OBJPROP_BACK,false);
        ObjectSetInteger(0,label,OBJPROP_HIDDEN, false);
    }
}

//+------------------------------------------------------------------+
//| Create Timestamp Display                                        |
//+------------------------------------------------------------------+
//| Create Copy Button                                              |
//+------------------------------------------------------------------+
void CTestPanel::CreateCopyButton(void)
{
    string button_name = m_object_prefix + "CopyButton";
    
    if(ObjectFind(0, button_name) < 0)
        ObjectCreate(0, button_name, OBJ_BUTTON, 0, 0, 0);
    
    ObjectSetString(0, button_name, OBJPROP_TEXT, "[COPY] Copy to Clipboard");
    ObjectSetString(0, button_name, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, button_name, OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, button_name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, button_name, OBJPROP_BGCOLOR, clrDarkGreen);
    ObjectSetInteger(0, button_name, OBJPROP_BORDER_COLOR, clrWhite);
    ObjectSetInteger(0, button_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, button_name, OBJPROP_XDISTANCE, 510);  // More centered for 1200px panel
    ObjectSetInteger(0, button_name, OBJPROP_YDISTANCE, 400);  // Bottom of panel
    ObjectSetInteger(0, button_name, OBJPROP_XSIZE, 180);      // Wider button
    ObjectSetInteger(0, button_name, OBJPROP_YSIZE, 30);       // Taller button
    ObjectSetInteger(0, button_name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, button_name, OBJPROP_HIDDEN, false);
    ObjectSetInteger(0, button_name, OBJPROP_BACK, false);
}

//+------------------------------------------------------------------+
//| Create Expert Log Copy Button                                   |
//+------------------------------------------------------------------+
void CTestPanel::CreateExpertLogButton(void)
{
    string button_name = m_object_prefix + "ExpertLogButton";
    
    if(ObjectFind(0, button_name) < 0)
        ObjectCreate(0, button_name, OBJ_BUTTON, 0, 0, 0);
    
    ObjectSetString(0, button_name, OBJPROP_TEXT, "[LOG] Copy Expert Log");
    ObjectSetString(0, button_name, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, button_name, OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, button_name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, button_name, OBJPROP_BGCOLOR, clrDarkBlue);  // Different color from copy button
    ObjectSetInteger(0, button_name, OBJPROP_BORDER_COLOR, clrWhite);
    ObjectSetInteger(0, button_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, button_name, OBJPROP_XDISTANCE, 710);  // Next to the main copy button
    ObjectSetInteger(0, button_name, OBJPROP_YDISTANCE, 400);  // Same level as copy button
    ObjectSetInteger(0, button_name, OBJPROP_XSIZE, 180);      // Same size as copy button
    ObjectSetInteger(0, button_name, OBJPROP_YSIZE, 30);       // Same height as copy button
    ObjectSetInteger(0, button_name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, button_name, OBJPROP_HIDDEN, false);
    ObjectSetInteger(0, button_name, OBJPROP_BACK, false);
}

//+------------------------------------------------------------------+
//| Create Progress Display                                          |
//+------------------------------------------------------------------+
void CTestPanel::CreateProgressDisplay(void)
{
    int y_offset = 70 + (m_test_mode_active ? 3 * 20 : 1 * 20) + 10; // position below DB labels
    string obj_name = m_object_prefix + "Progress";
    if(ObjectFind(0, obj_name) < 0)
        ObjectCreate(0, obj_name, OBJ_LABEL, 0, 0, 0);
    
    string progress_text = m_test_mode_active ? "Progress: 0%" : ""; // placeholder, updated later
    ObjectSetInteger(0, obj_name, OBJPROP_XDISTANCE, 30);
    ObjectSetInteger(0, obj_name, OBJPROP_YDISTANCE, y_offset);
    ObjectSetInteger(0, obj_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, obj_name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, obj_name, OBJPROP_FONTSIZE, 9);
    ObjectSetString(0, obj_name, OBJPROP_FONT, "Consolas");
    ObjectSetString(0, obj_name, OBJPROP_TEXT, progress_text);
    ObjectSetInteger(0, obj_name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, obj_name, OBJPROP_HIDDEN, false);
    ObjectSetInteger(0, obj_name, OBJPROP_BACK, false);
}

//+------------------------------------------------------------------+
//| Handle Chart Events (Button Clicks)                            |
//+------------------------------------------------------------------+
void CTestPanel::HandleChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        if(sparam == m_object_prefix + "CopyButton")
        {
            Print("[COPY] Copy button clicked!");
            
            if(CopyToClipboard())
            {
                // Show success status
                string status_name = m_object_prefix + "CopyStatus";
                if(ObjectFind(0, status_name) < 0)
                    ObjectCreate(0, status_name, OBJ_LABEL, 0, 0, 0);
                
                ObjectSetInteger(0, status_name, OBJPROP_XDISTANCE, 180);
                ObjectSetInteger(0, status_name, OBJPROP_YDISTANCE, 190);
                ObjectSetInteger(0, status_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
                ObjectSetInteger(0, status_name, OBJPROP_COLOR, clrLime);
                ObjectSetInteger(0, status_name, OBJPROP_FONTSIZE, 8);
                ObjectSetString(0, status_name, OBJPROP_FONT, "Arial");
                ObjectSetString(0, status_name, OBJPROP_TEXT, "[OK] Copied!");
                ObjectSetInteger(0, status_name, OBJPROP_SELECTABLE, false);
                ObjectSetInteger(0, status_name, OBJPROP_HIDDEN, false);
                ObjectSetInteger(0, status_name, OBJPROP_BACK, false);
                
                Print("[OK] Database report copied to clipboard successfully!");
            }
            else
            {
                // Show warning status
                string status_name = m_object_prefix + "CopyStatus";
                if(ObjectFind(0, status_name) < 0)
                    ObjectCreate(0, status_name, OBJ_LABEL, 0, 0, 0);
                
                ObjectSetInteger(0, status_name, OBJPROP_XDISTANCE, 180);
                ObjectSetInteger(0, status_name, OBJPROP_YDISTANCE, 190);
                ObjectSetInteger(0, status_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
                ObjectSetInteger(0, status_name, OBJPROP_COLOR, clrYellow);
                ObjectSetInteger(0, status_name, OBJPROP_FONTSIZE, 8);
                ObjectSetString(0, status_name, OBJPROP_FONT, "Arial");
                ObjectSetString(0, status_name, OBJPROP_TEXT, "[WARN] Check terminal");
                ObjectSetInteger(0, status_name, OBJPROP_SELECTABLE, false);
                ObjectSetInteger(0, status_name, OBJPROP_HIDDEN, false);
                ObjectSetInteger(0, status_name, OBJPROP_BACK, false);
                
                Print("[WARN] Direct copy failed - data available in terminal");
            }
            
            // Reset button state
            ObjectSetInteger(0, m_object_prefix + "CopyButton", OBJPROP_STATE, false);
            ChartRedraw(0);
        }
        else if(sparam == m_object_prefix + "ExpertLogButton")
        {
            Print("[LOG] Expert log copy button clicked!");
            
            if(CopyExpertLogToClipboard())
            {
                // Show success status
                string status_name = m_object_prefix + "LogCopyStatus";
                if(ObjectFind(0, status_name) < 0)
                    ObjectCreate(0, status_name, OBJ_LABEL, 0, 0, 0);
                
                ObjectSetInteger(0, status_name, OBJPROP_XDISTANCE, 180);
                ObjectSetInteger(0, status_name, OBJPROP_YDISTANCE, 190);
                ObjectSetInteger(0, status_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
                ObjectSetInteger(0, status_name, OBJPROP_COLOR, clrLime);
                ObjectSetInteger(0, status_name, OBJPROP_FONTSIZE, 8);
                ObjectSetString(0, status_name, OBJPROP_FONT, "Arial");
                ObjectSetString(0, status_name, OBJPROP_TEXT, "[LOG] Copied!");
                ObjectSetInteger(0, status_name, OBJPROP_SELECTABLE, false);
                ObjectSetInteger(0, status_name, OBJPROP_HIDDEN, false);
                ObjectSetInteger(0, status_name, OBJPROP_BACK, false);
                
                Print("[OK] Expert log copied to clipboard successfully!");
            }
            else
            {
                // Show warning status
                string status_name = m_object_prefix + "LogCopyStatus";
                if(ObjectFind(0, status_name) < 0)
                    ObjectCreate(0, status_name, OBJ_LABEL, 0, 0, 0);
                
                ObjectSetInteger(0, status_name, OBJPROP_XDISTANCE, 180);
                ObjectSetInteger(0, status_name, OBJPROP_YDISTANCE, 190);
                ObjectSetInteger(0, status_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
                ObjectSetInteger(0, status_name, OBJPROP_COLOR, clrYellow);
                ObjectSetInteger(0, status_name, OBJPROP_FONTSIZE, 8);
                ObjectSetString(0, status_name, OBJPROP_FONT, "Arial");
                ObjectSetString(0, status_name, OBJPROP_TEXT, "[WARN] Check terminal");
                ObjectSetInteger(0, status_name, OBJPROP_SELECTABLE, false);
                ObjectSetInteger(0, status_name, OBJPROP_HIDDEN, false);
                ObjectSetInteger(0, status_name, OBJPROP_BACK, false);
                
                Print("[WARN] Expert log copy failed - check terminal logs");
            }
            
            // Reset button state
            ObjectSetInteger(0, m_object_prefix + "ExpertLogButton", OBJPROP_STATE, false);
            ChartRedraw(0);
        }
    }
}

//+------------------------------------------------------------------+
//| Copy Database Report to Clipboard                               |
//+------------------------------------------------------------------+
bool CTestPanel::CopyToClipboard(void)
{
    string report = GenerateReportText();
    return CopyTextToClipboard(report);
}

//+------------------------------------------------------------------+
//| Generate Panel Content Text (EXACTLY what's displayed on panel) |
//+------------------------------------------------------------------+
string CTestPanel::GenerateReportText(void)
{
    string report = "";
    datetime current_time = TimeCurrent();
      // Simple header matching the panel (no timestamp)
    report += "SSoT Database Monitor\n";
    report += "Mode: " + (m_test_mode_active ? "TEST" : "LIVE") + "\n\n";
    
    // Get exactly what's displayed on the panel using CreateFullDatabaseDisplay logic
    // Main DB
    string info = GetDatabaseInfo(m_main_db, "sourcedb.sqlite");
    string candles = GetCandleDataInfo(m_main_db, "sourcedb.sqlite");
    string panel_text = info + "\n" + candles;

    if(m_test_mode_active) {
        // Input DB
        info = GetDatabaseInfo(m_test_input_db, "SSoT_input.db");
        candles = GetCandleDataInfo(m_test_input_db, "SSoT_input.db");
        panel_text += "\n---\n" + info + "\n" + candles;
        // Output DB
        info = GetDatabaseInfo(m_test_output_db, "SSoT_output.db");
        candles = GetCandleDataInfo(m_test_output_db, "SSoT_output.db");
        panel_text += "\n---\n" + info + "\n" + candles;
    }
    
    // Add the exact panel content
    report += panel_text;
    
    return report;
}

//+------------------------------------------------------------------+
//| Copy Text to Windows Clipboard                                  |
//+------------------------------------------------------------------+
bool CTestPanel::CopyTextToClipboard(string text)
{
    Print("[COPY] Attempting to copy text to clipboard...");
    
    // Save text to temporary file first
    string temp_file = "SSoT_Database_Report.txt";
    int file_handle = FileOpen(temp_file, FILE_WRITE | FILE_TXT | FILE_COMMON);
    
    if(file_handle == INVALID_HANDLE)
    {
        Print("ERROR: Failed to create temporary file for clipboard");
        return false;
    }
    
    FileWrite(file_handle, text);
    FileClose(file_handle);
    
    // Get full file path
    string file_path = TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "\\Files\\" + temp_file;
    
    // Try Windows clip command (most reliable)
    string clip_command = "cmd.exe";
    string clip_params = "/c type \"" + file_path + "\" | clip";
    
    Print("[COPY] Executing: " + clip_command + " " + clip_params);
    int result = ShellExecuteW(0, "open", clip_command, clip_params, "", SW_HIDE);
    
    if(result > 32)
    {
        Print("[OK] Text copied to clipboard successfully via Windows clip!");
        Print("💡 You can now paste with Ctrl+V anywhere");
        
        // Also display in terminal for verification
        Print("[DATA] === COPIED DATA (for verification) ===");
        Print(text);
        Print("[DATA] === END OF COPIED DATA ===");
        
        return true;
    }
    else
    {
        Print("[WARN] Clipboard copy failed (error " + IntegerToString(result) + ")");
        Print("[DATA] Data saved to file: " + file_path);
        Print("💡 You can open the file and copy manually");
        
        // Display in terminal for manual copy
        Print("[DATA] === COPY THIS DATA MANUALLY ===");
        Print(text);
        Print("[DATA] === END OF DATA ===");
        
        return false;
    }
}

//+------------------------------------------------------------------+
//| Cleanup Visual Panel                                            |
//+------------------------------------------------------------------+
void CTestPanel::CleanupVisualPanel(void)
{
    if(!m_panel_created) return;
    
    Print("[CLEANUP] Starting comprehensive visual panel cleanup...");
    
    // Remove main panel objects
    ObjectDelete(0, m_object_prefix + "Panel");
    ObjectDelete(0, m_object_prefix + "Mode");
    ObjectDelete(0, m_object_prefix + "Time");
    ObjectDelete(0, m_object_prefix + "Title");    ObjectDelete(0, m_object_prefix + "Status");
    ObjectDelete(0, m_object_prefix + "CopyButton");
    ObjectDelete(0, m_object_prefix + "CopyStatus");
    ObjectDelete(0, m_object_prefix + "ExpertLogButton");  // New: Expert log button
    ObjectDelete(0, m_object_prefix + "LogCopyStatus");    // New: Expert log status
    ObjectDelete(0, m_object_prefix + "Progress");
    ObjectDelete(0, m_object_prefix + "FullDBInfo");
    
    // Remove database status objects
    for(int i = 1; i <= 3; i++) {
        ObjectDelete(0, m_object_prefix + "DB" + IntegerToString(i));
        ObjectDelete(0, m_object_prefix + "DBInfo" + IntegerToString(i));
        ObjectDelete(0, m_object_prefix + "DBCandles" + IntegerToString(i));
    }
    
    // Clean up database column headers at known positions
    int header_positions[] = {40, 420, 800};  // Actual x positions used
    for(int i = 0; i < ArraySize(header_positions); i++) {
        ObjectDelete(0, m_object_prefix + "Header_" + IntegerToString(header_positions[i]));
    }
    
    // Clean up all line objects systematically 
    // Cover all possible x positions used by CreateDatabaseColumn (40, 420, 800)
    // Cover y range from 70 to 450 (panel height + margin)
    for(int i = 0; i < ArraySize(header_positions); i++) {
        int x_pos = header_positions[i];
        for(int y_pos = 70; y_pos <= 450; y_pos += 1) {  // Check every possible y position
            string line_obj = m_object_prefix + "Line_" + IntegerToString(x_pos) + "_" + IntegerToString(y_pos);
            ObjectDelete(0, line_obj);
        }
    }
    
    // Additional cleanup - remove any objects with our prefix that might be lingering
    // This is a safety net to catch any objects we might have missed
    for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
        string obj_name = ObjectName(0, i, -1, -1);
        if(StringFind(obj_name, m_object_prefix) == 0) {
            Print("[CLEANUP] Removing residual object: " + obj_name);
            ObjectDelete(0, obj_name);
        }
    }
    
    ChartRedraw(0);
    m_panel_created = false;
    Print("[CLEANUP] Comprehensive visual panel cleanup complete");
}

//+------------------------------------------------------------------+
//| Force cleanup of ALL SSoT objects on chart (emergency cleanup) |
//+------------------------------------------------------------------+
void CTestPanel::ForceCleanupAllSSoTObjects(void)
{
    Print("[FORCE-CLEANUP] Performing emergency cleanup of all SSoT objects...");
    
    int objects_removed = 0;
    
    // Get total objects and iterate backwards to avoid index issues
    for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
        string obj_name = ObjectName(0, i, -1, -1);
        
        // Remove any object that starts with "SSoT" (our prefix)
        if(StringFind(obj_name, "SSoT") == 0) {
            if(ObjectDelete(0, obj_name)) {
                objects_removed++;
                Print("[FORCE-CLEANUP] Removed: " + obj_name);
            }
        }
    }
    
    Print("[FORCE-CLEANUP] Emergency cleanup complete. Removed " + IntegerToString(objects_removed) + " objects.");
    
    // Force chart redraw
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Get Database Information for Report                             |
//+------------------------------------------------------------------+
string CTestPanel::GetDatabaseInfo(int db_handle, string db_name)
{
    string info = "";
    
    if(db_handle == INVALID_HANDLE) {
        info += "- Error: Database not available\n";
        return info;
    }    // Get DBInfo information - NO FALLBACKS, show real database state
    Print("[DEBUG] ===== QUERYING DATABASE: " + db_name + " (handle: " + IntegerToString(db_handle) + ") =====");
    int dbinfo_request = DatabasePrepare(db_handle, "SELECT broker_name, timezone, schema_version FROM DBInfo WHERE id=1");
    Print("[DEBUG] DBInfo query prepared. Request handle: " + IntegerToString(dbinfo_request));
    
    if(dbinfo_request != INVALID_HANDLE && DatabaseRead(dbinfo_request)) {
        string broker_name = "", timezone = "", schema_version = "";
        DatabaseColumnText(dbinfo_request, 0, broker_name);
        DatabaseColumnText(dbinfo_request, 1, timezone);
        DatabaseColumnText(dbinfo_request, 2, schema_version);
        
        Print("[DEBUG] DBInfo READ SUCCESS for " + db_name + " - Broker: '" + broker_name + "', TZ: '" + timezone + "', Schema: '" + schema_version + "'");
        
        info += "- Broker: " + broker_name + "\n";
        info += "- Timezone: " + timezone + "\n"; 
        info += "- Schema: " + schema_version + "\n";
        DatabaseFinalize(dbinfo_request);
    } else {
        Print("[DEBUG] DBInfo READ FAILED for " + db_name + " - NO DBInfo table or empty");
        // REAL state - DBInfo table missing or empty
        info += "- ERROR: DBInfo table missing or empty\n";
        info += "- Broker: MISSING\n";
        info += "- Timezone: MISSING\n";
        info += "- Schema: MISSING\n";
    }
      // Get database file information - REAL file data
    if(FileIsExist(db_name, FILE_COMMON)) {
        int file_handle = FileOpen(db_name, FILE_READ | FILE_BIN | FILE_COMMON);
        if(file_handle != INVALID_HANDLE) {
            long file_size = FileSize(file_handle);
            FileClose(file_handle);
            double size_mb = (double)file_size / (1024.0 * 1024.0);
            info += "- File Size: " + StringFormat("%.2f MB", size_mb) + "\n";
        } else {
            info += "- File Size: ERROR - Cannot open file\n";
        }
    } else {
        info += "- File Size: ERROR - File not found\n";
    }
      // Get table information - REAL table data (exclude sqlite internal tables)
    Print("[DEBUG] ===== QUERYING TABLES for ", db_name, " =====");
    int request = DatabasePrepare(db_handle, "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
    if(request != INVALID_HANDLE) {
        int table_count = 0;
        string table_names = "";
        while(DatabaseRead(request)) {
            table_count++;
            if(table_count > 1) table_names += ", ";
            string table_name = "";
            DatabaseColumnText(request, 0, table_name);
            table_names += table_name;
            Print("[DEBUG] Found table #", table_count, ": '", table_name, "'");
        }
        DatabaseFinalize(request);
        
        Print("[DEBUG] Table count for ", db_name, ": ", table_count, " tables: ", table_names);
        
        if(table_count > 0) {
            info += "- Tables (" + IntegerToString(table_count) + "): " + table_names + "\n";
        } else {
            info += "- Tables: EMPTY - No tables found\n";
        }
    } else {
        info += "- Tables: ERROR - Cannot query schema\n";
    }
    
    // Database type and location
    info += "- Type: SQLite Database\n";
    info += "- Location: " + db_name + "\n";
    
    return info;
}

//+------------------------------------------------------------------+
//| Get Candle Data Information for Report                          |
//+------------------------------------------------------------------+
string CTestPanel::GetCandleDataInfo(int db_handle, string db_name)
{
    string info = "";
    
    if(db_handle == INVALID_HANDLE) {
        // REAL state - database handle invalid
        info += "- ERROR: Database handle INVALID\n";
        info += "- Total Records: UNKNOWN\n";
        info += "- Date Range: UNKNOWN\n";
        info += "- Data Span: UNKNOWN\n";
        info += "- Assets: UNKNOWN\n";
        info += "- Timeframes: UNKNOWN\n";
        return info;
    }
    
    // Try to get AllCandleData table information - NO FALLBACKS
    int request = DatabasePrepare(db_handle, "SELECT COUNT(*) as total_records FROM AllCandleData");
    if(request != INVALID_HANDLE && DatabaseRead(request)) {
        int total_records = 0;
        DatabaseColumnInteger(request, 0, total_records);
        info += "- Total Records: " + IntegerToString(total_records) + "\n";
        DatabaseFinalize(request);
        
        if(total_records > 0) {
            // Get date range - show actual data or real errors
            request = DatabasePrepare(db_handle, "SELECT MIN(timestamp) as first_date, MAX(timestamp) as last_date FROM AllCandleData");
            if(request != INVALID_HANDLE && DatabaseRead(request)) {
                int first_date_int = 0, last_date_int = 0;
                DatabaseColumnInteger(request, 0, first_date_int);
                DatabaseColumnInteger(request, 1, last_date_int);
                datetime first_date = (datetime)first_date_int;
                datetime last_date = (datetime)last_date_int;
                
                if(first_date > 0 && last_date > 0) {
                    info += "- Date Range: " + TimeToString(first_date, TIME_DATE) + " to " + TimeToString(last_date, TIME_DATE) + "\n";
                    
                    // Calculate data span
                    int days = (int)((last_date - first_date) / 86400);
                    info += "- Data Span: " + IntegerToString(days) + " days\n";
                } else {
                    info += "- Date Range: ERROR - Invalid timestamps\n";
                    info += "- Data Span: ERROR - Invalid timestamps\n";
                }
                DatabaseFinalize(request);
            } else {
                info += "- Date Range: ERROR - Query failed\n";
                info += "- Data Span: ERROR - Query failed\n";
            }
            
            // Get assets - show real data or real errors
            request = DatabasePrepare(db_handle, "SELECT DISTINCT asset_symbol FROM AllCandleData ORDER BY asset_symbol");
            if(request != INVALID_HANDLE) {
                string assets = "";
                int asset_count = 0;
                while(DatabaseRead(request) && asset_count < 5) {  // Limit to first 5 assets
                    if(asset_count > 0) assets += ", ";
                    string asset_text = "";
                    DatabaseColumnText(request, 0, asset_text);
                    assets += asset_text;
                    asset_count++;
                }
                DatabaseFinalize(request);
                
                if(asset_count > 0) {
                    info += "- Assets (" + IntegerToString(asset_count) + "): " + assets;
                    if(asset_count == 5) info += "...";
                    info += "\n";
                } else {
                    info += "- Assets: EMPTY - No asset_symbol data\n";
                }
            } else {
                info += "- Assets: ERROR - Query failed\n";
            }
            
            // Get timeframes - show real data or real errors
            request = DatabasePrepare(db_handle, "SELECT DISTINCT timeframe FROM AllCandleData ORDER BY timeframe");
            if(request != INVALID_HANDLE) {
                string timeframes = "";
                int tf_count = 0;
                while(DatabaseRead(request)) {
                    if(tf_count > 0) timeframes += ", ";
                    string tf_text = "";
                    DatabaseColumnText(request, 0, tf_text);
                    timeframes += tf_text;
                    tf_count++;
                }
                DatabaseFinalize(request);
                
                if(tf_count > 0) {
                    info += "- Timeframes: " + timeframes + "\n";
                } else {
                    info += "- Timeframes: EMPTY - No timeframe data\n";
                }
            } else {
                info += "- Timeframes: ERROR - Query failed\n";
            }
        } else {
            // Database has AllCandleData table but no records - REAL state
            info += "- Date Range: EMPTY - No records\n";
            info += "- Data Span: EMPTY - No records\n";
            info += "- Assets: EMPTY - No records\n";
            info += "- Timeframes: EMPTY - No records\n";
        }
    } else {
        // AllCandleData table not found or query failed - REAL state
        info += "- ERROR: AllCandleData table missing or query failed\n";
        info += "- Total Records: UNKNOWN\n";
        info += "- Date Range: UNKNOWN\n";
        info += "- Data Span: UNKNOWN\n";
        info += "- Assets: UNKNOWN\n";
        info += "- Timeframes: UNKNOWN\n";
    }
    
    return info;
}

//+------------------------------------------------------------------+
//| Get Detailed Symbol/Timeframe Breakdown for Report              |
//+------------------------------------------------------------------+
string CTestPanel::GetDetailedBreakdown(int db_handle, string db_name)
{
    string breakdown = "";
    
    if(db_handle == INVALID_HANDLE) {
        breakdown += "- Detailed Breakdown: Database not available\n";
        return breakdown;
    }
    
    // Check for AllCandleData table first
    string active_table = "";
    int request = DatabasePrepare(db_handle, "SELECT name FROM sqlite_master WHERE type='table' AND (name='AllCandleData' OR name='candle_data' OR name='ohlctv_data' OR name='enhanced_data')");
    
    if(request == INVALID_HANDLE) {
        breakdown += "- Detailed Breakdown: Unable to query tables\n";
        return breakdown;
    }
    
    if(DatabaseRead(request)) {
        DatabaseColumnText(request, 0, active_table);
    }
    DatabaseFinalize(request);
    
    if(active_table == "") {
        breakdown += "- Detailed Breakdown: No candle data tables found\n";
        return breakdown;
    }
    
    breakdown += "- Active Table: " + active_table + "\n";
    
    // First check if table has any data
    string count_query = StringFormat("SELECT COUNT(*) FROM %s", active_table);
    request = DatabasePrepare(db_handle, count_query);
    
    if(request == INVALID_HANDLE) {
        breakdown += "- Symbol/Timeframe Breakdown: Unable to access table\n";
        return breakdown;
    }
    
    long total_records = 0;
    if(DatabaseRead(request)) {
        DatabaseColumnLong(request, 0, total_records);
    }
    DatabaseFinalize(request);
    
    if(total_records == 0) {
        breakdown += "- Symbol/Timeframe Breakdown: Table is empty\n";
        return breakdown;
    }
      // Get unique symbols
    string symbols_query = StringFormat("SELECT DISTINCT symbol FROM %s ORDER BY symbol", active_table);
    request = DatabasePrepare(db_handle, symbols_query);
    
    if(request == INVALID_HANDLE) {
        // Try alternative column names
        symbols_query = StringFormat("SELECT DISTINCT asset_symbol FROM %s ORDER BY asset_symbol", active_table);
        request = DatabasePrepare(db_handle, symbols_query);
        
        if(request == INVALID_HANDLE) {
            breakdown += "- Symbol/Timeframe Breakdown: Symbol column not found (tried 'symbol' and 'asset_symbol')\n";
            return breakdown;
        }
    }
    
    string symbols[];
    ArrayResize(symbols, 0);
    
    while(DatabaseRead(request)) {
        string symbol;
        DatabaseColumnText(request, 0, symbol);
        int size = ArraySize(symbols);
        ArrayResize(symbols, size + 1);
        symbols[size] = symbol;
    }
    DatabaseFinalize(request);
    
    if(ArraySize(symbols) == 0) {
        breakdown += "- Symbol/Timeframe Breakdown: No symbols found\n";
        return breakdown;
    }
    
    breakdown += "- Symbol/Timeframe Breakdown:\n";
    
    // For each symbol, get timeframe breakdown
    for(int i = 0; i < ArraySize(symbols) && i < 10; i++) { // Limit to 10 symbols for clipboard report
        string symbol = symbols[i];
        breakdown += "  * " + symbol + ":\n";
          // Get timeframes and counts for this symbol
        string tf_query = StringFormat(
            "SELECT timeframe, COUNT(*) as entries FROM %s WHERE symbol='%s' GROUP BY timeframe ORDER BY timeframe", 
            active_table, symbol);
        
        int tf_request = DatabasePrepare(db_handle, tf_query);
        
        // If symbol column doesn't work, try asset_symbol
        if(tf_request == INVALID_HANDLE) {
            tf_query = StringFormat(
                "SELECT timeframe, COUNT(*) as entries FROM %s WHERE asset_symbol='%s' GROUP BY timeframe ORDER BY timeframe", 
                active_table, symbol);
            tf_request = DatabasePrepare(db_handle, tf_query);
        }
        if(tf_request != INVALID_HANDLE) {
            bool has_data = false;
            while(DatabaseRead(tf_request)) {
                long timeframe = 0, entries = 0;
                DatabaseColumnLong(tf_request, 0, timeframe);
                DatabaseColumnLong(tf_request, 1, entries);
                
                string tf_string = TimeframeToString((int)timeframe);
                breakdown += "    - " + tf_string + ": " + IntegerToString(entries) + " entries\n";
                has_data = true;
            }
            DatabaseFinalize(tf_request);
            
            if(!has_data) {
                breakdown += "    - No timeframe data found\n";
            }
        } else {
            breakdown += "    - Error querying timeframes\n";
        }
    }
    
    // Add summary if more than 10 symbols
    if(ArraySize(symbols) > 10) {
        breakdown += "  * [" + IntegerToString(ArraySize(symbols) - 10) + " more symbols...]\n";
    }
    
    breakdown += "- Total Symbols: " + IntegerToString(ArraySize(symbols)) + "\n";
    
    return breakdown;
}

//+------------------------------------------------------------------+
//| Get COMPREHENSIVE Database Analysis (DBInfo + AllCandleData)     |
//+------------------------------------------------------------------+
string CTestPanel::GetComprehensiveBreakdown(int db_handle, string db_name)
{
    string breakdown = "";
    
    if(db_handle == INVALID_HANDLE) {
        breakdown += "- Database not available\n";
        return breakdown;
    }
    
    // === CHECK DBINFO TABLE FOR INVESTIGATION ASSETS/TIMEFRAMES ===
    breakdown += "=== DBInfo Table Analysis ===\n";
    int request = DatabasePrepare(db_handle, "SELECT key, value FROM DBInfo ORDER BY key");
    if(request != INVALID_HANDLE) {
        string investigation_symbols = "";
        string investigation_timeframes = "";
        
        while(DatabaseRead(request)) {
            string key, value;
            DatabaseColumnText(request, 0, key);
            DatabaseColumnText(request, 1, value);
            
            if(key == "symbols" || key == "investigation_symbols" || key == "monitored_symbols") {
                investigation_symbols = value;
            }
            if(key == "timeframes" || key == "investigation_timeframes" || key == "monitored_timeframes") {
                investigation_timeframes = value;
            }
            
            breakdown += "- " + key + ": " + value + "\n";
        }
        DatabaseFinalize(request);
        
        if(investigation_symbols != "") {
            breakdown += ">>> ASSETS UNDER INVESTIGATION: " + investigation_symbols + "\n";
        }
        if(investigation_timeframes != "") {
            breakdown += ">>> TIMEFRAMES UNDER INVESTIGATION: " + investigation_timeframes + "\n";
        }
    } else {
        breakdown += "- DBInfo table: Not accessible or doesn't exist\n";
    }
    breakdown += "\n";
    
    // === CHECK ALLCANDLEDATA TABLE FOR ACTUAL DATA ===
    breakdown += "=== AllCandleData Table Analysis ===\n";
    
    // Check for AllCandleData table
    string active_table = "";
    request = DatabasePrepare(db_handle, "SELECT name FROM sqlite_master WHERE type='table' AND (name='AllCandleData' OR name='candle_data' OR name='ohlctv_data' OR name='enhanced_data')");
    
    if(request == INVALID_HANDLE) {
        breakdown += "- AllCandleData: Unable to query tables\n";
        return breakdown;
    }
    
    if(DatabaseRead(request)) {
        DatabaseColumnText(request, 0, active_table);
    }
    DatabaseFinalize(request);
    
    if(active_table == "") {
        breakdown += "- AllCandleData: No candle data tables found\n";
        return breakdown;
    }
    
    breakdown += "- Active Data Table: " + active_table + "\n";
    
    // Get total record count
    string count_query = StringFormat("SELECT COUNT(*) FROM %s", active_table);
    request = DatabasePrepare(db_handle, count_query);
    
    if(request == INVALID_HANDLE) {
        breakdown += "- Total Records: Unable to access table\n";
        return breakdown;
    }
    
    long total_records = 0;
    if(DatabaseRead(request)) {
        DatabaseColumnLong(request, 0, total_records);
    }
    DatabaseFinalize(request);
    
    breakdown += "- TOTAL RECORDS: " + IntegerToString(total_records) + "\n";
    
    if(total_records == 0) {
        breakdown += "- Status: Table is empty\n";
        return breakdown;
    }
    
    // === GET TIMEFRAME TOTALS ===
    breakdown += "\n=== BREAKDOWN BY TIMEFRAME ===\n";
    string tf_totals_query = StringFormat("SELECT timeframe, COUNT(*) as entries FROM %s GROUP BY timeframe ORDER BY timeframe", active_table);
    request = DatabasePrepare(db_handle, tf_totals_query);
    
    if(request != INVALID_HANDLE) {
        long total_tf_records = 0;
        while(DatabaseRead(request)) {
            long timeframe = 0, entries = 0;
            DatabaseColumnLong(request, 0, timeframe);
            DatabaseColumnLong(request, 1, entries);
            total_tf_records += entries;
            
            string tf_string = TimeframeToString((int)timeframe);
            breakdown += "- " + tf_string + ": " + IntegerToString(entries) + " records\n";
        }
        DatabaseFinalize(request);
        breakdown += "- TIMEFRAME TOTAL: " + IntegerToString(total_tf_records) + " records\n";
    } else {
        breakdown += "- Timeframe breakdown: Query failed\n";
    }
    
    // === GET SYMBOLS AND THEIR BREAKDOWN ===
    breakdown += "\n=== BREAKDOWN BY SYMBOL ===\n";
    
    // Get unique symbols (try both column names)
    string symbols_query = StringFormat("SELECT DISTINCT symbol FROM %s ORDER BY symbol", active_table);
    request = DatabasePrepare(db_handle, symbols_query);
    
    if(request == INVALID_HANDLE) {
        symbols_query = StringFormat("SELECT DISTINCT asset_symbol FROM %s ORDER BY asset_symbol", active_table);
        request = DatabasePrepare(db_handle, symbols_query);
    }
    
    if(request == INVALID_HANDLE) {
        breakdown += "- Symbol breakdown: Column not found (tried 'symbol' and 'asset_symbol')\n";
        return breakdown;
    }
    
    string symbols[];
    ArrayResize(symbols, 0);
    
    while(DatabaseRead(request)) {
        string symbol;
        DatabaseColumnText(request, 0, symbol);
        int size = ArraySize(symbols);
        ArrayResize(symbols, size + 1);
        symbols[size] = symbol;
    }
    DatabaseFinalize(request);
    
    breakdown += "- TOTAL SYMBOLS: " + IntegerToString(ArraySize(symbols)) + "\n";
    
    // For each symbol, show timeframe breakdown
    for(int i = 0; i < ArraySize(symbols) && i < 20; i++) { // Show up to 20 symbols
        string symbol = symbols[i];
        breakdown += "\n* " + symbol + ":\n";
        
        // Get timeframes and counts for this symbol
        string tf_query = StringFormat(
            "SELECT timeframe, COUNT(*) as entries FROM %s WHERE symbol='%s' GROUP BY timeframe ORDER BY timeframe", 
            active_table, symbol);
        
        int tf_request = DatabasePrepare(db_handle, tf_query);
        
        // If symbol column doesn't work, try asset_symbol
        if(tf_request == INVALID_HANDLE) {
            tf_query = StringFormat(
                "SELECT timeframe, COUNT(*) as entries FROM %s WHERE asset_symbol='%s' GROUP BY timeframe ORDER BY timeframe", 
                active_table, symbol);
            tf_request = DatabasePrepare(db_handle, tf_query);
        }
        
        if(tf_request != INVALID_HANDLE) {
            long symbol_total = 0;
            while(DatabaseRead(tf_request)) {
                long timeframe = 0, entries = 0;
                DatabaseColumnLong(tf_request, 0, timeframe);
                DatabaseColumnLong(tf_request, 1, entries);
                symbol_total += entries;
                
                string tf_string = TimeframeToString((int)timeframe);
                breakdown += "  - " + tf_string + ": " + IntegerToString(entries) + " records\n";
            }
            DatabaseFinalize(tf_request);
            breakdown += "  SYMBOL TOTAL: " + IntegerToString(symbol_total) + " records\n";
        } else {
            breakdown += "  - Error querying timeframes for this symbol\n";
        }
    }
    
    // Add summary if more symbols exist
    if(ArraySize(symbols) > 20) {
        breakdown += "\n[" + IntegerToString(ArraySize(symbols) - 20) + " more symbols not shown - use console for full details]\n";
    }
    
    return breakdown;
}

//+------------------------------------------------------------------+
//| Copy Expert Log to Clipboard                                    |
//+------------------------------------------------------------------+
bool CTestPanel::CopyExpertLogToClipboard(void)
{
    string log_content = "";
      // Since log buffer is not implemented, just provide database state
    log_content = "=== MT5 EXPERT LOG EXPORT ===\n";
    log_content += "Timestamp: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\n";
    log_content += "Expert: SSoT Database Monitor\n";
    log_content += "Mode: " + (m_test_mode_active ? "TEST" : "LIVE") + "\n\n";
    log_content += "=== RECENT DEBUG OUTPUT ===\n";
    log_content += "Note: Full Expert log not accessible via MQL5.\n";
    log_content += "Check Experts tab in MetaTrader 5 Terminal for complete log.\n\n";
    log_content += "=== CURRENT DATABASE STATE ===\n";
    log_content += GenerateReportText();
    
    return CopyTextToClipboard(log_content);
}
//+------------------------------------------------------------------+
