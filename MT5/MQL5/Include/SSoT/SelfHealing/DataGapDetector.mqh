//+------------------------------------------------------------------+
//| DataGapDetector.mqh - Detects missing data gaps in databases    |
//| Focused class for identifying data continuity issues            |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.0.0"

#include <SSoT/HashUtils.mqh>

//+------------------------------------------------------------------+
//| Data Gap Information Structure                                   |
//+------------------------------------------------------------------+
struct SDataGap
{
    string                symbol;
    string                timeframe;
    datetime              gap_start;
    datetime              gap_end;
    int                   missing_bars;
    int                   severity; // 1=low, 2=medium, 3=high, 4=critical
};

//+------------------------------------------------------------------+
//| Gap Detection Configuration                                      |
//+------------------------------------------------------------------+
struct SGapDetectionConfig
{
    int                   max_acceptable_gap_minutes;
    bool                  check_weekends;
    bool                  check_holidays;
    bool                  strict_continuity;
    int                   sample_rate_percent; // 1-100, percentage of data to sample
};

//+------------------------------------------------------------------+
//| Data Gap Detector Class                                         |
//+------------------------------------------------------------------+
class CDataGapDetector
{
private:
    int                   m_main_db;
    int                   m_test_input_db;
    int                   m_test_output_db;
    SGapDetectionConfig   m_config;
    SDataGap              m_detected_gaps[];
    bool                  m_initialized;
    
    // Performance tracking
    int                   m_total_checks;
    int                   m_gaps_found;
    datetime              m_last_scan_time;

public:
    CDataGapDetector();
    ~CDataGapDetector();
    
    // Initialization
    bool Initialize(int main_db, int test_input_db, int test_output_db);
    void Configure(const SGapDetectionConfig &config);
    
    // Gap detection methods
    int DetectGaps();
    int DetectGapsInDatabase(int db_handle, const string &db_name);
    int DetectGapsForSymbol(int db_handle, const string &symbol, const string &timeframe);
    
    // Gap analysis
    bool AnalyzeContinuity(int db_handle, const string &symbol, const string &timeframe);
    bool ValidateDataSequence(int db_handle, const string &symbol, const string &timeframe, 
                             datetime start_time, datetime end_time);
    
    // Gap information
    int GetDetectedGapsCount() const { return ArraySize(m_detected_gaps); }
    SDataGap GetGap(int index);
    SDataGap[] GetAllGaps();
    string GetGapReport();
    
    // Utility methods
    bool IsMarketHours(datetime time, const string &symbol);
    bool IsWeekend(datetime time);
    int CalculateExpectedBars(datetime start_time, datetime end_time, const string &timeframe);
    
private:
    // Internal gap detection logic
    bool ScanDatabaseForGaps(int db_handle, const string &db_name);
    void AddDetectedGap(const string &symbol, const string &timeframe, 
                       datetime gap_start, datetime gap_end, int missing_bars);
    int CalculateGapSeverity(int missing_bars, const string &timeframe);
    
