//+------------------------------------------------------------------+
//| Example_RefactoredUsage.mqh - Example of using refactored components |
//| Demonstrates how to use the new modular TestPanel system       |
//+------------------------------------------------------------------+

#include <SSoT/TestPanelRefactored.mqh>

//+------------------------------------------------------------------+
//| Example class showing refactored panel usage                    |
//+------------------------------------------------------------------+
class CTestPanelExample
{
private:
    CTestPanelRefactored m_panel;
    int m_main_db;
    
public:
    CTestPanelExample(void) { m_main_db = INVALID_HANDLE; }
    ~CTestPanelExample(void) { Cleanup(); }
    
    //--- Example methods
    bool InitializeExample(void);
    void RunExample(void);
    void Cleanup(void);
    
    //--- Individual component examples
    void DatabaseOperationsExample(void);
    void VisualDisplayExample(void);
    void ReportGeneratorExample(void);
    void TestDatabaseExample(void);
};

//+------------------------------------------------------------------+
//| Initialize the example                                           |
//+------------------------------------------------------------------+
bool CTestPanelExample::InitializeExample(void)
{
    Print("[EXAMPLE] Initializing TestPanel refactored example...");
    
    // Open main database (example)
    m_main_db = DatabaseOpen("sourcedb.sqlite", DATABASE_OPEN_READONLY);
    
    if(m_main_db == INVALID_HANDLE) {
        Print("[EXAMPLE] Warning: Could not open main database, using test mode");
        // Initialize in test mode without databases for demonstration
        return m_panel.Initialize(true, INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE);
    }
    
    // Initialize in live mode with main database
    return m_panel.Initialize(false, m_main_db);
}

//+------------------------------------------------------------------+
//| Run the example                                                 |
//+------------------------------------------------------------------+
void CTestPanelExample::RunExample(void)
{
    Print("[EXAMPLE] Running TestPanel refactored example...");
    
    // 1. Basic panel operations
    Print("[EXAMPLE] 1. Displaying database overview...");
    m_panel.DisplayDatabaseOverview();
    
    // 2. Generate and copy report
    Print("[EXAMPLE] 2. Generating report...");
    string report = m_panel.GenerateReportText();
    Print("[EXAMPLE] Report generated: " + IntegerToString(StringLen(report)) + " characters");
    
    // 3. Copy to clipboard
    Print("[EXAMPLE] 3. Copying to clipboard...");
    if(m_panel.CopyToClipboard()) {
        Print("[EXAMPLE] Report copied to clipboard successfully");
    }
    
    // 4. Test database operations
    Print("[EXAMPLE] 4. Testing database operations...");
    TestDatabaseExample();
    
    // 5. Individual component examples
    Print("[EXAMPLE] 5. Individual component examples...");
    DatabaseOperationsExample();
    VisualDisplayExample();
    ReportGeneratorExample();
    
    Print("[EXAMPLE] Example completed successfully!");
}

//+------------------------------------------------------------------+
//| Example of using DatabaseOperations component independently     |
//+------------------------------------------------------------------+
void CTestPanelExample::DatabaseOperationsExample(void)
{
    Print("[EXAMPLE] --- DatabaseOperations Component Example ---");
    
    // Create database operations component
    CDatabaseOperations db_ops;
    
    if(m_main_db != INVALID_HANDLE) {
        // Get database information
        string db_info = db_ops.GetDatabaseInfo(m_main_db, "sourcedb.sqlite");
        Print("[EXAMPLE] DB Info: " + db_info);
        
        // Get candle data information
        string candle_info = db_ops.GetCandleDataInfo(m_main_db, "sourcedb.sqlite");
        Print("[EXAMPLE] Candle Info: " + candle_info);
        
        // Get detailed breakdown
        string breakdown = db_ops.GetDetailedBreakdown(m_main_db, "sourcedb.sqlite");
        Print("[EXAMPLE] Breakdown length: " + IntegerToString(StringLen(breakdown)) + " characters");
    } else {
        Print("[EXAMPLE] No database available for DatabaseOperations example");
    }
}

