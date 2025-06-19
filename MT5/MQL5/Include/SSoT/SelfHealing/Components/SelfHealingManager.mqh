//+------------------------------------------------------------------+
//| SelfHealingManager.mqh - Production Self-Healing System         |
//| Orchestrates all self-healing operations with modular design    |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.0.0"

#include <SSoT/SelfHealing/Components/GapDetector.mqh>
#include <SSoT/SelfHealing/Components/RecoveryEngine.mqh>
#include <SSoT/SelfHealing/ConnectionHealer.mqh>
#include <SSoT/SelfHealing/Components/IntegrityValidator.mqh>
#include <SSoT/SelfHealing/Utilities/HealingLogger.mqh>
#include <SSoT/SelfHealing/Utilities/HealthStatus.mqh>
#include <SSoT/SelfHealing/HealingScheduler.mqh>
#include <SSoT/SelfHealing/Components/PerformanceMonitor.mqh>

//+------------------------------------------------------------------+
//| Self-Healing Operation Types                                    |
//+------------------------------------------------------------------+
enum ENUM_HEALING_TYPE
{
    HEAL_DATA_GAPS,         // Detect and fill missing data gaps
    HEAL_CORRUPTED_DATA,    // Fix hash-mismatched data
    HEAL_CONNECTION,        // Restore database connections
    HEAL_SCHEMA,           // Repair database schema
    HEAL_PERFORMANCE       // Optimize slow operations
};

//+------------------------------------------------------------------+
//| Self-Healing Status                                             |
//+------------------------------------------------------------------+
enum ENUM_HEALING_STATUS
{
    HEALING_IDLE,           // No healing operations active
    HEALING_SCANNING,       // Scanning for issues
    HEALING_REPAIRING,      // Actively repairing issues
    HEALING_VALIDATING,     // Validating repairs
    HEALING_COMPLETE,       // All repairs completed
    HEALING_FAILED          // Healing operations failed
};

//+------------------------------------------------------------------+
//| Healing Operation Result                                         |
//+------------------------------------------------------------------+
struct SHealingResult
{
    ENUM_HEALING_TYPE     type;
    bool                  success;
    int                   issues_detected;
    int                   issues_repaired;
    int                   duration_ms;
    string                error_message;
    datetime              timestamp;
};

//+------------------------------------------------------------------+
//| Self-Healing Configuration                                       |
//+------------------------------------------------------------------+
struct SHealingConfig
{
    bool                  auto_healing_enabled;
    int                   scan_interval_seconds;
    int                   max_repair_attempts;
    bool                  aggressive_healing;
    bool                  backup_before_repair;
    int                   healing_timeout_ms;
    double                success_threshold_percent;
};

//+------------------------------------------------------------------+
//| Main Self-Healing Manager Class                                 |
//+------------------------------------------------------------------+
class CSelfHealingManager
{
private:
    // Component classes
    CDataGapDetector*     m_gap_detector;
    CDataRecoveryEngine*  m_recovery_engine;
    CConnectionHealer*    m_connection_healer;
    CIntegrityValidator*  m_integrity_validator;
    CHealingLogger*       m_logger;
    CHealthStatus*        m_health_status;
    CHealingScheduler*    m_scheduler;
    CPerformanceMonitor*  m_performance_monitor;
    
    // State management
    ENUM_HEALING_STATUS   m_current_status;
    SHealingConfig        m_config;
    SHealingResult        m_last_results[];
    datetime              m_last_scan_time;
    int                   m_active_operations;
    bool                  m_emergency_mode;
    
    // Database handles
    int                   m_main_db;
    int                   m_test_input_db;
    int                   m_test_output_db;
    
    // Performance tracking
    int                   m_total_scans;
    int                   m_successful_heals;
    int                   m_failed_heals;

public:
    CSelfHealingManager();
    ~CSelfHealingManager();
    
    // Initialization and configuration
    bool Initialize(int main_db, int test_input_db, int test_output_db);
    bool Configure(const SHealingConfig &config);
    void Cleanup();
    
    // Main healing operations
    bool StartComprehensiveScan();
    bool PerformTargetedHealing(ENUM_HEALING_TYPE type);
    bool PerformEmergencyHealing();
    bool ValidateSystemHealth();
    
