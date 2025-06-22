//+------------------------------------------------------------------+
//| HealingLogger.mqh - Self-healing operations logging             |
//| Focused class for audit trail and healing operation tracking    |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.0.0"

#ifndef SSOT_HEALING_LOGGER_MQH
#define SSOT_HEALING_LOGGER_MQH

//+------------------------------------------------------------------+
//| Forward declarations                                             |
//+------------------------------------------------------------------+
struct SHealingResult;  // Forward declaration

//+------------------------------------------------------------------+
//| Log Entry Types                                                  |
//+------------------------------------------------------------------+
enum ENUM_LOG_TYPE
{
    LOG_HEALING_START,          // Healing operation started
    LOG_HEALING_SUCCESS,        // Healing operation completed successfully
    LOG_HEALING_FAILURE,        // Healing operation failed
    LOG_DETECTION,              // Issue detection event
    LOG_VALIDATION,             // Validation event
    LOG_PERFORMANCE,            // Performance metrics
    LOG_SYSTEM_EVENT           // System-level events
};

//+------------------------------------------------------------------+
//| Log Entry Severity                                               |
//+------------------------------------------------------------------+
enum ENUM_LOG_SEVERITY
{
    SEVERITY_INFO,              // Informational message
    SEVERITY_WARNING,           // Warning message
    SEVERITY_ERROR,             // Error message
    SEVERITY_CRITICAL          // Critical system issue
};

//+------------------------------------------------------------------+
//| Healing Log Entry Structure                                      |
//+------------------------------------------------------------------+
struct SHealingLogEntry
{
    datetime                  timestamp;
    ENUM_LOG_TYPE            log_type;
    ENUM_LOG_SEVERITY        severity;
    string                   component;
    string                   operation;
    string                   message;
    string                   details;
    int                      duration_ms;
    bool                     success;
    string                   error_code;
};

//+------------------------------------------------------------------+
//| Logger Configuration                                             |
//+------------------------------------------------------------------+
struct SLoggerConfig
{
    bool                     log_to_file;
    bool                     log_to_console;
    bool                     log_to_database;
    string                   log_file_path;
    ENUM_LOG_SEVERITY       min_severity;
    int                      max_log_entries;
    bool                     auto_cleanup;
    int                      cleanup_days;
};

//+------------------------------------------------------------------+
//| Healing Logger Class                                             |
//+------------------------------------------------------------------+
class CHealingLogger
{
private:
    SLoggerConfig            m_config;
    SHealingLogEntry         m_log_entries[];
    bool                     m_initialized;
    int                      m_log_file_handle;
    
    // Statistics
    int                      m_total_entries;
    int                      m_info_count;
    int                      m_warning_count;
    int                      m_error_count;
    int                      m_critical_count;

public:
    CHealingLogger();
    ~CHealingLogger();
    
    // Initialization
    bool Initialize();
    void Configure(const SLoggerConfig &config);
    void Cleanup();    // Main logging methods
    void LogHealingOperation(string operation_type, bool success, int issues_detected, int issues_repaired);
    void LogDetection(string component, string message, ENUM_LOG_SEVERITY severity = SEVERITY_INFO);
    void LogValidation(string component, string message, bool success, int duration_ms = 0);
    void LogPerformance(string component, string operation, int duration_ms, bool success = true);
    void LogSystemEvent(string message, ENUM_LOG_SEVERITY severity = SEVERITY_INFO);
    
    // Generic logging
    void Log(ENUM_LOG_TYPE type, ENUM_LOG_SEVERITY severity, string component,
             string operation, string message, string details = "",
             int duration_ms = 0, bool success = true, string error_code = "");
    
    // Log retrieval
    int GetLogEntriesCount() const { return ArraySize(m_log_entries); }
    SHealingLogEntry GetLogEntry(int index);
    int GetLogEntries(SHealingLogEntry &entries[], ENUM_LOG_TYPE type = -1, ENUM_LOG_SEVERITY min_severity = SEVERITY_INFO);
    int GetRecentEntries(SHealingLogEntry &entries[], int count = 50);
    
