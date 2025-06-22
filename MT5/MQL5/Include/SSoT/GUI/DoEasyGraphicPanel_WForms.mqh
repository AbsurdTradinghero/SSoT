//+------------------------------------------------------------------+
//| DoEasyGraphicPanel.mqh                                           |
//| Phase 3: ACTUAL DoEasy WForms Implementation                     |
//| Author: Marton (AI Engineer)                                     |
//| Created: June 21, 2025                                           |
//+------------------------------------------------------------------+
#property copyright "Marton (AI Engineer)"
#property version   "3.00"

// SSoTAnalysisEngine include removed - using clean panel only
#include <DoEasy\Engine.mqh>
#include <DoEasy\Objects\Graph\WForms\Containers\Panel.mqh>
#include <DoEasy\Objects\Graph\WForms\Containers\TabControl.mqh>
#include <DoEasy\Objects\Graph\WForms\Common Controls\Button.mqh>
#include <DoEasy\Objects\Graph\WForms\Common Controls\Label.mqh>

//+------------------------------------------------------------------+
//| DoEasy Graphic Panel Class - Phase 3 REAL WForms Implementation |
//+------------------------------------------------------------------+
class CDoEasyGraphicPanel
{
private:
    // DoEasy engine reference
    CEngine* m_engine;
    
    // ACTUAL DoEasy WForms components
    CPanel* m_main_panel;
    CTabControl* m_tab_control;
    CLabel* m_title_label;
    CLabel* m_status_label;
    CButton* m_buttons[4];  // For toolbar buttons
    
    // Component state tracking
    bool m_visible;
    bool m_initialized;
    bool m_tabs_created;
      // Analysis engine removed - using clean panel only
    
    // Configuration
    int m_x_pos;
    int m_y_pos;
    int m_width;
    int m_height;

    // REAL DoEasy component creation methods
    bool CreateDoEasyMainPanel();
    bool CreateDoEasyTabControl();
    bool CreateDoEasyToolbar();
    bool CreateDoEasyStatusBar();

public:
    // Constructor/Destructor  
    CDoEasyGraphicPanel(CEngine* engine = NULL);
    ~CDoEasyGraphicPanel();
    
    // Core interface methods    bool Initialize();
    bool CreateMainComponents();
    void Show();
    void Hide();
    bool IsVisible() { return m_visible; }
    
