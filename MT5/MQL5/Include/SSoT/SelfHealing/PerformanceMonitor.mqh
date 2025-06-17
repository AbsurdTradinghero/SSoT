//+------------------------------------------------------------------+
//| PerformanceMonitor.mqh                                           |
//| Small, contained class for monitoring system performance        |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"
#property strict

//--- Performance metrics structure
struct SPerformanceMetrics
{
    datetime            timestamp;
    double              cpu_usage_percent;
    double              memory_usage_mb;
    int                 database_operations_per_sec;
    int                 healing_operations_per_min;
    double              avg_response_time_ms;
    int                 active_connections;
    int                 failed_operations;
    double              success_rate_percent;
    string              bottleneck_component;
};

//+------------------------------------------------------------------+
//| Performance Monitor Class                                        |
//| Purpose: Monitor and analyze system performance metrics         |
//+------------------------------------------------------------------+
class CPerformanceMonitor
{
private:
    SPerformanceMetrics m_current_metrics;
    SPerformanceMetrics m_history[60];     // 60 minutes of history
    int                 m_history_index;
    datetime            m_monitoring_start;
    datetime            m_last_measurement;
    
    // Performance counters
    int                 m_operation_count;
    double              m_total_response_time;
    int                 m_success_count;
    int                 m_failure_count;
    
    // Private methods
    bool                CalculateAverages();
    string              IdentifyBottleneck();
    bool                UpdateCounters();
    
public:
    //--- Constructor/Destructor
    CPerformanceMonitor();
    ~CPerformanceMonitor();
    
    //--- Monitoring Controls
    bool                StartMonitoring();
    bool                StopMonitoring();
    bool                ResetCounters();
    
    //--- Metrics Collection
    bool                RecordOperation(double response_time_ms, bool success);
    bool                RecordDatabaseOperation();
    bool                RecordHealingOperation();
    bool                UpdateConnectionCount(int active_connections);
    
    //--- Performance Analysis
    SPerformanceMetrics GetCurrentMetrics() const { return m_current_metrics; }
    double              GetAverageResponseTime() const;
    double              GetSuccessRate() const;
    int                 GetOperationsPerSecond() const;
    bool                IsPerformanceDegraded() const;
    
    //--- Alerts and Thresholds
    bool                CheckPerformanceThresholds();
    bool                IsResponseTimeCritical() const;
    bool                IsSuccessRateLow() const;
    string              GetPerformanceAlert() const;
    
    //--- Reporting
    string              GeneratePerformanceReport() const;
    string              GenerateBottleneckAnalysis() const;
    bool                ExportMetricsToFile(const string filename) const;
    
