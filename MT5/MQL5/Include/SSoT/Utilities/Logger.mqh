//+------------------------------------------------------------------+
//| Logger.mqh - Logging Utility Functions                          |
//| Contains logging functions with enable/disable switch            |
//| for Phase 1 Code Modularization                                  |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.0.0"

// Compile-time logging control switch
#ifndef LOG_ENABLED
#define LOG_ENABLED 1  // Default: logging enabled
#endif

//+------------------------------------------------------------------+
//| Log levels for different types of messages                       |
//+------------------------------------------------------------------+
enum LOG_LEVEL
{
    LOG_INFO,
    LOG_WARNING,
    LOG_ERROR,
    LOG_SUCCESS,
    LOG_DEBUG
};

//+------------------------------------------------------------------+
//| Format message with appropriate prefix based on log level        |
//+------------------------------------------------------------------+
string FormatLogMessage(LOG_LEVEL level, string message)
{
    string prefix = "";
    switch(level)
    {
        case LOG_INFO:    prefix = "ℹ️ "; break;
        case LOG_WARNING: prefix = "⚠️ "; break;
        case LOG_ERROR:   prefix = "❌ "; break;
        case LOG_SUCCESS: prefix = "✅ "; break;
        case LOG_DEBUG:   prefix = "🔍 "; break;
        default:          prefix = "📝 "; break;
    }
    return prefix + message;
}

//+------------------------------------------------------------------+
//| Main logging function with level control                         |
//+------------------------------------------------------------------+
void Log(LOG_LEVEL level, string message)
{
#ifdef LOG_ENABLED
    Print(FormatLogMessage(level, message));
#endif
}

//+------------------------------------------------------------------+
//| Convenience logging functions                                    |
//+------------------------------------------------------------------+
void LogInfo(string message)
{
#ifdef LOG_ENABLED
    Print(FormatLogMessage(LOG_INFO, message));
#endif
}

void LogWarning(string message)
{
#ifdef LOG_ENABLED
    Print(FormatLogMessage(LOG_WARNING, message));
#endif
}

void LogError(string message)
{
#ifdef LOG_ENABLED
    Print(FormatLogMessage(LOG_ERROR, message));
#endif
}

void LogSuccess(string message)
{
#ifdef LOG_ENABLED    Print(FormatLogMessage(LOG_SUCCESS, message));
#endif
}

void LogDebug(string message)
{
#ifdef LOG_ENABLED
    Print(FormatLogMessage(LOG_DEBUG, message));
#endif
}

//+------------------------------------------------------------------+
//| Conditional logging - always logs errors, respects flag for others |
//+------------------------------------------------------------------+
void LogConditional(LOG_LEVEL level, string message, bool force_log = false)
{
    // Always log errors regardless of LOG_ENABLED setting
    if(level == LOG_ERROR || force_log)
    {
        Print(FormatLogMessage(level, message));
        return;
    }
    
    // For other levels, respect the LOG_ENABLED setting
#ifdef LOG_ENABLED
    Print(FormatLogMessage(level, message));
#endif
}

//+------------------------------------------------------------------+
//| Performance logging for operations with timing                   |
//+------------------------------------------------------------------+
void LogPerformance(string operation, ulong start_time, ulong end_time)
{
#ifdef LOG_ENABLED
    ulong duration = end_time - start_time;
    string message = StringFormat("%s completed in %llu microseconds", operation, duration);
    Print(FormatLogMessage(LOG_INFO, message));
#endif
}

//+------------------------------------------------------------------+
//| Database operation logging                                       |
//+------------------------------------------------------------------+
void LogDatabaseOperation(string operation, bool success, string details = "")
{
#ifdef LOG_ENABLED
    LOG_LEVEL level = success ? LOG_SUCCESS : LOG_ERROR;
    string message = StringFormat("Database %s: %s", operation, success ? "SUCCESS" : "FAILED");
    if(details != "")
        message += " - " + details;
    Print(FormatLogMessage(level, message));
#endif
}

//+------------------------------------------------------------------+
//| Summary logging for batch operations                             |
//+------------------------------------------------------------------+
void LogSummary(string operation, int processed, int total, string unit = "items")
{
#ifdef LOG_ENABLED
    string message = StringFormat("%s: %d/%d %s processed", operation, processed, total, unit);
    Print(FormatLogMessage(LOG_INFO, message));
#endif
}
