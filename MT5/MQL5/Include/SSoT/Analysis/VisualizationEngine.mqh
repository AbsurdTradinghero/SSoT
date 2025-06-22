//+------------------------------------------------------------------+
//| VisualizationEngine.mqh - Modern GUI Visualization System       |
//| Creates interactive displays for class analysis data            |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"

#include <SSoT/Analysis/ClassAnalyzer.mqh>

//--- GUI Configuration Constants
#define GUI_MARGIN          10
#define GUI_BUTTON_HEIGHT   25
#define GUI_BUTTON_WIDTH    120
#define GUI_HEADER_HEIGHT   30
#define GUI_ROW_HEIGHT      20
#define GUI_COLUMN_WIDTH    150

//+------------------------------------------------------------------+
//| Visualization Engine - Modern GUI System                        |
//+------------------------------------------------------------------+
class CVisualizationEngine
{
private:
    SVisualizationConfig m_config;         // Configuration
    bool                 m_initialized;    // Initialization flag
    int                  m_current_page;   // Current display page
    string               m_selected_class; // Currently selected class
    
    // GUI Object Management
    string               m_gui_objects[];  // Tracked GUI objects
    
    // Layout methods
    bool                 CreateMainLayout();
    bool                 CreateClassList(SAnalysisData &data, int start_y);
    bool                 CreateMethodDetails(SClassInfo &class_info, int start_y);
    bool                 CreateNavigationButtons(int start_y);
    
    // Object management
    void                 AddTrackedObject(string object_name);
    void                 RemoveAllObjects();
    
    // Display helpers
    string               FormatMethodSignature(SMethodInfo &method);
    color                GetMethodColor(SMethodInfo &method);
    
public:
    // Constructor/Destructor
                        CVisualizationEngine();
                       ~CVisualizationEngine();
    
    // Core interface
    bool                Initialize(SVisualizationConfig &config);
    bool                UpdateDisplay(SAnalysisData &data);
    void                HandleChartEvent(int id, long lparam, double dparam, string sparam);
    void                Cleanup();
    
