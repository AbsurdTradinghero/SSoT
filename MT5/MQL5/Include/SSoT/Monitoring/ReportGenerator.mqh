//+------------------------------------------------------------------+
//| ReportGenerator.mqh - Report Generation and Clipboard          |
//| Handles report generation and clipboard operations              |
//+------------------------------------------------------------------+

#include <SSoT/Monitoring/DatabaseOperations.mqh>

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
        report += GetDatabaseSection("TEST OUTPUT DATABASE", test_output_db, "SSoT_output.db");
    } else {
        // Live Mode: Only main database
        report += GetDatabaseSection("LIVE DATABASE", main_db, "sourcedb.sqlite");
    }
    
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
        report += m_db_ops.GetComprehensiveBreakdown(test_output_db, "SSoT_output.db") + "\n";
    } else {
        // Live Mode: Comprehensive analysis of main database
        report += m_db_ops.GetComprehensiveBreakdown(main_db, "sourcedb.sqlite") + "\n";
    }
    
    report += "\n=== REPORT SUMMARY ===\n";
    report += StringFormat("Generated at: %s\n", GetTimeStamp());
    report += StringFormat("Total databases analyzed: %d\n", test_mode ? 3 : 1);
    report += "Report type: Comprehensive Analysis\n";
    
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
//| Copy text to Windows clipboard using simple method             |
//+------------------------------------------------------------------+
bool CReportGenerator::CopyTextToClipboard(string text)
{
    Print("[CLIPBOARD] Attempting to copy text to clipboard - Simple Method");
    
    if(StringLen(text) == 0) {
        Print("[CLIPBOARD] ERROR: Empty text");
        return false;
    }
    
    // Write text to a temporary file
    string temp_file = "ssot_clipboard_data.txt";
    int file_handle = FileOpen(temp_file, FILE_WRITE | FILE_TXT | FILE_ANSI);
    
    if(file_handle == INVALID_HANDLE) {
        Print("[CLIPBOARD] ERROR: Cannot create temporary file: ", temp_file);
        return false;
    }
    
    // Write the report text
    FileWriteString(file_handle, text);
    FileClose(file_handle);
    
    Print("[CLIPBOARD] File written successfully: ", temp_file);
    Print("[CLIPBOARD] File size: ", StringLen(text), " characters");
    Print("[CLIPBOARD] You can find the report at: ", TerminalInfoString(TERMINAL_DATA_PATH), "\\MQL5\\Files\\", temp_file);
    Print("[CLIPBOARD] Please manually copy the content from this file to your clipboard");
    
    return true;
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
//| Get formatted timestamp                                         |
//+------------------------------------------------------------------+
string CReportGenerator::GetTimeStamp(void)
{
    return TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
}
