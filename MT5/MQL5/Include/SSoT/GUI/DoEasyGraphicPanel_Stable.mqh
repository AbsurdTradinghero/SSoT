//+------------------------------------------------------------------+
//| DoEasyGraphicPanel.mqh                                           |
//| Phase 3: Clean and Stable DoEasy WForms Implementation          |
//| Author: Marton (AI Engineer)                                     |
//| Created: June 21, 2025                                           |
//+------------------------------------------------------------------+
#property copyright "Marton (AI Engineer)"
#property version   "3.01"

// SSoTAnalysisEngine include removed - using clean panel only
#include <DoEasy\Engine.mqh>
#include <DoEasy\Objects\Graph\WForms\Containers\Panel.mqh>
#include <DoEasy\Objects\Graph\WForms\Containers\TabControl.mqh>
#include <DoEasy\Objects\Graph\WForms\Common Controls\Button.mqh>
#include <DoEasy\Objects\Graph\WForms\Common Controls\Label.mqh>

//+------------------------------------------------------------------+
//| DoEasy Graphic Panel Class - Clean Stable Implementation        |
//+------------------------------------------------------------------+
class CDoEasyGraphicPanel
{
private:
    // DoEasy engine reference
    CEngine* m_engine;
    
    // DoEasy WForms components
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

    // DoEasy component creation methods
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
    
    // Event handling methods
    void HandleButtonClick(int button_index);
    void HandleTabChange(int tab_index);
    
    // Legacy compatibility methods
    bool CreateSystemTabs() { m_tabs_created = true; return true; }
    bool CreateToolbar() { return true; }
    
    // Tab control methods
    void SelectTab(int tab_index);
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
    
