//+------------------------------------------------------------------+
//| SimpleTestPanel.mqh - Basic Test Panel for Database Display     |
//| Simple test panel/monitor for SSoT EA - Phase 1                 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Simple Test Panel Class - Display Only                          |
//+------------------------------------------------------------------+
class CSimpleTestPanel
{
private:
    // Database handles
    int m_main_db;
    int m_test_input_db;
    int m_test_output_db;
    
    // Operating mode
    bool m_test_mode;
    
    // Display control
    datetime m_last_display;
    int m_display_interval;

public:
    //--- Constructor/Destructor
    CSimpleTestPanel(void);
    ~CSimpleTestPanel(void);
    
    //--- Initialization
    bool Initialize(bool test_mode, int main_db, int test_input_db = INVALID_HANDLE, int test_output_db = INVALID_HANDLE);
    
    //--- Main Display Function
    void UpdateDisplay(void);
    
    //--- Database Display Functions
    void DisplayDatabaseOverview(void);
    void DisplayDBInfo(int db_handle, string db_name);
    void DisplayAllCandleData(int db_handle, string db_name);
    
    //--- Helper Functions
    void DisplayAssetData(int db_handle, string table_name, string symbol);
    string TimeframeToString(int timeframe);
    bool ShouldUpdate(void);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CSimpleTestPanel::CSimpleTestPanel(void)
{
    m_main_db = INVALID_HANDLE;
    m_test_input_db = INVALID_HANDLE;
    m_test_output_db = INVALID_HANDLE;
    m_test_mode = false;
    m_last_display = 0;
    m_display_interval = 30; // 30 seconds
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CSimpleTestPanel::~CSimpleTestPanel(void)
{
}

//+------------------------------------------------------------------+
//| Initialize the test panel                                         |
//+------------------------------------------------------------------+
bool CSimpleTestPanel::Initialize(bool test_mode, int main_db, int test_input_db = INVALID_HANDLE, int test_output_db = INVALID_HANDLE)
{
    m_test_mode = test_mode;
    m_main_db = main_db;
    m_test_input_db = test_input_db;
    m_test_output_db = test_output_db;
    
    Print("📊 SimpleTestPanel: Initialized in ", m_test_mode ? "TEST MODE" : "LIVE MODE");
    
    // Initial display
    DisplayDatabaseOverview();
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if display should be updated                               |
//+------------------------------------------------------------------+
bool CSimpleTestPanel::ShouldUpdate(void)
{
    return (TimeCurrent() - m_last_display >= m_display_interval);
}

//+------------------------------------------------------------------+
//| Update display                                                    |
//+------------------------------------------------------------------+
void CSimpleTestPanel::UpdateDisplay(void)
{
    if(ShouldUpdate()) {
        DisplayDatabaseOverview();
        m_last_display = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| Display database overview according to mode                      |
//+------------------------------------------------------------------+
void CSimpleTestPanel::DisplayDatabaseOverview(void)
{
    Print("📊 ================================================================");
    Print("📊 SSoT DATABASE OVERVIEW");
    Print("📊 ================================================================");
    Print("📊 Time: ", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
    Print("📊 Mode: ", m_test_mode ? "🧪 TEST MODE" : "🔴 LIVE MODE");
    Print("📊");
    
    if(m_test_mode) {
        // Test Mode: Display all three databases
        Print("📊 DATABASE 1: MAIN (sourcedb.sqlite)");
        DisplayDBInfo(m_main_db, "sourcedb.sqlite");
        DisplayAllCandleData(m_main_db, "Main Database");
        Print("📊");
        
        Print("📊 DATABASE 2: TEST INPUT (SSoT_input.db)");
        DisplayDBInfo(m_test_input_db, "SSoT_input.db");
        DisplayAllCandleData(m_test_input_db, "Test Input Database");
        Print("📊");
        
        Print("📊 DATABASE 3: TEST OUTPUT (SSoT_output.db)");
        DisplayDBInfo(m_test_output_db, "SSoT_output.db");
        DisplayAllCandleData(m_test_output_db, "Test Output Database");
    } else {
        // Live Mode: Only main database
        Print("📊 DATABASE: MAIN (sourcedb.sqlite)");
        DisplayDBInfo(m_main_db, "sourcedb.sqlite");
        DisplayAllCandleData(m_main_db, "Live Database");
    }
    
    Print("📊 ================================================================");
}

//+------------------------------------------------------------------+
//| Display database server information                              |
//+------------------------------------------------------------------+
void CSimpleTestPanel::DisplayDBInfo(int db_handle, string db_name)
{
    if(db_handle == INVALID_HANDLE) {
        Print("📊   ❌ Database not available: ", db_name);
        return;
    }
    
    Print("📊   🖥️ DBInfo:");
    Print("📊      Server: SQLite Local Database");
    Print("📊      Filename: ", db_name);
    
    // Timezone information
    MqlDateTime dt;
    TimeCurrent(dt);
    int gmt_offset = (int)((TimeCurrent() - TimeGMT()) / 3600);
    string timezone = StringFormat("GMT%s%d", (gmt_offset >= 0 ? "+" : ""), gmt_offset);
    Print("📊      Timezone: ", timezone);
    Print("📊      Local Time: ", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
}

//+------------------------------------------------------------------+
//| Display all candle data information                              |
//+------------------------------------------------------------------+
void CSimpleTestPanel::DisplayAllCandleData(int db_handle, string db_name)
{
    if(db_handle == INVALID_HANDLE) {
        Print("📊   ❌ Database not available for candle data");
        return;
    }
    
    Print("📊   📈 AllCandleData:");
    
    // Find the appropriate table name
    string table_names[] = {"candle_data", "ohlctv_data", "enhanced_data"};
    string active_table = "";
    
    for(int i = 0; i < ArraySize(table_names); i++) {
        string check_query = StringFormat("SELECT name FROM sqlite_master WHERE type='table' AND name='%s'", table_names[i]);
        int request = DatabasePrepare(db_handle, check_query);
        
        if(request != INVALID_HANDLE) {
            if(DatabaseRead(request)) {
                active_table = table_names[i];
                DatabaseFinalize(request);
                break;
            }
            DatabaseFinalize(request);
        }
    }
    
    if(active_table == "") {
        Print("📊      📊 No candle data tables found");
        return;
    }
    
    Print("📊      📋 Table: ", active_table);
    
    // Get unique assets (symbols)
    string assets_query = StringFormat("SELECT DISTINCT symbol FROM %s ORDER BY symbol", active_table);
    int request = DatabasePrepare(db_handle, assets_query);
    
    if(request == INVALID_HANDLE) {
        Print("📊      ❌ Failed to query assets");
        return;
    }
    
    string assets[];
    ArrayResize(assets, 0);
    
    while(DatabaseRead(request)) {
        string symbol;
        DatabaseColumnText(request, 0, symbol);
        int size = ArraySize(assets);
        ArrayResize(assets, size + 1);
        assets[size] = symbol;
    }
    DatabaseFinalize(request);
    
    Print("📊      🏪 Assets in DB: ", ArraySize(assets));
    
    // Get unique timeframes
    string tf_query = StringFormat("SELECT DISTINCT timeframe FROM %s ORDER BY timeframe", active_table);
    request = DatabasePrepare(db_handle, tf_query);
    
    if(request != INVALID_HANDLE) {
        string timeframes_str = "";
        while(DatabaseRead(request)) {
            long tf = 0;
            DatabaseColumnLong(request, 0, tf);
            if(timeframes_str != "") timeframes_str += ", ";
            timeframes_str += TimeframeToString((int)tf);
        }
        DatabaseFinalize(request);
        Print("📊      ⏰ Timeframes: ", timeframes_str);
    }
    
    // Get total entries
    string total_query = StringFormat("SELECT COUNT(*) FROM %s", active_table);
    request = DatabasePrepare(db_handle, total_query);
    if(request != INVALID_HANDLE) {
        if(DatabaseRead(request)) {
            long total_entries = 0;
            DatabaseColumnLong(request, 0, total_entries);
            Print("📊      📊 Total Entries: ", total_entries);
        }
        DatabaseFinalize(request);
    }
    
    // Display entries organized by timeframes for each asset
    for(int i = 0; i < ArraySize(assets); i++) {
        DisplayAssetData(db_handle, active_table, assets[i]);
    }
}

//+------------------------------------------------------------------+
//| Display data for specific asset                                  |
//+------------------------------------------------------------------+
void CSimpleTestPanel::DisplayAssetData(int db_handle, string table_name, string symbol)
{
    Print("📊      💰 Asset: ", symbol);
    
    // Get timeframes and entry counts for this symbol
    string tf_query = StringFormat(
        "SELECT timeframe, COUNT(*) as entries FROM %s WHERE symbol='%s' GROUP BY timeframe ORDER BY timeframe", 
        table_name, symbol);
    
    int request = DatabasePrepare(db_handle, tf_query);
    
    if(request == INVALID_HANDLE) {
        Print("📊         ❌ Failed to query timeframes for ", symbol);
        return;
    }
    
    while(DatabaseRead(request)) {
        long timeframe = 0, entries = 0;
        DatabaseColumnLong(request, 0, timeframe);
        DatabaseColumnLong(request, 1, entries);
        
        string tf_string = TimeframeToString((int)timeframe);
        Print("📊         📊 ", tf_string, ": ", entries, " entries");
    }
    
    DatabaseFinalize(request);
}

//+------------------------------------------------------------------+
//| Convert timeframe number to string                               |
//+------------------------------------------------------------------+
string CSimpleTestPanel::TimeframeToString(int timeframe)
{
    switch(timeframe) {
        case PERIOD_M1:  return "M1";
        case PERIOD_M5:  return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1:  return "H1";
        case PERIOD_H4:  return "H4";
        case PERIOD_D1:  return "D1";
        case PERIOD_W1:  return "W1";
        case PERIOD_MN1: return "MN1";
        default: return StringFormat("TF%d", timeframe);
    }
}