    //--- History Management
    bool                AddCurrentToHistory();
    SPerformanceMetrics GetHistoryEntry(int minutes_ago) const;
    double              GetAverageMetricOverTime(const string metric_name, int minutes) const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPerformanceMonitor::CPerformanceMonitor()
{
    // Initialize current metrics
    m_current_metrics.timestamp = TimeCurrent();
    m_current_metrics.cpu_usage_percent = 0.0;
    m_current_metrics.memory_usage_mb = 0.0;
    m_current_metrics.database_operations_per_sec = 0;
    m_current_metrics.healing_operations_per_min = 0;
    m_current_metrics.avg_response_time_ms = 0.0;
    m_current_metrics.active_connections = 0;
    m_current_metrics.failed_operations = 0;
    m_current_metrics.success_rate_percent = 100.0;
    m_current_metrics.bottleneck_component = "";
    
    // Initialize history
    for(int i = 0; i < 60; i++)
    {
        m_history[i] = m_current_metrics;
    }
    m_history_index = 0;
    
    // Initialize counters
    m_monitoring_start = TimeCurrent();
    m_last_measurement = TimeCurrent();
    m_operation_count = 0;
    m_total_response_time = 0.0;
    m_success_count = 0;
    m_failure_count = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                      |
//+------------------------------------------------------------------+
CPerformanceMonitor::~CPerformanceMonitor()
{
    // Nothing to clean up for this simple class
}

//+------------------------------------------------------------------+
//| Start performance monitoring                                    |
//+------------------------------------------------------------------+
bool CPerformanceMonitor::StartMonitoring()
{
    m_monitoring_start = TimeCurrent();
    m_last_measurement = TimeCurrent();
    ResetCounters();
    
    Print("[PERFORMANCE] Monitoring started at ", TimeToString(m_monitoring_start));
    return true;
}

//+------------------------------------------------------------------+
//| Stop performance monitoring                                     |
//+------------------------------------------------------------------+
bool CPerformanceMonitor::StopMonitoring()
{
    Print("[PERFORMANCE] Monitoring stopped. Duration: ", 
          (TimeCurrent() - m_monitoring_start), " seconds");
    return true;
}

//+------------------------------------------------------------------+
//| Reset performance counters                                      |
//+------------------------------------------------------------------+
bool CPerformanceMonitor::ResetCounters()
{
    m_operation_count = 0;
    m_total_response_time = 0.0;
    m_success_count = 0;
    m_failure_count = 0;
    
    return true;
}

//+------------------------------------------------------------------+
//| Record an operation with response time and success status      |
//+------------------------------------------------------------------+
bool CPerformanceMonitor::RecordOperation(double response_time_ms, bool success)
{
    m_operation_count++;
    m_total_response_time += response_time_ms;
    
    if(success)
        m_success_count++;
    else
        m_failure_count++;
    
    // Update current metrics if enough time has passed
    if(TimeCurrent() - m_last_measurement >= 60) // Update every minute
    {
        CalculateAverages();
        m_last_measurement = TimeCurrent();
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Record a database operation                                     |
//+------------------------------------------------------------------+
bool CPerformanceMonitor::RecordDatabaseOperation()
{
    return RecordOperation(1.0, true); // Assume 1ms response time for simple tracking
}

//+------------------------------------------------------------------+
//| Record a healing operation                                      |
//+------------------------------------------------------------------+
bool CPerformanceMonitor::RecordHealingOperation()
{
    return RecordOperation(5.0, true); // Assume 5ms response time for healing ops
}

//+------------------------------------------------------------------+
//| Update active connection count                                  |
//+------------------------------------------------------------------+
bool CPerformanceMonitor::UpdateConnectionCount(int active_connections)
{
    m_current_metrics.active_connections = active_connections;
    m_current_metrics.timestamp = TimeCurrent();
    return true;
}

//+------------------------------------------------------------------+
//| Calculate performance averages                                  |
//+------------------------------------------------------------------+
bool CPerformanceMonitor::CalculateAverages()
{
    datetime current_time = TimeCurrent();
    double elapsed_seconds = (double)(current_time - m_last_measurement);
    
    if(elapsed_seconds <= 0) elapsed_seconds = 60.0;
    
    // Calculate operations per second
    m_current_metrics.database_operations_per_sec = (int)(m_operation_count / elapsed_seconds);
    
    // Calculate average response time
    if(m_operation_count > 0)
    {
        m_current_metrics.avg_response_time_ms = m_total_response_time / m_operation_count;
    }
    
    // Calculate success rate
    int total_ops = m_success_count + m_failure_count;
    if(total_ops > 0)
    {
        m_current_metrics.success_rate_percent = (double)m_success_count / total_ops * 100.0;
    }
    
    // Update other metrics
    m_current_metrics.timestamp = current_time;
    m_current_metrics.failed_operations = m_failure_count;
    m_current_metrics.bottleneck_component = IdentifyBottleneck();
    
    // Add to history
    AddCurrentToHistory();
    
    return true;
}

//+------------------------------------------------------------------+
//| Identify system bottleneck                                      |
//+------------------------------------------------------------------+
string CPerformanceMonitor::IdentifyBottleneck()
{
    if(m_current_metrics.avg_response_time_ms > 100.0)
        return "RESPONSE_TIME";
    
    if(m_current_metrics.success_rate_percent < 95.0)
        return "ERROR_RATE";
    
    if(m_current_metrics.database_operations_per_sec > 1000)
        return "DATABASE_LOAD";
    
    if(m_current_metrics.active_connections > 10)
        return "CONNECTION_LIMIT";
    
    return "NONE";
}

//+------------------------------------------------------------------+
//| Get average response time                                       |
//+------------------------------------------------------------------+
double CPerformanceMonitor::GetAverageResponseTime() const
{
    return m_current_metrics.avg_response_time_ms;
}

//+------------------------------------------------------------------+
//| Get success rate percentage                                     |
//+------------------------------------------------------------------+
double CPerformanceMonitor::GetSuccessRate() const
{
    return m_current_metrics.success_rate_percent;
}

//+------------------------------------------------------------------+
//| Get operations per second                                       |
//+------------------------------------------------------------------+
int CPerformanceMonitor::GetOperationsPerSecond() const
{
    return m_current_metrics.database_operations_per_sec;
}

//+------------------------------------------------------------------+
//| Check if performance is degraded                               |
//+------------------------------------------------------------------+
bool CPerformanceMonitor::IsPerformanceDegraded() const
{
    return (m_current_metrics.avg_response_time_ms > 50.0 ||
            m_current_metrics.success_rate_percent < 98.0 ||
            StringLen(m_current_metrics.bottleneck_component) > 0);
}

//+------------------------------------------------------------------+
//| Check performance thresholds                                   |
//+------------------------------------------------------------------+
bool CPerformanceMonitor::CheckPerformanceThresholds()
{
    bool alert_triggered = false;
    
    if(IsResponseTimeCritical())
    {
        Print("[PERFORMANCE] ALERT: Response time critical (", 
              m_current_metrics.avg_response_time_ms, "ms)");
        alert_triggered = true;
    }
    
    if(IsSuccessRateLow())
    {
        Print("[PERFORMANCE] ALERT: Success rate low (", 
              m_current_metrics.success_rate_percent, "%)");
        alert_triggered = true;
    }
    
    return !alert_triggered;
}

//+------------------------------------------------------------------+
//| Check if response time is critical                             |
//+------------------------------------------------------------------+
bool CPerformanceMonitor::IsResponseTimeCritical() const
{
    return (m_current_metrics.avg_response_time_ms > 100.0);
}

//+------------------------------------------------------------------+
//| Check if success rate is low                                   |
//+------------------------------------------------------------------+
bool CPerformanceMonitor::IsSuccessRateLow() const
{
    return (m_current_metrics.success_rate_percent < 95.0);
}

//+------------------------------------------------------------------+
//| Get performance alert message                                   |
//+------------------------------------------------------------------+
string CPerformanceMonitor::GetPerformanceAlert() const
{
    if(!IsPerformanceDegraded()) return "";
    
    string alert = "PERFORMANCE ALERT: ";
    
    if(IsResponseTimeCritical())
        alert += StringFormat("High response time (%.1fms) ", m_current_metrics.avg_response_time_ms);
    
    if(IsSuccessRateLow())
        alert += StringFormat("Low success rate (%.1f%%) ", m_current_metrics.success_rate_percent);
    
    if(StringLen(m_current_metrics.bottleneck_component) > 0)
        alert += StringFormat("Bottleneck: %s ", m_current_metrics.bottleneck_component);
    
    return alert;
}

//+------------------------------------------------------------------+
//| Generate performance report                                     |
//+------------------------------------------------------------------+
string CPerformanceMonitor::GeneratePerformanceReport() const
{
    string report = "=== PERFORMANCE REPORT ===\n";
    report += StringFormat("Timestamp: %s\n", TimeToString(m_current_metrics.timestamp));
    report += StringFormat("Operations/sec: %d\n", m_current_metrics.database_operations_per_sec);
    report += StringFormat("Avg Response Time: %.2f ms\n", m_current_metrics.avg_response_time_ms);
    report += StringFormat("Success Rate: %.2f%%\n", m_current_metrics.success_rate_percent);
    report += StringFormat("Active Connections: %d\n", m_current_metrics.active_connections);
    report += StringFormat("Failed Operations: %d\n", m_current_metrics.failed_operations);
    
    if(StringLen(m_current_metrics.bottleneck_component) > 0)
    {
        report += StringFormat("Bottleneck: %s\n", m_current_metrics.bottleneck_component);
    }
    
    if(IsPerformanceDegraded())
    {
        report += "Status: DEGRADED\n";
        report += GetPerformanceAlert() + "\n";
    }
    else
    {
        report += "Status: OPTIMAL\n";
    }
    
    return report;
}

//+------------------------------------------------------------------+
//| Add current metrics to history                                 |
//+------------------------------------------------------------------+
bool CPerformanceMonitor::AddCurrentToHistory()
{
    m_history[m_history_index] = m_current_metrics;
    m_history_index = (m_history_index + 1) % 60;
    return true;
}

//+------------------------------------------------------------------+
//| Get history entry from minutes ago                             |
//+------------------------------------------------------------------+
SPerformanceMetrics CPerformanceMonitor::GetHistoryEntry(int minutes_ago) const
{
    SPerformanceMetrics empty_metrics = {0};
    if(minutes_ago < 0 || minutes_ago >= 60) return empty_metrics;
    
    int index = (m_history_index - 1 - minutes_ago + 60) % 60;
    return m_history[index];
}
