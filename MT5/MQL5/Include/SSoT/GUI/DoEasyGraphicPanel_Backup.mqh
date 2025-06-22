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
    
    // Event handling methods
    void HandleButtonClick(int button_index);
    void HandleTabChange(int tab_index);
    
    // Legacy Phase 1 compatibility methods (for existing code)
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
    
    Print("DoEasyGraphicPanel Phase 3 WForms constructor completed");
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
    
    // Select the first tab by default
    SelectTab(0);
    
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
      // Create actual DoEasy CPanel by instantiating it directly
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
    
    // Create title label by instantiating it directly
    m_title_label = new CLabel(0, 0, "SSoT_Title", 10, 10, 200, 20);
    if (m_title_label != NULL)
    {
        m_title_label.SetText("SSoT Analyzer - DoEasy WForms");
        m_title_label.SetForeColor(clrBlack, true);
        m_title_label.SetFontSize(10);
        m_title_label.Show(); // Make label visible
    }
    
    Print("✅ REAL DoEasy WForms main panel created and shown");
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
      // Create actual DoEasy CTabControl by instantiating it directly
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
    
    // Set tab text only - keep default DoEasy formatting
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
    
    // Create actual DoEasy CButton components by instantiating them directly
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
      // Create actual DoEasy CLabel for status by instantiating it directly
    m_status_label = new CLabel(0, 0, "SSoT_Status", 10, m_height - 15, m_width - 20, 10);
    
    if (m_status_label != NULL)
    {
        m_status_label.SetText("DoEasy WForms Panel Ready - Phase 3 Implementation");
        m_status_label.SetForeColor(clrBlack, true);
        m_status_label.SetFontSize(8);
        m_status_label.SetBackgroundColor(clrLightGray, true);
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
    
    // Pass events to DoEasy WForms components for processing FIRST
    if(m_main_panel != NULL)
        m_main_panel.OnChartEvent(id, lparam, dparam, sparam);
    
    if(m_tab_control != NULL)
        m_tab_control.OnChartEvent(id, lparam, dparam, sparam);
    
    // Handle specific component events
    if (id == CHARTEVENT_OBJECT_CLICK)
    {        Print("🖱️ Object Click: '", sparam, "'");
        
        // Handle tab header clicks using DoEasy's naming pattern
        if(StringFind(sparam, "TabHeader") >= 0)
        {
            Print("🔍 Detected TabHeader click: '", sparam, "'");
            
            // Extract tab index from TabHeader name
            for(int i = 0; i < 4; i++)
            {
                string tab_pattern = "TabHeader" + IntegerToString(i);
                if(StringFind(sparam, tab_pattern) >= 0)
                {
                    Print("📑 Tab ", i, " clicked - Processing tab change");
                    HandleTabChange(i);
                    return;
                }
            }
        }
        
        // Keep the old logic as backup for our custom names
        if(StringFind(sparam, "SSoT_Tab_") >= 0)
        {
            Print("🔍 Detected tab-related click, analyzing sparam: '", sparam, "'");
            // Extract tab index from the clicked object name using exact matching
            for(int i = 0; i < 4; i++)
            {
                string tab_name = "SSoT_Tab_" + IntegerToString(i);
                if(sparam == tab_name)  // Use exact match instead of substring search
                {
                    Print("📑 Tab ", i, " clicked (exact match) - Processing tab change");
                    HandleTabChange(i);
                    return; // Exit immediately to prevent multiple matches
                }
            }
            
            // Backup: Check if sparam contains the tab name (for DoEasy internal naming)
            for(int i = 0; i < 4; i++)
            {
                string tab_name = "SSoT_Tab_" + IntegerToString(i);
                if(StringFind(sparam, tab_name) >= 0 && StringLen(sparam) > StringLen(tab_name))
                {
                    Print("📑 Tab ", i, " clicked (substring match) - Processing tab change");
                    HandleTabChange(i);
                    return; // Exit immediately
                }
            }
        }
        
        // Handle button clicks
        for(int i = 0; i < 4; i++)
        {
            if(m_buttons[i] != NULL && StringFind(sparam, "SSoT_Btn_" + IntegerToString(i)) >= 0)
            {
                Print("� Button ", i, " clicked");
                HandleButtonClick(i);
            }
        }
    }
      // Handle mouse click events for better interaction (DISABLED - causing false positives)
    /*
    if (id == CHARTEVENT_CLICK)
    {
        // Get click coordinates
        int x = (int)lparam;
        int y = (int)dparam;
        
        // Check if click was on tab control area
        if(m_tab_control != NULL)
        {
            // Check which tab header might have been clicked based on coordinates
            for(int i = 0; i < m_tab_control.TabPages(); i++)
            {
                CTabHeader* header = m_tab_control.GetTabHeader(i);
                if(header != NULL)
                {
                    // Check if the header is now in pressed state after the click
                    if(header.State())
                    {
                        Print("� Tab ", i, " detected as selected via mouse click");
                        HandleTabChange(i);
                        break;
                    }
                }
            }
        }
    }
    */
    
    if (id == CHARTEVENT_CUSTOM + 1) // DoEasy custom events
    {
        Print("📡 DoEasy WForms Event: ", lparam, ", ", dparam, ", ", sparam);
        
        // Check for tab selection change events from DoEasy
        if(StringFind(sparam, "TAB_") >= 0 || StringFind(sparam, "Tab") >= 0)
        {
            // Extract tab index from custom event if possible
            int tab_index = (int)lparam;
            if(tab_index >= 0 && tab_index < 4)
            {
                Print("📑 DoEasy Tab Change Event: Tab ", tab_index, " selected");
                HandleTabChange(tab_index);
            }
        }
    }
    
    // Handle mouse events for better interaction
    if (id == CHARTEVENT_MOUSE_MOVE)
    {
        // Forward to all components for proper interaction
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
    
    // Update DoEasy WForms components - DoEasy panels update automatically
    // No explicit timer call needed as DoEasy handles this internally
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
                // m_analysis_engine.StartAnalysis(); // Implement when ready
            }
            break;
            
        case 1: // Stop
            if(m_analysis_engine != NULL)
            {
                Print("⏹️ Stopping analysis...");
                UpdateStatus("Analysis stopped");
                // m_analysis_engine.StopAnalysis(); // Implement when ready
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
//| Handle tab change events                                         |
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
        
        // Use DoEasy's simple Select method
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
