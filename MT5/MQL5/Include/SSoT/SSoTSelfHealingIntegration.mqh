//+------------------------------------------------------------------+
//| SSoTSelfHealingIntegration.mqh                                   |
//| Integration wrapper for self-healing system in SSoT EA         |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"
#property strict

#include <SSoT/SelfHealing/SelfHealingManager.mqh>

//+------------------------------------------------------------------+
//| SSoT Self-Healing Integration Class                             |
//| Purpose: Lightweight wrapper to integrate self-healing into EA  |
//+------------------------------------------------------------------+
class CSSoTSelfHealingIntegration
{
private:
    CSelfHealingManager*  m_healing_manager;
    bool                  m_initialized;
    datetime              m_last_auto_check;
    datetime              m_last_performance_check;
    int                   m_check_interval;
    
public:
    //--- Constructor/Destructor
    CSSoTSelfHealingIntegration();
    ~CSSoTSelfHealingIntegration();
    
    //--- Initialization
    bool                  Initialize(int main_db, int test_input_db, int test_output_db);
    void                  Cleanup();
    
    //--- Main Integration Points
    bool                  OnTimerCheck();           // Called from OnTimer
    bool                  OnInitCheck();            // Called from OnInit
    bool                  OnDeinitCheck();          // Called from OnDeinit
    
    //--- Manual Controls
    bool                  TriggerManualScan();
    bool                  TriggerEmergencyHealing();
    string                GetQuickHealthStatus();
    
    //--- Configuration
    void                  SetAutoCheckInterval(int seconds) { m_check_interval = seconds; }
    void                  EnableAutoHealing(bool enable);
    
