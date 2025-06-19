//+------------------------------------------------------------------+
//| StatusDisplay.mqh - Visual Status Display Component             |
//| Handles all visual display elements for the SSoT Control Panel |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"
#property strict

#include <SSoT/Utilities/Logger.mqh>

//+------------------------------------------------------------------+
//| Visual Status Display Class                                     |
//+------------------------------------------------------------------+
class CStatusDisplay
{
private:
    string            m_object_prefix;
    bool              m_panel_created;
    int               m_panel_x;
    int               m_panel_y;
    int               m_panel_width;
    int               m_panel_height;
    color             m_background_color;
    color             m_text_color;
    color             m_border_color;
    
    // Display elements
    string            m_status_labels[];
    string            m_status_values[];
    
public:
    //--- Constructor/Destructor
    CStatusDisplay(const string prefix = "SSoT_Status_");
    ~CStatusDisplay(void);
    
    //--- Panel Management
    bool              CreatePanel(int x = 10, int y = 50, int width = 400, int height = 300);
    void              UpdatePanel(void);
    void              DestroyPanel(void);
    bool              IsPanelCreated(void) const { return m_panel_created; }
    
    //--- Display Configuration
    void              SetPosition(int x, int y);
    void              SetSize(int width, int height);
    void              SetColors(color background, color text, color border);
    
    //--- Content Management
    void              SetStatusItem(const string label, const string value);
    void              ClearAllItems(void);
    void              AddSystemInfo(const string mode, const string health, const string uptime);
    void              AddDatabaseInfo(const string main_status, const string input_status = "", const string output_status = "");
    void              AddChainInfo(const string symbol, const string timeframe, int validated, int total);
    
    //--- Interactive Elements
    bool              CreateButton(const string name, const string text, int x, int y, int width = 100, int height = 25);
    void              UpdateButtonText(const string name, const string text);
    bool              IsButtonClicked(const string name, const string sparam);
    