    // Log analysis
    string GetLogSummary();
    string GetLogReport(datetime from_time = 0, datetime to_time = 0);
    int CountLogEntries(ENUM_LOG_SEVERITY severity);
    
    // Log management
    void ClearLogs();
    bool ExportLogsToFile(const string &filename);
    bool ImportLogsFromFile(const string &filename);
    void AutoCleanupOldEntries();

private:
    // Internal logging logic
    void WriteToConsole(SHealingLogEntry &entry);
    void WriteToFile(SHealingLogEntry &entry);
    void WriteToDatabase(SHealingLogEntry &entry);
    
    // Helper methods
    string FormatLogEntry(SHealingLogEntry &entry);
    string GetSeverityString(ENUM_LOG_SEVERITY severity);
    string GetTypeString(ENUM_LOG_TYPE type);
    string GetTimestampString(datetime timestamp);
    
    // File operations
    bool OpenLogFile();
    void CloseLogFile();
    bool EnsureLogDirectory();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CHealingLogger::CHealingLogger()
{
    m_initialized = false;
    m_log_file_handle = INVALID_HANDLE;
    
    m_total_entries = 0;
    m_info_count = 0;
    m_warning_count = 0;
    m_error_count = 0;
    m_critical_count = 0;
    
    // Default configuration
    m_config.log_to_file = true;
    m_config.log_to_console = true;
    m_config.log_to_database = false;
    m_config.log_file_path = "SSoT_Healing.log";
    m_config.min_severity = SEVERITY_INFO;
    m_config.max_log_entries = 10000;
    m_config.auto_cleanup = true;
    m_config.cleanup_days = 30;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CHealingLogger::~CHealingLogger()
{
    Cleanup();
}

//+------------------------------------------------------------------+
//| Initialize the logger                                            |
//+------------------------------------------------------------------+
bool CHealingLogger::Initialize()
{
    if(m_config.log_to_file) {
        if(!OpenLogFile()) {
            Print("⚠️ HealingLogger: Failed to open log file, continuing with console logging only");
            m_config.log_to_file = false;
        }
    }
    
    m_initialized = true;
    
    // Log initialization
    LogSystemEvent("HealingLogger initialized successfully", SEVERITY_INFO);
    
    Print("✅ HealingLogger: Initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Log healing operation result                                     |
//+------------------------------------------------------------------+
void CHealingLogger::LogHealingOperation(string operation_type, bool success, int issues_detected, int issues_repaired)
{
    string message = StringFormat("Operation: %s", operation_type);
    string details = StringFormat("Detected: %d, Repaired: %d", issues_detected, issues_repaired);
    
    ENUM_LOG_TYPE log_type = success ? LOG_HEALING_SUCCESS : LOG_HEALING_FAILURE;
    ENUM_LOG_SEVERITY severity = success ? SEVERITY_INFO : SEVERITY_ERROR;
    
    Log(log_type, severity, "SelfHealingManager", operation_type, message, details, 0, success, "");
}

//+------------------------------------------------------------------+
//| Log detection event                                              |
//+------------------------------------------------------------------+
void CHealingLogger::LogDetection(string component, string message, ENUM_LOG_SEVERITY severity)
{
    Log(LOG_DETECTION, severity, component, "Detection", message);
}

//+------------------------------------------------------------------+
//| Log validation event                                             |
//+------------------------------------------------------------------+
void CHealingLogger::LogValidation(string component, string message, bool success, int duration_ms)
{
    ENUM_LOG_SEVERITY severity = success ? SEVERITY_INFO : SEVERITY_WARNING;
    Log(LOG_VALIDATION, severity, component, "Validation", message, "", duration_ms, success);
}

//+------------------------------------------------------------------+
//| Log performance metrics                                          |
//+------------------------------------------------------------------+
void CHealingLogger::LogPerformance(string component, string operation, int duration_ms, bool success)
{
    string message = StringFormat("Performance: %s completed in %dms", operation, duration_ms);
    ENUM_LOG_SEVERITY severity = success ? SEVERITY_INFO : SEVERITY_WARNING;
    Log(LOG_PERFORMANCE, severity, component, operation, message, "", duration_ms, success);
}

//+------------------------------------------------------------------+
//| Log system event                                                 |
//+------------------------------------------------------------------+
void CHealingLogger::LogSystemEvent(string message, ENUM_LOG_SEVERITY severity)
{
    Log(LOG_SYSTEM_EVENT, severity, "System", "Event", message);
}

//+------------------------------------------------------------------+
//| Generic log method                                               |
//+------------------------------------------------------------------+
void CHealingLogger::Log(ENUM_LOG_TYPE type, ENUM_LOG_SEVERITY severity, string component,
                         string operation, string message, string details,
                         int duration_ms, bool success, string error_code)
{
    if(!m_initialized || severity < m_config.min_severity) {
        return;
    }
    
    // Create log entry
    SHealingLogEntry entry;
    entry.timestamp = TimeCurrent();
    entry.log_type = type;
    entry.severity = severity;
    entry.component = component;
    entry.operation = operation;
    entry.message = message;
    entry.details = details;
    entry.duration_ms = duration_ms;
    entry.success = success;
    entry.error_code = error_code;
    
    // Add to memory log
    int size = ArraySize(m_log_entries);
    if(size >= m_config.max_log_entries) {
        // Remove oldest entries if at capacity
        for(int i = 0; i < size - 1; i++) {
            m_log_entries[i] = m_log_entries[i + 1];
        }
        size = m_config.max_log_entries - 1;
    }
    
    ArrayResize(m_log_entries, size + 1);
    m_log_entries[size] = entry;
    
    // Update statistics
    m_total_entries++;
    switch(severity) {
        case SEVERITY_INFO: m_info_count++; break;
        case SEVERITY_WARNING: m_warning_count++; break;
        case SEVERITY_ERROR: m_error_count++; break;
        case SEVERITY_CRITICAL: m_critical_count++; break;
    }
    
    // Write to configured outputs
    if(m_config.log_to_console) {
        WriteToConsole(entry);
    }
    
    if(m_config.log_to_file) {
        WriteToFile(entry);
    }
    
    if(m_config.log_to_database) {
        WriteToDatabase(entry);
    }
    
    // Auto cleanup if enabled
    if(m_config.auto_cleanup && (m_total_entries % 1000) == 0) {
        AutoCleanupOldEntries();
    }
}

//+------------------------------------------------------------------+
//| Write log entry to console                                       |
//+------------------------------------------------------------------+
void CHealingLogger::WriteToConsole(SHealingLogEntry &entry)
{
    string formatted = FormatLogEntry(entry);
    
    // Use different prefixes based on severity
    switch(entry.severity) {
        case SEVERITY_INFO:
            Print("ℹ️ [HEAL] ", formatted);
            break;
        case SEVERITY_WARNING:
            Print("⚠️ [HEAL] ", formatted);
            break;
        case SEVERITY_ERROR:
            Print("❌ [HEAL] ", formatted);
            break;
        case SEVERITY_CRITICAL:
            Print("🚨 [HEAL] ", formatted);
            break;
    }
}

//+------------------------------------------------------------------+
//| Write log entry to file                                          |
//+------------------------------------------------------------------+
void CHealingLogger::WriteToFile(SHealingLogEntry &entry)
{
    if(m_log_file_handle == INVALID_HANDLE) {
        return;
    }
    
    string formatted = FormatLogEntry(entry);
    string line = GetTimestampString(entry.timestamp) + " | " + formatted + "\n";
    
    FileWriteString(m_log_file_handle, line);
    FileFlush(m_log_file_handle);
}

//+------------------------------------------------------------------+
//| Write log entry to database                                      |
//+------------------------------------------------------------------+
void CHealingLogger::WriteToDatabase(SHealingLogEntry &entry)
{
    // This would write to a dedicated logging table in the database
    // For now, this is a placeholder implementation
    // In production, you would:
    // 1. Create a HealingLogs table
    // 2. Insert log entries into the table
    // 3. Implement log querying and cleanup
}

//+------------------------------------------------------------------+
//| Format log entry for display                                     |
//+------------------------------------------------------------------+
string CHealingLogger::FormatLogEntry(SHealingLogEntry &entry)
{
    string formatted = StringFormat("[%s] %s::%s - %s",
                                   GetSeverityString(entry.severity),
                                   entry.component,
                                   entry.operation,
                                   entry.message);
    
    if(entry.details != "") {
        formatted += " | " + entry.details;
    }
    
    if(entry.duration_ms > 0) {
        formatted += StringFormat(" (%dms)", entry.duration_ms);
    }
    
    if(!entry.success && entry.error_code != "") {
        formatted += " [Error: " + entry.error_code + "]";
    }
    
    return formatted;
}

//+------------------------------------------------------------------+
//| Get severity string                                              |
//+------------------------------------------------------------------+
string CHealingLogger::GetSeverityString(ENUM_LOG_SEVERITY severity)
{
    switch(severity) {
        case SEVERITY_INFO: return "INFO";
        case SEVERITY_WARNING: return "WARN";
        case SEVERITY_ERROR: return "ERROR";
        case SEVERITY_CRITICAL: return "CRIT";
        default: return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Get type string                                                  |
//+------------------------------------------------------------------+
string CHealingLogger::GetTypeString(ENUM_LOG_TYPE type)
{
    switch(type) {
        case LOG_HEALING_START: return "HEAL_START";
        case LOG_HEALING_SUCCESS: return "HEAL_SUCCESS";
        case LOG_HEALING_FAILURE: return "HEAL_FAILURE";
        case LOG_DETECTION: return "DETECTION";
        case LOG_VALIDATION: return "VALIDATION";
        case LOG_PERFORMANCE: return "PERFORMANCE";
        case LOG_SYSTEM_EVENT: return "SYSTEM";
        default: return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Get formatted timestamp string                                   |
//+------------------------------------------------------------------+
string CHealingLogger::GetTimestampString(datetime timestamp)
{
    return TimeToString(timestamp, TIME_DATE | TIME_MINUTES | TIME_SECONDS);
}

//+------------------------------------------------------------------+
//| Open log file                                                    |
//+------------------------------------------------------------------+
bool CHealingLogger::OpenLogFile()
{
    if(!EnsureLogDirectory()) {
        return false;
    }
    
    m_log_file_handle = FileOpen(m_config.log_file_path, FILE_WRITE | FILE_READ | FILE_TXT);
    
    if(m_log_file_handle == INVALID_HANDLE) {
        Print("❌ Failed to open log file: ", m_config.log_file_path);
        return false;
    }
    
    // Move to end of file for appending
    FileSeek(m_log_file_handle, 0, SEEK_END);
    
    return true;
}

//+------------------------------------------------------------------+
//| Close log file                                                   |
//+------------------------------------------------------------------+
void CHealingLogger::CloseLogFile()
{
    if(m_log_file_handle != INVALID_HANDLE) {
        FileClose(m_log_file_handle);
        m_log_file_handle = INVALID_HANDLE;
    }
}

//+------------------------------------------------------------------+
//| Ensure log directory exists                                      |
//+------------------------------------------------------------------+
bool CHealingLogger::EnsureLogDirectory()
{    // This would create the log directory if it doesn't exist
    // For now, assume the directory exists
    return true;
}

//+------------------------------------------------------------------+
//| Get specific log entry by index                                  |
//+------------------------------------------------------------------+
SHealingLogEntry CHealingLogger::GetLogEntry(int index)
{
    SHealingLogEntry empty = {};
    if(index < 0 || index >= ArraySize(m_log_entries)) {
        return empty;
    }
    return m_log_entries[index];
}

//+------------------------------------------------------------------+
//| Get filtered log entries                                         |
//+------------------------------------------------------------------+
int CHealingLogger::GetLogEntries(SHealingLogEntry &entries[], ENUM_LOG_TYPE type = -1, ENUM_LOG_SEVERITY min_severity = SEVERITY_INFO)
{
    int count = 0;
    int total = ArraySize(m_log_entries);
    
    // First pass: count matching entries
    for(int i = 0; i < total; i++) {
        if((type == -1 || m_log_entries[i].log_type == type) && 
           m_log_entries[i].severity >= min_severity) {
            count++;
        }
    }
    
    // Resize output array
    ArrayResize(entries, count);
    
    // Second pass: copy matching entries
    int idx = 0;
    for(int i = 0; i < total; i++) {
        if((type == -1 || m_log_entries[i].log_type == type) && 
           m_log_entries[i].severity >= min_severity) {
            entries[idx++] = m_log_entries[i];
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Get log summary                                                  |
//+------------------------------------------------------------------+
string CHealingLogger::GetLogSummary()
{
    string summary = "=== HEALING LOGGER SUMMARY ===\n";
    summary += "Total entries: " + IntegerToString(m_total_entries) + "\n";
    summary += "Info messages: " + IntegerToString(m_info_count) + "\n";
    summary += "Warnings: " + IntegerToString(m_warning_count) + "\n";
    summary += "Errors: " + IntegerToString(m_error_count) + "\n";
    summary += "Critical: " + IntegerToString(m_critical_count) + "\n";
    summary += "Memory entries: " + IntegerToString(ArraySize(m_log_entries)) + "\n";
    summary += "Log file: " + (m_config.log_to_file ? m_config.log_file_path : "Disabled") + "\n";
    
    return summary;
}

//+------------------------------------------------------------------+
//| Get recent log entries                                           |
//+------------------------------------------------------------------+
int CHealingLogger::GetRecentEntries(SHealingLogEntry &entries[], int count)
{
    int total = ArraySize(m_log_entries);
    int start = MathMax(0, total - count);
    int size = total - start;
    
    ArrayResize(entries, size);
    
    for(int i = 0; i < size; i++) {
        entries[i] = m_log_entries[start + i];
    }
    
    return size;
}

//+------------------------------------------------------------------+
//| Auto cleanup old entries                                         |
//+------------------------------------------------------------------+
void CHealingLogger::AutoCleanupOldEntries()
{
    if(!m_config.auto_cleanup) {
        return;
    }
    
    datetime cutoff_time = TimeCurrent() - (m_config.cleanup_days * 24 * 3600);
    int removed = 0;
    
    // Remove entries older than cutoff time
    for(int i = ArraySize(m_log_entries) - 1; i >= 0; i--) {
        if(m_log_entries[i].timestamp < cutoff_time) {
            // Shift remaining entries
            for(int j = i; j < ArraySize(m_log_entries) - 1; j++) {
                m_log_entries[j] = m_log_entries[j + 1];
            }
            ArrayResize(m_log_entries, ArraySize(m_log_entries) - 1);
            removed++;
        }
    }
    
    if(removed > 0) {
        LogSystemEvent(StringFormat("Auto cleanup removed %d old log entries", removed), SEVERITY_INFO);
    }
}

//+------------------------------------------------------------------+
//| Cleanup                                                          |
//+------------------------------------------------------------------+
void CHealingLogger::Cleanup()
{
    if(m_initialized) {
        LogSystemEvent("HealingLogger shutting down", SEVERITY_INFO);
    }
    
    CloseLogFile();
    ArrayResize(m_log_entries, 0);
    m_initialized = false;
}

#endif // SSOT_HEALING_LOGGER_MQH
