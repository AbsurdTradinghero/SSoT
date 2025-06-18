//+------------------------------------------------------------------+
//| VisualDisplay.mqh - Chart Visual Components                     |
//| Handles all chart objects, panels, and visual displays          |
//+------------------------------------------------------------------+

#include <SSoT/Monitoring/DatabaseOperations.mqh>

// Windows API imports for clipboard functionality
#import "shell32.dll"
int ShellExecuteW(int hwnd, string lpOperation, string lpFile, string lpParameters, string lpDirectory, int nShowCmd);
#import

// Windows API for clipboard
#import "user32.dll"
int OpenClipboard(int hWndNewOwner);
int EmptyClipboard();
int CloseClipboard();
int SetClipboardData(int uFormat, int hMem);
#import

#import "kernel32.dll"
int GlobalAlloc(int uFlags, int dwBytes);
int GlobalLock(int hMem);
int GlobalUnlock(int hMem);
string lstrcpyW(int lpString1, string lpString2);
#import

#define CF_UNICODETEXT 13
#define GMEM_MOVEABLE 2

#define SW_HIDE 0

//+------------------------------------------------------------------+
//| Visual Display Manager Class                                    |
//+------------------------------------------------------------------+
class CVisualDisplay
{
private:
    string m_object_prefix;
    
public:
    //--- Constructor
    CVisualDisplay(string prefix) { m_object_prefix = prefix; }
    ~CVisualDisplay(void) { CleanupAllObjects(); }
    
    //--- Main Panel Functions
    bool CreateVisualPanel(void);
    void UpdateVisualPanel(void);
    void CleanupVisualPanel(void);
    void ForceCleanupAllSSoTObjects(void);    //--- Database Display Methods
    void CreateFullDatabaseDisplay(bool test_mode, int main_db, int test_input_db, int test_output_db);
    void CreateFullDatabaseDisplayWithTracking(bool test_mode, int main_db, int test_input_db, int test_output_db, string &tracked_symbols[], ENUM_TIMEFRAMES &tracked_timeframes[]);
    void CreateDatabaseInfoDisplay(bool test_mode, int main_db, int test_input_db, int test_output_db);
    void CreateCandleCountDisplay(bool test_mode, int main_db, int test_input_db, int test_output_db);
      //--- Data Comparison Display (Live Mode Only)
    void CreateBrokerVsDatabaseComparison(string &symbols[], ENUM_TIMEFRAMES &timeframes[], int db_handle);
    void UpdateDataComparisonDisplay(string &symbols[], ENUM_TIMEFRAMES &timeframes[], int db_handle);
    void CreateValidationStatsDisplay(string &symbols[], ENUM_TIMEFRAMES &timeframes[], int db_handle);
    
    //--- Button Creation
    void CreateCopyButton(void);
    void CreateGenerateTestDBsButton(void);
    void CreateDeleteTestDBsButton(void);
      //--- Event Handling
    void HandleChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
      //--- Panel Content Capture
    string CaptureActualPanelContent(void);    //--- Clipboard Operations (moved from ReportGenerator for efficiency)
    bool CopyToClipboard(string text);
    bool CopyTextToClipboard(string text);
    
    //--- Debug Methods
    void CreateDatabaseDebugDisplay(int db_handle);
    
private:
    //--- Panel Creation Helpers
    void CreatePanelHeader(int y_pos);    void CreateDatabaseColumn(string title, int db_handle, string db_name, int x_pos, int y_pos, color header_color);
    void CreateEnhancedDatabaseColumn(string title, int db_handle, string db_name, int x_pos, int y_pos, color header_color, string &tracked_symbols[], ENUM_TIMEFRAMES &tracked_timeframes[]);
    void CreateColumnLine(string text, int x_pos, int y_pos, color text_color, bool bold = false);
    void CreateModeDisplay(bool test_mode);
    void CreateDatabaseStatusDisplay(void);
    void CreateProgressDisplay(void);
    void CreateSystemStatusDisplay(bool test_mode, int main_db);
    
    //--- Database Display Helpers
    void ParseDatabaseInfo(int db_handle, string db_name, string &info_lines[]);
    void ClearDatabaseDisplayObjects(void);
    
    //--- Cleanup Helpers
    void CleanupAllObjects(void);
    int CountLines(string text);
};