    // Navigation
    void                SelectClass(string class_name);
    void                NextPage();
    void                PreviousPage();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CVisualizationEngine::CVisualizationEngine()
{
    m_initialized = false;
    m_current_page = 0;
    m_selected_class = "";
    ArrayResize(m_gui_objects, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CVisualizationEngine::~CVisualizationEngine()
{
    Cleanup();
}

//+------------------------------------------------------------------+
//| Initialize visualization engine                                  |
//+------------------------------------------------------------------+
bool CVisualizationEngine::Initialize(SVisualizationConfig &config)
{
    m_config = config;
    m_initialized = true;
    
    Print("✅ VisualizationEngine initialized");
    Print("🎨 Modern GUI: ", m_config.enable_modern_gui ? "ENABLED" : "DISABLED");
    
    return CreateMainLayout();
}

//+------------------------------------------------------------------+
//| Create main GUI layout                                           |
//+------------------------------------------------------------------+
bool CVisualizationEngine::CreateMainLayout()
{
    RemoveAllObjects();
    
    // Create main title
    string title_name = "SSoT_Analyzer_Title";
    if(ObjectCreate(0, title_name, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, title_name, OBJPROP_XDISTANCE, GUI_MARGIN);
        ObjectSetInteger(0, title_name, OBJPROP_YDISTANCE, GUI_MARGIN);
        ObjectSetString(0, title_name, OBJPROP_TEXT, "SSoT Class Analyzer v1.00");
        ObjectSetInteger(0, title_name, OBJPROP_FONTSIZE, 14);
        ObjectSetInteger(0, title_name, OBJPROP_COLOR, m_config.primary_color);
        AddTrackedObject(title_name);
    }
    
    // Create status label
    string status_name = "SSoT_Analyzer_Status";
    if(ObjectCreate(0, status_name, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, status_name, OBJPROP_XDISTANCE, GUI_MARGIN);
        ObjectSetInteger(0, status_name, OBJPROP_YDISTANCE, GUI_MARGIN + GUI_HEADER_HEIGHT);
        ObjectSetString(0, status_name, OBJPROP_TEXT, "Ready for analysis...");
        ObjectSetInteger(0, status_name, OBJPROP_FONTSIZE, 10);
        ObjectSetInteger(0, status_name, OBJPROP_COLOR, m_config.secondary_color);
        AddTrackedObject(status_name);
    }
    
    ChartRedraw();
    return true;
}

//+------------------------------------------------------------------+
//| Update display with analysis data                               |
//+------------------------------------------------------------------+
bool CVisualizationEngine::UpdateDisplay(SAnalysisData &data)
{
    if(!m_initialized) return false;
    
    // Update status
    string status_text = StringFormat("Classes: %d | Methods: %d | Updated: %s", 
                                     data.total_classes, 
                                     data.total_methods,
                                     TimeToString(data.analysis_time, TIME_MINUTES));
    
    ObjectSetString(0, "SSoT_Analyzer_Status", OBJPROP_TEXT, status_text);
    
    // Create class list starting below header
    int start_y = GUI_MARGIN + GUI_HEADER_HEIGHT + 30;
    CreateClassList(data, start_y);
    
    // If a class is selected, show its methods
    if(m_selected_class != "")
    {
        for(int i = 0; i < ArraySize(data.classes); i++)
        {
            if(data.classes[i].name == m_selected_class)
            {
                CreateMethodDetails(data.classes[i], start_y + 200);
                break;
            }
        }
    }
    
    ChartRedraw();
    return true;
}

//+------------------------------------------------------------------+
//| Create class list display                                        |
//+------------------------------------------------------------------+
bool CVisualizationEngine::CreateClassList(SAnalysisData &data, int start_y)
{
    // Remove existing class objects
    for(int i = ArraySize(m_gui_objects) - 1; i >= 0; i--)
    {
        if(StringFind(m_gui_objects[i], "Class_") == 0)
        {
            ObjectDelete(0, m_gui_objects[i]);
        }
    }
    
    // Create class header
    string header_name = "Class_List_Header";
    if(ObjectCreate(0, header_name, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, header_name, OBJPROP_XDISTANCE, GUI_MARGIN);
        ObjectSetInteger(0, header_name, OBJPROP_YDISTANCE, start_y);
        ObjectSetString(0, header_name, OBJPROP_TEXT, "Classes:");
        ObjectSetInteger(0, header_name, OBJPROP_FONTSIZE, 12);
        ObjectSetInteger(0, header_name, OBJPROP_COLOR, m_config.primary_color);
        AddTrackedObject(header_name);
    }
    
    // Display classes
    int display_count = MathMin(ArraySize(data.classes), m_config.max_classes_per_page);
    for(int i = 0; i < display_count; i++)
    {
        string class_button_name = "Class_Button_" + IntegerToString(i);
        int y_pos = start_y + GUI_ROW_HEIGHT + (i * GUI_ROW_HEIGHT);
        
        if(ObjectCreate(0, class_button_name, OBJ_BUTTON, 0, 0, 0))
        {
            ObjectSetInteger(0, class_button_name, OBJPROP_XDISTANCE, GUI_MARGIN + 20);
            ObjectSetInteger(0, class_button_name, OBJPROP_YDISTANCE, y_pos);
            ObjectSetInteger(0, class_button_name, OBJPROP_XSIZE, GUI_BUTTON_WIDTH * 2);
            ObjectSetInteger(0, class_button_name, OBJPROP_YSIZE, GUI_ROW_HEIGHT);
            
            string class_text = StringFormat("%s (%d methods)", 
                                            data.classes[i].name, 
                                            ArraySize(data.classes[i].methods));
            ObjectSetString(0, class_button_name, OBJPROP_TEXT, class_text);
            
            // Highlight selected class
            if(data.classes[i].name == m_selected_class)
            {
                ObjectSetInteger(0, class_button_name, OBJPROP_BGCOLOR, m_config.primary_color);
                ObjectSetInteger(0, class_button_name, OBJPROP_COLOR, clrWhite);
            }
            else
            {
                ObjectSetInteger(0, class_button_name, OBJPROP_BGCOLOR, m_config.secondary_color);
                ObjectSetInteger(0, class_button_name, OBJPROP_COLOR, clrBlack);
            }
            
            AddTrackedObject(class_button_name);
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Create method details display                                   |
//+------------------------------------------------------------------+
bool CVisualizationEngine::CreateMethodDetails(SClassInfo &class_info, int start_y)
{
    // Method details header
    string methods_header = "Methods_Header";
    if(ObjectCreate(0, methods_header, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, methods_header, OBJPROP_XDISTANCE, GUI_MARGIN);
        ObjectSetInteger(0, methods_header, OBJPROP_YDISTANCE, start_y);
        string header_text = StringFormat("Methods for %s:", class_info.name);
        ObjectSetString(0, methods_header, OBJPROP_TEXT, header_text);
        ObjectSetInteger(0, methods_header, OBJPROP_FONTSIZE, 12);
        ObjectSetInteger(0, methods_header, OBJPROP_COLOR, m_config.primary_color);
        AddTrackedObject(methods_header);
    }
    
    // Display methods
    for(int i = 0; i < ArraySize(class_info.methods); i++)
    {
        string method_name = "Method_" + IntegerToString(i);
        int y_pos = start_y + GUI_ROW_HEIGHT + (i * GUI_ROW_HEIGHT);
        
        if(ObjectCreate(0, method_name, OBJ_LABEL, 0, 0, 0))
        {
            ObjectSetInteger(0, method_name, OBJPROP_XDISTANCE, GUI_MARGIN + 20);
            ObjectSetInteger(0, method_name, OBJPROP_YDISTANCE, y_pos);
            
            string method_text = FormatMethodSignature(class_info.methods[i]);
            ObjectSetString(0, method_name, OBJPROP_TEXT, method_text);
            ObjectSetInteger(0, method_name, OBJPROP_FONTSIZE, 9);
            ObjectSetInteger(0, method_name, OBJPROP_COLOR, GetMethodColor(class_info.methods[i]));
            AddTrackedObject(method_name);
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Handle chart events                                              |
//+------------------------------------------------------------------+
void CVisualizationEngine::HandleChartEvent(int id, long lparam, double dparam, string sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        // Handle class button clicks
        if(StringFind(sparam, "Class_Button_") == 0)
        {
            // Extract class index and select it
            string index_str = StringSubstr(sparam, 13); // Remove "Class_Button_"
            int class_index = (int)StringToInteger(index_str);
            
            // This would need access to current data to get class name
            // For now, just print the click
            Print("Class button clicked: ", sparam, " (index: ", class_index, ")");
        }
    }
}

//+------------------------------------------------------------------+
//| Helper: Format method signature for display                     |
//+------------------------------------------------------------------+
string CVisualizationEngine::FormatMethodSignature(SMethodInfo &method)
{
    string visibility = method.is_public ? "+" : "-";
    string static_flag = method.is_static ? "static " : "";
    
    return StringFormat("%s %s%s %s(%s)", 
                       visibility, 
                       static_flag,
                       method.return_type, 
                       method.name, 
                       method.parameters);
}

//+------------------------------------------------------------------+
//| Helper: Get color for method based on properties               |
//+------------------------------------------------------------------+
color CVisualizationEngine::GetMethodColor(SMethodInfo &method)
{
    if(!method.is_public) return clrGray;        // Private methods
    if(method.is_static) return clrBlue;         // Static methods
    if(method.is_virtual) return clrGreen;       // Virtual methods
    return clrBlack;                             // Regular public methods
}

//+------------------------------------------------------------------+
//| Add object to tracking list                                     |
//+------------------------------------------------------------------+
void CVisualizationEngine::AddTrackedObject(string object_name)
{
    int size = ArraySize(m_gui_objects);
    ArrayResize(m_gui_objects, size + 1);
    m_gui_objects[size] = object_name;
}

//+------------------------------------------------------------------+
//| Remove all GUI objects                                           |
//+------------------------------------------------------------------+
void CVisualizationEngine::RemoveAllObjects()
{
    for(int i = 0; i < ArraySize(m_gui_objects); i++)
    {
        ObjectDelete(0, m_gui_objects[i]);
    }
    ArrayResize(m_gui_objects, 0);
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Cleanup visualization engine                                     |
//+------------------------------------------------------------------+
void CVisualizationEngine::Cleanup()
{
    RemoveAllObjects();
    m_initialized = false;
    Print("🧹 VisualizationEngine cleaned up");
}

//+------------------------------------------------------------------+
//| Select a specific class for detailed view                       |
//+------------------------------------------------------------------+
void CVisualizationEngine::SelectClass(string class_name)
{
    m_selected_class = class_name;
    Print("🎯 Selected class: ", class_name);
}
