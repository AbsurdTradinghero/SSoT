//+------------------------------------------------------------------+
//| HealthStatus.mqh                                                 |
//| Small, contained class for tracking system health status        |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"
#property strict

//--- Health status enumeration
enum HEALTH_STATUS_TYPE
{
    HEALTH_UNKNOWN = 0,
    HEALTH_EXCELLENT = 1,
    HEALTH_GOOD = 2,
    HEALTH_WARNING = 3,
    HEALTH_CRITICAL = 4,
    HEALTH_FAILED = 5
};

//--- Health metrics structure
struct SHealthMetrics
{
    datetime            timestamp;
    HEALTH_STATUS_TYPE  overall_status;
    HEALTH_STATUS_TYPE  database_status;
    HEALTH_STATUS_TYPE  connection_status;
    HEALTH_STATUS_TYPE  data_integrity_status;
    int                 gaps_detected;
    int                 corruption_incidents;
    int                 healing_attempts;
    int                 successful_heals;
    double              uptime_percentage;
    string              last_error_message;
};

//+------------------------------------------------------------------+
//| Health Status Monitor Class                                     |
//| Purpose: Track and report system health metrics                 |
//+------------------------------------------------------------------+
class CHealthStatus
{
private:
    SHealthMetrics      m_current_metrics;
    SHealthMetrics      m_history[24];  // 24-hour history
    int                 m_history_index;
    datetime            m_last_update;
    
public:
    //--- Constructor/Destructor
    CHealthStatus();
    ~CHealthStatus();
    
    //--- Status Management
    bool                UpdateStatus(const SHealthMetrics &metrics);
    SHealthMetrics      GetCurrentStatus() const { return m_current_metrics; }
    HEALTH_STATUS_TYPE  GetOverallHealth() const { return m_current_metrics.overall_status; }
    
    //--- Status Evaluation
    HEALTH_STATUS_TYPE  EvaluateOverallHealth();
    bool                IsHealthy() const;
    bool                RequiresAttention() const;
    bool                IsCritical() const;
    
    //--- Metrics
    double              GetUptimePercentage() const { return m_current_metrics.uptime_percentage; }
    int                 GetGapsDetected() const { return m_current_metrics.gaps_detected; }
    int                 GetHealingSuccessRate() const;
    
    //--- History Management
    bool                AddToHistory();
    SHealthMetrics      GetHistoryEntry(int index) const;
    string              GenerateHealthReport() const;
    
