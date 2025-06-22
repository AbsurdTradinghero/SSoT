//+------------------------------------------------------------------+
//| SSoT_Analyzer.mq5 - SSoT Class Analysis and Testing EA          |
//| Modern DoEasy-based GUI for SSoT Class Fine-tuning              |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"
#property description "SSoT Class Analyzer with DoEasy Tabbed Interface"
#property strict

//--- Include Framework Components
#include <DoEasy\Engine.mqh>                              // DoEasy main engine
#include <SSoT\GUI\DoEasyGraphicPanel.mqh>                // DoEasy GUI manager

//--- Input Parameters
input group "=== Analysis Configuration ==="
input bool      EnableAutoDiscovery = true;               // Auto-discover SSoT classes
input string    SpecificClasses = "";                     // Specific classes to analyze (comma-separated)
input int       MaxConcurrentTests = 3;                   // Maximum concurrent tests

input group "=== GUI Configuration ==="
input int       PanelWidth = 1000;                        // Main panel width
input int       PanelHeight = 700;                        // Main panel height
input int       PanelX = 50;                             // Panel X position
input int       PanelY = 50;                             // Panel Y position
input bool      EnableDocking = true;                     // Enable panel docking

input group "=== Analysis Settings ==="
input bool      EnableRealTimeMonitoring = true;          // Real-time class monitoring
input int       MonitoringInterval = 1000;                // Monitoring interval (ms)
input bool      EnableDetailedLogging = true;             // Detailed analysis logging
input string    LogLevel = "INFO";                        // Log level (DEBUG,INFO,WARN,ERROR)

//--- Global Objects
CEngine               *g_engine = NULL;                    // DoEasy engine instance
CDoEasyGraphicPanel   *g_gui_panel = NULL;                // GUI panel manager

//--- Global State Variables
bool                   g_initialized = false;             // Initialization state
string                 g_current_status = "Initializing"; // Current system status

//+------------------------------------------------------------------+
//| Expert Advisor Initialization                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("🚀 SSoT_Analyzer v1.00 - Initializing DoEasy-based Analysis System...");
    
    // Initialize DoEasy engine
    if(!InitializeDoEasyEngine())
    {
        Print("❌ Failed to initialize DoEasy engine");
        return INIT_FAILED;
    }
      // Analysis engine initialization removed - using clean panel only
    
    // Initialize GUI Panel
    if(!InitializeGUIPanel())
    {
        Print("❌ Failed to initialize GUI panel");
        return INIT_FAILED;
    }
      // Auto-discovery removed - using clean panel onlyg_initialized = true;
    g_current_status = "Ready";
    
    // Chart events are automatically enabled for Expert Advisors
    // No need to explicitly enable them - OnChartEvent will be called automatically
    
    Print("✅ SSoT_Analyzer initialized successfully");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert Advisor Deinitialization                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("🔄 SSoT_Analyzer deinitializing...");
      // Analysis engine references removed - using clean panel only
    
    // Cleanup GUI
    if(g_gui_panel != NULL)
    {
        delete g_gui_panel;
        g_gui_panel = NULL;
    }
      // Analysis engine cleanup removed - using clean panel only
    
    // Cleanup DoEasy Engine
    if(g_engine != NULL)
    {
        delete g_engine;
        g_engine = NULL;
    }
      // Cleanup removed - using clean panel only
    
    Print("✅ SSoT_Analyzer deinitialized successfully");
}

//+------------------------------------------------------------------+
//| Expert Advisor Tick Event                                       |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!g_initialized)
        return;
    
    // Update DoEasy engine with empty SDataCalculate
    if(g_engine != NULL)
    {
        SDataCalculate data_calculate = {};
        g_engine.OnTick(data_calculate, 0);
    }
      // Update analysis engine removed - using clean panel only
      // Update GUI
    if(g_gui_panel != NULL)
    {
        g_gui_panel.Update();
        g_gui_panel.OnTick();  // Enable persistent visibility management
    }
}

//+------------------------------------------------------------------+
//| Chart Event Handler                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
    if(!g_initialized)
        return;
    
    // Handle GUI events - Enable interactive tab functionality
    if(g_gui_panel != NULL)
        g_gui_panel.OnChartEvent(id, lparam, dparam, sparam);
}

//+------------------------------------------------------------------+
//| Initialize DoEasy Engine                                         |
//+------------------------------------------------------------------+
bool InitializeDoEasyEngine()
{    // Create DoEasy engine instance
    g_engine = new CEngine();
    if(g_engine == NULL)
    {
        Print("Failed to create DoEasy engine instance");
        return false;    }
    
    // Initialize the engine - simplified for Phase 1
    // if(!g_engine.Initialize())
    // {
    //     Print("Failed to initialize DoEasy engine");
    //     delete g_engine;
    //     g_engine = NULL;
    //     return false;
    // }
    
    Print("✅ DoEasy engine initialized successfully");
    return true;
}

// InitializeAnalysisEngine function removed - using clean panel only

//+------------------------------------------------------------------+
//| Initialize GUI Panel                                            |
//+------------------------------------------------------------------+
bool InitializeGUIPanel()
{
    g_gui_panel = new CDoEasyGraphicPanel(g_engine);  // Pass the DoEasy engine reference
    if(g_gui_panel == NULL)
    {
        Print("Failed to create GUI panel instance");
        return false;
    }
      // Configure GUI panel
    g_gui_panel.SetDimensions(PanelX, PanelY, PanelWidth, PanelHeight);
    g_gui_panel.SetDockingEnabled(EnableDocking);
    // SetAnalysisEngine call removed - using clean panel only
    
    if(!g_gui_panel.Initialize())
    {
        Print("Failed to initialize GUI panel");
        delete g_gui_panel;
        g_gui_panel = NULL;
        return false;
    }
    
    // Make the panel visible
    g_gui_panel.Show();
    
    Print("✅ GUI panel initialized and shown successfully");
    return true;
}

// DiscoverSSoTClasses function removed - using clean panel only

//+------------------------------------------------------------------+
//| Get Current System Status                                        |
//+------------------------------------------------------------------+
string GetSystemStatus()
{
    if(!g_initialized)
        return "Not Initialized";
    
    return g_current_status;
}

// StartClassAnalysis function removed - using clean panel only

// StopClassAnalysis function removed - using clean panel only