    //--- Status Queries
    bool                  IsHealthy();
    bool                  IsActivelyHealing();
    string                GetHealthSummary();
    
private:
    //--- Internal helpers
    bool                  PerformQuickHealthCheck();
    bool                  UpdatePerformanceMetrics();
    void                  LogIntegrationEvent(const string message);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSSoTSelfHealingIntegration::CSSoTSelfHealingIntegration()
{
    m_healing_manager = NULL;
    m_initialized = false;
    m_last_auto_check = 0;
    m_last_performance_check = 0;
    m_check_interval = 600; // 10 minutes default
}

//+------------------------------------------------------------------+
//| Destructor                                                      |
//+------------------------------------------------------------------+
CSSoTSelfHealingIntegration::~CSSoTSelfHealingIntegration()
{
    Cleanup();
}

//+------------------------------------------------------------------+
//| Initialize the self-healing integration                        |
//+------------------------------------------------------------------+
bool CSSoTSelfHealingIntegration::Initialize(int main_db, int test_input_db, int test_output_db)
{
    if(m_initialized) {
        Print("🔧 Self-healing integration already initialized");
        return true;
    }
    
    // Create healing manager
    m_healing_manager = new CSelfHealingManager();
    if(m_healing_manager == NULL) {
        Print("❌ Failed to create self-healing manager");
        return false;
    }
    
    // Initialize the manager
    if(!m_healing_manager.Initialize(main_db, test_input_db, test_output_db)) {
        Print("❌ Failed to initialize self-healing manager");
        delete m_healing_manager;
        m_healing_manager = NULL;
        return false;
    }
    
    m_initialized = true;
    m_last_auto_check = TimeCurrent();
    m_last_performance_check = TimeCurrent();
    
    LogIntegrationEvent("Self-healing system integrated successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Cleanup resources                                               |
//+------------------------------------------------------------------+
void CSSoTSelfHealingIntegration::Cleanup()
{
    if(m_healing_manager != NULL) {
        m_healing_manager.Cleanup();
        delete m_healing_manager;
        m_healing_manager = NULL;
    }
    
    m_initialized = false;
    LogIntegrationEvent("Self-healing system cleanup completed");
}

//+------------------------------------------------------------------+
//| Timer-based health monitoring                                   |
//+------------------------------------------------------------------+
bool CSSoTSelfHealingIntegration::OnTimerCheck()
{
    if(!m_initialized || m_healing_manager == NULL) return false;
    
    datetime current_time = TimeCurrent();
    
    // Process scheduled healing tasks
    m_healing_manager.ProcessScheduledTasks();
    
    // Perform auto healing check if interval has passed
    if(current_time - m_last_auto_check >= m_check_interval) {
        m_last_auto_check = current_time;
        
        if(m_healing_manager.ShouldTriggerAutoHealing()) {
            LogIntegrationEvent("Auto-healing triggered by health check");
            m_healing_manager.ProcessAutoHealing();
        }
    }
    
    // Update performance metrics every minute
    if(current_time - m_last_performance_check >= 60) {
        m_last_performance_check = current_time;
        UpdatePerformanceMetrics();
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialization health check                                     |
//+------------------------------------------------------------------+
bool CSSoTSelfHealingIntegration::OnInitCheck()
{
    if(!m_initialized || m_healing_manager == NULL) return false;
    
    LogIntegrationEvent("Performing initialization health validation");
    
    // Validate system health on startup
    bool health_ok = m_healing_manager.ValidateSystemHealth();
    
    if(!health_ok) {
        LogIntegrationEvent("Startup health issues detected - triggering healing");
        m_healing_manager.PerformEmergencyHealing();
    }
    
    return health_ok;
}

//+------------------------------------------------------------------+
//| Deinitialization cleanup check                                 |
//+------------------------------------------------------------------+
bool CSSoTSelfHealingIntegration::OnDeinitCheck()
{
    if(!m_initialized || m_healing_manager == NULL) return false;
    
    LogIntegrationEvent("Performing shutdown health check");
    
    // Get final health report
    string final_report = m_healing_manager.GetHealthReport();
    Print("📊 Final Health Report:\n", final_report);
    
    return true;
}

//+------------------------------------------------------------------+
//| Trigger manual system scan                                     |
//+------------------------------------------------------------------+
bool CSSoTSelfHealingIntegration::TriggerManualScan()
{
    if(!m_initialized || m_healing_manager == NULL) {
        LogIntegrationEvent("Cannot trigger scan - system not initialized");
        return false;
    }
    
    LogIntegrationEvent("Manual system scan triggered");
    return m_healing_manager.StartComprehensiveScan();
}

//+------------------------------------------------------------------+
//| Trigger emergency healing                                       |
//+------------------------------------------------------------------+
bool CSSoTSelfHealingIntegration::TriggerEmergencyHealing()
{
    if(!m_initialized || m_healing_manager == NULL) {
        LogIntegrationEvent("Cannot trigger emergency healing - system not initialized");
        return false;
    }
    
    LogIntegrationEvent("Emergency healing triggered manually");
    return m_healing_manager.PerformEmergencyHealing();
}

//+------------------------------------------------------------------+
//| Get quick health status                                         |
//+------------------------------------------------------------------+
string CSSoTSelfHealingIntegration::GetQuickHealthStatus()
{
    if(!m_initialized || m_healing_manager == NULL) {
        return "Self-healing system not initialized";
    }
    
    if(m_healing_manager.IsSystemHealthy()) {
        return "HEALTHY";
    } else if(m_healing_manager.IsHealingActive()) {
        return "HEALING";
    } else {
        return "ISSUES DETECTED";
    }
}

//+------------------------------------------------------------------+
//| Enable/disable auto healing                                     |
//+------------------------------------------------------------------+
void CSSoTSelfHealingIntegration::EnableAutoHealing(bool enable)
{
    if(m_healing_manager != NULL) {
        m_healing_manager.EnableAutoHealing(enable);
        LogIntegrationEvent(StringFormat("Auto-healing %s", enable ? "enabled" : "disabled"));
    }
}

//+------------------------------------------------------------------+
//| Check if system is healthy                                      |
//+------------------------------------------------------------------+
bool CSSoTSelfHealingIntegration::IsHealthy()
{
    if(!m_initialized || m_healing_manager == NULL) return false;
    return m_healing_manager.IsSystemHealthy();
}

//+------------------------------------------------------------------+
//| Check if actively healing                                       |
//+------------------------------------------------------------------+
bool CSSoTSelfHealingIntegration::IsActivelyHealing()
{
    if(!m_initialized || m_healing_manager == NULL) return false;
    return m_healing_manager.IsHealingActive();
}

//+------------------------------------------------------------------+
//| Get health summary                                              |
//+------------------------------------------------------------------+
string CSSoTSelfHealingIntegration::GetHealthSummary()
{
    if(!m_initialized || m_healing_manager == NULL) {
        return "Self-healing system: NOT INITIALIZED";
    }
    
    string summary = "Self-healing: ";
    summary += GetQuickHealthStatus();
    
    if(IsActivelyHealing()) {
        summary += " (ACTIVE)";
    }
    
    SHealthMetrics metrics = m_healing_manager.GetCurrentHealthMetrics();
    summary += StringFormat(" | Uptime: %.1f%% | Gaps: %d", 
                          metrics.uptime_percentage, metrics.gaps_detected);
    
    return summary;
}

//+------------------------------------------------------------------+
//| Perform quick health check                                      |
//+------------------------------------------------------------------+
bool CSSoTSelfHealingIntegration::PerformQuickHealthCheck()
{
    if(!m_initialized || m_healing_manager == NULL) return false;
    
    // This is a lightweight check - full scans are scheduled separately
    return m_healing_manager.ValidateSystemHealth();
}

//+------------------------------------------------------------------+
//| Update performance metrics                                      |
//+------------------------------------------------------------------+
bool CSSoTSelfHealingIntegration::UpdatePerformanceMetrics()
{
    if(!m_initialized || m_healing_manager == NULL) return false;
    
    // Record a database operation to track performance
    // In real implementation, this would be called for actual operations
    return true;
}

//+------------------------------------------------------------------+
//| Log integration events                                          |
//+------------------------------------------------------------------+
void CSSoTSelfHealingIntegration::LogIntegrationEvent(const string message)
{
    Print(StringFormat("[SELF-HEALING] %s", message));
}
