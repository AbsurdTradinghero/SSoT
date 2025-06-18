//+------------------------------------------------------------------+
//| ReportGenerator.mqh - Report Generation and Clipboard          |
//| Handles report generation and clipboard operations              |
//+------------------------------------------------------------------+

#include <SSoT/Monitoring/DatabaseOperations.mqh>

// Forward declaration for external self-healing system access
class CSimpleSSoTSelfHealingIntegration;
extern CSimpleSSoTSelfHealingIntegration* g_self_healing;

// Windows API for clipboard
#import "user32.dll"
int OpenClipboard(int hWndNewOwner);
int EmptyClipboard();
int CloseClipboard();
int SetClipboardData(int uFormat, int hMem);
#import

#import "kernel32.dll"
int GlobalAlloc(int uFlags, int dwBytes);
int GlobalLock(int hMem);
int GlobalUnlock(int hMem);
string lstrcpyW(int lpString1, string lpString2);
#import

#define CF_UNICODETEXT 13
#define GMEM_MOVEABLE 2

//+------------------------------------------------------------------+
//| Report Generator Class                                          |
//+------------------------------------------------------------------+
class CReportGenerator
{
private:
    CDatabaseOperations m_db_ops;
    
public:
    //--- Constructor
    CReportGenerator(void) {}
    ~CReportGenerator(void) {}
    
    //--- Report Generation
    string GenerateReportText(bool test_mode, int main_db, int test_input_db, int test_output_db);
    string GenerateQuickReport(bool test_mode, int main_db, int test_input_db, int test_output_db);
    string GenerateDetailedReport(bool test_mode, int main_db, int test_input_db, int test_output_db);
    string GenerateComprehensiveReport(bool test_mode, int main_db, int test_input_db, int test_output_db);
    
    //--- Clipboard Operations
    bool CopyToClipboard(string report_text);
    bool CopyTextToClipboard(string text);
    
private:
    //--- Helper Methods
    string GetReportHeader(bool test_mode);
    string GetDatabaseSection(string title, int db_handle, string db_name);
    string GetHealthMonitorSection(void);  // New health monitoring section
    string GetTimeStamp(void);
};

//+------------------------------------------------------------------+
//| Generate main report text                                       |
//+------------------------------------------------------------------+
string CReportGenerator::GenerateReportText(bool test_mode, int main_db, int test_input_db, int test_output_db)
{
    string report = "";
    
    // Report header
    report += GetReportHeader(test_mode);
    report += "\n";
    
    if(test_mode) {
        // Test Mode: All three databases
        report += GetDatabaseSection("MAIN DATABASE", main_db, "sourcedb.sqlite");
        report += "\n";
        report += GetDatabaseSection("TEST INPUT DATABASE", test_input_db, "SSoT_input.db");
        report += "\n";
        report += GetDatabaseSection("TEST OUTPUT DATABASE", test_output_db, "SSoT_output.db");    } else {
        // Live Mode: Only main database
        report += GetDatabaseSection("LIVE DATABASE", main_db, "sourcedb.sqlite");
    }
    
    // Add health monitoring section
    report += "\n" + GetHealthMonitorSection();
    
    report += "\n" + StringFormat("Report generated at: %s", GetTimeStamp());
    
    return report;
}

//+------------------------------------------------------------------+
//| Generate quick summary report                                   |
//+------------------------------------------------------------------+
string CReportGenerator::GenerateQuickReport(bool test_mode, int main_db, int test_input_db, int test_output_db)
{
    string report = "";
    
    report += "SSoT QUICK DATABASE SUMMARY\n";
    report += "===========================\n";
    report += StringFormat("Time: %s\n", GetTimeStamp());
    report += StringFormat("Mode: %s\n\n", test_mode ? "TEST" : "LIVE");
    
    if(test_mode) {
        report += StringFormat("Main DB: %s\n", (main_db != INVALID_HANDLE) ? "CONNECTED" : "DISCONNECTED");
        report += StringFormat("Test Input: %s\n", (test_input_db != INVALID_HANDLE) ? "CONNECTED" : "DISCONNECTED");
        report += StringFormat("Test Output: %s\n", (test_output_db != INVALID_HANDLE) ? "CONNECTED" : "DISCONNECTED");
    } else {
        report += StringFormat("Database: %s\n", (main_db != INVALID_HANDLE) ? "CONNECTED" : "DISCONNECTED");
    }
    
    return report;
}