    //--- Status String Conversion
    string              StatusToString(HEALTH_STATUS_TYPE status) const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CHealthStatus::CHealthStatus()
{
    // Initialize current metrics
    m_current_metrics.timestamp = TimeCurrent();
    m_current_metrics.overall_status = HEALTH_UNKNOWN;
    m_current_metrics.database_status = HEALTH_UNKNOWN;
    m_current_metrics.connection_status = HEALTH_UNKNOWN;
    m_current_metrics.data_integrity_status = HEALTH_UNKNOWN;
    m_current_metrics.gaps_detected = 0;
    m_current_metrics.corruption_incidents = 0;
    m_current_metrics.healing_attempts = 0;
    m_current_metrics.successful_heals = 0;
    m_current_metrics.uptime_percentage = 100.0;
    m_current_metrics.last_error_message = "";
    
    // Initialize history
    ArrayInitialize(m_history, m_current_metrics);
    m_history_index = 0;
    m_last_update = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Destructor                                                      |
//+------------------------------------------------------------------+
CHealthStatus::~CHealthStatus()
{
    // Nothing to clean up for this simple class
}

//+------------------------------------------------------------------+
//| Update status with new metrics                                  |
//+------------------------------------------------------------------+
bool CHealthStatus::UpdateStatus(const SHealthMetrics &metrics)
{
    m_current_metrics = metrics;
    m_current_metrics.timestamp = TimeCurrent();
    m_current_metrics.overall_status = EvaluateOverallHealth();
    m_last_update = TimeCurrent();
    
    return true;
}

//+------------------------------------------------------------------+
//| Evaluate overall health based on component statuses            |
//+------------------------------------------------------------------+
HEALTH_STATUS_TYPE CHealthStatus::EvaluateOverallHealth()
{
    // Critical if any component is failed
    if(m_current_metrics.database_status == HEALTH_FAILED ||
       m_current_metrics.connection_status == HEALTH_FAILED ||
       m_current_metrics.data_integrity_status == HEALTH_FAILED)
    {
        return HEALTH_FAILED;
    }
    
    // Critical if any component is critical
    if(m_current_metrics.database_status == HEALTH_CRITICAL ||
       m_current_metrics.connection_status == HEALTH_CRITICAL ||
       m_current_metrics.data_integrity_status == HEALTH_CRITICAL)
    {
        return HEALTH_CRITICAL;
    }
    
    // Warning if any component has warnings or too many gaps
    if(m_current_metrics.database_status == HEALTH_WARNING ||
       m_current_metrics.connection_status == HEALTH_WARNING ||
       m_current_metrics.data_integrity_status == HEALTH_WARNING ||
       m_current_metrics.gaps_detected > 5)
    {
        return HEALTH_WARNING;
    }
    
    // Good if uptime is acceptable
    if(m_current_metrics.uptime_percentage >= 95.0)
    {
        return HEALTH_EXCELLENT;
    }
    else if(m_current_metrics.uptime_percentage >= 90.0)
    {
        return HEALTH_GOOD;
    }
    
    return HEALTH_WARNING;
}

//+------------------------------------------------------------------+
//| Check if system is healthy                                      |
//+------------------------------------------------------------------+
bool CHealthStatus::IsHealthy() const
{
    return (m_current_metrics.overall_status == HEALTH_EXCELLENT ||
            m_current_metrics.overall_status == HEALTH_GOOD);
}

//+------------------------------------------------------------------+
//| Check if system requires attention                              |
//+------------------------------------------------------------------+
bool CHealthStatus::RequiresAttention() const
{
    return (m_current_metrics.overall_status == HEALTH_WARNING ||
            m_current_metrics.overall_status == HEALTH_CRITICAL);
}

//+------------------------------------------------------------------+
//| Check if system is in critical state                           |
//+------------------------------------------------------------------+
bool CHealthStatus::IsCritical() const
{
    return (m_current_metrics.overall_status == HEALTH_CRITICAL ||
            m_current_metrics.overall_status == HEALTH_FAILED);
}

//+------------------------------------------------------------------+
//| Get healing success rate percentage                             |
//+------------------------------------------------------------------+
int CHealthStatus::GetHealingSuccessRate() const
{
    if(m_current_metrics.healing_attempts == 0) return 100;
    return (int)((double)m_current_metrics.successful_heals / m_current_metrics.healing_attempts * 100.0);
}

//+------------------------------------------------------------------+
//| Add current status to history                                   |
//+------------------------------------------------------------------+
bool CHealthStatus::AddToHistory()
{
    m_history[m_history_index] = m_current_metrics;
    m_history_index = (m_history_index + 1) % 24;
    return true;
}

//+------------------------------------------------------------------+
//| Get history entry by index                                      |
//+------------------------------------------------------------------+
SHealthMetrics CHealthStatus::GetHistoryEntry(int index) const
{
    SHealthMetrics empty_metrics = {0};
    if(index < 0 || index >= 24) return empty_metrics;
    return m_history[index];
}

//+------------------------------------------------------------------+
//| Generate comprehensive health report                            |
//+------------------------------------------------------------------+
string CHealthStatus::GenerateHealthReport() const
{
    string report = "=== SYSTEM HEALTH REPORT ===\n";
    report += StringFormat("Timestamp: %s\n", TimeToString(m_current_metrics.timestamp));
    report += StringFormat("Overall Status: %s\n", StatusToString(m_current_metrics.overall_status));
    report += StringFormat("Database: %s\n", StatusToString(m_current_metrics.database_status));
    report += StringFormat("Connection: %s\n", StatusToString(m_current_metrics.connection_status));
    report += StringFormat("Data Integrity: %s\n", StatusToString(m_current_metrics.data_integrity_status));
    report += StringFormat("Uptime: %.2f%%\n", m_current_metrics.uptime_percentage);
    report += StringFormat("Gaps Detected: %d\n", m_current_metrics.gaps_detected);
    report += StringFormat("Healing Success Rate: %d%%\n", GetHealingSuccessRate());
    
    if(StringLen(m_current_metrics.last_error_message) > 0)
    {
        report += StringFormat("Last Error: %s\n", m_current_metrics.last_error_message);
    }
    
    return report;
}

//+------------------------------------------------------------------+
//| Convert status enum to string                                   |
//+------------------------------------------------------------------+
string CHealthStatus::StatusToString(HEALTH_STATUS_TYPE status) const
{
    switch(status)
    {
        case HEALTH_EXCELLENT: return "EXCELLENT";
        case HEALTH_GOOD: return "GOOD";
        case HEALTH_WARNING: return "WARNING";
        case HEALTH_CRITICAL: return "CRITICAL";
        case HEALTH_FAILED: return "FAILED";
        default: return "UNKNOWN";
    }
}
