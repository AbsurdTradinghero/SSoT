//+------------------------------------------------------------------+
//| BoundaryAwareSelfHealingSystem.mqh                              |
//| Complete self-healing system that respects broker boundaries   |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"
#property strict

#include "BrokerDataBoundaryManager.mqh"
#include "BoundaryAwareGapDetector.mqh"
#include "BoundaryConstrainedHealer.mqh"

//--- System status enumeration
enum BOUNDARY_HEALING_STATUS
{
    BOUNDARY_HEALING_IDLE,
    BOUNDARY_HEALING_SCANNING,
    BOUNDARY_HEALING_DETECTING_BOUNDARIES,
    BOUNDARY_HEALING_DETECTING_GAPS,
    BOUNDARY_HEALING_HEALING_GAPS,
    BOUNDARY_HEALING_VALIDATING,
    BOUNDARY_HEALING_COMPLETE,
    BOUNDARY_HEALING_ERROR
};

//--- System statistics
struct SBoundaryHealingStats
{
    int                 total_symbols_tracked;
    int                 total_boundaries_detected;
    int                 total_gaps_found;
    int                 total_gaps_healed;
    int                 total_healing_operations;
    int                 successful_operations;
    double              overall_sync_percentage;
    datetime            last_full_scan;
    datetime            system_start_time;
    string              current_operation;
};

//+------------------------------------------------------------------+
//| Boundary-Aware Self-Healing System                             |
//| Purpose: Complete 1-1 broker sync with boundary constraints    |
//+------------------------------------------------------------------+
class CBoundaryAwareSelfHealingSystem
{
private:
    // Core components
    CBrokerDataBoundaryManager* m_boundary_manager;
    CBoundaryAwareGapDetector*  m_gap_detector;
    CBoundaryConstrainedHealer* m_healer;
    
    // System state
    BOUNDARY_HEALING_STATUS     m_status;
    SBoundaryHealingStats       m_stats;
    int                         m_database_handle;
    
    // Configuration
    bool                        m_auto_healing_enabled;
    int                         m_scan_interval_seconds;
    int                         m_max_gaps_per_cycle;
    bool                        m_aggressive_mode;
    
    // Tracking
    string                      m_tracked_symbols[50];
    ENUM_TIMEFRAMES             m_tracked_timeframes[50];
    int                         m_tracked_count;
    
public:
    //--- Constructor/Destructor
    CBoundaryAwareSelfHealingSystem();
    ~CBoundaryAwareSelfHealingSystem();
    
    //--- System Management
    bool                        Initialize(int database_handle);
    bool                        RegisterSymbolTimeframe(const string symbol, ENUM_TIMEFRAMES tf);
    bool                        Start();
    bool                        Stop();
    void                        Cleanup();
    
    //--- Main Operations
    bool                        PerformFullSystemScan();
    bool                        PerformIncrementalHealing();
    bool                        PerformEmergencySync();
    bool                        ValidateAllBoundaries();
    
    //--- Automated Processing
    bool                        ProcessAutoHealing();
    bool                        ShouldTriggerHealing();
    bool                        IsReadyForOperation();
    
    //--- Status and Reporting
    BOUNDARY_HEALING_STATUS     GetStatus() const { return m_status; }
    SBoundaryHealingStats       GetStatistics() const { return m_stats; }
    string                      GenerateSystemReport();
    string                      GenerateQuickStatus();
    
    //--- Configuration
    void                        EnableAutoHealing(bool enable) { m_auto_healing_enabled = enable; }
    void                        SetScanInterval(int seconds) { m_scan_interval_seconds = seconds; }
    void                        SetMaxGapsPerCycle(int max_gaps) { m_max_gaps_per_cycle = max_gaps; }
    void                        SetAggressiveMode(bool aggressive) { m_aggressive_mode = aggressive; }
    
    //--- Manual Controls
    bool                        TriggerManualBoundaryDetection();
    bool                        TriggerManualGapDetection();
    bool                        TriggerManualHealing();
    bool                        ForceCompleteResync(const string symbol, ENUM_TIMEFRAMES tf);
    
private:
    //--- Internal operations
    bool                        InitializeComponents();
    bool                        DetectAllBoundaries();
    bool                        DetectAllGaps();
    bool                        HealDetectedGaps();
    bool                        ValidateHealingResults();
    
    //--- Statistics updates
    void                        UpdateStatistics();
    void                        ResetStatistics();
    void                        IncrementOperationCount(bool success);
    
