//+------------------------------------------------------------------+
//| GraphicEngine.mqh - Simple Tabbed Interface for SSoT Analysis   |
//| Lightweight graphics engine with browser-like tabs              |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"

//--- Analysis data structures
#include <SSoT\Analysis\ClassAnalyzer.mqh>

//--- GUI Constants
#define GUI_MAIN_PANEL_WIDTH     800
#define GUI_MAIN_PANEL_HEIGHT    600
#define GUI_TAB_HEIGHT          30
#define GUI_BUTTON_WIDTH        80
#define GUI_BUTTON_HEIGHT       25
#define GUI_MARGIN              10  
#define GUI_CONTENT_PADDING     15
#define GUI_MAX_TABS            20

//--- Modern color scheme
#define COLOR_MODERN_BG         C'45,45,48'        // Dark background
#define COLOR_MODERN_TAB        C'63,63,70'        // Tab background
#define COLOR_MODERN_TAB_ACTIVE C'0,122,204'       // Active tab (VS Code blue)
#define COLOR_MODERN_TEXT       C'241,241,241'     // Light text
#define COLOR_MODERN_BORDER     C'104,104,104'     // Border color
#define COLOR_SUCCESS_GREEN     C'106,153,85'      // Success green
#define COLOR_ERROR_RED         C'244,71,71'       // Error red
#define COLOR_WARNING_ORANGE    C'255,206,84'      // Warning orange

//--- Tab state structure
struct SClassTab
{
    string class_name;              // Class name
    string tab_object_name;         // Tab background object name
    string tab_text_name;           // Tab text object name
    string start_button_name;       // Start/Stop button object name
    string status_label_name;       // Status label object name
    string content_bg_name;         // Content background object name
    bool is_running;                // Test running flag
    bool is_analyzed;               // Analysis completed flag
    int method_count;               // Number of methods
    int tab_x;                      // Tab X position
    int tab_width;                  // Tab width
};

//+------------------------------------------------------------------+
//| Simple Graphic Engine Class                                     |
//+------------------------------------------------------------------+
class CGraphicEngine
{
private:
    // Basic properties
    SClassTab           m_class_tabs[];         // Array of class tabs
    int                 m_active_tab_index;     // Currently active tab index
    bool                m_initialized;          // Initialization flag
    string              m_prefix;               // Object name prefix
    
    // Layout properties
    int                 m_panel_x;              // Panel X position
    int                 m_panel_y;              // Panel Y position
    long                m_chart_id;             // Chart ID
    int                 m_subwindow;            // Subwindow number
    
    // Internal methods
    bool                CreateMainPanel();
    bool                CreateClassTab(string class_name, int tab_index);
    bool                CreateTabContent(SClassTab &tab, int tab_index);
    void                UpdateTabStates();
    void                ShowTabContent(int tab_index);
    void                HideTabContent(int tab_index);
    
    // Button event handlers
    void                OnTabClick(int tab_index);
    void                OnStartButtonClick(int tab_index);
    
    // UI helpers
    string              GenerateObjectName(string base_name, int index = -1);

public:
    // Constructor/Destructor
                        CGraphicEngine();
                       ~CGraphicEngine();
    
    // Core interface
    bool                Initialize(long chart_id, int subwindow, int x, int y);
    bool                AddClassTab(string class_name, int method_count = 0);
    bool                UpdateClassInfo(string class_name, SClassInfo &class_info);
    void                Cleanup();
    
    // Tab management
    bool                SelectTab(string class_name);
    bool                SelectTab(int tab_index);
    int                 GetActiveTabIndex() { return m_active_tab_index; }
    string              GetActiveTabName();
    
    // Test control
    bool                StartClassTest(string class_name);
    bool                StopClassTest(string class_name);
    bool                IsTestRunning(string class_name);
    
    // Event handling
    void                HandleChartEvent(int id, long lparam, double dparam, string sparam);
    