    // Database query helpers
    bool GetSymbolList(int db_handle, string &symbols[]);
    bool GetTimeframeList(int db_handle, const string &symbol, string &timeframes[]);
    bool GetTimeRange(int db_handle, const string &symbol, const string &timeframe,
                     datetime &first_time, datetime &last_time);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CDataGapDetector::CDataGapDetector()
{
    m_main_db = INVALID_HANDLE;
    m_test_input_db = INVALID_HANDLE;
    m_test_output_db = INVALID_HANDLE;
    m_initialized = false;
    
    m_total_checks = 0;
    m_gaps_found = 0;
    m_last_scan_time = 0;
    
    // Default configuration
    m_config.max_acceptable_gap_minutes = 60; // 1 hour
    m_config.check_weekends = false;
    m_config.check_holidays = false;
    m_config.strict_continuity = true;
    m_config.sample_rate_percent = 10; // Check 10% of data for performance
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CDataGapDetector::~CDataGapDetector()
{
    ArrayResize(m_detected_gaps, 0);
}

//+------------------------------------------------------------------+
//| Initialize the gap detector                                      |
//+------------------------------------------------------------------+
bool CDataGapDetector::Initialize(int main_db, int test_input_db, int test_output_db)
{
    if(main_db == INVALID_HANDLE) {
        Print("❌ DataGapDetector: Invalid main database handle");
        return false;
    }
    
    m_main_db = main_db;
    m_test_input_db = test_input_db;
    m_test_output_db = test_output_db;
    m_initialized = true;
    
    Print("✅ DataGapDetector: Initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Detect gaps in all databases                                    |
//+------------------------------------------------------------------+
int CDataGapDetector::DetectGaps()
{
    if(!m_initialized) {
        Print("❌ DataGapDetector: Not initialized");
        return -1;
    }
    
    Print("🔍 DataGapDetector: Starting gap detection scan...");
    
    // Clear previous results
    ArrayResize(m_detected_gaps, 0);
    m_gaps_found = 0;
    
    int total_gaps = 0;
    
    // Scan main database
    total_gaps += DetectGapsInDatabase(m_main_db, "Main");
    
    // Scan test databases if available
    if(m_test_input_db != INVALID_HANDLE) {
        total_gaps += DetectGapsInDatabase(m_test_input_db, "TestInput");
    }
    
    if(m_test_output_db != INVALID_HANDLE) {
        total_gaps += DetectGapsInDatabase(m_test_output_db, "TestOutput");
    }
    
    m_total_checks++;
    m_last_scan_time = TimeCurrent();
    m_gaps_found = total_gaps;
    
    Print("🔍 DataGapDetector: Scan complete - ", total_gaps, " gaps detected");
    
    return total_gaps;
}

//+------------------------------------------------------------------+
//| Detect gaps in specific database                                |
//+------------------------------------------------------------------+
int CDataGapDetector::DetectGapsInDatabase(int db_handle, const string &db_name)
{
    if(db_handle == INVALID_HANDLE) {
        return 0;
    }
    
    Print("🔍 Scanning database: ", db_name);
    
    string symbols[];
    if(!GetSymbolList(db_handle, symbols)) {
        Print("⚠️ Failed to get symbol list from ", db_name);
        return 0;
    }
    
    int database_gaps = 0;
    
    for(int i = 0; i < ArraySize(symbols); i++) {
        string timeframes[];
        if(GetTimeframeList(db_handle, symbols[i], timeframes)) {
            for(int j = 0; j < ArraySize(timeframes); j++) {
                database_gaps += DetectGapsForSymbol(db_handle, symbols[i], timeframes[j]);
            }
        }
    }
    
    Print("📊 ", db_name, ": ", database_gaps, " gaps found");
    return database_gaps;
}

//+------------------------------------------------------------------+
//| Detect gaps for specific symbol and timeframe                   |
//+------------------------------------------------------------------+
int CDataGapDetector::DetectGapsForSymbol(int db_handle, const string &symbol, const string &timeframe)
{
    // Get time range for this symbol/timeframe
    datetime first_time, last_time;
    if(!GetTimeRange(db_handle, symbol, timeframe, first_time, last_time)) {
        return 0;
    }
    
    // Query all timestamps for this symbol/timeframe
    string query = StringFormat(
        "SELECT timestamp FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s' ORDER BY timestamp",
        symbol, timeframe
    );
    
    int request = DatabasePrepare(db_handle, query);
    if(request == INVALID_HANDLE) {
        return 0;
    }
    
    datetime timestamps[];
    int count = 0;
    
    // Collect all timestamps
    while(DatabaseRead(request)) {
        datetime timestamp;
        DatabaseColumnLong(request, 0, timestamp);
        
        ArrayResize(timestamps, count + 1);
        timestamps[count] = timestamp;
        count++;
    }
    
    DatabaseFinalize(request);
    
    if(count < 2) {
        return 0; // Need at least 2 records to detect gaps
    }
    
    // Analyze gaps between timestamps
    int timeframe_minutes = GetTimeframeMinutes(timeframe);
    int gaps_found = 0;
    
    for(int i = 1; i < count; i++) {
        datetime prev_time = timestamps[i-1];
        datetime curr_time = timestamps[i];
        
        int gap_minutes = (int)((curr_time - prev_time) / 60);
        int expected_gap = timeframe_minutes;
        
        // Skip weekend gaps if configured
        if(!m_config.check_weekends && IsWeekend(prev_time)) {
            continue;
        }
        
        // Check if gap is larger than expected
        if(gap_minutes > expected_gap + m_config.max_acceptable_gap_minutes) {
            int missing_bars = (gap_minutes - expected_gap) / timeframe_minutes;
            
            if(missing_bars > 0) {
                AddDetectedGap(symbol, timeframe, prev_time + timeframe_minutes * 60, 
                             curr_time - timeframe_minutes * 60, missing_bars);
                gaps_found++;
            }
        }
    }
    
    return gaps_found;
}

//+------------------------------------------------------------------+
//| Add detected gap to the list                                    |
//+------------------------------------------------------------------+
void CDataGapDetector::AddDetectedGap(const string &symbol, const string &timeframe,
                                     datetime gap_start, datetime gap_end, int missing_bars)
{
    int size = ArraySize(m_detected_gaps);
    ArrayResize(m_detected_gaps, size + 1);
    
    m_detected_gaps[size].symbol = symbol;
    m_detected_gaps[size].timeframe = timeframe;
    m_detected_gaps[size].gap_start = gap_start;
    m_detected_gaps[size].gap_end = gap_end;
    m_detected_gaps[size].missing_bars = missing_bars;
    m_detected_gaps[size].severity = CalculateGapSeverity(missing_bars, timeframe);
}

//+------------------------------------------------------------------+
//| Calculate gap severity                                           |
//+------------------------------------------------------------------+
int CDataGapDetector::CalculateGapSeverity(int missing_bars, const string &timeframe)
{
    // Severity based on missing bars and timeframe
    if(missing_bars < 5) return 1;        // Low
    if(missing_bars < 20) return 2;       // Medium
    if(missing_bars < 100) return 3;      // High
    return 4;                              // Critical
}

//+------------------------------------------------------------------+
//| Get symbol list from database                                   |
//+------------------------------------------------------------------+
bool CDataGapDetector::GetSymbolList(int db_handle, string &symbols[])
{
    string query = "SELECT DISTINCT asset_symbol FROM AllCandleData ORDER BY asset_symbol";
    int request = DatabasePrepare(db_handle, query);
    if(request == INVALID_HANDLE) {
        return false;
    }
    
    ArrayResize(symbols, 0);
    int count = 0;
    
    while(DatabaseRead(request)) {
        string symbol;
        DatabaseColumnText(request, 0, symbol);
        
        ArrayResize(symbols, count + 1);
        symbols[count] = symbol;
        count++;
    }
    
    DatabaseFinalize(request);
    return count > 0;
}

//+------------------------------------------------------------------+
//| Get timeframe list for symbol                                   |
//+------------------------------------------------------------------+
bool CDataGapDetector::GetTimeframeList(int db_handle, const string &symbol, string &timeframes[])
{
    string query = StringFormat(
        "SELECT DISTINCT timeframe FROM AllCandleData WHERE asset_symbol='%s' ORDER BY timeframe",
        symbol
    );
    
    int request = DatabasePrepare(db_handle, query);
    if(request == INVALID_HANDLE) {
        return false;
    }
    
    ArrayResize(timeframes, 0);
    int count = 0;
    
    while(DatabaseRead(request)) {
        string timeframe;
        DatabaseColumnText(request, 0, timeframe);
        
        ArrayResize(timeframes, count + 1);
        timeframes[count] = timeframe;
        count++;
    }
    
    DatabaseFinalize(request);
    return count > 0;
}

//+------------------------------------------------------------------+
//| Get time range for symbol/timeframe                             |
//+------------------------------------------------------------------+
bool CDataGapDetector::GetTimeRange(int db_handle, const string &symbol, const string &timeframe,
                                   datetime &first_time, datetime &last_time)
{
    string query = StringFormat(
        "SELECT MIN(timestamp), MAX(timestamp) FROM AllCandleData WHERE asset_symbol='%s' AND timeframe='%s'",
        symbol, timeframe
    );
    
    int request = DatabasePrepare(db_handle, query);
    if(request == INVALID_HANDLE) {
        return false;
    }
    
    bool success = false;
    if(DatabaseRead(request)) {
        DatabaseColumnLong(request, 0, first_time);
        DatabaseColumnLong(request, 1, last_time);
        success = true;
    }
    
    DatabaseFinalize(request);
    return success;
}

//+------------------------------------------------------------------+
//| Get timeframe in minutes                                         |
//+------------------------------------------------------------------+
int GetTimeframeMinutes(const string &timeframe)
{
    if(timeframe == "M1") return 1;
    if(timeframe == "M5") return 5;
    if(timeframe == "M15") return 15;
    if(timeframe == "M30") return 30;
    if(timeframe == "H1") return 60;
    if(timeframe == "H4") return 240;
    if(timeframe == "D1") return 1440;
    return 60; // Default to 1 hour
}

//+------------------------------------------------------------------+
//| Check if time is weekend                                         |
//+------------------------------------------------------------------+
bool CDataGapDetector::IsWeekend(datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    return (dt.day_of_week == 0 || dt.day_of_week == 6); // Sunday or Saturday
}

//+------------------------------------------------------------------+
//| Get gap report                                                   |
//+------------------------------------------------------------------+
string CDataGapDetector::GetGapReport()
{
    string report = "=== DATA GAP DETECTION REPORT ===\n";
    report += "Total checks performed: " + IntegerToString(m_total_checks) + "\n";
    report += "Last scan time: " + TimeToString(m_last_scan_time) + "\n";
    report += "Gaps detected: " + IntegerToString(ArraySize(m_detected_gaps)) + "\n\n";
    
    if(ArraySize(m_detected_gaps) > 0) {
        report += "DETECTED GAPS:\n";
        for(int i = 0; i < ArraySize(m_detected_gaps); i++) {
            SDataGap gap = m_detected_gaps[i];
            report += StringFormat("- %s %s: %s to %s (%d bars missing, severity: %d)\n",
                                 gap.symbol, gap.timeframe,
                                 TimeToString(gap.gap_start), TimeToString(gap.gap_end),
                                 gap.missing_bars, gap.severity);
        }
    } else {
        report += "✅ No data gaps detected\n";
    }
    
    return report;
}

#endif // SSOT_DATA_GAP_DETECTOR_MQH
