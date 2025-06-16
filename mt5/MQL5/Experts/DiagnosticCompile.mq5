//+------------------------------------------------------------------+
//| DiagnosticCompile.mq5 - Simple test for compilation issues      |
//+------------------------------------------------------------------+
#property copyright "Test"
#property version   "1.0"
#property strict

// Test basic MQL5 syntax and core functions
int OnInit()
{
    Print("Test compilation successful");
    
    // Test string operations
    string test_symbols = "EURUSD,GBPUSD,USDJPY";
    string symbolTokens[];
    int symCount = StringSplit(test_symbols, ',', symbolTokens);
    
    // Test array operations
    string g_symbols[];
    ArrayResize(g_symbols, symCount);
    
    // Test enum
    ENUM_TIMEFRAMES g_timeframes[];
    ArrayResize(g_timeframes, 4);
    g_timeframes[0] = PERIOD_M1;
    g_timeframes[1] = PERIOD_M5;
    g_timeframes[2] = PERIOD_M15;
    g_timeframes[3] = PERIOD_H1;
    
    // Test database functions
    int db_handle = DatabaseOpen("test.db", DATABASE_OPEN_READONLY);
    if(db_handle != INVALID_HANDLE) {
        DatabaseClose(db_handle);
    }
    
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
    Print("Test deinitialization");
}

void OnTick()
{
    // Empty
}
