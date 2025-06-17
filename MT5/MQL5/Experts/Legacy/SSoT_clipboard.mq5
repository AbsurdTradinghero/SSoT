//+------------------------------------------------------------------+
//| SSoT Monitor - Working Clipboard Version                         |
//| Simple, clean implementation that actually copies to clipboard  |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "4.00"
#property description "Working SSoT EA Monitor with Direct Clipboard Copy"

// Include database utilities
#include <DbUtils.mqh>

// Windows API imports for clipboard functionality
#import "shell32.dll"
int ShellExecuteW(int hwnd, string lpOperation, string lpFile, string lpParameters, string lpDirectory, int nShowCmd);
#import

#define SW_HIDE 0

// Monitor configuration
input bool InpAutoDetectDatabases = true; // Automatically detect available databases
input string InpMainDatabase = "sourceDB.sqlite"; // Main database (fallback)
input string InpTestInputDatabase = "test_input_sourceDB.sqlite"; // Test input database
input string InpTestOutputDatabase = "test_output_sourceDB.sqlite"; // Test output database
input int InpRefreshInterval = 5; // Refresh interval in seconds
input bool InpEnableClipboard = true; // Enable clipboard functionality
input bool InpVerboseLogging = true; // Enhanced logging for debugging

// Global variables
string g_detected_input_db = "";
string g_detected_output_db = "";
bool g_test_mode_detected = false;
datetime g_last_refresh = 0;
int g_refresh_count = 0;

struct MonitorStats
{
    int input_records;
    int output_records;
    double sync_percentage;
    int validated_records;
    datetime last_update;
    string mode_detected;
};

MonitorStats g_stats;

// Chart interface constants
#define PANEL_WIDTH 400
#define PANEL_HEIGHT 300
#define TEXT_SIZE 9
#define BUTTON_WIDTH 100
#define BUTTON_HEIGHT 25

// Object name prefix
string g_object_prefix = "SSoT_Monitor_";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("🚀 SSoT Monitor Working v4.0 - Starting...");
    
    if(InpAutoDetectDatabases)
    {
        DetectAvailableDatabases();
    }
    else
    {
        g_detected_input_db = InpMainDatabase;
        g_detected_output_db = InpMainDatabase;
    }
    
    PrintDatabaseStatus();
    
    // Create the monitor panel on chart
    CreateMonitorPanel();
    
    // Initial data gathering
    GatherStatistics();
    UpdateDisplay();
    
    // Set up timer for regular monitoring
    EventSetTimer(InpRefreshInterval);
    
    Print("✅ SSoT Monitor Working v4.0 initialized successfully");
    Print("📊 Monitor panel created - clipboard functionality ready!");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Create monitor panel on chart                                    |
