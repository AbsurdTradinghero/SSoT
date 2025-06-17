//+------------------------------------------------------------------+
//| VisualDisplay.mqh - Chart Visual Components                     |
//| Handles all chart objects, panels, and visual displays          |
//+------------------------------------------------------------------+

#include <SSoT/Monitoring/DatabaseOperations.mqh>

// Windows API imports for clipboard functionality
#import "shell32.dll"
int ShellExecuteW(int hwnd, string lpOperation, string lpFile, string lpParameters, string lpDirectory, int nShowCmd);
#import

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
    void CreateDatabaseInfoDisplay(bool test_mode, int main_db, int test_input_db, int test_output_db);
    void CreateCandleCountDisplay(bool test_mode, int main_db, int test_input_db, int test_output_db);
      //--- Data Comparison Display (Live Mode Only)
    void CreateBrokerVsDatabaseComparison(string &symbols[], ENUM_TIMEFRAMES &timeframes[], int db_handle);
    void UpdateDataComparisonDisplay(string &symbols[], ENUM_TIMEFRAMES &timeframes[], int db_handle);
    
    //--- Button Creation
    void CreateCopyButton(void);
    void CreateGenerateTestDBsButton(void);
    void CreateDeleteTestDBsButton(void);
    
    //--- Event Handling
    void HandleChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
    
private:
    //--- Panel Creation Helpers
    void CreatePanelHeader(int y_pos);
    void CreateDatabaseColumn(string title, int db_handle, string db_name, int x_pos, int y_pos, color header_color);
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
        for(int t = 0; t < ArraySize(timeframes); t++) {
            string symbol = symbols[s];
            ENUM_TIMEFRAMES timeframe = timeframes[t];
            string tf_string = EnumToString(timeframe);
            
            // Get broker data count
            int broker_bars = iBars(symbol, timeframe);
            
            // Get database data count
            int db_bars = 0;
            string sql = StringFormat("SELECT COUNT(*) FROM candle_data WHERE symbol='%s' AND timeframe='%s'", 
                                    symbol, tf_string);
            int request = DatabasePrepare(db_handle, sql);            if(request != INVALID_HANDLE) {
                if(DatabaseRead(request)) {
                    long count_value;
                    if(DatabaseColumnLong(request, 0, count_value)) {
                        db_bars = (int)count_value;
                    }
                }
                DatabaseFinalize(request);
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
{    // Basic cleanup of main panel objects
    ObjectDelete(0, m_object_prefix + "Panel");
    ObjectDelete(0, m_object_prefix + "Mode");
    ObjectDelete(0, m_object_prefix + "SystemStatus");
    ObjectDelete(0, m_object_prefix + "Separator");
    ObjectDelete(0, m_object_prefix + "CopyButton");ObjectDelete(0, m_object_prefix + "GenerateButton");
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