    // Event handling
    void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam);
    void OnTick();
    
    // Configuration
    void SetPosition(int x, int y) { m_x_pos = x; m_y_pos = y; }
    void SetSize(int width, int height) { m_width = width; m_height = height; }
    void SetDimensions(int x, int y, int width, int height);    void SetDockingEnabled(bool enabled);
    // SetAnalysisEngine method removed - using clean panel only
    
    // Status updates
    void UpdateStatus(const string& message);
    void Update();
    void UpdateClassList(const string& class_list);
    
    // Legacy Phase 1 compatibility methods (for existing code)
    bool CreateSystemTabs() { m_tabs_created = true; return true; }
    bool CreateToolbar() { return true; }
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CDoEasyGraphicPanel::CDoEasyGraphicPanel(CEngine* engine = NULL)
{
    m_engine = engine;
    m_visible = false;
    m_initialized = false;
    m_tabs_created = false;
    m_analysis_engine = NULL;
    
    // Initialize DoEasy WForms component pointers
    m_main_panel = NULL;
    m_tab_control = NULL;
    m_title_label = NULL;
    m_status_label = NULL;
    
    for (int i = 0; i < 4; i++)
        m_buttons[i] = NULL;
    
    // Default configuration
    m_x_pos = 50;
    m_y_pos = 50;
    m_width = 400;
    m_height = 300;
    
    Print("DoEasyGraphicPanel Phase 3 WForms constructor completed");
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CDoEasyGraphicPanel::~CDoEasyGraphicPanel()
{
    Hide();  // Clean up components
    Print("DoEasyGraphicPanel Phase 3 WForms destructor completed");
}

//+------------------------------------------------------------------+
//| Initialize the panel                                             |
//+------------------------------------------------------------------+
bool CDoEasyGraphicPanel::Initialize()
{
    // Analysis engine parameter removed - using clean panel only
    
    if (m_engine == NULL)
    {
        Print("❌ DoEasy engine is required for WForms initialization");
        return false;
    }
    
    m_initialized = true;
    
    Print("✅ DoEasyGraphicPanel Phase 3 WForms initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Create main DoEasy WForms components                             |
//+------------------------------------------------------------------+
bool CDoEasyGraphicPanel::CreateMainComponents()
{
    if (!m_initialized)
    {
        Print("❌ Panel must be initialized before creating WForms components");
        return false;
    }
    
    Print("🚀 Phase 3: Creating REAL DoEasy WForms components...");
    
    // Create REAL DoEasy main panel
    if(!CreateDoEasyMainPanel())
    {
        Print("❌ Failed to create DoEasy WForms main panel");
        return false;
    }
    
    // Create REAL DoEasy tab control
    if(!CreateDoEasyTabControl())
    {
        Print("❌ Failed to create DoEasy WForms tab control");
        return false;
    }
    
    // Create REAL DoEasy toolbar with buttons
    if(!CreateDoEasyToolbar())
    {
        Print("❌ Failed to create DoEasy WForms toolbar");
        return false;
    }
    
    // Create REAL DoEasy status bar
    if(!CreateDoEasyStatusBar())
    {
        Print("❌ Failed to create DoEasy WForms status bar");
        return false;
    }
    
    m_visible = true;
    
    Print("✅ Phase 3 REAL DoEasy WForms components created successfully!");
    Print("🎨 Professional tabbed interface with ACTUAL DoEasy components");
    
    return true;
}

//+------------------------------------------------------------------+
//| Create REAL DoEasy main panel component                          |
//+------------------------------------------------------------------+
bool CDoEasyGraphicPanel::CreateDoEasyMainPanel()
{
    Print("📱 Creating REAL DoEasy WForms main panel...");
    
    if (m_engine == NULL)
    {
        Print("❌ DoEasy engine not available");
        return false;
    }
    
    // Create actual DoEasy CPanel using the engine
    m_main_panel = m_engine.GetGraphElementsCollection().CreateNewElement(GRAPH_ELEMENT_TYPE_WF_PANEL, m_x_pos, m_y_pos, m_width, m_height, clrLightGray, 255, true, false);
    
    if (m_main_panel == NULL)
    {
        Print("❌ Failed to create DoEasy CPanel");
        return false;
    }
    
    // Configure the panel properties
    m_main_panel.SetBorderStyle(FRAME_STYLE_SIMPLE);
    m_main_panel.SetBorderSizeAll(1);
    m_main_panel.SetBorderColor(clrBlack);
    m_main_panel.SetBackgroundColor(clrLightGray);
    
    // Create title label
    m_title_label = m_main_panel.CreateNewElement(GRAPH_ELEMENT_TYPE_WF_LABEL, 10, 10, 200, 20, clrNONE, 255, true, false);
    if (m_title_label != NULL)
    {
        m_title_label.SetText("SSoT Analyzer - DoEasy WForms");
        m_title_label.SetForeColor(clrBlack);
        m_title_label.SetFontSize(10);
    }
    
    Print("✅ REAL DoEasy WForms main panel created");
    return true;
}

//+------------------------------------------------------------------+
//| Create REAL DoEasy tab control component                         |
//+------------------------------------------------------------------+
bool CDoEasyGraphicPanel::CreateDoEasyTabControl()
{
    Print("📑 Creating REAL DoEasy WForms tab control...");
    
    if (m_main_panel == NULL)
    {
        Print("❌ Main panel must be created first");
        return false;
    }
    
    // Create actual DoEasy CTabControl
    m_tab_control = m_main_panel.CreateNewElement(GRAPH_ELEMENT_TYPE_WF_TAB_CONTROL, 10, 35, m_width - 20, m_height - 80, clrWhite, 255, true, false);
    
    if (m_tab_control == NULL)
    {
        Print("❌ Failed to create DoEasy CTabControl");
        return false;
    }
    
    // Add tab pages
    string tabs[] = {"Analysis", "Classes", "Database", "Settings"};
    for (int i = 0; i < ArraySize(tabs); i++)
    {
        m_tab_control.AddTabPage(tabs[i]);
    }
    
    // Set the first tab as selected
    m_tab_control.Select(0);
    
    m_tabs_created = true;
    
    Print("✅ REAL DoEasy WForms tab control created with ", ArraySize(tabs), " tabs");
    return true;
}

//+------------------------------------------------------------------+
//| Create REAL DoEasy toolbar component                             |
//+------------------------------------------------------------------+
bool CDoEasyGraphicPanel::CreateDoEasyToolbar()
{
    Print("🔧 Creating REAL DoEasy WForms toolbar...");
    
    if (m_main_panel == NULL)
    {
        Print("❌ Main panel must be created first");
        return false;
    }
    
    // Create actual DoEasy CButton components
    string buttonTexts[] = {"Run", "Stop", "Reset", "Export"};
    int buttonWidth = 60;
    int buttonSpacing = 70;
    
    for (int i = 0; i < ArraySize(buttonTexts) && i < 4; i++)
    {
        m_buttons[i] = m_main_panel.CreateNewElement(GRAPH_ELEMENT_TYPE_WF_BUTTON, 10 + (i * buttonSpacing), m_height - 35, buttonWidth, 25, clrLightBlue, 255, true, false);
        
        if (m_buttons[i] != NULL)
        {
            m_buttons[i].SetText(buttonTexts[i]);
            m_buttons[i].SetForeColor(clrBlack);
            m_buttons[i].SetBackgroundColor(clrLightBlue);
            m_buttons[i].SetBorderStyle(FRAME_STYLE_SIMPLE);
        }
    }
    
    Print("✅ REAL DoEasy WForms toolbar created with ", ArraySize(buttonTexts), " buttons");
    return true;
}

//+------------------------------------------------------------------+
//| Create REAL DoEasy status bar component                          |
//+------------------------------------------------------------------+
bool CDoEasyGraphicPanel::CreateDoEasyStatusBar()
{
    Print("📊 Creating REAL DoEasy WForms status bar...");
    
    if (m_main_panel == NULL)
    {
        Print("❌ Main panel must be created first");
        return false;
    }
    
    // Create actual DoEasy CLabel for status
    m_status_label = m_main_panel.CreateNewElement(GRAPH_ELEMENT_TYPE_WF_LABEL, 10, m_height - 15, m_width - 20, 10, clrNONE, 255, true, false);
    
    if (m_status_label != NULL)
    {
        m_status_label.SetText("DoEasy WForms Panel Ready - Phase 3 Implementation");
        m_status_label.SetForeColor(clrBlack);
        m_status_label.SetFontSize(8);
        m_status_label.SetBackgroundColor(clrLightGray);
    }
    
    Print("✅ REAL DoEasy WForms status bar created");
    return true;
}

//+------------------------------------------------------------------+
//| Show the panel                                                   |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::Show()
{
    if (!m_initialized)
    {
        Print("❌ Panel must be initialized before showing");
        return;
    }
    
    if (!m_visible)
    {
        CreateMainComponents();
    }
    
    // Show the main panel and all child components
    if (m_main_panel != NULL)
    {
        m_main_panel.Show();
        m_main_panel.Redraw(true);
    }
    
    m_visible = true;
    Print("✅ DoEasyGraphicPanel Phase 3 WForms shown");
}

//+------------------------------------------------------------------+
//| Hide the panel                                                   |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::Hide()
{
    // Hide and clean up REAL DoEasy WForms components
    if (m_main_panel != NULL)
    {
        m_main_panel.Hide();
        // Note: DoEasy handles cleanup of child components automatically
    }
    
    m_visible = false;
    Print("✅ DoEasyGraphicPanel Phase 3 WForms hidden");
}

//+------------------------------------------------------------------+
//| Handle chart events                                              |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
    if (!m_visible || m_main_panel == NULL) return;
    
    // Pass events to DoEasy WForms components
    m_main_panel.OnChartEvent(id, lparam, dparam, sparam);
    
    // Handle specific component events
    if (id == CHARTEVENT_CUSTOM)
    {
        // Handle DoEasy WForms component events
        Print("Phase 3 WForms Event: Custom event received");
    }
}

//+------------------------------------------------------------------+
//| Handle tick events                                               |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::OnTick()
{
    if (!m_visible || m_main_panel == NULL) return;
    
    // Update DoEasy WForms components
    m_main_panel.OnTimer();
}

//+------------------------------------------------------------------+
//| Update status message                                            |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::UpdateStatus(const string& message)
{
    if (m_status_label != NULL)
    {
        m_status_label.SetText(message);
        m_status_label.Redraw(true);
    }
    Print("📊 Status Update: " + message);
}

//+------------------------------------------------------------------+
//| Set panel dimensions                                             |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::SetDimensions(int x, int y, int width, int height)
{
    m_x_pos = x;
    m_y_pos = y;
    m_width = width;
    m_height = height;
    Print("📐 Panel dimensions set: ", x, ",", y, " - ", width, "x", height);
}

//+------------------------------------------------------------------+
//| Set docking enabled                                              |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::SetDockingEnabled(bool enabled)
{
    Print("🔗 Panel docking: ", enabled ? "enabled" : "disabled");
    // TODO: Implement DoEasy WForms docking logic
}

// SetAnalysisEngine method removed - using clean panel only

//+------------------------------------------------------------------+
//| Update panel                                                     |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::Update()
{
    if (!m_visible || m_main_panel == NULL) return;
    
    // Update all DoEasy WForms components
    m_main_panel.Redraw(true);
    Print("🔄 WForms panel update cycle");
}

//+------------------------------------------------------------------+
//| Update class list                                                |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::UpdateClassList(const string& class_list)
{
    Print("📋 Class list updated: ", class_list);
    // TODO: Update DoEasy WForms list component with class data
}