    // Automatic healing
    bool ProcessAutoHealing();
    bool ShouldTriggerAutoHealing();
      // Status and reporting
    ENUM_HEALING_STATUS GetStatus() const { return m_current_status; }
    bool IsHealingActive() const { return m_current_status != HEALING_IDLE; }
    SHealingResult GetLastResult(ENUM_HEALING_TYPE type);
    string GetHealthReport();
    string GetHealingStatistics();
    
    // Health monitoring
    SHealthMetrics GetCurrentHealthMetrics();
    bool IsSystemHealthy();
    string GetPerformanceReport();
    
    // Scheduling
    int ScheduleHealthCheck(datetime when, bool recurring = true);
    bool ProcessScheduledTasks();
    string GetSchedulerStatus();
    
    // Configuration management
    void EnableAutoHealing(bool enable) { m_config.auto_healing_enabled = enable; }
    void SetScanInterval(int seconds) { m_config.scan_interval_seconds = seconds; }
    void SetAggressiveMode(bool aggressive) { m_config.aggressive_healing = aggressive; }
    
    // Emergency controls
    void ActivateEmergencyMode() { m_emergency_mode = true; }
    void DeactivateEmergencyMode() { m_emergency_mode = false; }
    bool IsEmergencyMode() const { return m_emergency_mode; }

private:
    // Internal healing orchestration
    bool ExecuteHealingPipeline(ENUM_HEALING_TYPE type);
    bool ValidateRepairResults(ENUM_HEALING_TYPE type);
    void UpdateHealingStatistics(const SHealingResult &result);
    
    // Component initialization
    bool InitializeComponents();
    void CleanupComponents();
    
