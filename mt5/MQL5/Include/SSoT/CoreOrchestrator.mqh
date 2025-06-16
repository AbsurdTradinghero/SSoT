//+------------------------------------------------------------------+
//| CoreOrchestrator.mqh - Core EA Orchestration Logic              |
//| External class for all non-essential EA functions               |
//+------------------------------------------------------------------+

#include <SSoT\DatabaseSetup.mqh>
#include <SSoT\LegacyCore.mqh>

//+------------------------------------------------------------------+
//| Core Orchestrator Class for SSoT EA                             |
//+------------------------------------------------------------------+
class CCoreOrchestrator
{
private:
    string m_symbols[];
    ENUM_TIMEFRAMES m_timeframes[];
    bool m_test_mode_active;
    
public:
    //--- Constructor
    CCoreOrchestrator(void) { m_test_mode_active = false; }
    
    //--- Initialization functions
    bool ParseInputParameters(string symbols_input, string timeframes_input, string &symbols[], ENUM_TIMEFRAMES &timeframes[]);
    bool InitializeDatabases(bool enable_test_mode, string main_db, string test_input_db, string test_output_db, 
                            int &main_handle, int &input_handle, int &output_handle, bool &test_mode_active);
    bool LoadHistoricalData(string symbols[], ENUM_TIMEFRAMES timeframes[], int max_bars);
    
    //--- Processing functions
    void ProcessNewBars(string symbols[], ENUM_TIMEFRAMES timeframes[]);
    void PerformValidation(void);
    void ExecuteTestModeFlow(bool test_mode_active, int main_db, int input_db, int output_db, 
                            string symbols[], ENUM_TIMEFRAMES timeframes[]);
};

//+------------------------------------------------------------------+
//| Parse input parameters into arrays                               |
//+------------------------------------------------------------------+
bool CCoreOrchestrator::ParseInputParameters(string symbols_input, string timeframes_input, 
                                             string &symbols[], ENUM_TIMEFRAMES &timeframes[])
{
    // Parse symbols
    string symbol_array[];
    int symbols_count = StringSplit(symbols_input, ',', symbol_array);
    if(symbols_count <= 0) return false;
    
    ArrayResize(symbols, symbols_count);
    for(int i = 0; i < symbols_count; i++) {
        StringTrimLeft(symbol_array[i]);
        StringTrimRight(symbol_array[i]);
        symbols[i] = symbol_array[i];
    }
    
    // Parse timeframes
    string tf_array[];
    int tf_count = StringSplit(timeframes_input, ',', tf_array);
    if(tf_count <= 0) return false;
    
    ArrayResize(timeframes, tf_count);
    for(int i = 0; i < tf_count; i++) {
        StringTrimLeft(tf_array[i]);
        StringTrimRight(tf_array[i]);
        
        ENUM_TIMEFRAMES tf = PERIOD_CURRENT;
        string tf_str = tf_array[i];
        
        if(tf_str == "M1") tf = PERIOD_M1;
        else if(tf_str == "M5") tf = PERIOD_M5;
        else if(tf_str == "M15") tf = PERIOD_M15;
        else if(tf_str == "M30") tf = PERIOD_M30;
        else if(tf_str == "H1") tf = PERIOD_H1;
        else if(tf_str == "H4") tf = PERIOD_H4;
        else if(tf_str == "D1") tf = PERIOD_D1;
        else if(tf_str == "W1") tf = PERIOD_W1;
        else if(tf_str == "MN1") tf = PERIOD_MN1;
        
        timeframes[i] = tf;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize all databases                                         |
//+------------------------------------------------------------------+
bool CCoreOrchestrator::InitializeDatabases(bool enable_test_mode, string main_db, string test_input_db, string test_output_db,
                                            int &main_handle, int &input_handle, int &output_handle, bool &test_mode_active)
{
    Print("🗄️ Initializing databases...");
    
    // Initialize main database (always required)
    main_handle = DatabaseOpen(main_db, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
    if(main_handle == INVALID_HANDLE) {
        Print("❌ Failed to open main database: ", main_db);
        return false;
    }
    Print("✅ Main database connected: ", main_db);
    
    // Initialize test databases if test mode enabled
    if(enable_test_mode) {
        input_handle = DatabaseOpen(test_input_db, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
        if(input_handle == INVALID_HANDLE) {
            Print("❌ Failed to open test input database: ", test_input_db);
            return false;
        }
        
        output_handle = DatabaseOpen(test_output_db, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
        if(output_handle == INVALID_HANDLE) {
            Print("❌ Failed to open test output database: ", test_output_db);
            DatabaseClose(input_handle);
            return false;
        }
        
        test_mode_active = true;
        Print("✅ Test databases connected: ", test_input_db, " & ", test_output_db);
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Load historical data for all symbols/timeframes                 |
//+------------------------------------------------------------------+
bool CCoreOrchestrator::LoadHistoricalData(string symbols[], ENUM_TIMEFRAMES timeframes[], int max_bars)
{
    Print("📊 Loading historical data...");
    
    for(int s = 0; s < ArraySize(symbols); s++) {
        for(int t = 0; t < ArraySize(timeframes); t++) {
            int bars_loaded = CLegacyCore::LoadSymbolData(symbols[s], timeframes[t], max_bars);
            if(bars_loaded > 0) {
                Print(StringFormat("✅ Loaded %d bars for %s %s", 
                      bars_loaded, symbols[s], EnumToString(timeframes[t])));
            }
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Process new bars for all monitored symbols/timeframes           |
//+------------------------------------------------------------------+
void CCoreOrchestrator::ProcessNewBars(string symbols[], ENUM_TIMEFRAMES timeframes[])
{
    for(int s = 0; s < ArraySize(symbols); s++) {
        for(int t = 0; t < ArraySize(timeframes); t++) {
            if(CLegacyCore::IsNewBar(symbols[s], timeframes[t])) {
                CLegacyCore::ProcessNewBarData(symbols[s], timeframes[t]);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Perform system validation                                        |
//+------------------------------------------------------------------+
void CCoreOrchestrator::PerformValidation(void)
{
    Print("🔍 PerformValidation: Running system validation...");
    CLegacyCore::ValidateSystemHealth();
    Print("✅ PerformValidation: System validation completed");
}

//+------------------------------------------------------------------+
//| Execute test mode 3-database flow                               |
//+------------------------------------------------------------------+
void CCoreOrchestrator::ExecuteTestModeFlow(bool test_mode_active, int main_db, int input_db, int output_db,
                                           string symbols[], ENUM_TIMEFRAMES timeframes[])
{
    if(!test_mode_active) return;
    
    Print("🧪 ExecuteTestModeFlow: Starting 3-database test flow...");
    
    // Execute the complete test mode flow:
    // Broker → sourceDB → SSoT_in → SSoT_out
    bool success = CLegacyCore::ProcessTestModeFlow(
        main_db,        // sourceDB (main database)
        input_db,       // SSoT_in (test input)
        output_db,      // SSoT_out (test output)
        symbols,        // Monitored symbols
        timeframes      // Monitored timeframes
    );
    
    if(success) {
        Print("✅ ExecuteTestModeFlow: 3-database flow completed successfully");
    } else {
        Print("❌ ExecuteTestModeFlow: 3-database flow completed with issues");
    }
}