    Print("DoEasyGraphicPanel Stable Version constructor completed");
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CDoEasyGraphicPanel::~CDoEasyGraphicPanel()
{
    Hide();
    
    // Clean up DoEasy WForms components
    if (m_status_label != NULL)
    {
        delete m_status_label;
        m_status_label = NULL;
    }
    
    for (int i = 0; i < 4; i++)
    {
        if (m_buttons[i] != NULL)
        {
            delete m_buttons[i];
            m_buttons[i] = NULL;
        }
    }
    
    if (m_title_label != NULL)
    {
        delete m_title_label;
        m_title_label = NULL;
    }
    
    if (m_tab_control != NULL)
    {
        delete m_tab_control;
        m_tab_control = NULL;
    }
    
    if (m_main_panel != NULL)
    {
        delete m_main_panel;
        m_main_panel = NULL;
    }
    
    Print("DoEasyGraphicPanel Stable Version destructor completed");
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
    
    Print("✅ DoEasyGraphicPanel Stable Version initialized successfully");
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
    
    Print("🚀 Creating DoEasy WForms components (Stable Version)...");
    
    // Create DoEasy main panel
    if(!CreateDoEasyMainPanel())
    {
        Print("❌ Failed to create DoEasy main panel");
        return false;
    }
    
    // Create DoEasy tab control
    if(!CreateDoEasyTabControl())
    {
        Print("❌ Failed to create DoEasy tab control");
        return false;
    }
    
    // Create DoEasy toolbar with buttons
    if(!CreateDoEasyToolbar())
    {
        Print("❌ Failed to create DoEasy toolbar");
        return false;
    }
    
    // Create DoEasy status bar
    if(!CreateDoEasyStatusBar())
    {
        Print("❌ Failed to create DoEasy status bar");
        return false;
    }
    
    m_visible = true;
    
    // Select the first tab by default
    SelectTab(0);
    
    Print("✅ DoEasy WForms components created successfully (Stable Version)!");
    
    return true;
}

//+------------------------------------------------------------------+
//| Create DoEasy main panel component                               |
//+------------------------------------------------------------------+
bool CDoEasyGraphicPanel::CreateDoEasyMainPanel()
{
    Print("📱 Creating DoEasy main panel...");
    
    // Create DoEasy CPanel
    m_main_panel = new CPanel(0, 0, "SSoT_Panel", m_x_pos, m_y_pos, m_width, m_height);
    
    if (m_main_panel == NULL)
    {
        Print("❌ Failed to create DoEasy CPanel");
        return false;
    }
    
    // Configure the panel properties
    m_main_panel.SetBorderStyle(FRAME_STYLE_SIMPLE);
    m_main_panel.SetBorderSizeAll(1);
    m_main_panel.SetBorderColor(clrBlack, true);
    m_main_panel.SetBackgroundColor(clrLightGray, true);
    
    // Make the panel visible
    m_main_panel.Show();
    
    // Create title label
    m_title_label = new CLabel(0, 0, "SSoT_Title", 10, 10, 200, 20);
    if (m_title_label != NULL)
    {
        m_title_label.SetText("SSoT Analyzer - DoEasy WForms (Stable)");
        m_title_label.SetForeColor(clrBlack, true);
        m_title_label.SetFontSize(10);
        m_title_label.Show();
    }
    
    Print("✅ DoEasy main panel created and shown");
    return true;
}

//+------------------------------------------------------------------+
//| Create DoEasy tab control component                              |
//+------------------------------------------------------------------+
bool CDoEasyGraphicPanel::CreateDoEasyTabControl()
{
    Print("📑 Creating DoEasy tab control...");
    
    if (m_main_panel == NULL)
    {
        Print("❌ Main panel must be created first");
        return false;
    }
    
    // Create DoEasy CTabControl
    m_tab_control = new CTabControl(0, 0, "SSoT_Tabs", 10, 35, m_width - 20, m_height - 80);
    
    if (m_tab_control == NULL)
    {
        Print("❌ Failed to create DoEasy CTabControl");
        return false;
    }
    
    // Add tab pages using CreateTabPages method
    string tabs[] = {"Analysis", "Classes", "Database", "Settings"};
    bool success = m_tab_control.CreateTabPages(ArraySize(tabs), 0, 80, 25, "");
    if (!success)
    {
        Print("❌ Failed to create tab pages");
        return false;
    }
    
    // Set tab text only - keep default DoEasy formatting for stability
    for(int i = 0; i < ArraySize(tabs); i++)
    {
        CTabHeader* header = m_tab_control.GetTabHeader(i);
        if(header != NULL)
        {
            header.SetText(tabs[i]);
            Print("📑 Tab ", i, " set up: '", tabs[i], "'");
        }
    }
    
    m_tabs_created = true;
    
    Print("✅ DoEasy tab control created with ", ArraySize(tabs), " tabs");
    return true;
}

//+------------------------------------------------------------------+
//| Create DoEasy toolbar component                                  |
//+------------------------------------------------------------------+
bool CDoEasyGraphicPanel::CreateDoEasyToolbar()
{
    Print("🔧 Creating DoEasy toolbar...");
    
    if (m_main_panel == NULL)
    {
        Print("❌ Main panel must be created first");
        return false;
    }
    
    // Create DoEasy CButton components
    string buttonTexts[] = {"Run", "Stop", "Reset", "Export"};
    int buttonWidth = 60;
    int buttonSpacing = 70;
    
    for (int i = 0; i < ArraySize(buttonTexts) && i < 4; i++)
    {
        m_buttons[i] = new CButton(0, 0, "SSoT_Btn_" + IntegerToString(i), 10 + (i * buttonSpacing), m_height - 35, buttonWidth, 25);
        
        if (m_buttons[i] != NULL)
        {
            m_buttons[i].SetText(buttonTexts[i]);
            m_buttons[i].SetForeColor(clrBlack, true);
            m_buttons[i].SetBackgroundColor(clrLightBlue, true);
            m_buttons[i].SetBorderStyle(FRAME_STYLE_SIMPLE);
        }
    }
    
    Print("✅ DoEasy toolbar created with ", ArraySize(buttonTexts), " buttons");
    return true;
}

//+------------------------------------------------------------------+
//| Create DoEasy status bar component                               |
//+------------------------------------------------------------------+
bool CDoEasyGraphicPanel::CreateDoEasyStatusBar()
{
    Print("📊 Creating DoEasy status bar...");
    
    if (m_main_panel == NULL)
    {
        Print("❌ Main panel must be created first");
        return false;
    }
    
    // Create DoEasy CLabel for status
    m_status_label = new CLabel(0, 0, "SSoT_Status", 10, m_height - 15, m_width - 20, 10);
    
    if (m_status_label != NULL)
    {
        m_status_label.SetText("DoEasy WForms Panel Ready - Stable Version");
        m_status_label.SetForeColor(clrBlack, true);
        m_status_label.SetFontSize(8);
        m_status_label.SetBackgroundColor(clrLightGray, true);
    }
    
    Print("✅ DoEasy status bar created");
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
    Print("✅ DoEasyGraphicPanel Stable Version shown");
}

//+------------------------------------------------------------------+
//| Hide the panel                                                   |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::Hide()
{
    // Hide DoEasy WForms components
    if (m_main_panel != NULL)
    {
        m_main_panel.Hide();
    }
    
    m_visible = false;
    Print("✅ DoEasyGraphicPanel Stable Version hidden");
}

//+------------------------------------------------------------------+
//| Handle chart events - Clean and Stable Version                  |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
    if (!m_visible || m_main_panel == NULL) return;
    
    // Pass events to DoEasy WForms components first
    if(m_main_panel != NULL)
        m_main_panel.OnChartEvent(id, lparam, dparam, sparam);
    
    if(m_tab_control != NULL)
        m_tab_control.OnChartEvent(id, lparam, dparam, sparam);
    