    //--- Event Handling
    void              HandleChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
    
private:
    //--- Internal helpers
    void              CreatePanelBackground(void);
    void              CreatePanelBorder(void);
    void              CreateStatusLabels(void);
    void              UpdateStatusDisplay(void);
    void              CleanupObjects(void);
    string            GenerateObjectName(const string suffix);
    bool              CreateTextLabel(const string name, const string text, int x, int y, color clr = clrWhite);
    void              RepositionElements(void);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CStatusDisplay::CStatusDisplay(const string prefix)
{
    m_object_prefix = prefix;
    m_panel_created = false;
    m_panel_x = 10;
    m_panel_y = 50;
    m_panel_width = 400;
    m_panel_height = 300;
    m_background_color = C'25,25,25';    // Dark gray
    m_text_color = clrWhite;
    m_border_color = clrDodgerBlue;
    
    ArrayResize(m_status_labels, 0);
    ArrayResize(m_status_values, 0);
    
    Log(LOG_DEBUG, "StatusDisplay: Constructor completed with prefix: " + m_object_prefix);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CStatusDisplay::~CStatusDisplay(void)
{
    DestroyPanel();
}

//+------------------------------------------------------------------+
//| Create visual status panel                                      |
//+------------------------------------------------------------------+
bool CStatusDisplay::CreatePanel(int x = 10, int y = 50, int width = 400, int height = 300)
{
    if(m_panel_created) {
        // CLogger::Warning("StatusDisplay: Panel already created");
        return true;
    }
    
    m_panel_x = x;
    m_panel_y = y;
    m_panel_width = width;
    m_panel_height = height;
    
    // Create panel components
    CreatePanelBackground();
    CreatePanelBorder();
    CreateStatusLabels();
    
    // Create control buttons
    CreateButton("btn_refresh", "Refresh", m_panel_x + 10, m_panel_y + m_panel_height - 35);
    CreateButton("btn_export", "Export", m_panel_x + 120, m_panel_y + m_panel_height - 35);
    CreateButton("btn_test", "Test Flow", m_panel_x + 230, m_panel_y + m_panel_height - 35);
    
    m_panel_created = true;
    
    // CLogger::Info(StringFormat("StatusDisplay: Panel created at (%d,%d) size %dx%d", x, y, width, height));
    
    return true;
}

//+------------------------------------------------------------------+
//| Update panel content                                            |
//+------------------------------------------------------------------+
void CStatusDisplay::UpdatePanel(void)
{
    if(!m_panel_created) return;
    
    UpdateStatusDisplay();
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Destroy visual panel                                            |
//+------------------------------------------------------------------+
void CStatusDisplay::DestroyPanel(void)
{
    if(!m_panel_created) return;
    
    CleanupObjects();
    m_panel_created = false;
    
    // CLogger::Info("StatusDisplay: Panel destroyed");
}

//+------------------------------------------------------------------+
//| Set status item value                                           |
//+------------------------------------------------------------------+
void CStatusDisplay::SetStatusItem(const string label, const string value)
{
    int size = ArraySize(m_status_labels);
    
    // Check if label already exists
    for(int i = 0; i < size; i++) {
        if(m_status_labels[i] == label) {
            m_status_values[i] = value;
            return;
        }
    }
    
    // Add new item
    ArrayResize(m_status_labels, size + 1);
    ArrayResize(m_status_values, size + 1);
    m_status_labels[size] = label;
    m_status_values[size] = value;
}

//+------------------------------------------------------------------+
//| Add system information                                          |
//+------------------------------------------------------------------+
void CStatusDisplay::AddSystemInfo(const string mode, const string health, const string uptime)
{
    SetStatusItem("Mode", mode);
    SetStatusItem("Health", health);
    SetStatusItem("Uptime", uptime);
}

//+------------------------------------------------------------------+
//| Add database information                                        |
//+------------------------------------------------------------------+
void CStatusDisplay::AddDatabaseInfo(const string main_status, const string input_status = "", const string output_status = "")
{
    SetStatusItem("Main DB", main_status);
    if(input_status != "") SetStatusItem("Input DB", input_status);
    if(output_status != "") SetStatusItem("Output DB", output_status);
}

//+------------------------------------------------------------------+
//| Create button                                                   |
//+------------------------------------------------------------------+
bool CStatusDisplay::CreateButton(const string name, const string text, int x, int y, int width = 100, int height = 25)
{
    string obj_name = GenerateObjectName(name);
    
    // Create button rectangle
    if(!ObjectCreate(0, obj_name, OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
        // CLogger::Error("StatusDisplay: Failed to create button: " + name);
        return false;
    }
    
    ObjectSetInteger(0, obj_name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, obj_name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, obj_name, OBJPROP_XSIZE, width);
    ObjectSetInteger(0, obj_name, OBJPROP_YSIZE, height);
    ObjectSetInteger(0, obj_name, OBJPROP_BGCOLOR, clrDarkBlue);
    ObjectSetInteger(0, obj_name, OBJPROP_BORDER_COLOR, clrWhite);
    ObjectSetInteger(0, obj_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    
    // Create button text
    string text_name = obj_name + "_text";
    if(!ObjectCreate(0, text_name, OBJ_LABEL, 0, 0, 0)) {
        ObjectDelete(0, obj_name);
        return false;
    }
    
    ObjectSetInteger(0, text_name, OBJPROP_XDISTANCE, x + width/2);
    ObjectSetInteger(0, text_name, OBJPROP_YDISTANCE, y + height/2);
    ObjectSetInteger(0, text_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, text_name, OBJPROP_ANCHOR, ANCHOR_CENTER);
    ObjectSetInteger(0, text_name, OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, text_name, OBJPROP_TEXT, text);
    ObjectSetString(0, text_name, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, text_name, OBJPROP_FONTSIZE, 9);
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if button was clicked                                     |
//+------------------------------------------------------------------+
bool CStatusDisplay::IsButtonClicked(const string name, const string sparam)
{
    string obj_name = GenerateObjectName(name);
    return (sparam == obj_name);
}

//+------------------------------------------------------------------+
//| Create panel background                                         |
//+------------------------------------------------------------------+
void CStatusDisplay::CreatePanelBackground(void)
{
    string bg_name = GenerateObjectName("background");
    
    if(ObjectCreate(0, bg_name, OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
        ObjectSetInteger(0, bg_name, OBJPROP_XDISTANCE, m_panel_x);
        ObjectSetInteger(0, bg_name, OBJPROP_YDISTANCE, m_panel_y);
        ObjectSetInteger(0, bg_name, OBJPROP_XSIZE, m_panel_width);
        ObjectSetInteger(0, bg_name, OBJPROP_YSIZE, m_panel_height);
        ObjectSetInteger(0, bg_name, OBJPROP_BGCOLOR, m_background_color);
        ObjectSetInteger(0, bg_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    }
}

//+------------------------------------------------------------------+
//| Create panel border                                             |
//+------------------------------------------------------------------+
void CStatusDisplay::CreatePanelBorder(void)
{
    string border_name = GenerateObjectName("border");
    
    if(ObjectCreate(0, border_name, OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
        ObjectSetInteger(0, border_name, OBJPROP_XDISTANCE, m_panel_x - 2);
        ObjectSetInteger(0, border_name, OBJPROP_YDISTANCE, m_panel_y - 2);
        ObjectSetInteger(0, border_name, OBJPROP_XSIZE, m_panel_width + 4);
        ObjectSetInteger(0, border_name, OBJPROP_YSIZE, m_panel_height + 4);
        ObjectSetInteger(0, border_name, OBJPROP_BGCOLOR, m_border_color);
        ObjectSetInteger(0, border_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    }
}

//+------------------------------------------------------------------+
//| Create status labels                                            |
//+------------------------------------------------------------------+
void CStatusDisplay::CreateStatusLabels(void)
{
    // Create title
    string title_name = GenerateObjectName("title");
    CreateTextLabel(title_name, "SSoT Control Panel v2.00", m_panel_x + 10, m_panel_y + 10, clrYellow);
}

//+------------------------------------------------------------------+
//| Update status display                                           |
//+------------------------------------------------------------------+
void CStatusDisplay::UpdateStatusDisplay(void)
{
    int y_offset = 40;
    int line_height = 20;
    
    for(int i = 0; i < ArraySize(m_status_labels); i++) {
        string label_name = GenerateObjectName("label_" + IntegerToString(i));
        string value_name = GenerateObjectName("value_" + IntegerToString(i));
        
        // Create or update label
        if(ObjectFind(0, label_name) < 0) {
            CreateTextLabel(label_name, m_status_labels[i] + ":", m_panel_x + 10, m_panel_y + y_offset + (i * line_height));
        }
        
        // Create or update value
        if(ObjectFind(0, value_name) < 0) {
            CreateTextLabel(value_name, m_status_values[i], m_panel_x + 150, m_panel_y + y_offset + (i * line_height), clrLightGreen);
        } else {
            ObjectSetString(0, value_name, OBJPROP_TEXT, m_status_values[i]);
        }
    }
}

//+------------------------------------------------------------------+
//| Create text label                                               |
//+------------------------------------------------------------------+
bool CStatusDisplay::CreateTextLabel(const string name, const string text, int x, int y, color clr = clrWhite)
{
    if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0)) {
        return false;
    }
    
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
    
    return true;
}

//+------------------------------------------------------------------+
//| Generate object name with prefix                                |
//+------------------------------------------------------------------+
string CStatusDisplay::GenerateObjectName(const string suffix)
{
    return m_object_prefix + suffix;
}

//+------------------------------------------------------------------+
//| Cleanup all objects                                             |
//+------------------------------------------------------------------+
void CStatusDisplay::CleanupObjects(void)
{
    // Remove all objects with our prefix
    int total = ObjectsTotal(0, -1, -1);
    for(int i = total - 1; i >= 0; i--) {
        string obj_name = ObjectName(0, i, -1, -1);
        if(StringFind(obj_name, m_object_prefix) == 0) {
            ObjectDelete(0, obj_name);
        }
    }
    
    ChartRedraw();
}