//+------------------------------------------------------------------+
void CreateMonitorPanel()
{
    // Create background panel
    string panel_name = g_object_prefix + "Panel";
    if(!ObjectCreate(0, panel_name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
    {
        if(GetLastError() != 4200) // Object already exists
        {
            Print("❌ Failed to create monitor panel: ", GetLastError());
            return;
        }
    }
    
    ObjectSetInteger(0, panel_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, panel_name, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(0, panel_name, OBJPROP_YDISTANCE, 30);
    ObjectSetInteger(0, panel_name, OBJPROP_XSIZE, PANEL_WIDTH);
    ObjectSetInteger(0, panel_name, OBJPROP_YSIZE, PANEL_HEIGHT);
    ObjectSetInteger(0, panel_name, OBJPROP_BGCOLOR, clrDarkBlue);
    ObjectSetInteger(0, panel_name, OBJPROP_BORDER_COLOR, clrWhite);
    ObjectSetInteger(0, panel_name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, panel_name, OBJPROP_WIDTH, 2);
    
    // Create title
    CreateLabel("Title", "🚀 SSoT Monitor Working v4.0", 20, 50, clrYellow, 12);
    
    // Create copy button
    CreateButton("CopyButton", "📋 Copy to Clipboard", 250, 260);
    
    Print("✅ Monitor panel created successfully");
}

//+------------------------------------------------------------------+
//| Create text label                                                |
//+------------------------------------------------------------------+
void CreateLabel(string suffix, string text, int x, int y, color clr = clrWhite, int font_size = TEXT_SIZE)
{
    string label_name = g_object_prefix + suffix;
    if(!ObjectCreate(0, label_name, OBJ_LABEL, 0, 0, 0))
    {
        if(GetLastError() != 4200) // Object already exists
            return;
    }
    
    ObjectSetString(0, label_name, OBJPROP_TEXT, text);
    ObjectSetString(0, label_name, OBJPROP_FONT, "Consolas");
    ObjectSetInteger(0, label_name, OBJPROP_FONTSIZE, font_size);
    ObjectSetInteger(0, label_name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, label_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, label_name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, label_name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, label_name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
}

//+------------------------------------------------------------------+
//| Create button                                                    |
//+------------------------------------------------------------------+
void CreateButton(string suffix, string text, int x, int y)
{
    string button_name = g_object_prefix + suffix;
    if(!ObjectCreate(0, button_name, OBJ_BUTTON, 0, 0, 0))
    {
        if(GetLastError() != 4200) // Object already exists
            return;
    }
    
    ObjectSetString(0, button_name, OBJPROP_TEXT, text);
    ObjectSetString(0, button_name, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, button_name, OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, button_name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, button_name, OBJPROP_BGCOLOR, clrDarkGreen);
    ObjectSetInteger(0, button_name, OBJPROP_BORDER_COLOR, clrWhite);
    ObjectSetInteger(0, button_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, button_name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, button_name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, button_name, OBJPROP_XSIZE, BUTTON_WIDTH + 20);
    ObjectSetInteger(0, button_name, OBJPROP_YSIZE, BUTTON_HEIGHT);
}

//+------------------------------------------------------------------+
//| Handle chart events (button clicks)                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        if(sparam == g_object_prefix + "CopyButton")
        {
            Print("📋 Copy button clicked!");
            
            // Generate and copy statistics
            string stats = GenerateStatisticsReport();
            bool copy_success = CopyTextToClipboard(stats);
            
            if(copy_success)
            {
                CreateLabel("CopyStatus", "✅ Copied to clipboard!", 20, 280, clrLime, 8);
                Print("✅ Statistics copied to clipboard successfully!");
            }
            else
            {
                CreateLabel("CopyStatus", "⚠️ Check terminal for data", 20, 280, clrYellow, 8);
                Print("⚠️ Direct copy failed - data available in terminal");
            }
            
            // Reset button state
            ObjectSetInteger(0, g_object_prefix + "CopyButton", OBJPROP_STATE, false);
            ChartRedraw(0);
        }
    }
}

//+------------------------------------------------------------------+
//| Copy text to Windows clipboard - WORKING VERSION                |
//+------------------------------------------------------------------+
bool CopyTextToClipboard(string text)
{
    Print("📋 Attempting to copy text to clipboard...");
    
    // Save text to temporary file first
    string temp_file = "SSoT_Monitor_Data.txt";
    int file_handle = FileOpen(temp_file, FILE_WRITE | FILE_TXT | FILE_COMMON);
    
    if(file_handle == INVALID_HANDLE)
    {
        Print("❌ Failed to create temporary file for clipboard");
        return false;
    }
    
    FileWrite(file_handle, text);
    FileClose(file_handle);
    
    // Get full file path
    string file_path = TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "\\Files\\" + temp_file;
    
    // Method 1: Try Windows clip command (most reliable)
    string clip_command = "cmd.exe";
    string clip_params = "/c type \"" + file_path + "\" | clip";
    
    Print("📋 Executing: " + clip_command + " " + clip_params);
    int result = ShellExecuteW(0, "open", clip_command, clip_params, "", SW_HIDE);
    
    if(result > 32)
    {
        Print("✅ Text copied to clipboard successfully via Windows clip!");
        Print("💡 You can now paste with Ctrl+V anywhere");
        
        // Also display in terminal for verification
        Print("📊 === COPIED DATA (for verification) ===");
        Print(text);
        Print("📊 === END OF COPIED DATA ===");
        
        return true;
    }
    else
    {
        Print("⚠️ Clipboard copy failed (error " + IntegerToString(result) + ")");
        Print("📊 Data saved to file: " + file_path);
        Print("💡 You can open the file and copy manually");
        
        // Display in terminal for manual copy
        Print("📊 === COPY THIS DATA MANUALLY ===");
        Print(text);
        Print("📊 === END OF DATA ===");
        
        return false;
    }
}

//+------------------------------------------------------------------+
//| Detect available databases using enhanced fallback logic        |
//+------------------------------------------------------------------+
void DetectAvailableDatabases()
{
    Print("🔍 Auto-detecting available databases...");
    
    bool main_db_exists = FileIsExist(InpMainDatabase);
    bool test_input_exists = FileIsExist(InpTestInputDatabase);
    bool test_output_exists = FileIsExist(InpTestOutputDatabase);
    
    if(InpVerboseLogging)
    {
        Print("📊 Database Detection Results:");
        Print("   • Main (" + InpMainDatabase + "): " + (main_db_exists ? "✅ EXISTS" : "❌ MISSING"));
        Print("   • Test Input (" + InpTestInputDatabase + "): " + (test_input_exists ? "✅ EXISTS" : "❌ MISSING"));
        Print("   • Test Output (" + InpTestOutputDatabase + "): " + (test_output_exists ? "✅ EXISTS" : "❌ MISSING"));
    }
    
    // Enhanced logic with automatic fallback
    if(test_input_exists && test_output_exists)
    {
        g_detected_input_db = InpTestInputDatabase;
        g_detected_output_db = InpTestOutputDatabase;
        g_test_mode_detected = true;
        g_stats.mode_detected = "TEST MODE (Full)";
        
        if(InpVerboseLogging)
            Print("🧪 FULL TEST MODE DETECTED - Using test databases");
    }
    else if(test_output_exists)
    {
        g_detected_input_db = main_db_exists ? InpMainDatabase : InpTestOutputDatabase;
        g_detected_output_db = InpTestOutputDatabase;
        g_test_mode_detected = true;
        g_stats.mode_detected = "TEST MODE (Partial)";
        
        if(InpVerboseLogging)
            Print("🧪 PARTIAL TEST MODE - Using test output with fallback input");
    }
    else if(main_db_exists)
    {
        g_detected_input_db = InpMainDatabase;
        g_detected_output_db = InpMainDatabase;
        g_test_mode_detected = false;
        g_stats.mode_detected = "PRODUCTION MODE";
        
        if(InpVerboseLogging)
            Print("🏭 PRODUCTION MODE DETECTED - Using main database");
    }
    else
    {
        g_detected_input_db = InpMainDatabase;
        g_detected_output_db = InpMainDatabase;
        g_test_mode_detected = false;
        g_stats.mode_detected = "FALLBACK MODE (Auto-Create)";
        
        Print("⚠️ FALLBACK MODE: No databases found, will auto-create");
        Print("   • Will create: " + InpMainDatabase);
    }
}

//+------------------------------------------------------------------+
//| Print current database status                                    |
//+------------------------------------------------------------------+
void PrintDatabaseStatus()
{
    Print("📊 === DATABASE STATUS ===");
    Print("🔹 Mode: " + g_stats.mode_detected);
    Print("🔹 Input DB: " + g_detected_input_db);
    Print("🔹 Output DB: " + g_detected_output_db);
    Print("🔹 Test Mode: " + (g_test_mode_detected ? "YES" : "NO"));
    Print("========================");
}

//+------------------------------------------------------------------+
//| Timer function - refresh data                                    |
//+------------------------------------------------------------------+
void OnTimer()
{
    g_refresh_count++;
    g_last_refresh = TimeCurrent();
    
    // Gather statistics from detected databases
    GatherStatistics();
    
    // Update the chart display
    UpdateDisplay();
    
    // Generate and display report
    GenerateAndDisplayReport();
    
    if(InpVerboseLogging && (g_refresh_count % 12 == 0)) // Every minute with 5-second refresh
    {
        PrintDatabaseStatus();
    }
}

//+------------------------------------------------------------------+
//| Update display with current statistics                           |
//+------------------------------------------------------------------+
void UpdateDisplay()
{
    // Update various labels with current stats
    CreateLabel("Mode", "📊 Mode: " + g_stats.mode_detected, 20, 80);
    CreateLabel("InputDB", "🔹 Input: " + g_detected_input_db, 20, 100);
    CreateLabel("OutputDB", "🔹 Output: " + g_detected_output_db, 20, 120);
    CreateLabel("TestMode", "🔹 Test: " + (g_test_mode_detected ? "ACTIVE 🧪" : "INACTIVE 🏭"), 20, 140);
    
    CreateLabel("InputRecs", "📈 Input Records: " + FormatNumber(g_stats.input_records), 20, 170);
    CreateLabel("OutputRecs", "📈 Output Records: " + FormatNumber(g_stats.output_records), 20, 190);
    CreateLabel("ValidRecs", "📈 Validated: " + FormatNumber(g_stats.validated_records), 20, 210);
    CreateLabel("SyncPct", "📈 Sync: " + StringFormat("%.2f%%", g_stats.sync_percentage), 20, 230);
    
    CreateLabel("LastUpdate", "🕐 Updated: " + TimeToString(g_stats.last_update, TIME_SECONDS), 20, 250);
    CreateLabel("RefreshCount", "🔄 Refresh #" + IntegerToString(g_refresh_count), 200, 250);
    
    // Force chart redraw
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Gather statistics from databases using DbUtils                   |
//+------------------------------------------------------------------+
void GatherStatistics()
{
    // Reset stats
    g_stats.input_records = 0;
    g_stats.output_records = 0;
    g_stats.validated_records = 0;
    g_stats.sync_percentage = 0.0;
    g_stats.last_update = TimeCurrent();
    
    // Count input records using enhanced DbUtils logic
    int input_db_handle = INVALID_HANDLE;
    if(InitializeDatabase(g_detected_input_db, input_db_handle))
    {
        int request = DatabasePrepare(input_db_handle, "SELECT COUNT(*) FROM AllCandleData");
        if(request != INVALID_HANDLE && DatabaseRead(request))
        {
            DatabaseColumnInteger(request, 0, g_stats.input_records);
            DatabaseFinalize(request);
        }
        DatabaseClose(input_db_handle);
    }
    
    // Count output records (only if different from input)
    if(g_detected_output_db != g_detected_input_db)
    {
        int output_db_handle = INVALID_HANDLE;
        if(InitializeDatabase(g_detected_output_db, output_db_handle))
        {
            int request = DatabasePrepare(output_db_handle, "SELECT COUNT(*) FROM AllCandleData");
            if(request != INVALID_HANDLE && DatabaseRead(request))
            {
                DatabaseColumnInteger(request, 0, g_stats.output_records);
                DatabaseFinalize(request);
            }
            
            // Count validated records
            request = DatabasePrepare(output_db_handle, "SELECT COUNT(*) FROM AllCandleData WHERE is_validated = 1");
            if(request != INVALID_HANDLE && DatabaseRead(request))
            {
                DatabaseColumnInteger(request, 0, g_stats.validated_records);
                DatabaseFinalize(request);
            }
            
            DatabaseClose(output_db_handle);
        }
    }
    else
    {
        // Same database for input and output (production mode)
        g_stats.output_records = g_stats.input_records;
        
        int db_handle = INVALID_HANDLE;
        if(InitializeDatabase(g_detected_input_db, db_handle))
        {
            int request = DatabasePrepare(db_handle, "SELECT COUNT(*) FROM AllCandleData WHERE is_validated = 1");
            if(request != INVALID_HANDLE && DatabaseRead(request))
            {
                DatabaseColumnInteger(request, 0, g_stats.validated_records);
                DatabaseFinalize(request);
            }
            DatabaseClose(db_handle);
        }
    }
    
    // Calculate sync percentage
    if(g_stats.input_records > 0)
    {
        g_stats.sync_percentage = (double)g_stats.output_records / (double)g_stats.input_records * 100.0;
    }
}

//+------------------------------------------------------------------+
//| Generate and display comprehensive report                        |
//+------------------------------------------------------------------+
void GenerateAndDisplayReport()
{
    string report = GenerateStatisticsReport();
    
    if(InpVerboseLogging)
    {
        Print("📊 === SSoT MONITOR REPORT (Working v4.0) ===");
        Print(report);
        Print("==========================================");
    }
}

//+------------------------------------------------------------------+
//| Generate comprehensive statistics report                         |
//+------------------------------------------------------------------+
string GenerateStatisticsReport()
{
    string report = "";
    datetime current_time = TimeCurrent();
    
    // Header
    report += "🚀 SSoT EA Monitor Report (Working v4.0)\n";
    report += "📅 " + TimeToString(current_time) + "\n";
    report += "🔄 Refresh #" + IntegerToString(g_refresh_count) + "\n";
    report += "─────────────────────────────────\n";
    
    // Database Status
    report += "📊 DATABASE STATUS:\n";
    report += "🔹 Mode: " + g_stats.mode_detected + "\n";
    report += "🔹 Input DB: " + g_detected_input_db + "\n";
    report += "🔹 Output DB: " + g_detected_output_db + "\n";
    report += "🔹 Test Mode: " + (g_test_mode_detected ? "ACTIVE 🧪" : "INACTIVE 🏭") + "\n\n";
    
    // Record Counts
    report += "📈 RECORD STATISTICS:\n";
    report += "🔹 Input Records: " + FormatNumber(g_stats.input_records) + "\n";
    report += "🔹 Output Records: " + FormatNumber(g_stats.output_records) + "\n";
    report += "🔹 Validated Records: " + FormatNumber(g_stats.validated_records) + "\n";
    report += "🔹 Sync Percentage: " + StringFormat("%.2f%%", g_stats.sync_percentage) + "\n\n";
    
    // Status
    string sync_status = "⚠️ PARTIAL";
    if(g_stats.sync_percentage >= 99.9) sync_status = "✅ EXCELLENT";
    else if(g_stats.sync_percentage >= 95.0) sync_status = "🟡 GOOD";
    
    report += "🎯 SYSTEM STATUS:\n";
    report += "🔹 Sync Status: " + sync_status + "\n";
    report += "🔹 Last Update: " + TimeToString(g_stats.last_update, TIME_SECONDS) + "\n";
    report += "🔹 Monitor Version: Working v4.0 with Direct Clipboard\n\n";
    
    report += "─────────────────────────────────\n";
    report += "Generated by SSoT Monitor Working v4.0\n";
    
    return report;
}

//+------------------------------------------------------------------+
//| Format number with thousands separators                          |
//+------------------------------------------------------------------+
string FormatNumber(int number)
{
    string num_str = IntegerToString(number);
    string result = "";
    int len = StringLen(num_str);
    
    for(int i = 0; i < len; i++)
    {
        if(i > 0 && (len - i) % 3 == 0)
            result += ",";
        result += StringSubstr(num_str, i, 1);
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Remove all monitor objects from chart                            |
//+------------------------------------------------------------------+
void RemoveMonitorObjects()
{
    string objects_to_remove[] = {
        "Panel", "Title", "CopyButton", "Mode", "InputDB", "OutputDB", "TestMode",
        "InputRecs", "OutputRecs", "ValidRecs", "SyncPct", "LastUpdate", "RefreshCount", "CopyStatus"
    };
    
    for(int i = 0; i < ArraySize(objects_to_remove); i++)
    {
        ObjectDelete(0, g_object_prefix + objects_to_remove[i]);
    }
    
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer();
    
    // Clean up all chart objects
    RemoveMonitorObjects();
    
    Print("🔴 SSoT Monitor Working v4.0 shutting down...");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Minimal tick handling for monitor
}