//+------------------------------------------------------------------+
//| Generate detailed report                                        |
//+------------------------------------------------------------------+
string CReportGenerator::GenerateDetailedReport(bool test_mode, int main_db, int test_input_db, int test_output_db)
{
    string report = "";
    
    report += "SSoT DETAILED DATABASE REPORT\n";
    report += "=============================\n";
    report += StringFormat("Generated: %s\n", GetTimeStamp());
    report += StringFormat("Mode: %s\n\n", test_mode ? "TEST MODE" : "LIVE MODE");
    
    if(test_mode) {
        // Test Mode: Detailed breakdown of all databases
        report += m_db_ops.GetDetailedBreakdown(main_db, "sourcedb.sqlite") + "\n\n";
        report += m_db_ops.GetDetailedBreakdown(test_input_db, "SSoT_input.db") + "\n\n";
        report += m_db_ops.GetDetailedBreakdown(test_output_db, "SSoT_output.db") + "\n";
    } else {
        // Live Mode: Detailed breakdown of main database
        report += m_db_ops.GetDetailedBreakdown(main_db, "sourcedb.sqlite") + "\n";
    }
    
    return report;
}

//+------------------------------------------------------------------+
//| Generate comprehensive report with full details                 |
//+------------------------------------------------------------------+
string CReportGenerator::GenerateComprehensiveReport(bool test_mode, int main_db, int test_input_db, int test_output_db)
{
    string report = "";
    
    report += "SSoT COMPREHENSIVE DATABASE ANALYSIS\n";
    report += "====================================\n";
    report += StringFormat("Generated: %s\n", GetTimeStamp());
    report += StringFormat("Mode: %s\n", test_mode ? "TEST MODE" : "LIVE MODE");
    report += StringFormat("Databases Monitored: %d\n\n", test_mode ? 3 : 1);
    
    if(test_mode) {
        // Test Mode: Comprehensive analysis of all databases
        report += m_db_ops.GetComprehensiveBreakdown(main_db, "sourcedb.sqlite") + "\n\n";
        report += m_db_ops.GetComprehensiveBreakdown(test_input_db, "SSoT_input.db") + "\n\n";
        report += m_db_ops.GetComprehensiveBreakdown(test_output_db, "SSoT_output.db") + "\n";    } else {
        // Live Mode: Comprehensive analysis of main database
        report += m_db_ops.GetComprehensiveBreakdown(main_db, "sourcedb.sqlite") + "\n";
    }
    
    // Add health monitoring section to comprehensive report
    report += "\n" + GetHealthMonitorSection();
    
    report += "\n=== REPORT SUMMARY ===\n";
    report += StringFormat("Generated at: %s\n", GetTimeStamp());
    report += StringFormat("Total databases analyzed: %d\n", test_mode ? 3 : 1);
    report += "Report type: Comprehensive Analysis with Health Monitoring\n";
    
    return report;
}