    // Display updates
    void                Redraw();
    void                UpdateAllTabs();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CGraphicEngine::CGraphicEngine()
{
    m_active_tab_index = 0;
    m_initialized = false;
    m_panel_x = 10;
    m_panel_y = 30;
    m_chart_id = 0;
    m_subwindow = 0;
    m_prefix = "SSoT_GUI_";
    ArrayResize(m_class_tabs, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CGraphicEngine::~CGraphicEngine()
{
    Cleanup();
}

//+------------------------------------------------------------------+
//| Initialize the graphic engine                                    |
//+------------------------------------------------------------------+
bool CGraphicEngine::Initialize(long chart_id, int subwindow, int x, int y)
{
    if(m_initialized)
        return true;
        
    m_chart_id = chart_id;
    m_subwindow = subwindow;
    m_panel_x = x;
    m_panel_y = y;
    
    // Create main panel background
    if(!CreateMainPanel())
    {
        Print("Failed to create main panel");
        return false;
    }
    
    m_initialized = true;
    Print("GraphicEngine initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Create main panel background                                     |
//+------------------------------------------------------------------+
bool CGraphicEngine::CreateMainPanel()
{
    string panel_name = GenerateObjectName("MainPanel");
    
    // Create main panel rectangle
    if(!ObjectCreate(m_chart_id, panel_name, OBJ_RECTANGLE_LABEL, m_subwindow, 0, 0))
    {
        Print("Failed to create main panel rectangle");
        return false;
    }
    
    // Set panel properties
    ObjectSetInteger(m_chart_id, panel_name, OBJPROP_XDISTANCE, m_panel_x);
    ObjectSetInteger(m_chart_id, panel_name, OBJPROP_YDISTANCE, m_panel_y);
    ObjectSetInteger(m_chart_id, panel_name, OBJPROP_XSIZE, GUI_MAIN_PANEL_WIDTH);
    ObjectSetInteger(m_chart_id, panel_name, OBJPROP_YSIZE, GUI_MAIN_PANEL_HEIGHT);
    ObjectSetInteger(m_chart_id, panel_name, OBJPROP_BGCOLOR, COLOR_MODERN_BG);
    ObjectSetInteger(m_chart_id, panel_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(m_chart_id, panel_name, OBJPROP_BORDER_COLOR, COLOR_MODERN_BORDER);
    ObjectSetInteger(m_chart_id, panel_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(m_chart_id, panel_name, OBJPROP_BACK, false);
    ObjectSetInteger(m_chart_id, panel_name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(m_chart_id, panel_name, OBJPROP_SELECTED, false);
    ObjectSetInteger(m_chart_id, panel_name, OBJPROP_HIDDEN, true);
    
    // Create title label
    string title_name = GenerateObjectName("Title");
    if(!ObjectCreate(m_chart_id, title_name, OBJ_LABEL, m_subwindow, 0, 0))
    {
        Print("Failed to create title label");
        return false;
    }
    
    ObjectSetInteger(m_chart_id, title_name, OBJPROP_XDISTANCE, m_panel_x + GUI_MARGIN);
    ObjectSetInteger(m_chart_id, title_name, OBJPROP_YDISTANCE, m_panel_y + GUI_MARGIN);
    ObjectSetInteger(m_chart_id, title_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(m_chart_id, title_name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
    ObjectSetInteger(m_chart_id, title_name, OBJPROP_COLOR, COLOR_MODERN_TEXT);
    ObjectSetInteger(m_chart_id, title_name, OBJPROP_FONTSIZE, 12);
    ObjectSetInteger(m_chart_id, title_name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(m_chart_id, title_name, OBJPROP_SELECTED, false);
    ObjectSetInteger(m_chart_id, title_name, OBJPROP_HIDDEN, true);
    ObjectSetString(m_chart_id, title_name, OBJPROP_TEXT, "SSoT Class Analyzer");
    ObjectSetString(m_chart_id, title_name, OBJPROP_FONT, "Arial Bold");
    
    return true;
}

//+------------------------------------------------------------------+
//| Generate unique object name                                      |
//+------------------------------------------------------------------+
string CGraphicEngine::GenerateObjectName(string base_name, int index = -1)
{
    string result = m_prefix + base_name;
    if(index >= 0)
        result += "_" + IntegerToString(index);
    return result;
}

//+------------------------------------------------------------------+
//| Add a new class tab                                              |
//+------------------------------------------------------------------+  
bool CGraphicEngine::AddClassTab(string class_name, int method_count = 0)
{
    if(!m_initialized)
    {
        Print("GraphicEngine not initialized");
        return false;
    }
    
    int tab_count = ArraySize(m_class_tabs);
    if(tab_count >= GUI_MAX_TABS)
    {
        Print("Maximum number of tabs reached: ", GUI_MAX_TABS);
        return false;
    }
    
    // Check if tab already exists
    for(int i = 0; i < tab_count; i++)
    {
        if(m_class_tabs[i].class_name == class_name)
        {
            Print("Tab for class '", class_name, "' already exists");
            return false;
        }
    }
    
    // Resize array and create new tab
    ArrayResize(m_class_tabs, tab_count + 1);
    
    // Initialize tab structure
    m_class_tabs[tab_count].class_name = class_name;
    m_class_tabs[tab_count].is_running = false;
    m_class_tabs[tab_count].is_analyzed = false;
    m_class_tabs[tab_count].method_count = method_count;
    
    // Create the tab visual elements
    if(!CreateClassTab(class_name, tab_count))
    {
        ArrayResize(m_class_tabs, tab_count); // Revert on failure
        return false;
    }
    
    // Update layout
    UpdateTabStates();
    
    // Select first tab by default
    if(tab_count == 0)
    {
        SelectTab(0);
    }
    
    Print("Added tab for class: ", class_name, " (", method_count, " methods)");
    return true;
}

//+------------------------------------------------------------------+
//| Create visual elements for a class tab                          |
//+------------------------------------------------------------------+
bool CGraphicEngine::CreateClassTab(string class_name, int tab_index)
{
    int tab_width = 120;
    int tab_x = m_panel_x + GUI_MARGIN + (tab_index * (tab_width + 2));
    int tab_y = m_panel_y + 35;
    
    // Store tab position and width
    m_class_tabs[tab_index].tab_x = tab_x;
    m_class_tabs[tab_index].tab_width = tab_width;
    
    // Create tab background rectangle
    string tab_bg_name = GenerateObjectName("TabBg", tab_index);
    m_class_tabs[tab_index].tab_object_name = tab_bg_name;
    
    if(!ObjectCreate(m_chart_id, tab_bg_name, OBJ_RECTANGLE_LABEL, m_subwindow, 0, 0))
    {
        Print("Failed to create tab background for: ", class_name);
        return false;
    }
    
    ObjectSetInteger(m_chart_id, tab_bg_name, OBJPROP_XDISTANCE, tab_x);
    ObjectSetInteger(m_chart_id, tab_bg_name, OBJPROP_YDISTANCE, tab_y);
    ObjectSetInteger(m_chart_id, tab_bg_name, OBJPROP_XSIZE, tab_width);
    ObjectSetInteger(m_chart_id, tab_bg_name, OBJPROP_YSIZE, GUI_TAB_HEIGHT);
    ObjectSetInteger(m_chart_id, tab_bg_name, OBJPROP_BGCOLOR, COLOR_MODERN_TAB);
    ObjectSetInteger(m_chart_id, tab_bg_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(m_chart_id, tab_bg_name, OBJPROP_BORDER_COLOR, COLOR_MODERN_BORDER);
    ObjectSetInteger(m_chart_id, tab_bg_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(m_chart_id, tab_bg_name, OBJPROP_BACK, false);
    ObjectSetInteger(m_chart_id, tab_bg_name, OBJPROP_SELECTABLE, true);
    ObjectSetInteger(m_chart_id, tab_bg_name, OBJPROP_SELECTED, false);
    ObjectSetInteger(m_chart_id, tab_bg_name, OBJPROP_HIDDEN, true);
    
    // Create tab text label
    string tab_text_name = GenerateObjectName("TabText", tab_index);
    m_class_tabs[tab_index].tab_text_name = tab_text_name;
    
    if(!ObjectCreate(m_chart_id, tab_text_name, OBJ_LABEL, m_subwindow, 0, 0))
    {
        Print("Failed to create tab text for: ", class_name);
        return false;
    }
    
    ObjectSetInteger(m_chart_id, tab_text_name, OBJPROP_XDISTANCE, tab_x + tab_width/2);
    ObjectSetInteger(m_chart_id, tab_text_name, OBJPROP_YDISTANCE, tab_y + GUI_TAB_HEIGHT/2);
    ObjectSetInteger(m_chart_id, tab_text_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(m_chart_id, tab_text_name, OBJPROP_ANCHOR, ANCHOR_CENTER);
    ObjectSetInteger(m_chart_id, tab_text_name, OBJPROP_COLOR, COLOR_MODERN_TEXT);
    ObjectSetInteger(m_chart_id, tab_text_name, OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(m_chart_id, tab_text_name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(m_chart_id, tab_text_name, OBJPROP_SELECTED, false);
    ObjectSetInteger(m_chart_id, tab_text_name, OBJPROP_HIDDEN, true);
    ObjectSetString(m_chart_id, tab_text_name, OBJPROP_TEXT, class_name);
    ObjectSetString(m_chart_id, tab_text_name, OBJPROP_FONT, "Arial");
    
    return CreateTabContent(m_class_tabs[tab_index], tab_index);
}

//+------------------------------------------------------------------+
//| Create content area for a tab                                   |
//+------------------------------------------------------------------+
bool CGraphicEngine::CreateTabContent(SClassTab &tab, int tab_index)
{
    int content_y = m_panel_y + 70; // Below tabs
    int content_height = GUI_MAIN_PANEL_HEIGHT - 80;
    
    // Create content background
    tab.content_bg_name = GenerateObjectName("Content", tab_index);
    if(!ObjectCreate(m_chart_id, tab.content_bg_name, OBJ_RECTANGLE_LABEL, m_subwindow, 0, 0))
    {
        Print("Failed to create content background for tab: ", tab_index);
        return false;
    }
    
    ObjectSetInteger(m_chart_id, tab.content_bg_name, OBJPROP_XDISTANCE, m_panel_x + GUI_MARGIN);
    ObjectSetInteger(m_chart_id, tab.content_bg_name, OBJPROP_YDISTANCE, content_y);
    ObjectSetInteger(m_chart_id, tab.content_bg_name, OBJPROP_XSIZE, GUI_MAIN_PANEL_WIDTH - 2*GUI_MARGIN);
    ObjectSetInteger(m_chart_id, tab.content_bg_name, OBJPROP_YSIZE, content_height);
    ObjectSetInteger(m_chart_id, tab.content_bg_name, OBJPROP_BGCOLOR, COLOR_MODERN_BG);
    ObjectSetInteger(m_chart_id, tab.content_bg_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(m_chart_id, tab.content_bg_name, OBJPROP_BORDER_COLOR, COLOR_MODERN_BORDER);
    ObjectSetInteger(m_chart_id, tab.content_bg_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(m_chart_id, tab.content_bg_name, OBJPROP_BACK, false);
    ObjectSetInteger(m_chart_id, tab.content_bg_name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(m_chart_id, tab.content_bg_name, OBJPROP_SELECTED, false);
    ObjectSetInteger(m_chart_id, tab.content_bg_name, OBJPROP_HIDDEN, true);
    
    // Create Start/Stop button
    tab.start_button_name = GenerateObjectName("StartBtn", tab_index);
    if(!ObjectCreate(m_chart_id, tab.start_button_name, OBJ_RECTANGLE_LABEL, m_subwindow, 0, 0))
    {
        Print("Failed to create start button for tab: ", tab_index);
        return false;
    }
    
    ObjectSetInteger(m_chart_id, tab.start_button_name, OBJPROP_XDISTANCE, m_panel_x + GUI_MARGIN + GUI_CONTENT_PADDING);
    ObjectSetInteger(m_chart_id, tab.start_button_name, OBJPROP_YDISTANCE, content_y + GUI_CONTENT_PADDING);
    ObjectSetInteger(m_chart_id, tab.start_button_name, OBJPROP_XSIZE, GUI_BUTTON_WIDTH);
    ObjectSetInteger(m_chart_id, tab.start_button_name, OBJPROP_YSIZE, GUI_BUTTON_HEIGHT);
    ObjectSetInteger(m_chart_id, tab.start_button_name, OBJPROP_BGCOLOR, COLOR_SUCCESS_GREEN);
    ObjectSetInteger(m_chart_id, tab.start_button_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(m_chart_id, tab.start_button_name, OBJPROP_BORDER_COLOR, COLOR_MODERN_BORDER);
    ObjectSetInteger(m_chart_id, tab.start_button_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(m_chart_id, tab.start_button_name, OBJPROP_BACK, false);
    ObjectSetInteger(m_chart_id, tab.start_button_name, OBJPROP_SELECTABLE, true);
    ObjectSetInteger(m_chart_id, tab.start_button_name, OBJPROP_SELECTED, false);
    ObjectSetInteger(m_chart_id, tab.start_button_name, OBJPROP_HIDDEN, true);
    
    // Create button text
    string button_text_name = GenerateObjectName("StartBtnText", tab_index);
    if(!ObjectCreate(m_chart_id, button_text_name, OBJ_LABEL, m_subwindow, 0, 0))
    {
        Print("Failed to create start button text for tab: ", tab_index);
        return false;
    }
    
    ObjectSetInteger(m_chart_id, button_text_name, OBJPROP_XDISTANCE, m_panel_x + GUI_MARGIN + GUI_CONTENT_PADDING + GUI_BUTTON_WIDTH/2);
    ObjectSetInteger(m_chart_id, button_text_name, OBJPROP_YDISTANCE, content_y + GUI_CONTENT_PADDING + GUI_BUTTON_HEIGHT/2);
    ObjectSetInteger(m_chart_id, button_text_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(m_chart_id, button_text_name, OBJPROP_ANCHOR, ANCHOR_CENTER);
    ObjectSetInteger(m_chart_id, button_text_name, OBJPROP_COLOR, COLOR_MODERN_TEXT);
    ObjectSetInteger(m_chart_id, button_text_name, OBJPROP_FONTSIZE, 8);
    ObjectSetInteger(m_chart_id, button_text_name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(m_chart_id, button_text_name, OBJPROP_SELECTED, false);
    ObjectSetInteger(m_chart_id, button_text_name, OBJPROP_HIDDEN, true);
    ObjectSetString(m_chart_id, button_text_name, OBJPROP_TEXT, "START");
    ObjectSetString(m_chart_id, button_text_name, OBJPROP_FONT, "Arial Bold");
    
    // Create status label
    tab.status_label_name = GenerateObjectName("Status", tab_index);
    if(!ObjectCreate(m_chart_id, tab.status_label_name, OBJ_LABEL, m_subwindow, 0, 0))
    {
        Print("Failed to create status label for tab: ", tab_index);
        return false;
    }
    
    ObjectSetInteger(m_chart_id, tab.status_label_name, OBJPROP_XDISTANCE, m_panel_x + GUI_MARGIN + GUI_CONTENT_PADDING + GUI_BUTTON_WIDTH + 20);
    ObjectSetInteger(m_chart_id, tab.status_label_name, OBJPROP_YDISTANCE, content_y + GUI_CONTENT_PADDING + 5);
    ObjectSetInteger(m_chart_id, tab.status_label_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(m_chart_id, tab.status_label_name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
    ObjectSetInteger(m_chart_id, tab.status_label_name, OBJPROP_COLOR, COLOR_MODERN_TEXT);
    ObjectSetInteger(m_chart_id, tab.status_label_name, OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(m_chart_id, tab.status_label_name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(m_chart_id, tab.status_label_name, OBJPROP_SELECTED, false);
    ObjectSetInteger(m_chart_id, tab.status_label_name, OBJPROP_HIDDEN, true);
    ObjectSetString(m_chart_id, tab.status_label_name, OBJPROP_TEXT, StringFormat("Status: Ready (%d methods)", tab.method_count));
    ObjectSetString(m_chart_id, tab.status_label_name, OBJPROP_FONT, "Arial");
    
    return true;
}

//+------------------------------------------------------------------+
//| Cleanup all objects                                              |
//+------------------------------------------------------------------+
void CGraphicEngine::Cleanup()
{
    if(!m_initialized)
        return;
        
    // Delete all objects with our prefix
    ObjectsDeleteAll(m_chart_id, m_prefix, m_subwindow, OBJ_RECTANGLE_LABEL);
    ObjectsDeleteAll(m_chart_id, m_prefix, m_subwindow, OBJ_LABEL);
    
    ArrayResize(m_class_tabs, 0);
    m_initialized = false;
    
    Print("GraphicEngine cleaned up");
}

//+------------------------------------------------------------------+
//| Update tab visual states                                         |
//+------------------------------------------------------------------+
void CGraphicEngine::UpdateTabStates()
{
    int tab_count = ArraySize(m_class_tabs);
    
    for(int i = 0; i < tab_count; i++)
    {
        // Update tab background color
        color tab_color = (i == m_active_tab_index) ? COLOR_MODERN_TAB_ACTIVE : COLOR_MODERN_TAB;
        ObjectSetInteger(m_chart_id, m_class_tabs[i].tab_object_name, OBJPROP_BGCOLOR, tab_color);
        
        // Show/hide content based on active tab
        if(i == m_active_tab_index)
            ShowTabContent(i);
        else
            HideTabContent(i);
    }
    
    ChartRedraw(m_chart_id);
}

//+------------------------------------------------------------------+
//| Select tab by index                                              |
//+------------------------------------------------------------------+
bool CGraphicEngine::SelectTab(int tab_index)
{
    int tab_count = ArraySize(m_class_tabs);
    if(tab_index < 0 || tab_index >= tab_count)
        return false;
        
    m_active_tab_index = tab_index;
    UpdateTabStates();
    
    Print("Selected tab: ", m_class_tabs[tab_index].class_name);
    return true;
}

//+------------------------------------------------------------------+
//| Select tab by class name                                         |
//+------------------------------------------------------------------+
bool CGraphicEngine::SelectTab(string class_name)
{
    int tab_count = ArraySize(m_class_tabs);
    
    for(int i = 0; i < tab_count; i++)
    {
        if(m_class_tabs[i].class_name == class_name)
        {
            return SelectTab(i);
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Show content for specific tab                                    |
//+------------------------------------------------------------------+
void CGraphicEngine::ShowTabContent(int tab_index)
{
    if(tab_index < 0 || tab_index >= ArraySize(m_class_tabs))
        return;
        
    SClassTab tab = m_class_tabs[tab_index];
    
    // Show content background
    ObjectSetInteger(m_chart_id, tab.content_bg_name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
    
    // Show start button
    ObjectSetInteger(m_chart_id, tab.start_button_name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
    
    // Show button text
    string button_text_name = GenerateObjectName("StartBtnText", tab_index);
    ObjectSetInteger(m_chart_id, button_text_name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
    
    // Show status label
    ObjectSetInteger(m_chart_id, tab.status_label_name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
}

//+------------------------------------------------------------------+
//| Hide content for specific tab                                    |
//+------------------------------------------------------------------+
void CGraphicEngine::HideTabContent(int tab_index)
{
    if(tab_index < 0 || tab_index >= ArraySize(m_class_tabs))
        return;
        
    SClassTab tab = m_class_tabs[tab_index];
    
    // Hide content background
    ObjectSetInteger(m_chart_id, tab.content_bg_name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
    
    // Hide start button
    ObjectSetInteger(m_chart_id, tab.start_button_name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
    
    // Hide button text
    string button_text_name = GenerateObjectName("StartBtnText", tab_index);
    ObjectSetInteger(m_chart_id, button_text_name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
    
    // Hide status label
    ObjectSetInteger(m_chart_id, tab.status_label_name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
}

//+------------------------------------------------------------------+
//| Handle tab click event                                           |
//+------------------------------------------------------------------+
void CGraphicEngine::OnTabClick(int tab_index)
{
    if(tab_index >= 0 && tab_index < ArraySize(m_class_tabs))
    {
        SelectTab(tab_index);
        Print("Tab clicked: ", m_class_tabs[tab_index].class_name);
    }
}

//+------------------------------------------------------------------+
//| Handle start button click event                                  |
//+------------------------------------------------------------------+
void CGraphicEngine::OnStartButtonClick(int tab_index)
{    if(tab_index < 0 || tab_index >= ArraySize(m_class_tabs))
        return;
        
    // Since we can't use references, we need to access the array directly
    if(m_class_tabs[tab_index].is_running)
    {
        // Stop the test
        m_class_tabs[tab_index].is_running = false;
        
        // Update button appearance
        ObjectSetInteger(m_chart_id, m_class_tabs[tab_index].start_button_name, OBJPROP_BGCOLOR, COLOR_SUCCESS_GREEN);
        string button_text_name = GenerateObjectName("StartBtnText", tab_index);
        ObjectSetString(m_chart_id, button_text_name, OBJPROP_TEXT, "START");
        
        // Update status
        ObjectSetString(m_chart_id, m_class_tabs[tab_index].status_label_name, OBJPROP_TEXT, 
            StringFormat("Status: Stopped (%d methods)", m_class_tabs[tab_index].method_count));
        ObjectSetInteger(m_chart_id, m_class_tabs[tab_index].status_label_name, OBJPROP_COLOR, COLOR_MODERN_TEXT);
        
        Print("Stopped test for class: ", m_class_tabs[tab_index].class_name);
    }
    else
    {
        // Start the test
        m_class_tabs[tab_index].is_running = true;
        
        // Update button appearance
        ObjectSetInteger(m_chart_id, m_class_tabs[tab_index].start_button_name, OBJPROP_BGCOLOR, COLOR_ERROR_RED);
        string button_text_name = GenerateObjectName("StartBtnText", tab_index);
        ObjectSetString(m_chart_id, button_text_name, OBJPROP_TEXT, "STOP");
          // Update status
        ObjectSetString(m_chart_id, m_class_tabs[tab_index].status_label_name, OBJPROP_TEXT, 
            StringFormat("Status: Running tests... (%d methods)", m_class_tabs[tab_index].method_count));
        ObjectSetInteger(m_chart_id, m_class_tabs[tab_index].status_label_name, OBJPROP_COLOR, COLOR_SUCCESS_GREEN);
        
        Print("Started test for class: ", m_class_tabs[tab_index].class_name);
    }
    
    ChartRedraw(m_chart_id);
}

//+------------------------------------------------------------------+
//| Get active tab name                                              |
//+------------------------------------------------------------------+
string CGraphicEngine::GetActiveTabName()
{
    if(m_active_tab_index >= 0 && m_active_tab_index < ArraySize(m_class_tabs))
        return m_class_tabs[m_active_tab_index].class_name;
    return "";
}

//+------------------------------------------------------------------+
//| Start class test                                                 |
//+------------------------------------------------------------------+
bool CGraphicEngine::StartClassTest(string class_name)
{
    int tab_count = ArraySize(m_class_tabs);
    
    for(int i = 0; i < tab_count; i++)
    {
        if(m_class_tabs[i].class_name == class_name)
        {
            OnStartButtonClick(i);
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Stop class test                                                  |
//+------------------------------------------------------------------+
bool CGraphicEngine::StopClassTest(string class_name)
{
    int tab_count = ArraySize(m_class_tabs);
    
    for(int i = 0; i < tab_count; i++)
    {
        if(m_class_tabs[i].class_name == class_name && m_class_tabs[i].is_running)
        {
            OnStartButtonClick(i);
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if test is running for class                              |
//+------------------------------------------------------------------+
bool CGraphicEngine::IsTestRunning(string class_name)
{
    int tab_count = ArraySize(m_class_tabs);
    
    for(int i = 0; i < tab_count; i++)
    {
        if(m_class_tabs[i].class_name == class_name)
        {
            return m_class_tabs[i].is_running;
        }
    }
    
    return false;
}
void CGraphicEngine::Redraw() { ChartRedraw(m_chart_id); }
void CGraphicEngine::UpdateAllTabs() { ChartRedraw(m_chart_id); }

//+------------------------------------------------------------------+
//| Handle chart events (clicks, etc.)                              |
//+------------------------------------------------------------------+
void CGraphicEngine::HandleChartEvent(int id, long lparam, double dparam, string sparam)
{
    if(id != CHARTEVENT_OBJECT_CLICK)
        return;
        
    string clicked_object = sparam;
    
    // Check if a tab was clicked
    int tab_count = ArraySize(m_class_tabs);
    for(int i = 0; i < tab_count; i++)
    {
        if(clicked_object == m_class_tabs[i].tab_object_name)
        {
            OnTabClick(i);
            return;
        }
        
        // Check if start button was clicked
        if(clicked_object == m_class_tabs[i].start_button_name)
        {
            OnStartButtonClick(i);
            return;
        }
    }
}

//+------------------------------------------------------------------+
//| Update class information                                         |
//+------------------------------------------------------------------+
bool CGraphicEngine::UpdateClassInfo(string class_name, SClassInfo &class_info)
{
    int tab_count = ArraySize(m_class_tabs);
    
    for(int i = 0; i < tab_count; i++)
    {
        if(m_class_tabs[i].class_name == class_name)
        {
            m_class_tabs[i].method_count = ArraySize(class_info.methods);
            m_class_tabs[i].is_analyzed = true;
            
            Print("Updated info for class: ", class_name, " (", m_class_tabs[i].method_count, " methods)");
            return true;
        }
    }
    
    return false;
}
