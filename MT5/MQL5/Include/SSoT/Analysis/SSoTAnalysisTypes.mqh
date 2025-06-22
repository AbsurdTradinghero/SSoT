//+------------------------------------------------------------------+
//| SSoTAnalysisTypes.mqh - Type Definitions for SSoT Analysis      |
//| Common structures and enums for the SSoT Analysis System        |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"
#property strict

//--- Analysis Status Enumeration
enum ENUM_ANALYSIS_STATUS
{
    ANALYSIS_STATUS_IDLE,           // Not running
    ANALYSIS_STATUS_INITIALIZING,   // Starting up
    ANALYSIS_STATUS_RUNNING,        // Currently running
    ANALYSIS_STATUS_PAUSED,         // Temporarily paused
    ANALYSIS_STATUS_COMPLETED,      // Successfully completed
    ANALYSIS_STATUS_FAILED,         // Failed with error
    ANALYSIS_STATUS_CANCELLED       // Cancelled by user
};

//--- Test Result Status
enum ENUM_TEST_RESULT
{
    TEST_RESULT_UNKNOWN,           // Not tested yet
    TEST_RESULT_PASSED,            // Test passed
    TEST_RESULT_FAILED,            // Test failed
    TEST_RESULT_WARNING,           // Test passed with warnings
    TEST_RESULT_SKIPPED            // Test was skipped
};

//--- Analysis Type
enum ENUM_ANALYSIS_TYPE
{
    ANALYSIS_TYPE_BASIC,           // Basic functionality test
    ANALYSIS_TYPE_PERFORMANCE,     // Performance analysis
    ANALYSIS_TYPE_STRESS,          // Stress testing
    ANALYSIS_TYPE_INTEGRATION,     // Integration testing
    ANALYSIS_TYPE_CUSTOM          // Custom analysis
};

//--- GUI Tab Type
enum ENUM_TAB_TYPE
{
    TAB_TYPE_OVERVIEW,            // System overview tab
    TAB_TYPE_CLASS_DETAILS,       // Individual class details
    TAB_TYPE_TEST_RESULTS,        // Test results tab
    TAB_TYPE_PERFORMANCE,         // Performance metrics
    TAB_TYPE_LOGS,                // Log viewer
    TAB_TYPE_SETTINGS             // Settings tab
};

//--- SSoT Class Information Structure
struct SSSoTClassInfo
{
    string               class_name;              // Class name
    string               file_path;               // File path
    string               description;             // Class description
    int                  method_count;            // Number of methods
    int                  test_count;              // Number of tests
    ENUM_ANALYSIS_STATUS status;                  // Current analysis status
    datetime             last_tested;             // Last test time
    double               success_rate;            // Success rate percentage
    long                 execution_time_ms;       // Average execution time
    string               version;                 // Class version
    bool                 is_critical;             // Is critical class
    string               dependencies[];          // Class dependencies
    string               tags[];                  // Classification tags
};

//--- Test Method Information
struct STestMethodInfo
{
    string               method_name;             // Method name
    string               description;             // Method description
    ENUM_TEST_RESULT     last_result;            // Last test result
    datetime             last_run;               // Last run time
    long                 execution_time_ms;      // Execution time in ms
    int                  run_count;              // Total run count
    int                  success_count;          // Success count
    string               last_error;             // Last error message
    double               memory_usage_kb;        // Memory usage in KB
    bool                 is_enabled;             // Is test enabled
    int                  priority;               // Test priority
};

//--- Analysis Results Structure
struct SAnalysisResults
{
    string               class_name;              // Analyzed class
    ENUM_ANALYSIS_TYPE   analysis_type;          // Type of analysis
    datetime             start_time;             // Analysis start time
    datetime             end_time;               // Analysis end time
    ENUM_ANALYSIS_STATUS final_status;           // Final status
    int                  total_tests;            // Total number of tests
    int                  passed_tests;           // Number of passed tests
    int                  failed_tests;           // Number of failed tests
    int                  warning_tests;          // Number of tests with warnings
    double               success_rate;           // Overall success rate
    long                 total_execution_time;   // Total execution time
    double               average_memory_usage;   // Average memory usage
    double               peak_memory_usage;      // Peak memory usage
    string               summary;                // Analysis summary
    string               recommendations[];      // Recommendations for improvement
    STestMethodInfo      method_results[];       // Individual method results
};