//+------------------------------------------------------------------+
//| Create the main visual panel                                    |
//+------------------------------------------------------------------+
bool CVisualDisplay::CreateVisualPanel(void)
{
    Print("[VISUAL] Creating visual panel...");
    
    // Clean up any existing objects first
    CleanupVisualPanel();    // Create background panel
    string panel_name = m_object_prefix + "Panel";
    if(ObjectFind(0, panel_name) < 0) {        ObjectCreate(0, panel_name, OBJ_EDIT, 0, 0, 0);  // Using EDIT for guaranteed opacity
        ObjectSetInteger(0, panel_name, OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, panel_name, OBJPROP_YDISTANCE, 30);
        ObjectSetInteger(0, panel_name, OBJPROP_XSIZE, 1200);
        ObjectSetInteger(0, panel_name, OBJPROP_YSIZE, 680); // Increased height for better spacing        ObjectSetInteger(0, panel_name, OBJPROP_BGCOLOR, C'0,0,128'); // Dark blue RGB color - fully opaque
        ObjectSetInteger(0, panel_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, panel_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, panel_name, OBJPROP_COLOR, clrWhite); // White border for better contrast
        ObjectSetString(0, panel_name, OBJPROP_TEXT, ""); // Empty text for EDIT object
        ObjectSetInteger(0, panel_name, OBJPROP_READONLY, true); // Make read-only
        ObjectSetInteger(0, panel_name, OBJPROP_BACK, false); // Foreground object - blocks chart
        ObjectSetInteger(0, panel_name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, panel_name, OBJPROP_HIDDEN, false);
    }
    
    Print("[VISUAL] Visual panel created successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Update the visual panel                                         |
//+------------------------------------------------------------------+
void CVisualDisplay::UpdateVisualPanel(void)
{
    // Force chart redraw to ensure all objects are visible
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Create comprehensive database display                           |
//+------------------------------------------------------------------+
void CVisualDisplay::CreateFullDatabaseDisplay(bool test_mode, int main_db, int test_input_db, int test_output_db)
{
    Print("[VISUAL] Creating full database display...");
    
    // Clear existing display objects
    ClearDatabaseDisplayObjects();
      // Create mode display
    CreateModeDisplay(test_mode);
    
    // Create system status display
    CreateSystemStatusDisplay(test_mode, main_db);
    
    // Create panel header
    CreatePanelHeader(65);
    
    // Define column positions and headers
    int col1_x = 40, col2_x = 420, col3_x = 800;
    int start_y = 85;
      if(test_mode) {
        // Test Mode: Show all three databases
        CreateDatabaseColumn("MAIN DATABASE", main_db, "sourcedb.sqlite", col1_x, start_y, clrLime);
        CreateDatabaseColumn("TEST INPUT", test_input_db, "SSoT_input.db", col2_x, start_y, clrYellow);
        CreateDatabaseColumn("TEST OUTPUT", test_output_db, "SSoT_output.db", col3_x, start_y, clrCyan);
        
        // Create all action buttons for test mode
        CreateCopyButton();
        CreateGenerateTestDBsButton();
        CreateDeleteTestDBsButton();    } else {
        // Live Mode: Show only main database (centered)
        CreateDatabaseColumn("LIVE DATABASE", main_db, "sourcedb.sqlite", col2_x, start_y, clrLime);
        
        // Create visual separator for live mode
        string separator_obj = m_object_prefix + "Separator";
        if(ObjectFind(0, separator_obj) < 0)
            ObjectCreate(0, separator_obj, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, separator_obj, OBJPROP_XDISTANCE, 40);
        ObjectSetInteger(0, separator_obj, OBJPROP_YDISTANCE, 330);
        ObjectSetInteger(0, separator_obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, separator_obj, OBJPROP_FONTSIZE, 10);
        ObjectSetInteger(0, separator_obj, OBJPROP_COLOR, clrGray);
        ObjectSetString(0, separator_obj, OBJPROP_FONT, "Arial");
        ObjectSetString(0, separator_obj, OBJPROP_TEXT, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        ObjectSetInteger(0, separator_obj, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, separator_obj, OBJPROP_BACK, false);
        ObjectSetInteger(0, separator_obj, OBJPROP_HIDDEN, false);
        
        // Create only copy button for live mode
        CreateCopyButton();
    }
    
    // Force redraw
    ChartRedraw(0);
    
    Print("[VISUAL] Full database display created");
}

//+------------------------------------------------------------------+
//| Create panel header                                             |
//+------------------------------------------------------------------+
void CVisualDisplay::CreatePanelHeader(int y_pos)
{
    string header_obj = m_object_prefix + "Header_Main";
    if(ObjectFind(0, header_obj) < 0)
        ObjectCreate(0, header_obj, OBJ_LABEL, 0, 0, 0);
    
    ObjectSetInteger(0, header_obj, OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, header_obj, OBJPROP_YDISTANCE, y_pos);
    ObjectSetInteger(0, header_obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, header_obj, OBJPROP_FONTSIZE, 12);
    ObjectSetInteger(0, header_obj, OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, header_obj, OBJPROP_FONT, "Arial Bold");
    ObjectSetString(0, header_obj, OBJPROP_TEXT, "SSoT DATABASE MONITOR - " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
    ObjectSetInteger(0, header_obj, OBJPROP_BACK, false);
    ObjectSetInteger(0, header_obj, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, header_obj, OBJPROP_HIDDEN, false);
}

//+------------------------------------------------------------------+
//| Create database column display                                  |
//+------------------------------------------------------------------+
void CVisualDisplay::CreateDatabaseColumn(string title, int db_handle, string db_name, int x_pos, int y_pos, color header_color)
{
    int current_y = y_pos;
    int line_height = 18;
    
    // Column header
    string header_obj = m_object_prefix + "Header_" + IntegerToString(x_pos);
    if(ObjectFind(0, header_obj) < 0)
        ObjectCreate(0, header_obj, OBJ_LABEL, 0, 0, 0);
    
    ObjectSetInteger(0, header_obj, OBJPROP_XDISTANCE, x_pos);
    ObjectSetInteger(0, header_obj, OBJPROP_YDISTANCE, current_y);
    ObjectSetInteger(0, header_obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, header_obj, OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, header_obj, OBJPROP_COLOR, header_color);
    ObjectSetString(0, header_obj, OBJPROP_FONT, "Arial Bold");
    ObjectSetString(0, header_obj, OBJPROP_TEXT, title);
    ObjectSetInteger(0, header_obj, OBJPROP_BACK, false);
    ObjectSetInteger(0, header_obj, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, header_obj, OBJPROP_HIDDEN, false);
    
    current_y += line_height + 5;
    
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
void CVisualDisplay::CreateColumnLine(string text, int x_pos, int y_pos, color text_color, bool bold = false)
{
    string line_obj = m_object_prefix + "Line_" + IntegerToString(x_pos) + "_" + IntegerToString(y_pos);
    if(ObjectFind(0, line_obj) < 0)
        ObjectCreate(0, line_obj, OBJ_LABEL, 0, 0, 0);
    
    ObjectSetInteger(0, line_obj, OBJPROP_XDISTANCE, x_pos + 15);
    ObjectSetInteger(0, line_obj, OBJPROP_YDISTANCE, y_pos);
    ObjectSetInteger(0, line_obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, line_obj, OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, line_obj, OBJPROP_COLOR, text_color);
    ObjectSetString(0, line_obj, OBJPROP_FONT, bold ? "Arial Bold" : "Arial");
    ObjectSetString(0, line_obj, OBJPROP_TEXT, text);
    ObjectSetInteger(0, line_obj, OBJPROP_BACK, false);
    ObjectSetInteger(0, line_obj, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, line_obj, OBJPROP_HIDDEN, false);
}

//+------------------------------------------------------------------+
//| Parse database info into organized lines                        |
//+------------------------------------------------------------------+
void CVisualDisplay::ParseDatabaseInfo(int db_handle, string db_name, string &info_lines[])
{
    ArrayResize(info_lines, 0);
    
    if(db_handle == INVALID_HANDLE) {
        ArrayResize(info_lines, 1);
        info_lines[0] = "No data available";
        return;
    }
    
    // Create database operations helper
    CDatabaseOperations db_ops;
    
    // Get database info
    string db_info = db_ops.GetDatabaseInfo(db_handle, db_name);
    string candle_info = db_ops.GetCandleDataInfo(db_handle, db_name);
    
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
//| Create mode display                                             |
//+------------------------------------------------------------------+
void CVisualDisplay::CreateModeDisplay(bool test_mode)
{
    string mode_name = m_object_prefix + "Mode";
    
    if(ObjectFind(0, mode_name) < 0)
        ObjectCreate(0, mode_name, OBJ_LABEL, 0, 0, 0);
    
    string mode_text = "SSoT Monitor v4.06 - " + (test_mode ? "[TEST MODE]" : "[LIVE MODE]");
    
    ObjectSetInteger(0, mode_name, OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, mode_name, OBJPROP_YDISTANCE, 45);
    ObjectSetInteger(0, mode_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, mode_name, OBJPROP_COLOR, test_mode ? clrLime : clrOrange);
    ObjectSetInteger(0, mode_name, OBJPROP_FONTSIZE, 10);
    ObjectSetString(0, mode_name, OBJPROP_FONT, "Arial Bold");
    ObjectSetString(0, mode_name, OBJPROP_TEXT, mode_text);
    ObjectSetInteger(0, mode_name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, mode_name, OBJPROP_HIDDEN, false);
    ObjectSetInteger(0, mode_name, OBJPROP_BACK, false);
}

//+------------------------------------------------------------------+
//| Create copy to clipboard button                                 |
//+------------------------------------------------------------------+
void CVisualDisplay::CreateCopyButton(void)
{
    string button_name = m_object_prefix + "CopyButton";
    
    if(ObjectFind(0, button_name) < 0)
        ObjectCreate(0, button_name, OBJ_BUTTON, 0, 0, 0);
      // Position copy button prominently for live mode
    ObjectSetInteger(0, button_name, OBJPROP_XDISTANCE, 50);
    ObjectSetInteger(0, button_name, OBJPROP_YDISTANCE, 590);  // Moved down for better spacing
    ObjectSetInteger(0, button_name, OBJPROP_XSIZE, 180);      // Made wider for better visibility
    ObjectSetInteger(0, button_name, OBJPROP_YSIZE, 35);       // Made taller for better visibility
    ObjectSetInteger(0, button_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, button_name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, button_name, OBJPROP_BGCOLOR, C'0,0,100'); // Dark blue RGB for solid appearance
    ObjectSetInteger(0, button_name, OBJPROP_BORDER_COLOR, clrGold); // Gold border for prominence
    ObjectSetString(0, button_name, OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, button_name, OBJPROP_FONTSIZE, 11);    // Slightly larger font
    ObjectSetString(0, button_name, OBJPROP_TEXT, "📋 Copy Report to Clipboard");
    ObjectSetInteger(0, button_name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, button_name, OBJPROP_HIDDEN, false);
}

//+------------------------------------------------------------------+
//| Create generate test databases button                           |
//+------------------------------------------------------------------+
void CVisualDisplay::CreateGenerateTestDBsButton(void)
{
    string button_name = m_object_prefix + "GenerateButton";
    
    if(ObjectFind(0, button_name) < 0)
        ObjectCreate(0, button_name, OBJ_BUTTON, 0, 0, 0);
    
    ObjectSetInteger(0, button_name, OBJPROP_XDISTANCE, 150);
    ObjectSetInteger(0, button_name, OBJPROP_YDISTANCE, 400);
    ObjectSetInteger(0, button_name, OBJPROP_XSIZE, 120);
    ObjectSetInteger(0, button_name, OBJPROP_YSIZE, 25);
    ObjectSetInteger(0, button_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, button_name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, button_name, OBJPROP_BGCOLOR, clrGreen);
    ObjectSetInteger(0, button_name, OBJPROP_BORDER_COLOR, clrGray);
    ObjectSetString(0, button_name, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, button_name, OBJPROP_FONTSIZE, 9);
    ObjectSetString(0, button_name, OBJPROP_TEXT, "Generate Test DBs");
    ObjectSetInteger(0, button_name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, button_name, OBJPROP_HIDDEN, false);
}

//+------------------------------------------------------------------+
//| Create delete test databases button                             |
//+------------------------------------------------------------------+
void CVisualDisplay::CreateDeleteTestDBsButton(void)
{
    string button_name = m_object_prefix + "DeleteButton";
    
    if(ObjectFind(0, button_name) < 0)
        ObjectCreate(0, button_name, OBJ_BUTTON, 0, 0, 0);
    
    ObjectSetInteger(0, button_name, OBJPROP_XDISTANCE, 280);
    ObjectSetInteger(0, button_name, OBJPROP_YDISTANCE, 400);
    ObjectSetInteger(0, button_name, OBJPROP_XSIZE, 120);
    ObjectSetInteger(0, button_name, OBJPROP_YSIZE, 25);
    ObjectSetInteger(0, button_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, button_name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, button_name, OBJPROP_BGCOLOR, clrRed);
    ObjectSetInteger(0, button_name, OBJPROP_BORDER_COLOR, clrGray);
    ObjectSetString(0, button_name, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, button_name, OBJPROP_FONTSIZE, 9);
    ObjectSetString(0, button_name, OBJPROP_TEXT, "Delete Test DBs");
    ObjectSetInteger(0, button_name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, button_name, OBJPROP_HIDDEN, false);
}

//+------------------------------------------------------------------+
//| Clear all database display objects                              |
//+------------------------------------------------------------------+
void CVisualDisplay::ClearDatabaseDisplayObjects(void)
{
    Print("[CLEANUP] Starting ClearDatabaseDisplayObjects...");
    
    // Clear header objects for the three columns at actual positions
    int header_positions[] = {40, 420, 800};
    for(int i = 0; i < ArraySize(header_positions); i++) {
        ObjectDelete(0, m_object_prefix + "Header_" + IntegerToString(header_positions[i]));
    }
    
    // Clear title and status
    ObjectDelete(0, m_object_prefix + "Title");
    ObjectDelete(0, m_object_prefix + "Status");
    ObjectDelete(0, m_object_prefix + "FullDBInfo");
    ObjectDelete(0, m_object_prefix + "Header_Main");
    
    // Clear all line objects that were created by CreateColumnLine
    for(int i = 0; i < ArraySize(header_positions); i++) {
        int x_pos = header_positions[i];
        for(int y_pos = 70; y_pos <= 450; y_pos += 1) {
            string line_obj = m_object_prefix + "Line_" + IntegerToString(x_pos) + "_" + IntegerToString(y_pos);
            ObjectDelete(0, line_obj);
        }
    }
    
    // Force chart redraw
    ChartRedraw(0);
    
    Print("[CLEANUP] ClearDatabaseDisplayObjects completed");
}

//+------------------------------------------------------------------+
//| Cleanup visual panel                                            |
//+------------------------------------------------------------------+
void CVisualDisplay::CleanupVisualPanel(void)
{
    Print("[CLEANUP] Cleaning up visual panel...");
    ClearDatabaseDisplayObjects();
    CleanupAllObjects();
}

//+------------------------------------------------------------------+
//| Force cleanup of all SSoT objects                              |
//+------------------------------------------------------------------+
void CVisualDisplay::ForceCleanupAllSSoTObjects(void)
{
    Print("[CLEANUP] Force cleanup of ALL SSoT objects...");
    
    // Get list of all objects on chart
    int total_objects = ObjectsTotal(0);
    string objects_to_delete[];
    ArrayResize(objects_to_delete, 0);
    
    // Collect all SSoT objects
    for(int i = 0; i < total_objects; i++) {
        string obj_name = ObjectName(0, i);
        if(StringFind(obj_name, m_object_prefix) == 0) {
            int size = ArraySize(objects_to_delete);
            ArrayResize(objects_to_delete, size + 1);
            objects_to_delete[size] = obj_name;
        }
    }
    
    // Delete collected objects
    for(int i = 0; i < ArraySize(objects_to_delete); i++) {
        ObjectDelete(0, objects_to_delete[i]);
        Print("[CLEANUP] Deleted: " + objects_to_delete[i]);
    }
    
    ChartRedraw(0);
    Print("[CLEANUP] Force cleanup completed. Deleted " + IntegerToString(ArraySize(objects_to_delete)) + " objects");
}

//+------------------------------------------------------------------+
//| Handle chart events                                             |
//+------------------------------------------------------------------+
void CVisualDisplay::HandleChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK) {
        if(sparam == m_object_prefix + "CopyButton") {
            Print("[EVENT] Copy button clicked");
            // Reset button state
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
        }
        else if(sparam == m_object_prefix + "GenerateButton") {
            Print("[EVENT] Generate test databases button clicked");
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
        }
        else if(sparam == m_object_prefix + "DeleteButton") {
            Print("[EVENT] Delete test databases button clicked");
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
        }
    }
}

//+------------------------------------------------------------------+
//| Create simplified database info display                         |
//+------------------------------------------------------------------+
void CVisualDisplay::CreateDatabaseInfoDisplay(bool test_mode, int main_db, int test_input_db, int test_output_db)
{
    CDatabaseOperations db_ops;
    int y = 50;
    int count = test_mode ? 3 : 1;
    
    for(int i=0; i<count; i++) {
        int db = (i==0?main_db:(i==1?test_input_db:test_output_db));
        string name = (i==0?"sourcedb.sqlite":(i==1?"SSoT_input.db":"SSoT_output.db"));
        string info = db_ops.GetDatabaseInfo(db, name);
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
//| Create candle count display                                     |
//+------------------------------------------------------------------+
void CVisualDisplay::CreateCandleCountDisplay(bool test_mode, int main_db, int test_input_db, int test_output_db)
{
    CDatabaseOperations db_ops;
    int y = 70;
    int count = test_mode ? 3 : 1;
    
    for(int i=0; i<count; i++) {
        int db = (i==0?main_db:(i==1?test_input_db:test_output_db));
        string name = (i==0?"sourcedb.sqlite":(i==1?"SSoT_input.db":"SSoT_output.db"));
        string counts = db_ops.GetCandleDataInfo(db, name);
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
        ObjectSetInteger(0, obj, OBJPROP_HIDDEN, false);    }
}

//+------------------------------------------------------------------+
//| Create Broker vs Database Comparison Display                    |
//+------------------------------------------------------------------+
void CVisualDisplay::CreateBrokerVsDatabaseComparison(string &symbols[], ENUM_TIMEFRAMES &timeframes[], int db_handle)
{
    Print("[VISUAL] Creating Broker vs Database comparison display...");
    
    // Clear existing comparison objects
    for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
        string obj_name = ObjectName(0, i, -1, -1);
        if(StringFind(obj_name, m_object_prefix + "Comparison") == 0) {
            ObjectDelete(0, obj_name);
        }
    }    // Create comparison panel header
    string header_obj = m_object_prefix + "ComparisonHeader";
    ObjectCreate(0, header_obj, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, header_obj, OBJPROP_XDISTANCE, 40);
    ObjectSetInteger(0, header_obj, OBJPROP_YDISTANCE, 350);  // Moved up for better spacing
    ObjectSetInteger(0, header_obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, header_obj, OBJPROP_FONTSIZE, 12);
    ObjectSetInteger(0, header_obj, OBJPROP_COLOR, clrYellow);
    ObjectSetString(0, header_obj, OBJPROP_FONT, "Arial Bold");
    ObjectSetString(0, header_obj, OBJPROP_TEXT, "📊 BROKER vs DATABASE COMPARISON");
    ObjectSetInteger(0, header_obj, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, header_obj, OBJPROP_BACK, false);
    ObjectSetInteger(0, header_obj, OBJPROP_HIDDEN, false);
    
    // Create table headers
    int start_y = 370;  // Adjusted to match header movement
    int line_height = 16;
    int col_width = 120;
    
    // Table headers
    string headers[] = {"SYMBOL", "TIMEFRAME", "BROKER BARS", "DATABASE BARS", "DIFFERENCE", "STATUS"};
    int header_x_positions[] = {40, 160, 280, 420, 560, 700};
    
    for(int h = 0; h < ArraySize(headers); h++) {
        string header_name = m_object_prefix + "ComparisonTableHeader" + IntegerToString(h);
        ObjectCreate(0, header_name, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, header_name, OBJPROP_XDISTANCE, header_x_positions[h]);
        ObjectSetInteger(0, header_name, OBJPROP_YDISTANCE, start_y);
        ObjectSetInteger(0, header_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, header_name, OBJPROP_FONTSIZE, 9);
        ObjectSetInteger(0, header_name, OBJPROP_COLOR, clrCyan);
        ObjectSetString(0, header_name, OBJPROP_FONT, "Arial Bold");
        ObjectSetString(0, header_name, OBJPROP_TEXT, headers[h]);
        ObjectSetInteger(0, header_name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, header_name, OBJPROP_BACK, false);
        ObjectSetInteger(0, header_name, OBJPROP_HIDDEN, false);
    }
    
    int current_y = start_y + line_height + 5;
    int row_count = 0;
    
    // Loop through each symbol and timeframe combination
    for(int s = 0; s < ArraySize(symbols); s++) {
        for(int t = 0; t < ArraySize(timeframes); t++) {            string symbol = symbols[s];
            ENUM_TIMEFRAMES timeframe = timeframes[t];
            
            // Use proper timeframe conversion: PERIOD_M1 -> M1, etc.
            CDatabaseOperations db_ops;
            string tf_string = db_ops.TimeframeToString((int)timeframe);
            
            // Get broker data count
            int broker_bars = iBars(symbol, timeframe);
            
            // DEBUG: Show what we're searching for
            Print("[DEBUG] Searching for Symbol: '", symbol, "', Timeframe: '", tf_string, "' (converted from ", (int)timeframe, ")");
            
            // DEBUG: First, let's see what timeframe values actually exist in the database
            string debug_sql = "SELECT DISTINCT timeframe FROM AllCandleData LIMIT 10";
            int debug_request = DatabasePrepare(db_handle, debug_sql);
            if(debug_request != INVALID_HANDLE) {
                Print("[DEBUG] Timeframes actually in database:");
                while(DatabaseRead(debug_request)) {
                    string actual_tf = "";
                    if(DatabaseColumnText(debug_request, 0, actual_tf)) {
                        Print("[DEBUG]   - '", actual_tf, "'");
                    }
                }
                DatabaseFinalize(debug_request);
            }
            
            // DEBUG: Also check what symbols exist
            string symbol_sql = "SELECT DISTINCT asset_symbol FROM AllCandleData LIMIT 10";
            int symbol_request = DatabasePrepare(db_handle, symbol_sql);
            if(symbol_request != INVALID_HANDLE) {
                Print("[DEBUG] Symbols actually in database:");
                while(DatabaseRead(symbol_request)) {
                    string actual_symbol = "";
                    if(DatabaseColumnText(symbol_request, 0, actual_symbol)) {
                        Print("[DEBUG]   - '", actual_symbol, "'");
                    }
                }
                DatabaseFinalize(symbol_request);
            }
            
            // Get database data count
            int db_bars = 0;
            string sql = StringFormat("SELECT COUNT(*) FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s'", 
                                    symbol, tf_string);
            Print("[DEBUG] Executing query: ", sql);
            int request = DatabasePrepare(db_handle, sql);            if(request != INVALID_HANDLE) {
                if(DatabaseRead(request)) {
                    long count_value;
                    if(DatabaseColumnLong(request, 0, count_value)) {
                        db_bars = (int)count_value;
                        Print("[DEBUG] Query result: ", db_bars, " rows found");
                    }
                } else {
                    Print("[DEBUG] DatabaseRead failed for query: ", sql);
                }
                DatabaseFinalize(request);
            } else {
                Print("[DEBUG] DatabasePrepare failed for query: ", sql, ", Error: ", GetLastError());
            }
            
            // Calculate difference and status
            int difference = broker_bars - db_bars;
            string status;
            color status_color;
            
            if(difference == 0) {
                status = "✅ SYNCED";
                status_color = clrLime;
            } else if(MathAbs(difference) <= 5) {
                status = "⚠️ MINOR GAP";
                status_color = clrYellow;
            } else {
                status = "❌ MAJOR GAP";
                status_color = clrRed;
            }
            
            // Create row data
            string row_data[] = {
                symbol,
                tf_string,
                IntegerToString(broker_bars),
                IntegerToString(db_bars),
                IntegerToString(difference),
                status
            };
            
            color row_colors[] = {clrSilver, clrSilver, clrWhite, clrWhite, clrOrange, status_color};
            
            // Create row objects
            for(int col = 0; col < ArraySize(row_data); col++) {
                string cell_name = m_object_prefix + "ComparisonCell_" + IntegerToString(row_count) + "_" + IntegerToString(col);
                ObjectCreate(0, cell_name, OBJ_LABEL, 0, 0, 0);
                ObjectSetInteger(0, cell_name, OBJPROP_XDISTANCE, header_x_positions[col]);
                ObjectSetInteger(0, cell_name, OBJPROP_YDISTANCE, current_y);
                ObjectSetInteger(0, cell_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
                ObjectSetInteger(0, cell_name, OBJPROP_FONTSIZE, 8);
                ObjectSetInteger(0, cell_name, OBJPROP_COLOR, row_colors[col]);
                ObjectSetString(0, cell_name, OBJPROP_FONT, "Arial");
                ObjectSetString(0, cell_name, OBJPROP_TEXT, row_data[col]);
                ObjectSetInteger(0, cell_name, OBJPROP_SELECTABLE, false);
                ObjectSetInteger(0, cell_name, OBJPROP_BACK, false);
                ObjectSetInteger(0, cell_name, OBJPROP_HIDDEN, false);
            }
            
            current_y += line_height;
            row_count++;
        }
    }
    
    Print("[VISUAL] Broker vs Database comparison created with ", row_count, " rows");
}

//+------------------------------------------------------------------+
//| Update Data Comparison Display                                  |
//+------------------------------------------------------------------+
void CVisualDisplay::UpdateDataComparisonDisplay(string &symbols[], ENUM_TIMEFRAMES &timeframes[], int db_handle)
{
    CreateBrokerVsDatabaseComparison(symbols, timeframes, db_handle);
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Cleanup all objects                                             |
//+------------------------------------------------------------------+
void CVisualDisplay::CleanupAllObjects(void)
{
    // Basic cleanup of main panel objects
    ObjectDelete(0, m_object_prefix + "Panel");
    ObjectDelete(0, m_object_prefix + "Mode");
    ObjectDelete(0, m_object_prefix + "SystemStatus");
    ObjectDelete(0, m_object_prefix + "Separator");
    ObjectDelete(0, m_object_prefix + "CopyButton");
    ObjectDelete(0, m_object_prefix + "GenerateButton");
    ObjectDelete(0, m_object_prefix + "DeleteButton");
    
    // Cleanup comparison objects
    for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
        string obj_name = ObjectName(0, i, -1, -1);
        if(StringFind(obj_name, m_object_prefix + "Comparison") == 0) {
            ObjectDelete(0, obj_name);
        }
    }
}

//+------------------------------------------------------------------+
//| Create System Status Display                                    |
//+------------------------------------------------------------------+
void CVisualDisplay::CreateSystemStatusDisplay(bool test_mode, int main_db)
{
    string status_obj = m_object_prefix + "SystemStatus";
    
    if(ObjectFind(0, status_obj) < 0)
        ObjectCreate(0, status_obj, OBJ_LABEL, 0, 0, 0);
    
    // Determine system status
    string status_text;
    color status_color;
    
    if(main_db != INVALID_HANDLE) {
        if(test_mode) {
            status_text = "🔧 SYSTEM STATUS: TEST MODE ACTIVE";
            status_color = clrYellow;
        } else {
            status_text = "✅ SYSTEM STATUS: LIVE MODE - OPERATIONAL";
            status_color = clrLime;
        }
    } else {
        status_text = "❌ SYSTEM STATUS: DATABASE DISCONNECTED";
        status_color = clrRed;
    }
    
    ObjectSetInteger(0, status_obj, OBJPROP_XDISTANCE, 850);
    ObjectSetInteger(0, status_obj, OBJPROP_YDISTANCE, 50);
    ObjectSetInteger(0, status_obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, status_obj, OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, status_obj, OBJPROP_COLOR, status_color);
    ObjectSetString(0, status_obj, OBJPROP_FONT, "Arial Bold");
    ObjectSetString(0, status_obj, OBJPROP_TEXT, status_text);
    ObjectSetInteger(0, status_obj, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, status_obj, OBJPROP_BACK, false);
    ObjectSetInteger(0, status_obj, OBJPROP_HIDDEN, false);
}

//+------------------------------------------------------------------+
//| Capture actual panel content from chart objects                 |
//+------------------------------------------------------------------+
//| Capture actual panel content from chart objects                 |
//+------------------------------------------------------------------+
string CVisualDisplay::CaptureActualPanelContent(void)
{
    Print("[PANEL CAPTURE] Reading actual panel content from chart objects...");
    
    string content = "";
    content += "=======================================================\n";
    content += "SSoT PANEL CONTENT CAPTURE\n";
    content += "Generated: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\n";
    content += "=======================================================\n\n";
    
    // Get all objects on chart and filter for our prefix
    int total_objects = ObjectsTotal(0, -1, -1);
    string panel_objects[];
    
    // Collect all panel objects
    for(int i = 0; i < total_objects; i++) {
        string obj_name = ObjectName(0, i, -1, -1);
        
        // Only capture objects that belong to our panel
        if(StringFind(obj_name, m_object_prefix) == 0) {
            int new_size = ArraySize(panel_objects) + 1;
            ArrayResize(panel_objects, new_size);
            panel_objects[new_size - 1] = obj_name;
        }
    }
    
    Print("[PANEL CAPTURE] Found ", ArraySize(panel_objects), " panel objects");
    
    // Sort objects by Y position for logical reading order
    for(int i = 0; i < ArraySize(panel_objects) - 1; i++) {
        for(int j = i + 1; j < ArraySize(panel_objects); j++) {
            int y_pos_i = (int)ObjectGetInteger(0, panel_objects[i], OBJPROP_YDISTANCE);
            int y_pos_j = (int)ObjectGetInteger(0, panel_objects[j], OBJPROP_YDISTANCE);
            
            if(y_pos_i > y_pos_j) {
                string temp = panel_objects[i];
                panel_objects[i] = panel_objects[j];
                panel_objects[j] = temp;
            }
        }
    }
    
    // Capture content from each object
    string last_section = "";
    int current_y = -1;
    
    for(int i = 0; i < ArraySize(panel_objects); i++) {
        string obj_name = panel_objects[i];
        
        // Skip the background panel itself
        if(StringFind(obj_name, "Panel") >= 0 && ObjectGetInteger(0, obj_name, OBJPROP_TYPE) == OBJ_EDIT) {
            continue;
        }
        
        // Get object properties
        ENUM_OBJECT obj_type = (ENUM_OBJECT)ObjectGetInteger(0, obj_name, OBJPROP_TYPE);
        int y_pos = (int)ObjectGetInteger(0, obj_name, OBJPROP_YDISTANCE);
        int x_pos = (int)ObjectGetInteger(0, obj_name, OBJPROP_XDISTANCE);
        
        // Add spacing between different Y levels
        if(current_y != -1 && y_pos > current_y + 20) {
            content += "\n";
        }
        current_y = y_pos;
        
        // Extract text content based on object type
        if(obj_type == OBJ_LABEL) {
            string text = ObjectGetString(0, obj_name, OBJPROP_TEXT);
            if(StringLen(text) > 0) {
                // Format based on object name pattern
                if(StringFind(obj_name, "Header") >= 0) {
                    content += "--- " + text + " ---\n";
                } else if(StringFind(obj_name, "Comparison") >= 0) {
                    if(StringFind(obj_name, "Header") >= 0) {
                        content += "\n📊 " + text + "\n";
                    } else {
                        // Format table data
                        content += text;
                        if(x_pos < 200) content += "\t"; // Add tab for alignment
                        else if(x_pos < 400) content += "\t";
                        else if(x_pos < 600) content += "\t";
                        else content += "\n"; // End of row
                    }
                } else {
                    content += text + "\n";
                }
            }
        } else if(obj_type == OBJ_BUTTON) {
            string button_text = ObjectGetString(0, obj_name, OBJPROP_TEXT);
            if(StringLen(button_text) > 0) {
                content += "[BUTTON: " + button_text + "]\n";
            }
        }
    }
    
    content += "\n=======================================================\n";
    content += "Panel content captured from " + IntegerToString(ArraySize(panel_objects)) + " objects\n";
    content += "Capture time: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\n";
    content += "=======================================================\n";
    
    Print("[PANEL CAPTURE] Successfully captured ", StringLen(content), " characters");
    return content;
}

//+------------------------------------------------------------------+
//| Copy text to clipboard (moved from ReportGenerator)            |
//+------------------------------------------------------------------+
bool CVisualDisplay::CopyToClipboard(string report_text)
{
    Print("[CLIPBOARD] Attempting to copy report to clipboard...");
    
    if(StringLen(report_text) == 0) {
        Print("[CLIPBOARD] ERROR: Empty report text");
        return false;
    }
    
    bool result = CopyTextToClipboard(report_text);
    
    if(result) {
        Print("[CLIPBOARD] SUCCESS: Report copied to clipboard (" + IntegerToString(StringLen(report_text)) + " characters)");
    } else {
        Print("[CLIPBOARD] ERROR: Failed to copy report to clipboard");
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Copy text to clipboard - File method with auto-open           |
//+------------------------------------------------------------------+
bool CVisualDisplay::CopyTextToClipboard(string text)
{
    Print("[CLIPBOARD] Creating report file for easy copying...");
    
    if(StringLen(text) == 0) {
        Print("[CLIPBOARD] ERROR: Empty text");
        return false;
    }
    
    // Create a well-formatted file
    string report_file = "SSoT_Panel_Export_" + TimeToString(TimeCurrent(), TIME_DATE) + ".txt";
    StringReplace(report_file, ".", "_");
    StringReplace(report_file, ":", "_");
    
    int file_handle = FileOpen(report_file, FILE_WRITE | FILE_TXT | FILE_UNICODE);
    
    if(file_handle == INVALID_HANDLE) {
        Print("[CLIPBOARD] ERROR: Cannot create report file: ", report_file);
        return false;
    }
    
    // Write the actual captured panel content directly
    FileWriteString(file_handle, text);
    
    FileClose(file_handle);
    
    // Get full file path
    string full_path = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\" + report_file;
    
    Print("[CLIPBOARD] ✅ Panel content exported successfully!");
    Print("[CLIPBOARD] 📁 File: ", report_file);
    Print("[CLIPBOARD] 📂 Location: ", full_path);
    Print("[CLIPBOARD] 📋 Opening file for easy copying...");
    
    // Try to open the file automatically
    int result = ShellExecuteW(0, "open", full_path, "", "", 5); // SW_SHOW = 5
    
    if(result > 32) {
        Print("[CLIPBOARD] ✅ File opened successfully in default text editor");
        Print("[CLIPBOARD] 📌 Instructions: Select All (Ctrl+A) then Copy (Ctrl+C)");
        return true;
    } else {
        Print("[CLIPBOARD] ⚠️ Could not auto-open file (Error: ", result, ")");
        Print("[CLIPBOARD] 📌 Manual Instructions:");
        Print("[CLIPBOARD] 1. Navigate to: ", full_path);
        Print("[CLIPBOARD] 2. Open the file in any text editor");
        Print("[CLIPBOARD] 3. Select All (Ctrl+A) and Copy (Ctrl+C)");
        return true; // Still success since file was created
    }
}

//+------------------------------------------------------------------+
//| Create database debug display                                    |
//+------------------------------------------------------------------+
void CVisualDisplay::CreateDatabaseDebugDisplay(int db_handle)
{
    CDatabaseOperations db_ops;
    
    Print("=== DATABASE DEBUG INFORMATION ===");
    Print("Database handle: ", db_handle);
    
    if(db_handle == INVALID_HANDLE) {
        Print("ERROR: Invalid database handle");
        return;
    }
    
    // Check what tables exist
    Print("--- Checking available tables ---");
    string tables[] = {"AllCandleData", "CandleData", "candle_data", "data"};
    
    for(int i = 0; i < ArraySize(tables); i++) {
        string table = tables[i];
        Print("Checking table: ", table);
        
        // Try to count rows
        string sql = "SELECT COUNT(*) FROM " + table;
        int request = DatabasePrepare(db_handle, sql);
        
        if(request != INVALID_HANDLE) {
            if(DatabaseRead(request)) {
                long count;
                if(DatabaseColumnLong(request, 0, count)) {
                    Print("  - Table '", table, "' exists with ", count, " rows");
                    
                    // Get schema
                    string schema = db_ops.GetDatabaseSchema(db_handle, table);
                    Print("  - Schema: ", schema);
                    
                    // Get sample data
                    string sample = db_ops.GetSampleData(db_handle, table, 3);
                    Print("  - Sample: ", sample);
                }
            }
            DatabaseFinalize(request);
        } else {
            Print("  - Table '", table, "' does not exist or cannot be accessed");
        }
    }
      // Check specific queries that are failing
    Print("--- Testing specific queries ---");
    string test_symbols[] = {"EURUSD", "GBPUSD"};
    string test_timeframes[] = {"PERIOD_M1", "PERIOD_M5", "PERIOD_H1"};
    
    // First, check what symbols and timeframes actually exist in the database
    Print("--- Checking what symbols exist in database ---");
    string sql_symbols = "SELECT DISTINCT asset_symbol FROM AllCandleData LIMIT 10";
    int request_symbols = DatabasePrepare(db_handle, sql_symbols);
    if(request_symbols != INVALID_HANDLE) {
        while(DatabaseRead(request_symbols)) {
            string symbol = "";
            DatabaseColumnText(request_symbols, 0, symbol);
            Print("  - Found symbol: '", symbol, "'");
        }
        DatabaseFinalize(request_symbols);
    }
    
    Print("--- Checking what timeframes exist in database ---");
    string sql_timeframes = "SELECT DISTINCT timeframe FROM AllCandleData LIMIT 10";
    int request_timeframes = DatabasePrepare(db_handle, sql_timeframes);
    if(request_timeframes != INVALID_HANDLE) {
        while(DatabaseRead(request_timeframes)) {
            string tf = "";
            DatabaseColumnText(request_timeframes, 0, tf);
            Print("  - Found timeframe: '", tf, "'");
        }
        DatabaseFinalize(request_timeframes);
    }
    
    for(int s = 0; s < ArraySize(test_symbols); s++) {
        for(int t = 0; t < ArraySize(test_timeframes); t++) {
            string symbol = test_symbols[s];
            string tf = test_timeframes[t];
            
            string sql = StringFormat("SELECT COUNT(*) FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s'", 
                                    symbol, tf);
            Print("Testing query: ", sql);
            
            int request = DatabasePrepare(db_handle, sql);
            if(request != INVALID_HANDLE) {
                if(DatabaseRead(request)) {
                    long count;
                    if(DatabaseColumnLong(request, 0, count)) {
                        Print("  - Result: ", count, " rows for ", symbol, " ", tf);
                    }
                }
                DatabaseFinalize(request);
            } else {
                Print("  - Query failed for ", symbol, " ", tf);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Create database display with asset/timeframe tracking          |
//+------------------------------------------------------------------+
void CVisualDisplay::CreateFullDatabaseDisplayWithTracking(bool test_mode, int main_db, int test_input_db, int test_output_db, string &tracked_symbols[], ENUM_TIMEFRAMES &tracked_timeframes[])
{
    Print("[VISUAL] Creating enhanced database display with tracking...");
    
    // Clear existing display objects
    ClearDatabaseDisplayObjects();
    
    // Create mode display
    CreateModeDisplay(test_mode);
    
    // Create system status display
    CreateSystemStatusDisplay(test_mode, main_db);
    
    // Create panel header
    CreatePanelHeader(65);
    
    // Define column positions and headers
    int col1_x = 40, col2_x = 420, col3_x = 800;
    int start_y = 85;
    
    if(test_mode) {
        // Test Mode: Show all three databases (use standard method for test databases)
        CreateDatabaseColumn("MAIN DATABASE", main_db, "sourcedb.sqlite", col1_x, start_y, clrLime);
        CreateDatabaseColumn("TEST INPUT", test_input_db, "SSoT_input.db", col2_x, start_y, clrYellow);
        CreateDatabaseColumn("TEST OUTPUT", test_output_db, "SSoT_output.db", col3_x, start_y, clrCyan);
        
        // Create all action buttons for test mode
        CreateCopyButton();
        CreateGenerateTestDBsButton();
        CreateDeleteTestDBsButton();
    } else {
        // Live Mode: Show enhanced main database (centered)
        CreateEnhancedDatabaseColumn("LIVE DATABASE", main_db, "sourcedb.sqlite", col2_x, start_y, clrLime, tracked_symbols, tracked_timeframes);
        
        // Create visual separator for live mode
        string separator_obj = m_object_prefix + "Separator";
        if(ObjectFind(0, separator_obj) < 0)
            ObjectCreate(0, separator_obj, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, separator_obj, OBJPROP_XDISTANCE, 40);
        ObjectSetInteger(0, separator_obj, OBJPROP_YDISTANCE, 330);
        ObjectSetInteger(0, separator_obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, separator_obj, OBJPROP_FONTSIZE, 10);
        ObjectSetInteger(0, separator_obj, OBJPROP_COLOR, clrGray);
        ObjectSetString(0, separator_obj, OBJPROP_FONT, "Arial");
        ObjectSetString(0, separator_obj, OBJPROP_TEXT, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        ObjectSetInteger(0, separator_obj, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, separator_obj, OBJPROP_BACK, false);
        ObjectSetInteger(0, separator_obj, OBJPROP_HIDDEN, false);
        
        // Create only copy button for live mode
        CreateCopyButton();
    }
    
    // Force redraw
    ChartRedraw(0);
    
    Print("[VISUAL] Enhanced database display with tracking created");
}

//+------------------------------------------------------------------+
//| Create enhanced database column with tracking info              |
//+------------------------------------------------------------------+
void CVisualDisplay::CreateEnhancedDatabaseColumn(string title, int db_handle, string db_name, int x_pos, int y_pos, color header_color, string &tracked_symbols[], ENUM_TIMEFRAMES &tracked_timeframes[])
{
    int current_y = y_pos;
    int line_height = 18;
    
    // Column header
    string header_obj = m_object_prefix + "Header_" + IntegerToString(x_pos);
    if(ObjectFind(0, header_obj) < 0)
        ObjectCreate(0, header_obj, OBJ_LABEL, 0, 0, 0);
    
    ObjectSetInteger(0, header_obj, OBJPROP_XDISTANCE, x_pos);
    ObjectSetInteger(0, header_obj, OBJPROP_YDISTANCE, current_y);
    ObjectSetInteger(0, header_obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, header_obj, OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, header_obj, OBJPROP_COLOR, header_color);
    ObjectSetString(0, header_obj, OBJPROP_FONT, "Arial Bold");
    ObjectSetString(0, header_obj, OBJPROP_TEXT, title);
    ObjectSetInteger(0, header_obj, OBJPROP_BACK, false);
    ObjectSetInteger(0, header_obj, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, header_obj, OBJPROP_HIDDEN, false);
    
    current_y += line_height + 5;
    
    // Connection status
    string status_text = (db_handle != INVALID_HANDLE) ? "Status: CONNECTED" : "Status: DISCONNECTED";
    color status_color = (db_handle != INVALID_HANDLE) ? clrLime : clrRed;
    
    CreateColumnLine(status_text, x_pos, current_y, status_color, true);
    current_y += line_height;
    
    if(db_handle != INVALID_HANDLE) {
        // Enhanced database information with tracking
        CDatabaseOperations db_ops;
        
        if(ArraySize(tracked_symbols) > 0 && ArraySize(tracked_timeframes) > 0) {
            // Use enhanced database info
            string enhanced_info = db_ops.GetEnhancedDatabaseInfo(db_handle, db_name, tracked_symbols, tracked_timeframes);
            
            // Parse and display enhanced info
            string info_lines[];
            int line_count = StringSplit(enhanced_info, '\n', info_lines);
            
            for(int i = 0; i < line_count && i < 15; i++) { // Limit to 15 lines for display
                string line = info_lines[i];
                StringTrimLeft(line);
                StringTrimRight(line);
                
                if(StringLen(line) > 0) {
                    // Determine line color based on content
                    color line_color = clrSilver;
                    if(StringFind(line, "Tracked Symbols:") >= 0 || StringFind(line, "Tracked Timeframes:") >= 0) {
                        line_color = clrYellow;
                    } else if(StringFind(line, "Data Availability:") >= 0) {
                        line_color = clrCyan;
                    } else if(StringFind(line, " entries") >= 0) {
                        line_color = clrLightGreen;
                    }
                    
                    CreateColumnLine(line, x_pos, current_y, line_color, false);
                    current_y += line_height;
                }
            }
        } else {
            // Fall back to standard database info
            string info_lines[];
            ParseDatabaseInfo(db_handle, db_name, info_lines);
            
            for(int i = 0; i < ArraySize(info_lines); i++) {
                if(StringLen(info_lines[i]) > 0) {
                    CreateColumnLine(info_lines[i], x_pos, current_y, clrSilver, false);
                    current_y += line_height;
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Create validation statistics display                            |
//+------------------------------------------------------------------+
void CVisualDisplay::CreateValidationStatsDisplay(string &symbols[], ENUM_TIMEFRAMES &timeframes[], int db_handle)
{
    Print("[VISUAL] Creating validation statistics display...");
    
    // Clear existing validation objects
    for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
        string obj_name = ObjectName(0, i, -1, -1);
        if(StringFind(obj_name, m_object_prefix + "Validation") == 0) {
            ObjectDelete(0, obj_name);
        }
    }
    
    // Create validation panel header
    string header_obj = m_object_prefix + "ValidationHeader";
    ObjectCreate(0, header_obj, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, header_obj, OBJPROP_XDISTANCE, 40);
    ObjectSetInteger(0, header_obj, OBJPROP_YDISTANCE, 550);  // Below the comparison table
    ObjectSetInteger(0, header_obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, header_obj, OBJPROP_FONTSIZE, 12);
    ObjectSetInteger(0, header_obj, OBJPROP_COLOR, clrLightBlue);
    ObjectSetString(0, header_obj, OBJPROP_FONT, "Arial Bold");
    ObjectSetString(0, header_obj, OBJPROP_TEXT, "🔍 HASH VALIDATION & COMPLETION STATUS");
    ObjectSetInteger(0, header_obj, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, header_obj, OBJPROP_BACK, false);
    ObjectSetInteger(0, header_obj, OBJPROP_HIDDEN, false);
    
    // Create table headers for validation
    int start_y = 570;
    int line_height = 16;
    
    string val_headers[] = {"SYMBOL", "TIMEFRAME", "VALIDATED", "COMPLETED", "HASH STATUS"};
    int val_header_x_positions[] = {40, 160, 280, 420, 560};
    
    for(int h = 0; h < ArraySize(val_headers); h++) {
        string header_name = m_object_prefix + "ValidationTableHeader" + IntegerToString(h);
        ObjectCreate(0, header_name, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, header_name, OBJPROP_XDISTANCE, val_header_x_positions[h]);
        ObjectSetInteger(0, header_name, OBJPROP_YDISTANCE, start_y);
        ObjectSetInteger(0, header_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, header_name, OBJPROP_FONTSIZE, 9);
        ObjectSetInteger(0, header_name, OBJPROP_COLOR, clrCyan);
        ObjectSetString(0, header_name, OBJPROP_FONT, "Arial Bold");
        ObjectSetString(0, header_name, OBJPROP_TEXT, val_headers[h]);
        ObjectSetInteger(0, header_name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, header_name, OBJPROP_BACK, false);
        ObjectSetInteger(0, header_name, OBJPROP_HIDDEN, false);
    }
    
    int current_y = start_y + line_height + 5;
    int row_count = 0;
    
    // Loop through each symbol and timeframe combination
    for(int s = 0; s < ArraySize(symbols); s++) {
        for(int t = 0; t < ArraySize(timeframes); t++) {
            string symbol = symbols[s];
            ENUM_TIMEFRAMES timeframe = timeframes[t];
            
            CDatabaseOperations db_ops;
            string tf_string = db_ops.TimeframeToString((int)timeframe);
            
            // Get total bars for this symbol/timeframe
            int total_bars = 0;
            string total_sql = StringFormat("SELECT COUNT(*) FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s'", 
                                          symbol, tf_string);
            int total_request = DatabasePrepare(db_handle, total_sql);
            if(total_request != INVALID_HANDLE) {
                if(DatabaseRead(total_request)) {
                    long count_value;
                    if(DatabaseColumnLong(total_request, 0, count_value)) {
                        total_bars = (int)count_value;
                    }
                }
                DatabaseFinalize(total_request);
            }
            
            // Get validated bars count
            int validated_bars = 0;
            string val_sql = StringFormat("SELECT COUNT(*) FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s' AND is_validated=1", 
                                        symbol, tf_string);
            int val_request = DatabasePrepare(db_handle, val_sql);
            if(val_request != INVALID_HANDLE) {
                if(DatabaseRead(val_request)) {
                    long count_value;
                    if(DatabaseColumnLong(val_request, 0, count_value)) {
                        validated_bars = (int)count_value;
                    }
                }
                DatabaseFinalize(val_request);
            }
            
            // Get completed bars count
            int completed_bars = 0;
            string comp_sql = StringFormat("SELECT COUNT(*) FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s' AND is_complete=1", 
                                         symbol, tf_string);
            int comp_request = DatabasePrepare(db_handle, comp_sql);
            if(comp_request != INVALID_HANDLE) {
                if(DatabaseRead(comp_request)) {
                    long count_value;
                    if(DatabaseColumnLong(comp_request, 0, count_value)) {
                        completed_bars = (int)count_value;
                    }
                }
                DatabaseFinalize(comp_request);
            }
            
            // Determine hash status
            string hash_status;
            color hash_color;
            
            if(total_bars == 0) {
                hash_status = "❌ NO DATA";
                hash_color = clrRed;
            } else if(validated_bars == total_bars) {
                hash_status = "✅ ALL VALID";
                hash_color = clrLime;
            } else if(validated_bars > total_bars * 0.9) {
                hash_status = "⚠️ MOSTLY VALID";
                hash_color = clrYellow;
            } else {
                hash_status = "❌ INVALID";
                hash_color = clrRed;
            }
            
            // Create row data
            string row_data[] = {
                symbol,
                tf_string,
                StringFormat("%d/%d", validated_bars, total_bars),
                StringFormat("%d/%d", completed_bars, total_bars),
                hash_status
            };
            
            color row_colors[] = {clrWhite, clrWhite, clrLightBlue, clrLightGreen, hash_color};
            
            for(int col = 0; col < ArraySize(row_data); col++) {
                string row_obj = m_object_prefix + "ValidationRow" + IntegerToString(row_count) + "Col" + IntegerToString(col);
                ObjectCreate(0, row_obj, OBJ_LABEL, 0, 0, 0);
                ObjectSetInteger(0, row_obj, OBJPROP_XDISTANCE, val_header_x_positions[col]);
                ObjectSetInteger(0, row_obj, OBJPROP_YDISTANCE, current_y);
                ObjectSetInteger(0, row_obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
                ObjectSetInteger(0, row_obj, OBJPROP_FONTSIZE, 8);
                ObjectSetInteger(0, row_obj, OBJPROP_COLOR, row_colors[col]);
                ObjectSetString(0, row_obj, OBJPROP_FONT, "Arial");
                ObjectSetString(0, row_obj, OBJPROP_TEXT, row_data[col]);
                ObjectSetInteger(0, row_obj, OBJPROP_SELECTABLE, false);
                ObjectSetInteger(0, row_obj, OBJPROP_BACK, false);
                ObjectSetInteger(0, row_obj, OBJPROP_HIDDEN, false);
            }
            
            current_y += line_height;
            row_count++;
        }
    }
    
    Print("[VISUAL] Validation statistics display created with ", row_count, " rows");
}