    // Handle object clicks
    if (id == CHARTEVENT_OBJECT_CLICK)
    {
        Print("🖱️ Object Click: '", sparam, "'");
        
        // Handle tab header clicks
        if(StringFind(sparam, "TabHeader") >= 0)
        {
            Print("🔍 TabHeader clicked: '", sparam, "'");
            
            for(int i = 0; i < 4; i++)
            {
                string tab_pattern = "TabHeader" + IntegerToString(i);
                if(StringFind(sparam, tab_pattern) >= 0)
                {
                    Print("📑 Tab ", i, " selected");
                    HandleTabChange(i);
                    return;
                }
            }
        }
        
        // Handle button clicks
        for(int i = 0; i < 4; i++)
        {
            if(m_buttons[i] != NULL && StringFind(sparam, "SSoT_Btn_" + IntegerToString(i)) >= 0)
            {
                Print("🔘 Button ", i, " clicked");
                HandleButtonClick(i);
                return;
            }
        }
    }
    
    // Forward mouse events to components
    if (id == CHARTEVENT_MOUSE_MOVE)
    {
        if(m_title_label != NULL)
            m_title_label.OnChartEvent(id, lparam, dparam, sparam);
        
        for(int i = 0; i < 4; i++)
        {
            if(m_buttons[i] != NULL)
                m_buttons[i].OnChartEvent(id, lparam, dparam, sparam);
        }
        
        if(m_status_label != NULL)
            m_status_label.OnChartEvent(id, lparam, dparam, sparam);
    }
}

//+------------------------------------------------------------------+
//| Handle tick events                                               |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::OnTick()
{
    if (!m_visible || m_main_panel == NULL) return;
    
    // DoEasy handles component updates automatically
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
    Print("📊 Status: " + message);
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
}

//+------------------------------------------------------------------+
//| Set analysis engine                                              |
//+------------------------------------------------------------------+
// SetAnalysisEngine method removed - using clean panel only

//+------------------------------------------------------------------+
//| Update panel                                                     |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::Update()
{
    if (!m_visible || m_main_panel == NULL) return;
    
    // Update all DoEasy WForms components
    m_main_panel.Redraw(true);
    Print("🔄 Panel update cycle");
}

//+------------------------------------------------------------------+
//| Update class list                                                |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::UpdateClassList(const string& class_list)
{
    Print("📋 Class list updated: ", class_list);
}

//+------------------------------------------------------------------+
//| Handle button click events                                       |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::HandleButtonClick(int button_index)
{
    string button_names[] = {"Run", "Stop", "Reset", "Export"};
    
    if(button_index < 0 || button_index >= ArraySize(button_names))
        return;
        
    string button_name = button_names[button_index];
    Print("🔘 Button '", button_name, "' (", button_index, ") clicked");
    
    // Update status
    string status_msg = "Button '" + button_name + "' clicked";
    UpdateStatus(status_msg);
    
    // Handle different button actions
    switch(button_index)
    {
        case 0: // Run
            if(m_analysis_engine != NULL)
            {
                Print("▶️ Starting analysis...");
                UpdateStatus("Analysis started");
            }
            break;
            
        case 1: // Stop
            if(m_analysis_engine != NULL)
            {
                Print("⏹️ Stopping analysis...");
                UpdateStatus("Analysis stopped");
            }
            break;
            
        case 2: // Reset
            Print("🔄 Resetting system...");
            UpdateStatus("System reset");
            break;
            
        case 3: // Export
            Print("📤 Exporting results...");
            UpdateStatus("Exporting results");
            break;
    }
}

//+------------------------------------------------------------------+
//| Handle tab change events - Clean and Stable Version             |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::HandleTabChange(int tab_index)
{
    string tab_names[] = {"Analysis", "Classes", "Database", "Settings"};
    
    if(tab_index < 0 || tab_index >= ArraySize(tab_names))
        return;
        
    string tab_name = tab_names[tab_index];
    Print("📑 Tab '", tab_name, "' (", tab_index, ") selected");
    
    // Update status
    string status_msg = "Active: " + tab_name + " tab";
    UpdateStatus(status_msg);
    
    // Simple tab selection using DoEasy's built-in method
    if(m_tab_control != NULL)
    {
        // Check if this tab is already selected
        int current_selected = m_tab_control.SelectedTabPageNum();
        if(current_selected == tab_index)
        {
            Print("📋 Tab ", tab_index, " already selected");
            return;
        }
        
        Print("🎯 Selecting tab ", tab_index, " (was ", current_selected, ")");
        
        // Use DoEasy's simple Select method - let DoEasy handle all the visual updates
        m_tab_control.Select(tab_index, true);
        
        Print("✅ Tab ", tab_index, " selected successfully");
    }
    
    // Handle tab-specific content
    switch(tab_index)
    {
        case 0: // Analysis tab
            Print("🔍 Analysis tab content active");
            break;
            
        case 1: // Classes tab
            Print("📚 Classes tab content active");
            break;
            
        case 2: // Database tab
            Print("🗄️ Database tab content active");
            break;
            
        case 3: // Settings tab
            Print("⚙️ Settings tab content active");
            break;
    }
}

//+------------------------------------------------------------------+
//| Select a tab programmatically                                    |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::SelectTab(int tab_index)
{
    if(m_tab_control == NULL || tab_index < 0 || tab_index >= m_tab_control.TabPages())
        return;
    
    Print("🎯 Programmatically selecting tab ", tab_index);
    HandleTabChange(tab_index);
}
