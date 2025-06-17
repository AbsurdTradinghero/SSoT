//+------------------------------------------------------------------+
//| SimpleSSoTSelfHealingIntegration.mqh                             |
//| Simplified integration wrapper for SSoT EA                      |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"

#ifndef SIMPLE_SSOT_SELF_HEALING_INTEGRATION_MQH
#define SIMPLE_SSOT_SELF_HEALING_INTEGRATION_MQH

#include <SSoT/SelfHealing/SimpleSelfHealingManager.mqh>

//+------------------------------------------------------------------+
//| Simple SSoT Self-Healing Integration Class                      |
//+------------------------------------------------------------------+
class CSimpleSSoTSelfHealingIntegration
{
private:
    CSimpleSelfHealingManager* m_healing_manager;
    bool                       m_initialized;
    datetime                   m_last_auto_check;
    int                        m_check_interval;
    
public:
    //--- Constructor/Destructor
    CSimpleSSoTSelfHealingIntegration();
    ~CSimpleSSoTSelfHealingIntegration();
    
    //--- Initialization
    bool                  Initialize(int main_db, int test_input_db = INVALID_HANDLE, int test_output_db = INVALID_HANDLE);
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
    void                  SetAutoCheckInterval(int seconds);
    void                  EnableAutoHealing(bool enable);
    
    //--- Status Queries
    bool                  IsHealthy();
    bool                  IsActivelyHealing();
    string                GetHealthSummary();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSimpleSSoTSelfHealingIntegration::CSimpleSSoTSelfHealingIntegration()
{
    m_healing_manager = NULL;
    m_initialized = false;
    m_last_auto_check = 0;
    m_check_interval = 300; // 5 minutes
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSimpleSSoTSelfHealingIntegration::~CSimpleSSoTSelfHealingIntegration()
{
    Cleanup();
}

//+------------------------------------------------------------------+
//| Initialize the integration                                       |
//+------------------------------------------------------------------+
bool CSimpleSSoTSelfHealingIntegration::Initialize(int main_db, int test_input_db = INVALID_HANDLE, int test_output_db = INVALID_HANDLE)
{
    if(main_db == INVALID_HANDLE) {
        Print("❌ SimpleSSoTSelfHealingIntegration: Invalid main database handle");
        return false;
    }
    
    // Create healing manager
    m_healing_manager = new CSimpleSelfHealingManager();
    if(m_healing_manager == NULL) {
        Print("❌ SimpleSSoTSelfHealingIntegration: Failed to create healing manager");
        return false;
    }
    
    // Initialize healing manager
    if(!m_healing_manager.Initialize(main_db, test_input_db, test_output_db)) {
        Print("❌ SimpleSSoTSelfHealingIntegration: Failed to initialize healing manager");
        delete m_healing_manager;
        m_healing_manager = NULL;
        return false;
    }
    
    m_initialized = true;
    m_last_auto_check = TimeCurrent();
    
    Print("✅ SimpleSSoTSelfHealingIntegration: Initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Cleanup                                                          |
//+------------------------------------------------------------------+
void CSimpleSSoTSelfHealingIntegration::Cleanup()
{
    if(m_healing_manager != NULL) {
        m_healing_manager.Cleanup();
        delete m_healing_manager;
        m_healing_manager = NULL;
    }
    m_initialized = false;
}

//+------------------------------------------------------------------+
//| Timer check - called from EA OnTimer                           |
//+------------------------------------------------------------------+
bool CSimpleSSoTSelfHealingIntegration::OnTimerCheck()
{
    if(!m_initialized || m_healing_manager == NULL) {
        return false;
    }
    
    return m_healing_manager.OnTimerCheck();
}

//+------------------------------------------------------------------+
//| Init check - called from EA OnInit                             |
//+------------------------------------------------------------------+
bool CSimpleSSoTSelfHealingIntegration::OnInitCheck()
{
    if(!m_initialized || m_healing_manager == NULL) {
        return false;
    }
    
    Print("🔧 Performing initial self-healing check");
    return m_healing_manager.PerformHealthCheck();
}

//+------------------------------------------------------------------+
//| Deinit check - called from EA OnDeinit                         |
//+------------------------------------------------------------------+
bool CSimpleSSoTSelfHealingIntegration::OnDeinitCheck()
{
    if(!m_initialized || m_healing_manager == NULL) {
        return false;
    }
    
    Print("🔧 Performing final self-healing check");
    bool result = m_healing_manager.PerformQuickScan();
    Print("🔧 Self-healing final status: ", GetQuickHealthStatus());
    return result;
}

//+------------------------------------------------------------------+
//| Trigger manual scan                                             |
//+------------------------------------------------------------------+
bool CSimpleSSoTSelfHealingIntegration::TriggerManualScan()
{
    if(!m_initialized || m_healing_manager == NULL) {
        return false;
    }
    
    Print("🔧 Triggering manual self-healing scan");
    return m_healing_manager.PerformHealthCheck();
}

//+------------------------------------------------------------------+
//| Trigger emergency healing                                        |
//+------------------------------------------------------------------+
bool CSimpleSSoTSelfHealingIntegration::TriggerEmergencyHealing()
{
    if(!m_initialized || m_healing_manager == NULL) {
        return false;
    }
    
    Print("🚨 Triggering emergency self-healing");
    return m_healing_manager.PerformHealthCheck();
}

//+------------------------------------------------------------------+
//| Get quick health status                                          |
//+------------------------------------------------------------------+
string CSimpleSSoTSelfHealingIntegration::GetQuickHealthStatus()
{
    if(!m_initialized || m_healing_manager == NULL) {
        return "NOT INITIALIZED";
    }
    
    return m_healing_manager.GetQuickStatus();
}

//+------------------------------------------------------------------+
//| Set auto check interval                                          |
//+------------------------------------------------------------------+
void CSimpleSSoTSelfHealingIntegration::SetAutoCheckInterval(int seconds)
{
    m_check_interval = seconds;
    if(m_healing_manager != NULL) {
        m_healing_manager.SetCheckInterval(seconds);
    }
}

//+------------------------------------------------------------------+
//| Enable/disable auto healing                                      |
//+------------------------------------------------------------------+
void CSimpleSSoTSelfHealingIntegration::EnableAutoHealing(bool enable)
{
    if(m_healing_manager != NULL) {
        m_healing_manager.SetAutoHealing(enable);
    }
}

//+------------------------------------------------------------------+
//| Check if system is healthy                                       |
//+------------------------------------------------------------------+
bool CSimpleSSoTSelfHealingIntegration::IsHealthy()
{
    if(!m_initialized || m_healing_manager == NULL) {
        return false;
    }
    
    return m_healing_manager.IsHealthy();
}

//+------------------------------------------------------------------+
//| Check if actively healing                                        |
//+------------------------------------------------------------------+
bool CSimpleSSoTSelfHealingIntegration::IsActivelyHealing()
{
    // For simplified version, always return false
    // In full version, this would check if healing operations are in progress
    return false;
}

//+------------------------------------------------------------------+
//| Get health summary                                               |
//+------------------------------------------------------------------+
string CSimpleSSoTSelfHealingIntegration::GetHealthSummary()
{
    if(!m_initialized || m_healing_manager == NULL) {
        return "Self-healing system not initialized";
    }
    
    return m_healing_manager.GetStatistics();
}

#endif // SIMPLE_SSOT_SELF_HEALING_INTEGRATION_MQH
