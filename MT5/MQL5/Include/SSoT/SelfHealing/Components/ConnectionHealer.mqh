//+------------------------------------------------------------------+
//| ConnectionHealer.mqh - Database connection self-healing          |
//| Focused class for database connectivity issues                  |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.0.0"

//+------------------------------------------------------------------+
//| Connection Status Enumeration                                    |
//+------------------------------------------------------------------+
enum ENUM_CONNECTION_STATUS
{
    CONNECTION_HEALTHY,         // Connection is working properly
    CONNECTION_SLOW,           // Connection is slow but functional
    CONNECTION_UNSTABLE,       // Connection has intermittent issues
    CONNECTION_FAILED,         // Connection is not working
    CONNECTION_UNKNOWN         // Connection status not determined
};

//+------------------------------------------------------------------+
//| Connection Issue Types                                           |
//+------------------------------------------------------------------+
enum ENUM_CONNECTION_ISSUE
{
    ISSUE_NONE,                // No issues detected
    ISSUE_TIMEOUT,             // Database operation timeouts
    ISSUE_LOCK,                // Database lock issues
    ISSUE_CORRUPTION,          // Database file corruption
    ISSUE_PERMISSIONS,         // File permission problems
    ISSUE_DISK_SPACE,          // Insufficient disk space
    ISSUE_MEMORY               // Memory allocation issues
};

//+------------------------------------------------------------------+
//| Connection Diagnostic Result                                     |
//+------------------------------------------------------------------+
struct SConnectionDiagnostic
{
    string                    database_name;
    int                       database_handle;
    ENUM_CONNECTION_STATUS    status;
    ENUM_CONNECTION_ISSUE     primary_issue;
    int                       response_time_ms;
    int                       error_count;
    bool                      can_read;
    bool                      can_write;
    bool                      schema_valid;
    string                    error_message;
    datetime                  last_checked;
};

//+------------------------------------------------------------------+
//| Connection Healing Configuration                                 |
//+------------------------------------------------------------------+
struct SConnectionConfig
{
    int                       max_retry_attempts;
    int                       retry_delay_ms;
    int                       timeout_threshold_ms;
    bool                      auto_reconnect;
    bool                      create_missing_tables;
    bool                      repair_corruption;
    int                       health_check_interval_seconds;
};

//+------------------------------------------------------------------+
//| Connection Healer Class                                          |
//+------------------------------------------------------------------+
class CConnectionHealer
{
private:
    SConnectionConfig         m_config;
    SConnectionDiagnostic     m_diagnostics[];
    bool                      m_initialized;
    datetime                  m_last_health_check;
    
    // Tracking statistics
    int                       m_total_diagnoses;
    int                       m_successful_heals;
    int                       m_failed_heals;
    int                       m_auto_reconnects;

public:
    CConnectionHealer();
    ~CConnectionHealer();
    
    // Initialization
    bool Initialize();
    void Configure(const SConnectionConfig &config);
    
    // Main diagnostic and healing methods
    int DiagnoseConnections();
    int DiagnoseConnection(int db_handle, const string &db_name);
    int HealConnections();
    bool HealSpecificConnection(int &db_handle, const string &db_name);
    
    // Health monitoring
    bool PerformHealthCheck();
    bool IsConnectionHealthy(int db_handle);
    ENUM_CONNECTION_STATUS GetConnectionStatus(int db_handle);
    
    // Connection testing
    bool TestBasicConnectivity(int db_handle);
    bool TestReadOperations(int db_handle);
    bool TestWriteOperations(int db_handle);
    bool TestSchemaIntegrity(int db_handle);
    
    // Healing strategies
    bool AttemptReconnection(int &db_handle, const string &db_name);
    bool RepairDatabaseFile(const string &db_name);
    bool RecreateConnection(int &db_handle, const string &db_name);
    bool ValidateAndRepairSchema(int db_handle);
    
    // Utility methods
    int MeasureResponseTime(int db_handle);
    bool CheckDiskSpace(const string &db_path);
    bool CheckFilePermissions(const string &db_path);
    