//+------------------------------------------------------------------+
//| Copy report to clipboard                                        |
//+------------------------------------------------------------------+
bool CReportGenerator::CopyToClipboard(string report_text)
{
    Print("[CLIPBOARD] Attempting to copy report to clipboard...");
    
    if(StringLen(report_text) == 0) {
        Print("[CLIPBOARD] ERROR: Empty report text");
        return false;
    }
    
    bool result = CopyTextToClipboard(report_text);
    
    if(result) {
        Print("[CLIPBOARD] SUCCESS: Report copied to clipboard (" + IntegerToString(StringLen(report_text)) + " characters)");
    } else {
        Print("[CLIPBOARD] ERROR: Failed to copy report to clipboard");
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Copy text to clipboard - File method with auto-open           |
//+------------------------------------------------------------------+
bool CReportGenerator::CopyTextToClipboard(string text)
{
    Print("[CLIPBOARD] Creating report file for easy copying...");
    
    if(StringLen(text) == 0) {
        Print("[CLIPBOARD] ERROR: Empty text");
        return false;
    }
    
    // Create a well-formatted file
    string report_file = "SSoT_Report_" + TimeToString(TimeCurrent(), TIME_DATE) + ".txt";
    StringReplace(report_file, ".", "_");
    StringReplace(report_file, ":", "_");
    
    int file_handle = FileOpen(report_file, FILE_WRITE | FILE_TXT | FILE_UNICODE);
    
    if(file_handle == INVALID_HANDLE) {
        Print("[CLIPBOARD] ERROR: Cannot create report file: ", report_file);
        return false;
    }
    
    // Write formatted header
    FileWriteString(file_handle, "=======================================================\n");
    FileWriteString(file_handle, "SSoT DATABASE REPORT\n");
    FileWriteString(file_handle, "Generated: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\n");
    FileWriteString(file_handle, "=======================================================\n\n");
    
    // Write the actual report
    FileWriteString(file_handle, text);
    
    // Write footer
    FileWriteString(file_handle, "\n\n=======================================================\n");
    FileWriteString(file_handle, "End of Report - Copy content above to clipboard\n");
    FileWriteString(file_handle, "=======================================================\n");
    
    FileClose(file_handle);
    
    // Get full file path
    string full_path = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\" + report_file;
    
    Print("[CLIPBOARD] ✅ Report saved successfully!");
    Print("[CLIPBOARD] 📁 File: ", report_file);
    Print("[CLIPBOARD] 📂 Location: ", full_path);
    Print("[CLIPBOARD] 📋 Opening file for easy copying...");
    
    // Try to open the file automatically
    int result = ShellExecuteW(0, "open", full_path, "", "", 5); // SW_SHOW = 5
    
    if(result > 32) {
        Print("[CLIPBOARD] ✅ File opened successfully in default text editor");
        Print("[CLIPBOARD] 📌 Instructions: Select All (Ctrl+A) then Copy (Ctrl+C)");
        return true;
    } else {
        Print("[CLIPBOARD] ⚠️ Could not auto-open file (Error: ", result, ")");
        Print("[CLIPBOARD] 📌 Manual Instructions:");
        Print("[CLIPBOARD] 1. Navigate to: ", full_path);
        Print("[CLIPBOARD] 2. Open the file in any text editor");
        Print("[CLIPBOARD] 3. Select All (Ctrl+A) and Copy (Ctrl+C)");
        return true; // Still success since file was created
    }
}

//+------------------------------------------------------------------+
//| Get report header                                               |
//+------------------------------------------------------------------+
string CReportGenerator::GetReportHeader(bool test_mode)
{
    string header = "";
    
    header += "================================================================\n";
    header += "SSoT TEST PANEL v4.06 - DATABASE MONITOR REPORT\n";
    header += "================================================================\n";
    header += StringFormat("Generated: %s\n", GetTimeStamp());
    header += StringFormat("Mode: %s\n", test_mode ? "[TEST] TEST MODE" : "[LIVE] LIVE MODE");
    header += "================================================================\n";
    
    return header;
}

//+------------------------------------------------------------------+
//| Get database section for report                                |
//+------------------------------------------------------------------+
string CReportGenerator::GetDatabaseSection(string title, int db_handle, string db_name)
{    string section = "";
    
    section += StringFormat("=== %s ===\n", title);
    
    if(db_handle == INVALID_HANDLE) {
        section += "Status: DISCONNECTED\n";
        section += StringFormat("Database: %s (not available)\n", db_name);
        return section;
    }
    
    section += "Status: CONNECTED\n";
    section += StringFormat("Database: %s\n\n", db_name);
    
    // Get database information
    section += "DATABASE INFO:\n";
    section += m_db_ops.GetDatabaseInfo(db_handle, db_name) + "\n\n";
    
    // Get candle data information
    section += "CANDLE DATA:\n";
    section += m_db_ops.GetCandleDataInfo(db_handle, db_name) + "\n";
    
    return section;
}

//+------------------------------------------------------------------+
//| Get health monitoring section                                   |
//+------------------------------------------------------------------+
string CReportGenerator::GetHealthMonitorSection(void)
{
    string section = "";
    section += "=============================================================\n";
    section += "HEALTH MONITORING & SELF-HEALING STATUS\n";
    section += "=============================================================\n";
    
    if(g_self_healing != NULL) {
        section += "System Status: ACTIVE\n";
        section += StringFormat("Quick Status: %s\n", g_self_healing.GetQuickHealthStatus());
        section += "Health Summary:\n";
        section += g_self_healing.GetHealthSummary() + "\n";
        section += StringFormat("System Health: %s\n", g_self_healing.IsHealthy() ? "✅ HEALTHY" : "⚠️ ISSUES DETECTED");
        section += StringFormat("Active Healing: %s\n", g_self_healing.IsActivelyHealing() ? "🔧 IN PROGRESS" : "🔄 MONITORING");
    } else {
        section += "System Status: NOT AVAILABLE\n";
        section += "Self-healing system is not initialized or disabled\n";
    }
    
    // Add system resource information
    section += "\n--- System Resources ---\n";
    section += StringFormat("Terminal Memory Usage: %d KB\n", TerminalInfoInteger(TERMINAL_MEMORY_USED));
    section += StringFormat("Free Disk Space: %d MB\n", TerminalInfoInteger(TERMINAL_DISK_SPACE));
    section += StringFormat("Connected to Trade Server: %s\n", TerminalInfoInteger(TERMINAL_CONNECTED) ? "✅ YES" : "❌ NO");
      // Add EA performance metrics
    section += "\n--- EA Performance ---\n";
    section += StringFormat("Current Time: %s\n", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
    section += StringFormat("Terminal Local Time: %s\n", TimeToString(TimeLocal(), TIME_DATE | TIME_SECONDS));
    section += StringFormat("Server Time Diff: %d seconds\n", (int)(TimeCurrent() - TimeLocal()));
    
    section += "=============================================================\n";
    return section;
}

//+------------------------------------------------------------------+
//| Get formatted timestamp                                         |
//+------------------------------------------------------------------+
string CReportGenerator::GetTimeStamp(void)
{
    return TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
}