    // Safety mechanisms
    bool CheckHealingSafety();
    bool ValidateSystemStability();
    void HandleHealingFailure(ENUM_HEALING_TYPE type, const string &error);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSelfHealingManager::CSelfHealingManager()
{
    m_gap_detector = NULL;
    m_recovery_engine = NULL;
    m_connection_healer = NULL;
    m_integrity_validator = NULL;
    m_logger = NULL;
    m_health_status = NULL;
    m_scheduler = NULL;
    m_performance_monitor = NULL;
    
    m_current_status = HEALING_IDLE;
    m_last_scan_time = 0;
    m_active_operations = 0;
    m_emergency_mode = false;
    
    m_main_db = INVALID_HANDLE;
    m_test_input_db = INVALID_HANDLE;
    m_test_output_db = INVALID_HANDLE;
    
    m_total_scans = 0;
    m_successful_heals = 0;
    m_failed_heals = 0;
    
    // Default configuration
    m_config.auto_healing_enabled = true;
    m_config.scan_interval_seconds = 300; // 5 minutes
    m_config.max_repair_attempts = 3;
    m_config.aggressive_healing = false;
    m_config.backup_before_repair = true;
    m_config.healing_timeout_ms = 30000; // 30 seconds
    m_config.success_threshold_percent = 80.0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSelfHealingManager::~CSelfHealingManager()
{
    Cleanup();
}

//+------------------------------------------------------------------+
//| Initialize the self-healing system                              |
//+------------------------------------------------------------------+
bool CSelfHealingManager::Initialize(int main_db, int test_input_db, int test_output_db)
{
    if(main_db == INVALID_HANDLE) {
        Print("❌ SelfHealingManager: Invalid main database handle");
        return false;
    }
    
    m_main_db = main_db;
    m_test_input_db = test_input_db;
    m_test_output_db = test_output_db;
    
    if(!InitializeComponents()) {
        Print("❌ SelfHealingManager: Failed to initialize components");
        return false;
    }
    
    Print("✅ SelfHealingManager: Initialized successfully");
    Print("🔧 Auto-healing: ", m_config.auto_healing_enabled ? "ENABLED" : "DISABLED");
    Print("⏱️ Scan interval: ", m_config.scan_interval_seconds, " seconds");
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize all component classes                                |
//+------------------------------------------------------------------+
bool CSelfHealingManager::InitializeComponents()
{
    // Initialize logger first
    m_logger = new CHealingLogger();
    if(m_logger == NULL || !m_logger.Initialize()) {
        Print("❌ Failed to initialize HealingLogger");
        return false;
    }
    
    // Initialize gap detector
    m_gap_detector = new CDataGapDetector();
    if(m_gap_detector == NULL || !m_gap_detector.Initialize(m_main_db, m_test_input_db, m_test_output_db)) {
        Print("❌ Failed to initialize DataGapDetector");
        return false;
    }
    
    // Initialize recovery engine
    m_recovery_engine = new CDataRecoveryEngine();
    if(m_recovery_engine == NULL || !m_recovery_engine.Initialize(m_main_db, m_test_input_db, m_test_output_db)) {
        Print("❌ Failed to initialize DataRecoveryEngine");
        return false;
    }
    
    // Initialize connection healer
    m_connection_healer = new CConnectionHealer();
    if(m_connection_healer == NULL || !m_connection_healer.Initialize()) {
        Print("❌ Failed to initialize ConnectionHealer");
        return false;
    }
      // Initialize integrity validator
    m_integrity_validator = new CIntegrityValidator();
    if(m_integrity_validator == NULL || !m_integrity_validator.Initialize(m_main_db, m_test_input_db, m_test_output_db)) {
        Print("❌ Failed to initialize IntegrityValidator");
        return false;
    }
    
    // Initialize health status monitor
    m_health_status = new CHealthStatus();
    if(m_health_status == NULL) {
        Print("❌ Failed to initialize HealthStatus");
        return false;
    }
    
    // Initialize scheduler
    m_scheduler = new CHealingScheduler();
    if(m_scheduler == NULL) {
        Print("❌ Failed to initialize HealingScheduler");
        return false;
    }
    
    // Initialize performance monitor
    m_performance_monitor = new CPerformanceMonitor();
    if(m_performance_monitor == NULL || !m_performance_monitor.StartMonitoring()) {
        Print("❌ Failed to initialize PerformanceMonitor");
        return false;
    }
    
    // Schedule initial health checks
    m_scheduler.ScheduleDataIntegrityCheck(TimeCurrent() + 60, true);  // Start in 1 minute, recurring
    m_scheduler.ScheduleConnectionHealth(TimeCurrent() + 120, true);   // Start in 2 minutes, recurring
    m_scheduler.ScheduleGapDetection(TimeCurrent() + 180, true);       // Start in 3 minutes, recurring
    
    return true;
}

//+------------------------------------------------------------------+
//| Start comprehensive system scan                                 |
//+------------------------------------------------------------------+
bool CSelfHealingManager::StartComprehensiveScan()
{
    if(m_current_status != HEALING_IDLE) {
        Print("⚠️ SelfHealing: Scan already in progress");
        return false;
    }
    
    m_current_status = HEALING_SCANNING;
    m_total_scans++;
    
    Print("🔍 SelfHealing: Starting comprehensive system scan...");
    
    bool overall_success = true;
    
    // Scan for data gaps
    if(!ExecuteHealingPipeline(HEAL_DATA_GAPS)) {
        overall_success = false;
    }
    
    // Scan for data corruption
    if(!ExecuteHealingPipeline(HEAL_CORRUPTED_DATA)) {
        overall_success = false;
    }
    
    // Check connection health
    if(!ExecuteHealingPipeline(HEAL_CONNECTION)) {
        overall_success = false;
    }
    
    m_current_status = overall_success ? HEALING_COMPLETE : HEALING_FAILED;
    m_last_scan_time = TimeCurrent();
    
    Print(overall_success ? "✅ SelfHealing: Comprehensive scan completed successfully" : 
                           "⚠️ SelfHealing: Scan completed with issues");
    
    return overall_success;
}

//+------------------------------------------------------------------+
//| Execute healing pipeline for specific type                      |
//+------------------------------------------------------------------+
bool CSelfHealingManager::ExecuteHealingPipeline(ENUM_HEALING_TYPE type)
{
    ulong start_time = GetTickCount64();
    SHealingResult result;
    result.type = type;
    result.timestamp = TimeCurrent();
    result.success = false;
    result.issues_detected = 0;
    result.issues_repaired = 0;
    result.error_message = "";
    
    switch(type) {
        case HEAL_DATA_GAPS:
            if(m_gap_detector != NULL) {
                result.issues_detected = m_gap_detector.DetectGaps();
                if(result.issues_detected > 0 && m_recovery_engine != NULL) {
                    result.issues_repaired = m_recovery_engine.RepairGaps(result.issues_detected);
                }
                result.success = (result.issues_detected == 0 || result.issues_repaired > 0);
            }
            break;
            
        case HEAL_CORRUPTED_DATA:
            if(m_integrity_validator != NULL) {
                result.issues_detected = m_integrity_validator.DetectCorruption();
                if(result.issues_detected > 0 && m_recovery_engine != NULL) {
                    result.issues_repaired = m_recovery_engine.RepairCorruption(result.issues_detected);
                }
                result.success = (result.issues_detected == 0 || result.issues_repaired > 0);
            }
            break;
            
        case HEAL_CONNECTION:
            if(m_connection_healer != NULL) {
                result.issues_detected = m_connection_healer.DiagnoseConnections();
                if(result.issues_detected > 0) {
                    result.issues_repaired = m_connection_healer.HealConnections();
                }
                result.success = (result.issues_detected == 0 || result.issues_repaired > 0);
            }
            break;
    }
    
    result.duration_ms = (int)(GetTickCount64() - start_time);
    
    // Store result
    int size = ArraySize(m_last_results);
    ArrayResize(m_last_results, size + 1);
    m_last_results[size] = result;
    
    // Update statistics
    UpdateHealingStatistics(result);
    
    // Log the operation
    if(m_logger != NULL) {
        m_logger.LogHealingOperation(result);
    }
    
    return result.success;
}

//+------------------------------------------------------------------+
//| Update healing statistics                                        |
//+------------------------------------------------------------------+
void CSelfHealingManager::UpdateHealingStatistics(const SHealingResult &result)
{
    if(result.success) {
        m_successful_heals++;
    } else {
        m_failed_heals++;
    }
}

//+------------------------------------------------------------------+
//| Process automatic healing                                        |
//+------------------------------------------------------------------+
bool CSelfHealingManager::ProcessAutoHealing()
{
    if(!m_config.auto_healing_enabled || !ShouldTriggerAutoHealing()) {
        return true;
    }
    
    return StartComprehensiveScan();
}

//+------------------------------------------------------------------+
//| Check if auto healing should be triggered                       |
//+------------------------------------------------------------------+
bool CSelfHealingManager::ShouldTriggerAutoHealing()
{
    if(m_current_status != HEALING_IDLE) {
        return false;
    }
    
    datetime time_since_last = TimeCurrent() - m_last_scan_time;
    return (time_since_last >= m_config.scan_interval_seconds);
}

//+------------------------------------------------------------------+
//| Get health report                                                |
//+------------------------------------------------------------------+
string CSelfHealingManager::GetHealthReport()
{
    string report = "=== SELF-HEALING SYSTEM HEALTH REPORT ===\n";
    report += "Status: " + EnumToString(m_current_status) + "\n";
    report += "Auto-healing: " + (m_config.auto_healing_enabled ? "ENABLED" : "DISABLED") + "\n";
    report += "Emergency mode: " + (m_emergency_mode ? "ACTIVE" : "INACTIVE") + "\n";
    report += "Last scan: " + TimeToString(m_last_scan_time) + "\n";
    report += "Total scans: " + IntegerToString(m_total_scans) + "\n";
    report += "Successful heals: " + IntegerToString(m_successful_heals) + "\n";
    report += "Failed heals: " + IntegerToString(m_failed_heals) + "\n";
    
    if(m_total_scans > 0) {
        double success_rate = (double)m_successful_heals / m_total_scans * 100.0;
        report += "Success rate: " + DoubleToString(success_rate, 1) + "%\n";
    }
    
    return report;
}

//+------------------------------------------------------------------+
//| Cleanup                                                          |
//+------------------------------------------------------------------+
void CSelfHealingManager::Cleanup()
{
    CleanupComponents();
    
    m_current_status = HEALING_IDLE;
    m_active_operations = 0;
    ArrayResize(m_last_results, 0);
}

//+------------------------------------------------------------------+
//| Cleanup all components                                           |
//+------------------------------------------------------------------+
void CSelfHealingManager::CleanupComponents()
{
    if(m_gap_detector != NULL) {
        delete m_gap_detector;
        m_gap_detector = NULL;
    }
    
    if(m_recovery_engine != NULL) {
        delete m_recovery_engine;
        m_recovery_engine = NULL;
    }
    
    if(m_connection_healer != NULL) {
        delete m_connection_healer;
        m_connection_healer = NULL;
    }
    
    if(m_integrity_validator != NULL) {
        delete m_integrity_validator;
        m_integrity_validator = NULL;
    }
    
    if(m_logger != NULL) {
        delete m_logger;
        m_logger = NULL;
    }
    
    if(m_health_status != NULL) {
        delete m_health_status;
        m_health_status = NULL;
    }
    
    if(m_scheduler != NULL) {
        delete m_scheduler;
        m_scheduler = NULL;
    }
    
    if(m_performance_monitor != NULL) {
        m_performance_monitor.StopMonitoring();
        delete m_performance_monitor;
        m_performance_monitor = NULL;
    }
}

//+------------------------------------------------------------------+
//| Get current health metrics                                      |
//+------------------------------------------------------------------+
SHealthMetrics CSelfHealingManager::GetCurrentHealthMetrics()
{
    if(m_health_status == NULL) {
        SHealthMetrics empty_metrics = {0};
        return empty_metrics;
    }
    
    return m_health_status.GetCurrentStatus();
}

//+------------------------------------------------------------------+
//| Check if system is healthy                                      |
//+------------------------------------------------------------------+
bool CSelfHealingManager::IsSystemHealthy()
{
    if(m_health_status == NULL) return false;
    return m_health_status.IsHealthy();
}

//+------------------------------------------------------------------+
//| Get performance report                                          |
//+------------------------------------------------------------------+
string CSelfHealingManager::GetPerformanceReport()
{
    if(m_performance_monitor == NULL) return "Performance monitor not initialized";
    return m_performance_monitor.GeneratePerformanceReport();
}

//+------------------------------------------------------------------+
//| Schedule health check                                           |
//+------------------------------------------------------------------+
int CSelfHealingManager::ScheduleHealthCheck(datetime when, bool recurring = true)
{
    if(m_scheduler == NULL) return -1;
    return m_scheduler.ScheduleDataIntegrityCheck(when, recurring);
}

//+------------------------------------------------------------------+
//| Process scheduled tasks                                         |
//+------------------------------------------------------------------+
bool CSelfHealingManager::ProcessScheduledTasks()
{
    if(m_scheduler == NULL) return false;
    
    // Get next due task
    SHealingTask task = m_scheduler.GetNextDueTask();
    if(task.task_id == 0) return true; // No tasks due
    
    bool success = false;
    
    // Execute based on task type
    if(task.task_type == "DataIntegrityCheck") {
        success = ExecuteHealingPipeline(HEAL_CORRUPTED_DATA);
        m_performance_monitor.RecordHealingOperation();
    }
    else if(task.task_type == "ConnectionHealth") {
        success = ExecuteHealingPipeline(HEAL_CONNECTION);
        m_performance_monitor.RecordHealingOperation();
    }
    else if(task.task_type == "GapDetection") {
        success = ExecuteHealingPipeline(HEAL_DATA_GAPS);
        m_performance_monitor.RecordHealingOperation();
    }
    else if(task.task_type == "EmergencyHeal") {
        success = PerformEmergencyHealing();
        m_performance_monitor.RecordHealingOperation();
    }
    
    // Update task status
    m_scheduler.MarkTaskCompleted(task.task_id, success);
    
    return success;
}

//+------------------------------------------------------------------+
//| Get scheduler status                                            |
//+------------------------------------------------------------------+
string CSelfHealingManager::GetSchedulerStatus()
{
    if(m_scheduler == NULL) return "Scheduler not initialized";
    return m_scheduler.GetScheduleStatus();
}

#endif // SSOT_SELF_HEALING_MANAGER_MQH