//--- GUI Panel Configuration
struct SGUIPanelConfig
{
    int                  width;                   // Panel width
    int                  height;                  // Panel height
    int                  x_position;             // X position
    int                  y_position;             // Y position
    bool                 docking_enabled;        // Docking enabled
    bool                 auto_resize;            // Auto resize
    color                background_color;       // Background color
    color                text_color;             // Text color
    color                border_color;           // Border color
    int                  font_size;              // Font size
    string               font_name;              // Font name
    bool                 show_toolbar;           // Show toolbar
    bool                 show_statusbar;         // Show status bar
    int                  tab_height;             // Tab height
    int                  min_width;              // Minimum width
    int                  min_height;             // Minimum height
};

//--- Tab Configuration
struct STabConfig
{
    ENUM_TAB_TYPE        tab_type;               // Tab type
    string               tab_title;              // Tab title
    string               tab_icon;               // Tab icon (optional)
    bool                 is_closable;            // Can be closed
    bool                 is_visible;             // Is visible
    bool                 is_active;              // Is currently active
    int                  sort_order;             // Sort order
    color                tab_color;              // Tab color
    string               tooltip;                // Tooltip text
    void*                data_context;           // Associated data
};

//--- Performance Metrics
struct SPerformanceMetrics
{
    datetime             timestamp;              // Measurement timestamp
    double               cpu_usage_percent;      // CPU usage percentage
    double               memory_usage_mb;        // Memory usage in MB
    double               memory_peak_mb;         // Peak memory usage
    int                  active_objects;         // Number of active objects
    int                  gui_updates_per_sec;    // GUI updates per second
    long                 total_operations;       // Total operations performed
    double               operations_per_sec;     // Operations per second
    long                 database_queries;       // Database queries count
    double               avg_query_time_ms;      // Average query time
    int                  active_threads;         // Active thread count
    double               network_latency_ms;     // Network latency
};

//--- System Status Information
struct SSystemStatus
{
    ENUM_ANALYSIS_STATUS overall_status;         // Overall system status
    datetime             last_update;            // Last status update
    int                  active_analyses;        // Number of active analyses
    int                  queued_analyses;        // Number of queued analyses
    int                  total_classes;          // Total discovered classes
    int                  healthy_classes;        // Number of healthy classes
    int                  problematic_classes;    // Classes with issues
    string               current_operation;      // Current operation
    double               system_load_percent;    // System load percentage
    string               version;                // System version
    bool                 is_connected;           // Connection status
    string               last_error;             // Last system error
    SPerformanceMetrics  performance;            // Current performance metrics
};

//--- Event Information
struct SAnalysisEvent
{
    datetime             timestamp;              // Event timestamp
    string               event_type;             // Event type
    string               class_name;             // Related class
    string               method_name;            // Related method (optional)
    string               message;                // Event message
    string               details;                // Additional details
    int                  severity;               // Severity level (0-5)
    bool                 requires_action;        // Requires user action
    string               action_suggestion;      // Suggested action
};

//--- Configuration Settings
struct SAnalysisConfig
{
    bool                 auto_discovery;         // Auto-discover classes
    string               specific_classes;       // Specific classes to analyze
    int                  max_concurrent_tests;   // Max concurrent tests
    int                  monitoring_interval;    // Monitoring interval (ms)
    bool                 detailed_logging;       // Enable detailed logging
    string               log_level;              // Log level
    bool                 real_time_monitoring;   // Real-time monitoring
    bool                 auto_start_analysis;    // Auto-start on init
    int                  test_timeout_seconds;   // Test timeout
    bool                 stop_on_first_error;    // Stop on first error
    int                  retry_count;            // Number of retries
    bool                 save_results;           // Save results to file
    string               results_path;           // Results file path
    bool                 email_notifications;    // Email notifications
    string               notification_email;     // Notification email
};