//+------------------------------------------------------------------+
//| Example of using VisualDisplay component independently          |
//+------------------------------------------------------------------+
void CTestPanelExample::VisualDisplayExample(void)
{
    Print("[EXAMPLE] --- VisualDisplay Component Example ---");
    
    // Create visual display component with custom prefix
    CVisualDisplay visual("Example_");
    
    // Create visual panel
    if(visual.CreateVisualPanel()) {
        Print("[EXAMPLE] Visual panel created successfully");
        
        // Create database info display
        visual.CreateDatabaseInfoDisplay(false, m_main_db, INVALID_HANDLE, INVALID_HANDLE);
        
        // Create buttons
        visual.CreateCopyButton();
        
        Print("[EXAMPLE] Visual components created");
        
        // Clean up after 5 seconds (in a real application, this would be managed differently)
        Sleep(5000);
        visual.CleanupVisualPanel();
        Print("[EXAMPLE] Visual components cleaned up");
    } else {
        Print("[EXAMPLE] Failed to create visual panel");
    }
}

//+------------------------------------------------------------------+
//| Example of using ReportGenerator component independently        |
//+------------------------------------------------------------------+
void CTestPanelExample::ReportGeneratorExample(void)
{
    Print("[EXAMPLE] --- ReportGenerator Component Example ---");
    
    // Create report generator
    CReportGenerator report_gen;
    
    // Generate different types of reports
    string quick_report = report_gen.GenerateQuickReport(false, m_main_db, INVALID_HANDLE, INVALID_HANDLE);
    Print("[EXAMPLE] Quick report: " + IntegerToString(StringLen(quick_report)) + " characters");
    
    string detailed_report = report_gen.GenerateDetailedReport(false, m_main_db, INVALID_HANDLE, INVALID_HANDLE);
    Print("[EXAMPLE] Detailed report: " + IntegerToString(StringLen(detailed_report)) + " characters");
    
    string comprehensive_report = report_gen.GenerateComprehensiveReport(false, m_main_db, INVALID_HANDLE, INVALID_HANDLE);
    Print("[EXAMPLE] Comprehensive report: " + IntegerToString(StringLen(comprehensive_report)) + " characters");
    
    // Copy one report to clipboard
    if(report_gen.CopyToClipboard(quick_report)) {
        Print("[EXAMPLE] Quick report copied to clipboard");
    }
}

//+------------------------------------------------------------------+
//| Example of using TestDatabaseManager component independently    |
//+------------------------------------------------------------------+
void CTestPanelExample::TestDatabaseExample(void)
{
    Print("[EXAMPLE] --- TestDatabaseManager Component Example ---");
    
    // Create test database manager
    CTestDatabaseManager test_db_mgr;
    
    // Generate test databases
    Print("[EXAMPLE] Generating test databases...");
    if(test_db_mgr.GenerateTestDatabases()) {
        Print("[EXAMPLE] Test databases generated successfully");
        
        // Validate the created databases
        if(test_db_mgr.ValidateTestDatabase("SSoT_input.db")) {
            Print("[EXAMPLE] SSoT_input.db validation: PASSED");
        }
        
        if(test_db_mgr.ValidateTestDatabase("SSoT_output.db")) {
            Print("[EXAMPLE] SSoT_output.db validation: PASSED");
        }
        
        // Clean up test databases
        Print("[EXAMPLE] Cleaning up test databases...");
        if(test_db_mgr.DeleteTestDatabases()) {
            Print("[EXAMPLE] Test databases deleted successfully");
        }
    } else {
        Print("[EXAMPLE] Failed to generate test databases");
    }
}

//+------------------------------------------------------------------+
//| Cleanup resources                                               |
//+------------------------------------------------------------------+
void CTestPanelExample::Cleanup(void)
{
    if(m_main_db != INVALID_HANDLE) {
        DatabaseClose(m_main_db);
        m_main_db = INVALID_HANDLE;
    }
    
    m_panel.Shutdown();
    Print("[EXAMPLE] Cleanup completed");
}

//+------------------------------------------------------------------+
//| Global function to run the example                             |
//+------------------------------------------------------------------+
void RunTestPanelRefactoredExample()
{
    Print("========================================");
    Print("TestPanel Refactored Component Example");
    Print("========================================");
    
    CTestPanelExample example;
    
    if(example.InitializeExample()) {
        example.RunExample();
    } else {
        Print("[EXAMPLE] Failed to initialize example");
    }
    
    // Cleanup is automatic via destructor
    Print("========================================");
    Print("Example completed");
    Print("========================================");
}
