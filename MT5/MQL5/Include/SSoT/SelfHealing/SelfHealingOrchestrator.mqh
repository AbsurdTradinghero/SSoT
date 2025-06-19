//+------------------------------------------------------------------+
//| SelfHealingOrchestrator.mqh - Main Self-Healing Coordinator     |
//| Consolidates all self-healing functionality into single system  |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"
#property strict

#include <SSoT/SelfHealing/Components/GapDetector.mqh>
#include <SSoT/SelfHealing/Components/IntegrityValidator.mqh>
#include <SSoT/SelfHealing/Components/RecoveryEngine.mqh>
#include <SSoT/SelfHealing/Components/PerformanceMonitor.mqh>
#include <SSoT/SelfHealing/Components/BrokerDataBoundaryManager.mqh>
#include <SSoT/SelfHealing/Utilities/HealingLogger.mqh>
#include <SSoT/SelfHealing/Utilities/HealthStatus.mqh>
#include <SSoT/SelfHealing/Utilities/SimpleSelfHealing.mqh>

//+------------------------------------------------------------------+
//| Self-Healing Orchestrator Class                                 |
//| Main coordinator for all self-healing operations                |
//+------------------------------------------------------------------+
class CSelfHealingOrchestrator
{
private:
    // Component instances
    CGapDetector*                   m_gap_detector;
    CIntegrityValidator*            m_integrity_validator;
    CRecoveryEngine*                m_recovery_engine;
    CPerformanceMonitor*            m_performance_monitor;
    CBrokerDataBoundaryManager*     m_boundary_manager;
    CHealingLogger*                 m_logger;
    
    // Database handles
    int                             m_main_db;
    int                             m_test_input_db;
    int                             m_test_output_db;
    
    // System state
    bool                            m_initialized;
    bool                            m_auto_healing_enabled;
    datetime                        m_last_health_check;
    datetime                        m_last_healing_run;
    int                             m_check_interval;
    SHealthStatus                   m_current_status;
    
public:
    //--- Constructor/Destructor
    CSelfHealingOrchestrator();
    ~CSelfHealingOrchestrator();
    
    //--- Initialization
    bool                Initialize(int main_db, int test_input_db, int test_output_db);
    void                Cleanup();
    
    //--- Main Operations
    bool                RunHealthCheck();
    bool                RunHealingCycle();
    bool                PerformEmergencyHealing();
    
    //--- Configuration
    void                SetAutoCheckInterval(int seconds) { m_check_interval = seconds; }
    void                EnableAutoHealing(bool enable) { m_auto_healing_enabled = enable; }
    
    //--- Status & Monitoring
    bool                IsHealthy();
    bool                IsActivelyHealing();
    string              GetHealthSummary();
    SHealthStatus       GetDetailedStatus();
    