    // Reporting
    string GetConnectionReport();
    SConnectionDiagnostic GetDiagnostic(const string &db_name);

private:
    // Internal healing logic
    ENUM_CONNECTION_ISSUE IdentifyPrimaryIssue(int db_handle, const string &db_name);
    bool ExecuteHealingStrategy(ENUM_CONNECTION_ISSUE issue, int &db_handle, const string &db_name);
    void UpdateDiagnostic(const string &db_name, const SConnectionDiagnostic &diagnostic);
    
    // Database operation helpers
    bool ExecuteTestQuery(int db_handle, const string &query);
    bool ExecuteTestInsert(int db_handle);
    bool CheckTableExists(int db_handle, const string &table_name);
    
    // File system helpers
    string GetDatabaseFilePath(const string &db_name);
    long GetFileSize(const string &file_path);
    bool FileExists(const string &file_path);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CConnectionHealer::CConnectionHealer()
{
    m_initialized = false;
    m_last_health_check = 0;
    
    m_total_diagnoses = 0;
    m_successful_heals = 0;
    m_failed_heals = 0;
    m_auto_reconnects = 0;
    
    // Default configuration
    m_config.max_retry_attempts = 3;
    m_config.retry_delay_ms = 1000;
    m_config.timeout_threshold_ms = 5000;
    m_config.auto_reconnect = true;
    m_config.create_missing_tables = true;
    m_config.repair_corruption = true;
    m_config.health_check_interval_seconds = 60;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CConnectionHealer::~CConnectionHealer()
{
    ArrayResize(m_diagnostics, 0);
}

//+------------------------------------------------------------------+
//| Initialize the connection healer                                 |
//+------------------------------------------------------------------+
bool CConnectionHealer::Initialize()
{
    m_initialized = true;
    Print("✅ ConnectionHealer: Initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Diagnose all registered connections                              |
//+------------------------------------------------------------------+
int CConnectionHealer::DiagnoseConnections()
{
    if(!m_initialized) {
        Print("❌ ConnectionHealer: Not initialized");
        return -1;
    }
    
    Print("🔍 ConnectionHealer: Starting connection diagnostics...");
    
    int total_issues = 0;
    m_total_diagnoses++;
    
    // In a production system, this would iterate through all registered database connections
    // For now, we'll simulate the diagnostic process
    
    // Simulate diagnosing 3 databases (main, test_input, test_output)
    string database_names[] = {"sourcedb.sqlite", "SSoT_input.db", "SSoT_output.db"};
    int simulated_handles[] = {1, 2, 3}; // Simulated handles
    
    for(int i = 0; i < ArraySize(database_names); i++) {
        int issues = DiagnoseConnection(simulated_handles[i], database_names[i]);
        total_issues += issues;
    }
    
    m_last_health_check = TimeCurrent();
    
    Print("🔍 ConnectionHealer: Diagnostics complete - ", total_issues, " issues detected");
    return total_issues;
}

//+------------------------------------------------------------------+
//| Diagnose specific connection                                     |
//+------------------------------------------------------------------+
int CConnectionHealer::DiagnoseConnection(int db_handle, const string &db_name)
{
    Print("🔍 Diagnosing connection: ", db_name);
    
    SConnectionDiagnostic diagnostic;
    diagnostic.database_name = db_name;
    diagnostic.database_handle = db_handle;
    diagnostic.last_checked = TimeCurrent();
    diagnostic.error_count = 0;
    diagnostic.error_message = "";
    
    ulong start_time = GetTickCount64();
    
    // Test basic connectivity
    diagnostic.can_read = TestReadOperations(db_handle);
    diagnostic.can_write = TestWriteOperations(db_handle);
    diagnostic.schema_valid = TestSchemaIntegrity(db_handle);
    
    // Measure response time
    diagnostic.response_time_ms = MeasureResponseTime(db_handle);
    
    // Determine overall status
    if(!diagnostic.can_read || !diagnostic.can_write) {
        diagnostic.status = CONNECTION_FAILED;
        diagnostic.error_count++;
    } else if(diagnostic.response_time_ms > m_config.timeout_threshold_ms) {
        diagnostic.status = CONNECTION_SLOW;
    } else if(!diagnostic.schema_valid) {
        diagnostic.status = CONNECTION_UNSTABLE;
        diagnostic.error_count++;
    } else {
        diagnostic.status = CONNECTION_HEALTHY;
    }
    
    // Identify primary issue
    diagnostic.primary_issue = IdentifyPrimaryIssue(db_handle, db_name);
    
    // Update diagnostic record
    UpdateDiagnostic(db_name, diagnostic);
    
    Print("📊 ", db_name, " status: ", EnumToString(diagnostic.status), 
          " (", diagnostic.response_time_ms, "ms, issues: ", diagnostic.error_count, ")");
    
    return diagnostic.error_count;
}

//+------------------------------------------------------------------+
//| Heal all connections with issues                                 |
//+------------------------------------------------------------------+
int CConnectionHealer::HealConnections()
{
    Print("🔧 ConnectionHealer: Starting connection healing...");
    
    int healed_connections = 0;
    
    for(int i = 0; i < ArraySize(m_diagnostics); i++) {
        if(m_diagnostics[i].status != CONNECTION_HEALTHY) {
            int db_handle = m_diagnostics[i].database_handle;
            string db_name = m_diagnostics[i].database_name;
            
            if(HealSpecificConnection(db_handle, db_name)) {
                healed_connections++;
                m_successful_heals++;
            } else {
                m_failed_heals++;
            }
        }
    }
    
    Print("🔧 ConnectionHealer: Healing complete - ", healed_connections, " connections healed");
    return healed_connections;
}

//+------------------------------------------------------------------+
//| Heal specific connection                                         |
//+------------------------------------------------------------------+
bool CConnectionHealer::HealSpecificConnection(int &db_handle, const string &db_name)
{
    Print("🔧 Healing connection: ", db_name);
    
    // Find the diagnostic for this connection
    SConnectionDiagnostic diagnostic;
    bool found = false;
    
    for(int i = 0; i < ArraySize(m_diagnostics); i++) {
        if(m_diagnostics[i].database_name == db_name) {
            diagnostic = m_diagnostics[i];
            found = true;
            break;
        }
    }
    
    if(!found) {
        Print("❌ No diagnostic found for ", db_name);
        return false;
    }
    
    bool success = false;
    
    // Execute healing strategy based on primary issue
    switch(diagnostic.primary_issue) {
        case ISSUE_TIMEOUT:
        case ISSUE_UNSTABLE:
            success = AttemptReconnection(db_handle, db_name);
            break;
            
        case ISSUE_CORRUPTION:
            success = RepairDatabaseFile(db_name);
            if(success) {
                success = AttemptReconnection(db_handle, db_name);
            }
            break;
            
        case ISSUE_LOCK:
            Sleep(1000); // Wait for locks to release
            success = AttemptReconnection(db_handle, db_name);
            break;
            
        case ISSUE_PERMISSIONS:
            Print("⚠️ Permission issues require manual intervention");
            success = false;
            break;
            
        case ISSUE_DISK_SPACE:
            Print("⚠️ Disk space issues require manual intervention");
            success = false;
            break;
            
        default:
            success = AttemptReconnection(db_handle, db_name);
            break;
    }
    
    // Validate healing success
    if(success) {
        // Re-diagnose to confirm healing
        int issues = DiagnoseConnection(db_handle, db_name);
        success = (issues == 0);
    }
    
    Print(success ? "✅ Connection healed successfully" : "❌ Connection healing failed");
    return success;
}

//+------------------------------------------------------------------+
//| Test basic connectivity                                          |
//+------------------------------------------------------------------+
bool CConnectionHealer::TestBasicConnectivity(int db_handle)
{
    if(db_handle == INVALID_HANDLE) {
        return false;
    }
    
    // Try a simple query
    return ExecuteTestQuery(db_handle, "SELECT 1");
}

//+------------------------------------------------------------------+
//| Test read operations                                             |
//+------------------------------------------------------------------+
bool CConnectionHealer::TestReadOperations(int db_handle)
{
    // Simulate read test - in production this would:
    // 1. Try to read from AllCandleData table
    // 2. Check if results are returned properly
    // 3. Verify data integrity
    
    if(db_handle == INVALID_HANDLE) {
        return false;
    }
    
    // 95% success rate for read operations
    return (MathRand() % 100) < 95;
}

//+------------------------------------------------------------------+
//| Test write operations                                            |
//+------------------------------------------------------------------+
bool CConnectionHealer::TestWriteOperations(int db_handle)
{
    // Simulate write test - in production this would:
    // 1. Try to insert a test record
    // 2. Verify the insert succeeded
    // 3. Clean up the test record
    
    if(db_handle == INVALID_HANDLE) {
        return false;
    }
    
    // 90% success rate for write operations
    return (MathRand() % 100) < 90;
}

//+------------------------------------------------------------------+
//| Test schema integrity                                            |
//+------------------------------------------------------------------+
bool CConnectionHealer::TestSchemaIntegrity(int db_handle)
{
    // Simulate schema test - in production this would:
    // 1. Check if required tables exist
    // 2. Verify column structure
    // 3. Check indexes and constraints
    
    if(db_handle == INVALID_HANDLE) {
        return false;
    }
    
    // 98% success rate for schema integrity
    return (MathRand() % 100) < 98;
}

//+------------------------------------------------------------------+
//| Measure connection response time                                 |
//+------------------------------------------------------------------+
int CConnectionHealer::MeasureResponseTime(int db_handle)
{
    if(db_handle == INVALID_HANDLE) {
        return 9999; // Very high response time for invalid handles
    }
    
    ulong start_time = GetTickCount64();
    
    // Simulate a simple query execution
    bool success = ExecuteTestQuery(db_handle, "SELECT COUNT(*) FROM AllCandleData LIMIT 1");
    
    ulong elapsed = GetTickCount64() - start_time;
    
    // Add some realistic variation
    int simulated_time = (int)elapsed + (MathRand() % 100);
    
    return success ? simulated_time : 9999;
}

//+------------------------------------------------------------------+
//| Attempt to reconnect to database                                |
//+------------------------------------------------------------------+
bool CConnectionHealer::AttemptReconnection(int &db_handle, const string &db_name)
{
    Print("🔄 Attempting reconnection to ", db_name);
    
    // Close existing connection if valid
    if(db_handle != INVALID_HANDLE) {
        DatabaseClose(db_handle);
        db_handle = INVALID_HANDLE;
    }
    
    // Attempt to reopen connection
    for(int attempt = 1; attempt <= m_config.max_retry_attempts; attempt++) {
        Print("🔄 Reconnection attempt ", attempt, "/", m_config.max_retry_attempts);
        
        string db_path = GetDatabaseFilePath(db_name);
        db_handle = DatabaseOpen(db_name, DATABASE_OPEN_READWRITE | DATABASE_OPEN_COMMON);
        
        if(db_handle != INVALID_HANDLE) {
            // Test the connection
            if(TestBasicConnectivity(db_handle)) {
                Print("✅ Reconnection successful on attempt ", attempt);
                m_auto_reconnects++;
                return true;
            } else {
                DatabaseClose(db_handle);
                db_handle = INVALID_HANDLE;
            }
        }
        
        if(attempt < m_config.max_retry_attempts) {
            Sleep(m_config.retry_delay_ms);
        }
    }
    
    Print("❌ Reconnection failed after ", m_config.max_retry_attempts, " attempts");
    return false;
}

//+------------------------------------------------------------------+
//| Identify primary issue with connection                          |
//+------------------------------------------------------------------+
ENUM_CONNECTION_ISSUE CConnectionHealer::IdentifyPrimaryIssue(int db_handle, const string &db_name)
{
    if(db_handle == INVALID_HANDLE) {
        return ISSUE_TIMEOUT;
    }
    
    // Check various potential issues
    string db_path = GetDatabaseFilePath(db_name);
    
    if(!FileExists(db_path)) {
        return ISSUE_CORRUPTION;
    }
    
    if(!CheckFilePermissions(db_path)) {
        return ISSUE_PERMISSIONS;
    }
    
    if(!CheckDiskSpace(db_path)) {
        return ISSUE_DISK_SPACE;
    }
    
    // If basic tests fail, assume timeout/connection issues
    if(!TestBasicConnectivity(db_handle)) {
        return ISSUE_TIMEOUT;
    }
    
    return ISSUE_NONE;
}

//+------------------------------------------------------------------+
//| Execute test query                                               |
//+------------------------------------------------------------------+
bool CConnectionHealer::ExecuteTestQuery(int db_handle, const string &query)
{
    if(db_handle == INVALID_HANDLE) {
        return false;
    }
    
    int request = DatabasePrepare(db_handle, query);
    if(request == INVALID_HANDLE) {
        return false;
    }
    
    bool success = DatabaseRead(request);
    DatabaseFinalize(request);
    
    return success;
}

//+------------------------------------------------------------------+
//| Get database file path                                           |
//+------------------------------------------------------------------+
string CConnectionHealer::GetDatabaseFilePath(const string &db_name)
{
    // This would return the actual path to the database file
    // For now, return a simulated path
    return TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "\\Files\\" + db_name;
}

//+------------------------------------------------------------------+
//| Check if file exists                                             |
//+------------------------------------------------------------------+
bool CConnectionHealer::FileExists(const string &file_path)
{
    // Simulate file existence check
    return (MathRand() % 100) < 95; // 95% of files exist
}

//+------------------------------------------------------------------+
//| Check file permissions                                           |
//+------------------------------------------------------------------+
bool CConnectionHealer::CheckFilePermissions(const string &db_path)
{
    // Simulate permission check
    return (MathRand() % 100) < 98; // 98% have correct permissions
}

//+------------------------------------------------------------------+
//| Check available disk space                                       |
//+------------------------------------------------------------------+
bool CConnectionHealer::CheckDiskSpace(const string &db_path)
{
    // Simulate disk space check
    return (MathRand() % 100) < 99; // 99% have sufficient space
}

//+------------------------------------------------------------------+
//| Update diagnostic record                                         |
//+------------------------------------------------------------------+
void CConnectionHealer::UpdateDiagnostic(const string &db_name, const SConnectionDiagnostic &diagnostic)
{
    // Find existing diagnostic or create new one
    bool found = false;
    for(int i = 0; i < ArraySize(m_diagnostics); i++) {
        if(m_diagnostics[i].database_name == db_name) {
            m_diagnostics[i] = diagnostic;
            found = true;
            break;
        }
    }
    
    if(!found) {
        int size = ArraySize(m_diagnostics);
        ArrayResize(m_diagnostics, size + 1);
        m_diagnostics[size] = diagnostic;
    }
}

//+------------------------------------------------------------------+
//| Get connection report                                            |
//+------------------------------------------------------------------+
string CConnectionHealer::GetConnectionReport()
{
    string report = "=== CONNECTION HEALER REPORT ===\n";
    report += "Total diagnoses: " + IntegerToString(m_total_diagnoses) + "\n";
    report += "Successful heals: " + IntegerToString(m_successful_heals) + "\n";
    report += "Failed heals: " + IntegerToString(m_failed_heals) + "\n";
    report += "Auto reconnects: " + IntegerToString(m_auto_reconnects) + "\n";
    report += "Last health check: " + TimeToString(m_last_health_check) + "\n\n";
    
    report += "CONNECTION STATUS:\n";
    for(int i = 0; i < ArraySize(m_diagnostics); i++) {
        SConnectionDiagnostic diag = m_diagnostics[i];
        report += StringFormat("- %s: %s (%dms response, %d errors)\n",
                             diag.database_name,
                             EnumToString(diag.status),
                             diag.response_time_ms,
                             diag.error_count);
    }
    
    return report;
}

#endif // SSOT_CONNECTION_HEALER_MQH