    //--- Utility methods
    string                      StatusToString(BOUNDARY_HEALING_STATUS status);
    bool                        IsSystemHealthy();
    void                        LogSystemEvent(const string message);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CBoundaryAwareSelfHealingSystem::CBoundaryAwareSelfHealingSystem()
{
    m_boundary_manager = NULL;
    m_gap_detector = NULL;
    m_healer = NULL;
    
    m_status = BOUNDARY_HEALING_IDLE;
    m_database_handle = INVALID_HANDLE;
    
    // Initialize configuration
    m_auto_healing_enabled = true;
    m_scan_interval_seconds = 600; // 10 minutes
    m_max_gaps_per_cycle = 10;
    m_aggressive_mode = false;
    
    // Initialize tracking
    m_tracked_count = 0;
    for(int i = 0; i < 50; i++)
    {
        m_tracked_symbols[i] = "";
        m_tracked_timeframes[i] = PERIOD_CURRENT;
    }
    
    // Initialize statistics
    ResetStatistics();
}

//+------------------------------------------------------------------+
//| Destructor                                                      |
//+------------------------------------------------------------------+
CBoundaryAwareSelfHealingSystem::~CBoundaryAwareSelfHealingSystem()
{
    Cleanup();
}

//+------------------------------------------------------------------+
//| Initialize the system                                           |
//+------------------------------------------------------------------+
bool CBoundaryAwareSelfHealingSystem::Initialize(int database_handle)
{
    if(database_handle == INVALID_HANDLE)
    {
        LogSystemEvent("ERROR: Invalid database handle");
        return false;
    }
    
    m_database_handle = database_handle;
    
    if(!InitializeComponents())
    {
        LogSystemEvent("ERROR: Failed to initialize components");
        return false;
    }
    
    m_stats.system_start_time = TimeCurrent();
    m_status = BOUNDARY_HEALING_IDLE;
    
    LogSystemEvent("Boundary-aware self-healing system initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Initialize all components                                       |
//+------------------------------------------------------------------+
bool CBoundaryAwareSelfHealingSystem::InitializeComponents()
{
    // Initialize boundary manager
    m_boundary_manager = new CBrokerDataBoundaryManager();
    if(m_boundary_manager == NULL || !m_boundary_manager.Initialize(m_database_handle))
    {
        LogSystemEvent("ERROR: Failed to initialize boundary manager");
        return false;
    }
    
    // Initialize gap detector
    m_gap_detector = new CBoundaryAwareGapDetector();
    if(m_gap_detector == NULL || !m_gap_detector.Initialize(m_database_handle, m_boundary_manager))
    {
        LogSystemEvent("ERROR: Failed to initialize gap detector");
        return false;
    }
    
    // Initialize healer
    m_healer = new CBoundaryConstrainedHealer();
    if(m_healer == NULL || !m_healer.Initialize(m_database_handle, m_boundary_manager, m_gap_detector))
    {
        LogSystemEvent("ERROR: Failed to initialize healer");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Register symbol/timeframe for tracking                         |
//+------------------------------------------------------------------+
bool CBoundaryAwareSelfHealingSystem::RegisterSymbolTimeframe(const string symbol, ENUM_TIMEFRAMES tf)
{
    if(m_tracked_count >= 50)
    {
        LogSystemEvent("ERROR: Maximum tracked symbols reached (50)");
        return false;
    }
    
    // Check if already registered
    for(int i = 0; i < m_tracked_count; i++)
    {
        if(m_tracked_symbols[i] == symbol && m_tracked_timeframes[i] == tf)
        {
            LogSystemEvent("Symbol/timeframe already registered: " + symbol);
            return true;
        }
    }
    
    // Add to tracking list
    m_tracked_symbols[m_tracked_count] = symbol;
    m_tracked_timeframes[m_tracked_count] = tf;
    m_tracked_count++;
    
    // Register with boundary manager
    if(m_boundary_manager != NULL)
    {
        m_boundary_manager.RegisterSymbolTimeframe(symbol, tf);
    }
    
    m_stats.total_symbols_tracked = m_tracked_count;
    
    LogSystemEvent("Registered for tracking: " + symbol + " " + EnumToString(tf));
    return true;
}

//+------------------------------------------------------------------+
//| Start the system                                               |
//+------------------------------------------------------------------+
bool CBoundaryAwareSelfHealingSystem::Start()
{
    if(m_boundary_manager == NULL || m_gap_detector == NULL || m_healer == NULL)
    {
        LogSystemEvent("ERROR: System components not initialized");
        return false;
    }
    
    LogSystemEvent("Starting boundary-aware self-healing system");
    
    // Perform initial full scan
    if(!PerformFullSystemScan())
    {
        LogSystemEvent("WARNING: Initial system scan failed");
    }
    
    m_status = BOUNDARY_HEALING_IDLE;
    LogSystemEvent("System started successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Perform full system scan                                       |
//+------------------------------------------------------------------+
bool CBoundaryAwareSelfHealingSystem::PerformFullSystemScan()
{
    LogSystemEvent("Starting full system scan");
    m_status = BOUNDARY_HEALING_SCANNING;
    
    bool overall_success = true;
    
    // Step 1: Detect all boundaries
    if(!DetectAllBoundaries())
    {
        LogSystemEvent("ERROR: Boundary detection failed");
        overall_success = false;
    }
    
    // Step 2: Detect all gaps
    if(!DetectAllGaps())
    {
        LogSystemEvent("ERROR: Gap detection failed");
        overall_success = false;
    }
    
    // Step 3: Heal detected gaps (if auto-healing enabled)
    if(m_auto_healing_enabled && !HealDetectedGaps())
    {
        LogSystemEvent("WARNING: Gap healing partially failed");
        // Don't mark as overall failure for healing issues
    }
    
    // Step 4: Validate results
    if(!ValidateHealingResults())
    {
        LogSystemEvent("WARNING: Validation found issues");
    }
    
    m_stats.last_full_scan = TimeCurrent();
    UpdateStatistics();
    
    m_status = overall_success ? BOUNDARY_HEALING_COMPLETE : BOUNDARY_HEALING_ERROR;
    
    LogSystemEvent(overall_success ? "Full system scan completed successfully" : "Full system scan completed with errors");
    return overall_success;
}

//+------------------------------------------------------------------+
//| Detect all boundaries                                           |
//+------------------------------------------------------------------+
bool CBoundaryAwareSelfHealingSystem::DetectAllBoundaries()
{
    m_status = BOUNDARY_HEALING_DETECTING_BOUNDARIES;
    m_stats.current_operation = "Detecting boundaries";
    
    bool success = true;
    int boundaries_detected = 0;
    
    for(int i = 0; i < m_tracked_count; i++)
    {
        string symbol = m_tracked_symbols[i];
        ENUM_TIMEFRAMES tf = m_tracked_timeframes[i];
        
        if(m_boundary_manager.UpdateBoundaries(symbol, tf))
        {
            boundaries_detected++;
        }
        else
        {
            LogSystemEvent("WARNING: Failed to detect boundaries for " + symbol);
            success = false;
        }
    }
    
    m_stats.total_boundaries_detected = boundaries_detected;
    
    LogSystemEvent(StringFormat("Boundary detection: %d/%d successful", boundaries_detected, m_tracked_count));
    return success;
}

//+------------------------------------------------------------------+
//| Detect all gaps                                                 |
//+------------------------------------------------------------------+
bool CBoundaryAwareSelfHealingSystem::DetectAllGaps()
{
    m_status = BOUNDARY_HEALING_DETECTING_GAPS;
    m_stats.current_operation = "Detecting gaps";
    
    bool success = true;
    
    for(int i = 0; i < m_tracked_count; i++)
    {
        string symbol = m_tracked_symbols[i];
        ENUM_TIMEFRAMES tf = m_tracked_timeframes[i];
        
        if(!m_gap_detector.DetectGapsForSymbol(symbol, tf))
        {
            LogSystemEvent("WARNING: Gap detection failed for " + symbol);
            success = false;
        }
    }
    
    m_stats.total_gaps_found = m_gap_detector.GetTotalGapCount();
    
    LogSystemEvent(StringFormat("Gap detection completed: %d gaps found", m_stats.total_gaps_found));
    return success;
}

//+------------------------------------------------------------------+
//| Heal detected gaps                                              |
//+------------------------------------------------------------------+
bool CBoundaryAwareSelfHealingSystem::HealDetectedGaps()
{
    m_status = BOUNDARY_HEALING_HEALING_GAPS;
    m_stats.current_operation = "Healing gaps";
    
    int gaps_healed = 0;
    int healing_attempts = 0;
    
    // Heal gaps up to the maximum per cycle
    for(int i = 0; i < m_max_gaps_per_cycle; i++)
    {
        if(!m_healer.HealHighestPriorityGap())
        {
            break; // No more gaps to heal or healing failed
        }
        
        healing_attempts++;
        if(m_healer.GetLastOperation().success)
        {
            gaps_healed++;
        }
    }
    
    m_stats.total_gaps_healed += gaps_healed;
    m_stats.total_healing_operations += healing_attempts;
    
    if(healing_attempts > 0)
    {
        m_stats.successful_operations += gaps_healed;
    }
    
    LogSystemEvent(StringFormat("Gap healing: %d/%d gaps healed successfully", gaps_healed, healing_attempts));
    return (gaps_healed > 0 || healing_attempts == 0);
}

//+------------------------------------------------------------------+
//| Validate healing results                                        |
//+------------------------------------------------------------------+
bool CBoundaryAwareSelfHealingSystem::ValidateHealingResults()
{
    m_status = BOUNDARY_HEALING_VALIDATING;
    m_stats.current_operation = "Validating results";
    
    double total_sync = 0.0;
    int valid_measurements = 0;
    
    for(int i = 0; i < m_tracked_count; i++)
    {
        string symbol = m_tracked_symbols[i];
        ENUM_TIMEFRAMES tf = m_tracked_timeframes[i];
        
        double sync_percentage = m_boundary_manager.GetSyncPercentage(symbol, tf);
        if(sync_percentage > 0.0)
        {
            total_sync += sync_percentage;
            valid_measurements++;
        }
    }
    
    if(valid_measurements > 0)
    {
        m_stats.overall_sync_percentage = total_sync / valid_measurements;
    }
    
    LogSystemEvent(StringFormat("Validation complete: %.1f%% average sync", m_stats.overall_sync_percentage));
    return true;
}

//+------------------------------------------------------------------+
//| Process automated healing                                       |
//+------------------------------------------------------------------+
bool CBoundaryAwareSelfHealingSystem::ProcessAutoHealing()
{
    if(!m_auto_healing_enabled || !IsReadyForOperation())
    {
        return false;
    }
    
    static datetime last_auto_healing = 0;
    
    if(TimeCurrent() - last_auto_healing < m_scan_interval_seconds)
    {
        return false; // Not time yet
    }
    
    last_auto_healing = TimeCurrent();
    
    LogSystemEvent("Processing automated healing cycle");
    
    // Perform incremental healing
    bool success = PerformIncrementalHealing();
    
    IncrementOperationCount(success);
    
    return success;
}

//+------------------------------------------------------------------+
//| Perform incremental healing                                     |
//+------------------------------------------------------------------+
bool CBoundaryAwareSelfHealingSystem::PerformIncrementalHealing()
{
    LogSystemEvent("Starting incremental healing");
    
    // Quick gap detection and healing
    bool success = true;
    
    // Detect new gaps
    if(!DetectAllGaps())
    {
        success = false;
    }
    
    // Heal a few high-priority gaps
    int max_heals = m_aggressive_mode ? m_max_gaps_per_cycle : MathMin(m_max_gaps_per_cycle, 3);
    
    for(int i = 0; i < max_heals; i++)
    {
        if(!m_healer.HealHighestPriorityGap())
        {
            break;
        }
    }
    
    UpdateStatistics();
    
    LogSystemEvent("Incremental healing completed");
    return success;
}

//+------------------------------------------------------------------+
//| Generate system report                                          |
//+------------------------------------------------------------------+
string CBoundaryAwareSelfHealingSystem::GenerateSystemReport()
{
    string report = "=== BOUNDARY-AWARE SELF-HEALING SYSTEM REPORT ===\n";
    report += StringFormat("Status: %s\n", StatusToString(m_status));
    report += StringFormat("Current Operation: %s\n", m_stats.current_operation);
    report += StringFormat("Auto-Healing: %s\n", m_auto_healing_enabled ? "ENABLED" : "DISABLED");
    report += StringFormat("System Uptime: %d seconds\n", TimeCurrent() - m_stats.system_start_time);
    report += "\n--- TRACKING ---\n";
    report += StringFormat("Symbols Tracked: %d\n", m_stats.total_symbols_tracked);
    report += StringFormat("Boundaries Detected: %d\n", m_stats.total_boundaries_detected);
    report += "\n--- HEALING PERFORMANCE ---\n";
    report += StringFormat("Total Gaps Found: %d\n", m_stats.total_gaps_found);
    report += StringFormat("Total Gaps Healed: %d\n", m_stats.total_gaps_healed);
    report += StringFormat("Healing Operations: %d\n", m_stats.total_healing_operations);
    report += StringFormat("Success Rate: %.1f%%\n", m_stats.total_healing_operations > 0 ? 
              (double)m_stats.successful_operations / m_stats.total_healing_operations * 100.0 : 100.0);
    report += StringFormat("Overall Sync: %.1f%%\n", m_stats.overall_sync_percentage);
    report += StringFormat("Last Full Scan: %s\n", TimeToString(m_stats.last_full_scan));
    
    return report;
}

//+------------------------------------------------------------------+
//| Generate quick status                                           |
//+------------------------------------------------------------------+
string CBoundaryAwareSelfHealingSystem::GenerateQuickStatus()
{
    string status = "BoundaryHealing: ";
    status += StatusToString(m_status);
    
    if(m_stats.total_gaps_found > 0)
    {
        status += StringFormat(" | Gaps: %d", m_stats.total_gaps_found);
    }
    
    status += StringFormat(" | Sync: %.1f%%", m_stats.overall_sync_percentage);
    
    if(!m_auto_healing_enabled)
    {
        status += " | AUTO-DISABLED";
    }
    
    return status;
}

//+------------------------------------------------------------------+
//| Update statistics                                               |
//+------------------------------------------------------------------+
void CBoundaryAwareSelfHealingSystem::UpdateStatistics()
{
    if(m_gap_detector != NULL)
    {
        m_stats.total_gaps_found = m_gap_detector.GetTotalGapCount();
    }
    
    if(m_healer != NULL)
    {
        // Additional healer statistics could be added here
    }
}

//+------------------------------------------------------------------+
//| Check if system is ready for operation                         |
//+------------------------------------------------------------------+
bool CBoundaryAwareSelfHealingSystem::IsReadyForOperation()
{
    return (m_status == BOUNDARY_HEALING_IDLE || m_status == BOUNDARY_HEALING_COMPLETE) &&
           m_boundary_manager != NULL && m_gap_detector != NULL && m_healer != NULL;
}

//+------------------------------------------------------------------+
//| Convert status to string                                        |
//+------------------------------------------------------------------+
string CBoundaryAwareSelfHealingSystem::StatusToString(BOUNDARY_HEALING_STATUS status)
{
    switch(status)
    {
        case BOUNDARY_HEALING_IDLE: return "IDLE";
        case BOUNDARY_HEALING_SCANNING: return "SCANNING";
        case BOUNDARY_HEALING_DETECTING_BOUNDARIES: return "DETECTING_BOUNDARIES";
        case BOUNDARY_HEALING_DETECTING_GAPS: return "DETECTING_GAPS";
        case BOUNDARY_HEALING_HEALING_GAPS: return "HEALING_GAPS";
        case BOUNDARY_HEALING_VALIDATING: return "VALIDATING";
        case BOUNDARY_HEALING_COMPLETE: return "COMPLETE";
        case BOUNDARY_HEALING_ERROR: return "ERROR";
        default: return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Reset statistics                                                |
//+------------------------------------------------------------------+
void CBoundaryAwareSelfHealingSystem::ResetStatistics()
{
    m_stats.total_symbols_tracked = 0;
    m_stats.total_boundaries_detected = 0;
    m_stats.total_gaps_found = 0;
    m_stats.total_gaps_healed = 0;
    m_stats.total_healing_operations = 0;
    m_stats.successful_operations = 0;
    m_stats.overall_sync_percentage = 0.0;
    m_stats.last_full_scan = 0;
    m_stats.system_start_time = TimeCurrent();
    m_stats.current_operation = "Initializing";
}

//+------------------------------------------------------------------+
//| Cleanup resources                                               |
//+------------------------------------------------------------------+
void CBoundaryAwareSelfHealingSystem::Cleanup()
{
    if(m_boundary_manager != NULL)
    {
        delete m_boundary_manager;
        m_boundary_manager = NULL;
    }
    
    if(m_gap_detector != NULL)
    {
        delete m_gap_detector;
        m_gap_detector = NULL;
    }
    
    if(m_healer != NULL)
    {
        delete m_healer;
        m_healer = NULL;
    }
    
    m_status = BOUNDARY_HEALING_IDLE;
    LogSystemEvent("System cleanup completed");
}

//+------------------------------------------------------------------+
//| Log system events                                               |
//+------------------------------------------------------------------+
void CBoundaryAwareSelfHealingSystem::LogSystemEvent(const string message)
{
    Print("[BOUNDARY-HEALING] ", message);
}

//+------------------------------------------------------------------+
//| Increment operation count                                       |
//+------------------------------------------------------------------+
void CBoundaryAwareSelfHealingSystem::IncrementOperationCount(bool success)
{
    m_stats.total_healing_operations++;
    if(success)
    {
        m_stats.successful_operations++;
    }
}
