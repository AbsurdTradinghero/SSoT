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
    void ForceCleanupAllSSoTObjects(void);
    
    //--- Database Display Methods
    void CreateFullDatabaseDisplay(bool test_mode, int main_db, int test_input_db, int test_output_db);
    void CreateDatabaseInfoDisplay(bool test_mode, int main_db, int test_input_db, int test_output_db);
    void CreateCandleCountDisplay(bool test_mode, int main_db, int test_input_db, int test_output_db);
    
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
    CleanupVisualPanel();
    
    // Create background panel
    string panel_name = m_object_prefix + "Panel";
    if(ObjectFind(0, panel_name) < 0) {
        ObjectCreate(0, panel_name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
        ObjectSetInteger(0, panel_name, OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, panel_name, OBJPROP_YDISTANCE, 30);
        ObjectSetInteger(0, panel_name, OBJPROP_XSIZE, 1200);
        ObjectSetInteger(0, panel_name, OBJPROP_YSIZE, 450);
        ObjectSetInteger(0, panel_name, OBJPROP_BGCOLOR, clrDarkSlateGray);
        ObjectSetInteger(0, panel_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, panel_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, panel_name, OBJPROP_COLOR, clrSilver);
        ObjectSetInteger(0, panel_name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, panel_name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, panel_name, OBJPROP_BACK, true);
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
    } else {
        // Live Mode: Show only main database (centered)
        CreateDatabaseColumn("LIVE DATABASE", main_db, "sourcedb.sqlite", col2_x, start_y, clrLime);
    }
    
    // Create action buttons
    CreateCopyButton();
    CreateGenerateTestDBsButton();
    CreateDeleteTestDBsButton();
    
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
    
    ObjectSetInteger(0, button_name, OBJPROP_XDISTANCE, 20);
    ObjectSetInteger(0, button_name, OBJPROP_YDISTANCE, 400);
    ObjectSetInteger(0, button_name, OBJPROP_XSIZE, 120);
    ObjectSetInteger(0, button_name, OBJPROP_YSIZE, 25);
    ObjectSetInteger(0, button_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, button_name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, button_name, OBJPROP_BGCOLOR, clrBlue);
    ObjectSetInteger(0, button_name, OBJPROP_BORDER_COLOR, clrGray);
    ObjectSetString(0, button_name, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, button_name, OBJPROP_FONTSIZE, 9);
    ObjectSetString(0, button_name, OBJPROP_TEXT, "Copy to Clipboard");
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
        ObjectSetInteger(0, obj, OBJPROP_HIDDEN, false);
    }
}

//+------------------------------------------------------------------+
//| Cleanup all objects                                             |
//+------------------------------------------------------------------+
void CVisualDisplay::CleanupAllObjects(void)
{
    // Basic cleanup of main panel objects
    ObjectDelete(0, m_object_prefix + "Panel");
    ObjectDelete(0, m_object_prefix + "Mode");
    ObjectDelete(0, m_object_prefix + "CopyButton");
    ObjectDelete(0, m_object_prefix + "GenerateButton");
    ObjectDelete(0, m_object_prefix + "DeleteButton");
}