//--- Constants
#define MAX_CLASSES              100    // Maximum number of classes
#define MAX_METHODS_PER_CLASS    50     // Maximum methods per class
#define MAX_CONCURRENT_ANALYSES  10     // Maximum concurrent analyses
#define MAX_TAB_COUNT           20      // Maximum number of tabs
#define MAX_LOG_ENTRIES         1000    // Maximum log entries to keep
#define DEFAULT_TIMEOUT_MS      30000   // Default timeout in milliseconds
#define DEFAULT_RETRY_COUNT     3       // Default retry count
#define MIN_PANEL_WIDTH         600     // Minimum panel width
#define MIN_PANEL_HEIGHT        400     // Minimum panel height
#define MAX_PANEL_WIDTH         1920    // Maximum panel width
#define MAX_PANEL_HEIGHT        1080    // Maximum panel height

//--- Color Scheme Constants
#define COLOR_SUCCESS           C'46,125,50'    // Success green
#define COLOR_WARNING           C'255,152,0'    // Warning orange
#define COLOR_ERROR             C'244,67,54'    // Error red
#define COLOR_INFO              C'33,150,243'   // Info blue
#define COLOR_BACKGROUND        C'250,250,250'  // Background white
#define COLOR_PANEL_BG          C'245,245,245'  // Panel background
#define COLOR_TAB_ACTIVE        C'33,150,243'   // Active tab blue
#define COLOR_TAB_INACTIVE      C'189,189,189'  // Inactive tab gray
#define COLOR_BORDER            C'224,224,224'  // Border gray
#define COLOR_TEXT_PRIMARY      C'33,33,33'     // Primary text
#define COLOR_TEXT_SECONDARY    C'117,117,117'  // Secondary text

//--- String Constants
#define STR_ANALYZER_TITLE      "SSoT Class Analyzer"
#define STR_READY               "Ready"
#define STR_INITIALIZING        "Initializing..."
#define STR_ANALYZING           "Analyzing..."
#define STR_COMPLETED           "Completed"
#define STR_FAILED              "Failed"
#define STR_UNKNOWN             "Unknown"
#define STR_NOT_AVAILABLE       "N/A"
#define STR_NO_DATA             "No data available"
#define STR_LOADING             "Loading..."

//--- Utility Functions
string AnalysisStatusToString(ENUM_ANALYSIS_STATUS status)
{
    switch(status)
    {
        case ANALYSIS_STATUS_IDLE:         return "Idle";
        case ANALYSIS_STATUS_INITIALIZING: return "Initializing";
        case ANALYSIS_STATUS_RUNNING:      return "Running";
        case ANALYSIS_STATUS_PAUSED:       return "Paused";
        case ANALYSIS_STATUS_COMPLETED:    return "Completed";
        case ANALYSIS_STATUS_FAILED:       return "Failed";
        case ANALYSIS_STATUS_CANCELLED:    return "Cancelled";
        default:                           return "Unknown";
    }
}

string TestResultToString(ENUM_TEST_RESULT result)
{
    switch(result)
    {
        case TEST_RESULT_UNKNOWN:  return "Unknown";
        case TEST_RESULT_PASSED:   return "Passed";
        case TEST_RESULT_FAILED:   return "Failed";
        case TEST_RESULT_WARNING:  return "Warning";
        case TEST_RESULT_SKIPPED:  return "Skipped";
        default:                   return "Unknown";
    }
}

color GetStatusColor(ENUM_ANALYSIS_STATUS status)
{
    switch(status)
    {
        case ANALYSIS_STATUS_COMPLETED:    return COLOR_SUCCESS;
        case ANALYSIS_STATUS_RUNNING:      return COLOR_INFO;
        case ANALYSIS_STATUS_FAILED:       return COLOR_ERROR;
        case ANALYSIS_STATUS_PAUSED:       return COLOR_WARNING;
        default:                           return COLOR_TEXT_SECONDARY;
    }
}

color GetTestResultColor(ENUM_TEST_RESULT result)
{
    switch(result)
    {
        case TEST_RESULT_PASSED:   return COLOR_SUCCESS;
        case TEST_RESULT_FAILED:   return COLOR_ERROR;
        case TEST_RESULT_WARNING:  return COLOR_WARNING;
        case TEST_RESULT_SKIPPED:  return COLOR_TEXT_SECONDARY;
        default:                   return COLOR_TEXT_SECONDARY;
    }
}