    //--- Timer Integration
    bool                OnTimerCheck();
    
private:
    //--- Internal operations
    bool                InitializeComponents();
    bool                ValidateSystemHealth();
    bool                ExecuteHealingStrategy();
    void                UpdateHealthStatus();
    void                LogHealingActivity(const string message);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSelfHealingOrchestrator::CSelfHealingOrchestrator()
{
    m_gap_detector = NULL;
    m_integrity_validator = NULL;
    m_recovery_engine = NULL;
    m_performance_monitor = NULL;
    m_boundary_manager = NULL;
    m_logger = NULL;
    
    m_main_db = INVALID_HANDLE;
    m_test_input_db = INVALID_HANDLE;
    m_test_output_db = INVALID_HANDLE;
    
    m_initialized = false;
    m_auto_healing_enabled = true;
    m_last_health_check = 0;
    m_last_healing_run = 0;
    m_check_interval = 600; // 10 minutes default
    
    // Initialize health status
    m_current_status.overall_health = HEALTH_UNKNOWN;
    m_current_status.database_health = HEALTH_UNKNOWN;
    m_current_status.data_integrity = HEALTH_UNKNOWN;
    m_current_status.performance_status = HEALTH_UNKNOWN;
    m_current_status.last_check_time = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                      |
//+------------------------------------------------------------------+
CSelfHealingOrchestrator::~CSelfHealingOrchestrator()
{
    Cleanup();
}

//+------------------------------------------------------------------+
//| Initialize the orchestrator and all components                  |
//+------------------------------------------------------------------+
bool CSelfHealingOrchestrator::Initialize(int main_db, int test_input_db, int test_output_db)
{
    if(m_initialized) {
        Print("🔧 SelfHealingOrchestrator already initialized");
        return true;
    }
    
    // Store database handles
    m_main_db = main_db;
    m_test_input_db = test_input_db;
    m_test_output_db = test_output_db;
    
    // Validate database handles
    if(m_main_db == INVALID_HANDLE) {
        Print("❌ SelfHealingOrchestrator: Invalid main database handle");
        return false;
    }
    
    // Initialize components
    if(!InitializeComponents()) {
        Print("❌ SelfHealingOrchestrator: Failed to initialize components");
        Cleanup();
        return false;
    }
    
    m_initialized = true;
    Print("✅ SelfHealingOrchestrator initialized successfully");
    
    // Run initial health check
    RunHealthCheck();
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize all component instances                              |
//+------------------------------------------------------------------+
bool CSelfHealingOrchestrator::InitializeComponents()
{
    // Initialize logger first
    m_logger = new CHealingLogger();
    if(m_logger == NULL) {
        Print("❌ Failed to create healing logger");
        return false;
    }
    
    // Initialize gap detector
    m_gap_detector = new CGapDetector();
    if(m_gap_detector == NULL) {
        Print("❌ Failed to create gap detector");
        return false;
    }
    
    // Initialize integrity validator
    m_integrity_validator = new CIntegrityValidator();
    if(m_integrity_validator == NULL) {
        Print("❌ Failed to create integrity validator");
        return false;
    }
    
    // Initialize recovery engine
    m_recovery_engine = new CRecoveryEngine();
    if(m_recovery_engine == NULL) {
        Print("❌ Failed to create recovery engine");
        return false;
    }
    
    // Initialize performance monitor
    m_performance_monitor = new CPerformanceMonitor();
    if(m_performance_monitor == NULL) {
        Print("❌ Failed to create performance monitor");
        return false;
    }
    
    // Initialize boundary manager
    m_boundary_manager = new CBrokerDataBoundaryManager();
    if(m_boundary_manager == NULL) {
        Print("❌ Failed to create boundary manager");
        return false;
    }
    
    // Initialize all components with database handles
    if(!m_gap_detector.Initialize(m_main_db)) {
        Print("❌ Failed to initialize gap detector");
        return false;
    }
    
    if(!m_integrity_validator.Initialize(m_main_db)) {
        Print("❌ Failed to initialize integrity validator");
        return false;
    }
    
    if(!m_recovery_engine.Initialize(m_main_db)) {
        Print("❌ Failed to initialize recovery engine");
        return false;
    }
    
    Print("✅ All self-healing components initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Run comprehensive health check                                  |
//+------------------------------------------------------------------+
bool CSelfHealingOrchestrator::RunHealthCheck()
{
    if(!m_initialized) return false;
    
    m_last_health_check = TimeCurrent();
    LogHealingActivity("Starting comprehensive health check");
    
    bool overall_healthy = true;
    
    // Check database connectivity
    if(m_main_db == INVALID_HANDLE) {
        m_current_status.database_health = HEALTH_CRITICAL;
        overall_healthy = false;
    } else {
        m_current_status.database_health = HEALTH_GOOD;
    }
    
    // Check data integrity using validator
    if(m_integrity_validator != NULL) {
        bool integrity_ok = m_integrity_validator.ValidateSystemIntegrity();
        m_current_status.data_integrity = integrity_ok ? HEALTH_GOOD : HEALTH_WARNING;
        if(!integrity_ok) overall_healthy = false;
    }
    
    // Check performance metrics
    if(m_performance_monitor != NULL) {
        bool performance_ok = m_performance_monitor.CheckSystemPerformance();
        m_current_status.performance_status = performance_ok ? HEALTH_GOOD : HEALTH_WARNING;
    }
    
    // Update overall status
    m_current_status.overall_health = overall_healthy ? HEALTH_GOOD : HEALTH_WARNING;
    m_current_status.last_check_time = m_last_health_check;
    
    // Trigger healing if needed
    if(!overall_healthy && m_auto_healing_enabled) {
        LogHealingActivity("Health issues detected, triggering healing cycle");
        RunHealingCycle();
    }
    
    return overall_healthy;
}

//+------------------------------------------------------------------+
//| Run healing cycle                                               |
//+------------------------------------------------------------------+
bool CSelfHealingOrchestrator::RunHealingCycle()
{
    if(!m_initialized) return false;
    
    m_last_healing_run = TimeCurrent();
    LogHealingActivity("Starting healing cycle");
    
    bool healing_successful = true;
    
    // Step 1: Detect gaps
    if(m_gap_detector != NULL) {
        int gaps_found = m_gap_detector.ScanForGaps();
        if(gaps_found > 0) {
            LogHealingActivity(StringFormat("Found %d data gaps", gaps_found));
            
            // Step 2: Recover missing data
            if(m_recovery_engine != NULL) {
                int recovered = m_recovery_engine.RecoverMissingData();
                LogHealingActivity(StringFormat("Recovered %d missing data points", recovered));
            }
        }
    }
    
    // Step 3: Validate integrity after healing
    if(m_integrity_validator != NULL) {
        bool integrity_restored = m_integrity_validator.ValidateSystemIntegrity();
        if(!integrity_restored) {
            healing_successful = false;
            LogHealingActivity("WARNING: Integrity validation failed after healing");
        }
    }
    
    LogHealingActivity(StringFormat("Healing cycle completed: %s", 
                      healing_successful ? "SUCCESS" : "PARTIAL"));
    
    return healing_successful;
}

//+------------------------------------------------------------------+
//| Timer check integration                                         |
//+------------------------------------------------------------------+
bool CSelfHealingOrchestrator::OnTimerCheck()
{
    if(!m_initialized) return false;
    
    datetime current_time = TimeCurrent();
    
    // Check if it's time for health check
    if(current_time - m_last_health_check >= m_check_interval) {
        return RunHealthCheck();
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Get health summary string                                       |
//+------------------------------------------------------------------+
string CSelfHealingOrchestrator::GetHealthSummary()
{
    if(!m_initialized) return "Not Initialized";
    
    string status = "UNKNOWN";
    switch(m_current_status.overall_health) {
        case HEALTH_GOOD: status = "HEALTHY"; break;
        case HEALTH_WARNING: status = "WARNING"; break;
        case HEALTH_CRITICAL: status = "CRITICAL"; break;
        default: status = "UNKNOWN"; break;
    }
    
    return StringFormat("Self-Healing Status: %s (Last Check: %s)", 
                       status, TimeToString(m_current_status.last_check_time));
}

//+------------------------------------------------------------------+
//| Cleanup all resources                                           |
//+------------------------------------------------------------------+
void CSelfHealingOrchestrator::Cleanup()
{
    if(m_gap_detector != NULL) { delete m_gap_detector; m_gap_detector = NULL; }
    if(m_integrity_validator != NULL) { delete m_integrity_validator; m_integrity_validator = NULL; }
    if(m_recovery_engine != NULL) { delete m_recovery_engine; m_recovery_engine = NULL; }
    if(m_performance_monitor != NULL) { delete m_performance_monitor; m_performance_monitor = NULL; }
    if(m_boundary_manager != NULL) { delete m_boundary_manager; m_boundary_manager = NULL; }
    if(m_logger != NULL) { delete m_logger; m_logger = NULL; }
    
    m_initialized = false;
}

//+------------------------------------------------------------------+
//| Log healing activity                                            |
//+------------------------------------------------------------------+
void CSelfHealingOrchestrator::LogHealingActivity(const string message)
{
    if(m_logger != NULL) {
        m_logger.LogHealing(message);
    } else {
        Print("🔧 SelfHealing: ", message);
    }
}
