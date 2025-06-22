//+------------------------------------------------------------------+
//| DoEasyGraphicPanel.mqh                                           |
//| Phase 3: Clean and Stable DoEasy WForms Implementation          |
//| Author: Marton (AI Engineer)                                     |
//| Created: June 21, 2025                                           |
//+------------------------------------------------------------------+
#property copyright "Marton (AI Engineer)"
#property version   "3.02"

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
    bool m_force_visible;      // Force visibility maintenance
    datetime m_last_visibility_check;  // Last time we checked visibility
      // Analysis engine removed - using clean panel only
    
    // Configuration
    int m_x_pos;
    int m_y_pos;
    int m_width;
    int m_height;    // DoEasy component creation methods
    bool CreateDoEasyMainPanel();
    bool CreateDoEasyTabControl();
    bool CreateDoEasyToolbar();
    bool CreateDoEasyStatusBar();
    
    // Visibility management
    void EnsureVisibility();

public:
    // Constructor/Destructor  
    CDoEasyGraphicPanel(CEngine* engine = NULL);
    ~CDoEasyGraphicPanel();
      // Core interface methods
    bool Initialize();
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
    
    // Visibility management
    void ForceVisibilityRefresh();  // Public method to force visibility refresh
    
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
    m_initialized = false;    m_tabs_created = false;
    m_force_visible = false;
    m_last_visibility_check = 0;
    // Analysis engine initialization removed - using clean panel only
    
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
    
    // Ensure all components are properly visible
    EnsureVisibility();
    
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
    
    // Create DoEasy CPanel with proper integration
    if(m_engine == NULL)
    {
        Print("❌ DoEasy engine is required for component creation");
        return false;
    }
    
    // Create the main panel
    m_main_panel = new CPanel(0, 0, "SSoT_Panel", m_x_pos, m_y_pos, m_width, m_height);
    
    if (m_main_panel == NULL)
    {
        Print("❌ Failed to create DoEasy CPanel");
        return false;
    }
    
    // Configure panel properties BEFORE showing
    m_main_panel.SetBorderStyle(FRAME_STYLE_SIMPLE);
    m_main_panel.SetBorderSizeAll(1);
    m_main_panel.SetBorderColor(clrBlack, false);  // Don't redraw immediately
    m_main_panel.SetBackgroundColor(clrLightGray, false);  // Don't redraw immediately
    
    // Set proper coordinates and size
    m_main_panel.SetCoordX(m_x_pos);
    m_main_panel.SetCoordY(m_y_pos);
    m_main_panel.SetWidth(m_width);
    m_main_panel.SetHeight(m_height);
      // Show the panel (no need to call protected Initialize)
    m_main_panel.Show();
    m_main_panel.Redraw(true);  // Force redraw after all properties are set
    
    // Create title label as child of main panel
    m_title_label = new CLabel(0, 0, "SSoT_Title", 10, 10, 200, 20);
    if (m_title_label != NULL)
    {        m_title_label.SetText("SSoT Analyzer - DoEasy WForms (Stable v3.02)");
        m_title_label.SetForeColor(clrBlack, false);
        m_title_label.SetFontSize(10);
        m_title_label.Show();
        m_title_label.Redraw(true);
    }
    
    Print("✅ DoEasy main panel created and properly initialized");
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
      // Create DoEasy CTabControl with proper initialization
    m_tab_control = new CTabControl(0, 0, "SSoT_Tabs", 10, 35, m_width - 20, m_height - 80);
    
    if (m_tab_control == NULL)
    {
        Print("❌ Failed to create DoEasy CTabControl");
        return false;    }
    
    // Show the tab control (no need to call protected Initialize)
    
    // Add tab pages using CreateTabPages method
    string tabs[] = {"Analysis", "Classes", "Database", "Settings"};
    bool success = m_tab_control.CreateTabPages(ArraySize(tabs), 0, 80, 25, "");
    if (!success)
    {
        Print("❌ Failed to create tab pages");
        return false;
    }
    
    // Configure each tab header and field with proper initialization
    for(int i = 0; i < ArraySize(tabs); i++)
    {        CTabHeader* header = m_tab_control.GetTabHeader(i);
        if(header != NULL)
        {
            header.SetText(tabs[i]);
            Print("📑 Tab ", i, " header configured: '", tabs[i], "'");
        }
        
        // Properly configure tab content fields to prevent white rectangles
        CWinFormBase* field = m_tab_control.GetTabField(i);
        if(field != NULL)
        {
            field.SetBackgroundColor(clrNONE, false);  // Transparent background, no immediate redraw
            field.Hide();  // Start hidden
            Print("📋 Tab field ", i, " configured and hidden");
        }
    }
    
    // Show the tab control and force redraw
    m_tab_control.Show();
    m_tab_control.Redraw(true);
    
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
      // Create DoEasy CButton components with proper initialization
    string buttonTexts[] = {"Run", "Stop", "Reset", "Export"};
    int buttonWidth = 60;
    int buttonSpacing = 70;
      for (int i = 0; i < ArraySize(buttonTexts) && i < 4; i++)
    {
        string button_name = "SSoT_Btn_" + IntegerToString(i);
        int x_pos = 10 + (i * buttonSpacing);
        int y_pos = m_height - 35;
        
        m_buttons[i] = new CButton(0, 0, button_name, x_pos, y_pos, buttonWidth, 25);
        
        if (m_buttons[i] != NULL)
        {
            m_buttons[i].SetText(buttonTexts[i]);
            m_buttons[i].SetForeColor(clrBlack, false);
            m_buttons[i].SetBackgroundColor(clrLightBlue, false);
            m_buttons[i].SetBorderStyle(FRAME_STYLE_SIMPLE);
              // Try to set the name explicitly if possible
            if(m_buttons[i].Name() != button_name)
            {
                Print("⚠️ Button ", i, " name mismatch - Expected: '", button_name, "', Got: '", m_buttons[i].Name(), "'");
            }
            
            m_buttons[i].Show();
            m_buttons[i].Redraw(true);
            
            // Debug: Log button details for click detection troubleshooting
            Print("🔘 Button ", i, " ('", buttonTexts[i], "') created:");
            Print("   - Position: (", x_pos, ",", y_pos, ")");
            Print("   - Size: ", buttonWidth, "x25");
            Print("   - Bounds: [", x_pos, ",", y_pos, "-", x_pos+buttonWidth, ",", y_pos+25, "]");
            Print("   - Object Name: '", m_buttons[i].Name(), "'");
            Print("   - Expected Pattern: 'SSoT_Btn_", i, "'");
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
      // Create DoEasy CLabel for status with proper initialization
    m_status_label = new CLabel(0, 0, "SSoT_Status", 10, m_height - 15, m_width - 20, 10);
    
    if (m_status_label != NULL)
    {
        m_status_label.SetText("DoEasy WForms Panel Ready - v3.02 Stable with Proper Initialization");        m_status_label.SetForeColor(clrBlack, false);
        m_status_label.SetFontSize(8);
        m_status_label.SetBackgroundColor(clrLightGray, false);
        m_status_label.Show();
        m_status_label.Redraw(true);
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
        m_main_panel.BringToTop();
        m_main_panel.Redraw(true);
    }
    
    m_visible = true;
    m_force_visible = true;  // Enable persistent visibility
    m_last_visibility_check = TimeCurrent();
    
    // Ensure all components are visible after showing
    EnsureVisibility();
    
    Print("✅ DoEasyGraphicPanel shown with persistent visibility enabled");
}

//+------------------------------------------------------------------+
//| Hide the panel                                                   |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::Hide()
{
    // Disable persistent visibility
    m_force_visible = false;
    
    // Hide DoEasy WForms components
    if (m_main_panel != NULL)
    {
        m_main_panel.Hide();
    }
    
    m_visible = false;
    Print("✅ DoEasyGraphicPanel hidden with persistent visibility disabled");
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
        
        // Enhanced button click detection - check multiple possible naming patterns
        for(int i = 0; i < 4; i++)
        {
            if(m_buttons[i] != NULL)
            {
                // Check various possible naming patterns that DoEasy might use
                string btn_patterns[] = {
                    "SSoT_Btn_" + IntegerToString(i),
                    "Button" + IntegerToString(i),
                    "Btn" + IntegerToString(i),
                    m_buttons[i].Name()  // Try to get the actual object name
                };
                
                bool button_clicked = false;
                for(int j = 0; j < ArraySize(btn_patterns); j++)
                {
                    if(StringFind(sparam, btn_patterns[j]) >= 0)
                    {
                        button_clicked = true;
                        break;
                    }
                }
                
                if(button_clicked)
                {
                    Print("🔘 Button ", i, " clicked (detected via pattern matching)");
                    HandleButtonClick(i);
                    return;
                }
            }
        }
          // If no pattern matched, check coordinates-based detection
        Print("🔍 No button pattern matched, checking coordinates for click at (", (int)lparam, ",", (int)dparam, ")");
        
        // Check if click coordinates fall within any button's bounds
        for(int i = 0; i < 4; i++)
        {
            if(m_buttons[i] != NULL)
            {
                int btn_x = m_buttons[i].CoordX();
                int btn_y = m_buttons[i].CoordY();
                int btn_width = m_buttons[i].Width();
                int btn_height = m_buttons[i].Height();
                
                // Check if click is within button bounds
                if((int)lparam >= btn_x && (int)lparam <= btn_x + btn_width &&
                   (int)dparam >= btn_y && (int)dparam <= btn_y + btn_height)
                {
                    Print("🎯 Click at (", (int)lparam, ",", (int)dparam, ") matches button ", i, " bounds [", btn_x, ",", btn_y, "-", btn_x+btn_width, ",", btn_y+btn_height, "]");
                    HandleButtonClick(i);
                    return;
                }
            }
        }    }
    
    // Handle mouse click events (alternative detection method)
    if (id == CHARTEVENT_CLICK)
    {
        Print("🖱️ Mouse Click at (", (int)lparam, ",", (int)dparam, ")");
        
        // Check button bounds for mouse clicks
        for(int i = 0; i < 4; i++)
        {
            if(m_buttons[i] != NULL)
            {
                int btn_x = m_buttons[i].CoordX();
                int btn_y = m_buttons[i].CoordY();
                int btn_width = m_buttons[i].Width();
                int btn_height = m_buttons[i].Height();
                
                if((int)lparam >= btn_x && (int)lparam <= btn_x + btn_width &&
                   (int)dparam >= btn_y && (int)dparam <= btn_y + btn_height)
                {
                    Print("🎯 Mouse click detected on button ", i);
                    HandleButtonClick(i);
                    return;
                }
            }
        }
    }
      // Enhanced button event handling - check for button state changes
    if (id == CHARTEVENT_CUSTOM || id == CHARTEVENT_OBJECT_CHANGE)
    {
        // DoEasy may generate custom events - check for button-related events
        Print("🔍 Custom/Change event detected: sparam='", sparam, "'");
        
        // Check if the event relates to any of our buttons
        for(int i = 0; i < 4; i++)
        {
            if(m_buttons[i] != NULL)
            {
                string button_name = m_buttons[i].Name();
                if(StringFind(sparam, button_name) >= 0)
                {
                    Print("🔘 Button ", i, " detected via custom event");
                    HandleButtonClick(i);
                    return;
                }
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
    
    // Periodic visibility check - every 5 seconds when force_visible is enabled
    if (m_force_visible && (TimeCurrent() - m_last_visibility_check) >= 5)
    {
        // Check if main panel is still visible
        if (m_main_panel != NULL && !m_main_panel.IsVisible())
        {
            Print("⚠️ Panel disappeared - restoring visibility...");
            EnsureVisibility();
        }
        
        m_last_visibility_check = TimeCurrent();
    }
    
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
            // Analysis engine removed - using clean button logic only
            Print("▶️ Run button clicked - ready for new logic");
            UpdateStatus("Ready for run logic");
            break;
            
        case 1: // Stop
            // Analysis engine removed - using clean button logic only
            Print("⏹️ Stop button clicked - ready for new logic");
            UpdateStatus("Ready for stop logic");
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
      // Improved tab selection with proper visibility management
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
        
        // First, ensure all tab fields are hidden to prevent white rectangles
        for(int i = 0; i < m_tab_control.TabPages(); i++)
        {
            CWinFormBase* field = m_tab_control.GetTabField(i);
            if(field != NULL)
            {
                field.Hide();
            }
        }
          // Use DoEasy's Select method to change the active tab
        m_tab_control.Select(tab_index, true);
        
        // Show only the selected tab's content field
        CWinFormBase* selected_field = m_tab_control.GetTabField(tab_index);
        if(selected_field != NULL)
        {
            selected_field.Show();
            selected_field.SetBackgroundColor(clrWhiteSmoke, true);
        }
        
        // Force visibility of all critical components after tab change
        m_tab_control.Show();
        m_tab_control.BringToTop();
        m_tab_control.Redraw(true);
        
        if(m_main_panel != NULL)
        {
            m_main_panel.Show();
            m_main_panel.BringToTop();
            m_main_panel.Redraw(true);
        }
        
        // Force a chart redraw to ensure everything stays visible
        ChartRedraw();
        
        Print("✅ Tab ", tab_index, " selected with forced visibility maintenance");
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

//+------------------------------------------------------------------+
//| Ensure all components remain visible and properly initialized   |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::EnsureVisibility()
{
    Print("👁️ Ensuring component visibility (stable version)...");
    
    // Ensure main panel is properly visible
    if(m_main_panel != NULL)
    {
        m_main_panel.Show();
        m_main_panel.BringToTop();
        m_main_panel.Redraw(true);
        Print("📱 Main panel shown and brought to top");
    }
    
    // Ensure tab control visibility and proper tab field management
    if(m_tab_control != NULL)
    {
        m_tab_control.Show();
        m_tab_control.BringToTop();
        
        // Show all tab headers but manage field visibility properly
        int selected_tab = m_tab_control.SelectedTabPageNum();
        for(int i = 0; i < m_tab_control.TabPages(); i++)
        {
            CTabHeader* header = m_tab_control.GetTabHeader(i);
            if(header != NULL)
            {
                header.Show();
                header.BringToTop();
            }
            
            // Only show the selected tab field, hide others to prevent white rectangles
            CWinFormBase* field = m_tab_control.GetTabField(i);
            if(field != NULL)
            {
                field.SetBackgroundColor(clrNONE, false);
                if(i == selected_tab)
                {
                    field.Show();
                    field.BringToTop();
                }
                else
                {
                    field.Hide();
                }
            }
        }
        
        m_tab_control.Redraw(true);
        Print("📑 Tab control visibility managed - selected tab: ", selected_tab);
    }
    
    // Ensure title label visibility
    if(m_title_label != NULL)
    {
        m_title_label.Show();
        m_title_label.BringToTop();
        m_title_label.Redraw(true);
    }
    
    // Ensure buttons visibility
    for(int i = 0; i < 4; i++)
    {
        if(m_buttons[i] != NULL)
        {
            m_buttons[i].Show();
            m_buttons[i].BringToTop();
            m_buttons[i].Redraw(true);
        }
    }
    
    // Ensure status label visibility
    if(m_status_label != NULL)
    {
        m_status_label.Show();
        m_status_label.BringToTop();
        m_status_label.Redraw(true);
    }
    
    // Final chart redraw to ensure everything is properly displayed
    ChartRedraw();
    
    Print("✅ Component visibility ensured without protected method calls");
}

//+------------------------------------------------------------------+
//| Force visibility refresh - can be called from external code     |
//+------------------------------------------------------------------+
void CDoEasyGraphicPanel::ForceVisibilityRefresh()
{
    if (!m_visible || m_main_panel == NULL) 
    {
        Print("⚠️ Cannot refresh visibility - panel not visible or not created");
        return;
    }
    
    Print("🔄 Force visibility refresh requested...");
    
    // Enable force visibility mode
    m_force_visible = true;
    
    // Immediately ensure all components are visible
    EnsureVisibility();
    
    // Reset the visibility check timer
    m_last_visibility_check = TimeCurrent();
    
    Print("✅ Force visibility refresh completed");
}
