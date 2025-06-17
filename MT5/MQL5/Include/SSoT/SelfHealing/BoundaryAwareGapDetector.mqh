//+------------------------------------------------------------------+
//| BoundaryAwareGapDetector.mqh                                    |
//| Gap detection that respects broker data boundaries             |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"
#property strict

#include "BrokerDataBoundaryManager.mqh"

//--- Gap information structure
struct SGapInfo
{
    string              symbol;
    ENUM_TIMEFRAMES     timeframe;
    datetime            gap_start;
    datetime            gap_end;
    int                 missing_bars;
    bool                within_broker_boundaries;
    bool                is_healable;
    datetime            detected_at;
};

//+------------------------------------------------------------------+
//| Boundary-Aware Gap Detector Class                              |
//| Purpose: Detect gaps only within broker data boundaries        |
//+------------------------------------------------------------------+
class CBoundaryAwareGapDetector
{
private:
    CBrokerDataBoundaryManager* m_boundary_manager;
    SGapInfo            m_detected_gaps[1000];  // Support up to 1000 detected gaps
    int                 m_gap_count;
    int                 m_database_handle;
    
    // Gap detection methods
    bool                ScanForGapsInBoundaries(const string symbol, ENUM_TIMEFRAMES tf);
    bool                ValidateGapAgainstBroker(const string symbol, ENUM_TIMEFRAMES tf, datetime gap_start, datetime gap_end);
    bool                IsGapHealable(const string symbol, ENUM_TIMEFRAMES tf, datetime gap_start, datetime gap_end);
    
    // Database gap detection
    bool                DetectDatabaseGaps(const string symbol, ENUM_TIMEFRAMES tf, datetime boundary_start, datetime boundary_end);
    bool                AddGapToList(const string symbol, ENUM_TIMEFRAMES tf, datetime gap_start, datetime gap_end);
    
public:
    //--- Constructor/Destructor
    CBoundaryAwareGapDetector();
    ~CBoundaryAwareGapDetector();
    
    //--- Initialization
    bool                Initialize(int database_handle, CBrokerDataBoundaryManager* boundary_manager);
    void                Cleanup();
    
    //--- Gap Detection
    bool                DetectAllGapsWithinBoundaries();
    bool                DetectGapsForSymbol(const string symbol, ENUM_TIMEFRAMES tf);
    bool                RefreshGapDetection();
    
    //--- Gap Information
    int                 GetTotalGapCount() const { return m_gap_count; }
    int                 GetHealableGapCount();
    SGapInfo            GetGap(int index);
    SGapInfo[]          GetAllGapsForSymbol(const string symbol, ENUM_TIMEFRAMES tf);
    
    //--- Gap Validation
    bool                IsGapWithinBoundaries(const string symbol, ENUM_TIMEFRAMES tf, datetime gap_start, datetime gap_end);
    bool                CanGapBeHealed(const string symbol, ENUM_TIMEFRAMES tf, datetime gap_start, datetime gap_end);
    
    //--- Reporting
    string              GenerateGapReport();
    string              GenerateGapSummary();
    int                 CountGapsInTimeRange(const string symbol, ENUM_TIMEFRAMES tf, datetime from, datetime to);
    
    //--- Priority Analysis
    SGapInfo            GetHighestPriorityGap();
    SGapInfo[]          GetGapsByPriority(); // Returns gaps sorted by healing priority
    
private:
    //--- Internal helpers
    int                 CalculateExpectedBars(ENUM_TIMEFRAMES tf, datetime start, datetime end);
    bool                IsTimeWithinMarketHours(datetime check_time);
    string              TimeframeToString(ENUM_TIMEFRAMES tf);
    int                 CompareGapPriority(const SGapInfo &gap1, const SGapInfo &gap2);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CBoundaryAwareGapDetector::CBoundaryAwareGapDetector()
{
    m_boundary_manager = NULL;
    m_gap_count = 0;
    m_database_handle = INVALID_HANDLE;
    
    // Initialize gap array
    for(int i = 0; i < 1000; i++)
    {
        m_detected_gaps[i].symbol = "";
        m_detected_gaps[i].timeframe = PERIOD_CURRENT;
        m_detected_gaps[i].gap_start = 0;
        m_detected_gaps[i].gap_end = 0;
        m_detected_gaps[i].missing_bars = 0;
        m_detected_gaps[i].within_broker_boundaries = false;
        m_detected_gaps[i].is_healable = false;
        m_detected_gaps[i].detected_at = 0;
    }
}

//+------------------------------------------------------------------+
//| Destructor                                                      |
//+------------------------------------------------------------------+
CBoundaryAwareGapDetector::~CBoundaryAwareGapDetector()
{
    Cleanup();
}

//+------------------------------------------------------------------+
//| Initialize the gap detector                                     |
//+------------------------------------------------------------------+
bool CBoundaryAwareGapDetector::Initialize(int database_handle, CBrokerDataBoundaryManager* boundary_manager)
{
    if(database_handle == INVALID_HANDLE)
    {
        Print("[GAP-DETECTOR] ERROR: Invalid database handle");
        return false;
    }
    
    if(boundary_manager == NULL)
    {
        Print("[GAP-DETECTOR] ERROR: Boundary manager is NULL");
        return false;
    }
    
    m_database_handle = database_handle;
    m_boundary_manager = boundary_manager;
    
    Print("[GAP-DETECTOR] Boundary-aware gap detector initialized");
    return true;
}

//+------------------------------------------------------------------+
//| Cleanup resources                                               |
//+------------------------------------------------------------------+
void CBoundaryAwareGapDetector::Cleanup()
{
    m_gap_count = 0;
    m_database_handle = INVALID_HANDLE;
    m_boundary_manager = NULL;
}

//+------------------------------------------------------------------+
//| Detect gaps for specific symbol within boundaries              |
//+------------------------------------------------------------------+
bool CBoundaryAwareGapDetector::DetectGapsForSymbol(const string symbol, ENUM_TIMEFRAMES tf)
{
    if(m_boundary_manager == NULL)
    {
        Print("[GAP-DETECTOR] ERROR: Boundary manager not initialized");
        return false;
    }
    
    // Get boundary information
    SBrokerBoundary boundary = m_boundary_manager.GetBoundaryInfo(symbol, tf);
    if(boundary.symbol == "")
    {
        Print("[GAP-DETECTOR] ERROR: No boundary info for ", symbol, " ", TimeframeToString(tf));
        return false;
    }
    
    // Only scan within broker boundaries
    datetime scan_start = boundary.first_available;
    datetime scan_end = boundary.last_available;
    
    if(scan_start >= scan_end)
    {
        Print("[GAP-DETECTOR] ERROR: Invalid boundary range for ", symbol, " ", TimeframeToString(tf));
        return false;
    }
    
    Print("[GAP-DETECTOR] Scanning for gaps in ", symbol, " ", TimeframeToString(tf), 
          " within boundaries: ", TimeToString(scan_start), " to ", TimeToString(scan_end));
    
    // Detect gaps in this range
    bool success = DetectDatabaseGaps(symbol, tf, scan_start, scan_end);
    
    if(success)
    {
        Print("[GAP-DETECTOR] Gap scan completed for ", symbol, " ", TimeframeToString(tf));
    }
    else
    {
        Print("[GAP-DETECTOR] WARNING: Gap scan failed for ", symbol, " ", TimeframeToString(tf));
    }
    
    return success;
}

//+------------------------------------------------------------------+
//| Detect database gaps within specified boundaries               |
//+------------------------------------------------------------------+
bool CBoundaryAwareGapDetector::DetectDatabaseGaps(const string symbol, ENUM_TIMEFRAMES tf, datetime boundary_start, datetime boundary_end)
{
    if(m_database_handle == INVALID_HANDLE) return false;
    
    // Query to find gaps in the time series
    string query = StringFormat(
        "SELECT timestamp FROM market_data WHERE symbol='%s' AND timeframe=%d AND timestamp BETWEEN %d AND %d ORDER BY timestamp",
        symbol, tf, boundary_start, boundary_end
    );
    
    int request = DatabasePrepare(m_database_handle, query);
    if(request == INVALID_HANDLE)
    {
        Print("[GAP-DETECTOR] ERROR: Failed to prepare gap detection query");
        return false;
    }
    
    // Get expected timeframe interval
    int tf_seconds = PeriodSeconds(tf);
    if(tf_seconds <= 0)
    {
        DatabaseFinalize(request);
        return false;
    }
    
    datetime previous_time = 0;
    datetime current_time = 0;
    int gaps_found = 0;
    
    // Scan through results looking for gaps
    while(DatabaseRead(request))
    {
        current_time = (datetime)DatabaseColumnLong(request, 0);
        
        if(previous_time > 0)
        {
            // Calculate expected next time
            datetime expected_next = previous_time + tf_seconds;
            
            // Check if there's a gap (allowing for weekends/market closed periods)
            if(current_time > expected_next + tf_seconds) // Gap bigger than one bar
            {
                // Validate this is a real gap within market hours
                if(IsTimeWithinMarketHours(expected_next) && IsTimeWithinMarketHours(current_time))
                {
                    // This is a legitimate gap within broker boundaries
                    if(AddGapToList(symbol, tf, expected_next, current_time - tf_seconds))
                    {
                        gaps_found++;
                        Print("[GAP-DETECTOR] Gap found: ", symbol, " ", TimeframeToString(tf), 
                              " from ", TimeToString(expected_next), " to ", TimeToString(current_time - tf_seconds));
                    }
                }
            }
        }
        
        previous_time = current_time;
    }
    
    DatabaseFinalize(request);
    
    Print("[GAP-DETECTOR] Completed gap detection for ", symbol, " ", TimeframeToString(tf), 
          " - Found ", gaps_found, " gaps within boundaries");
    
    return true;
}

//+------------------------------------------------------------------+
//| Add gap to detection list                                       |
//+------------------------------------------------------------------+
bool CBoundaryAwareGapDetector::AddGapToList(const string symbol, ENUM_TIMEFRAMES tf, datetime gap_start, datetime gap_end)
{
    if(m_gap_count >= 1000)
    {
        Print("[GAP-DETECTOR] ERROR: Maximum gap count reached (1000)");
        return false;
    }
    
    // Validate gap is within broker boundaries
    bool within_boundaries = IsGapWithinBoundaries(symbol, tf, gap_start, gap_end);
    
    // Check if gap can be healed
    bool healable = CanGapBeHealed(symbol, tf, gap_start, gap_end);
    
    // Add to list
    m_detected_gaps[m_gap_count].symbol = symbol;
    m_detected_gaps[m_gap_count].timeframe = tf;
    m_detected_gaps[m_gap_count].gap_start = gap_start;
    m_detected_gaps[m_gap_count].gap_end = gap_end;
    m_detected_gaps[m_gap_count].missing_bars = CalculateExpectedBars(tf, gap_start, gap_end);
    m_detected_gaps[m_gap_count].within_broker_boundaries = within_boundaries;
    m_detected_gaps[m_gap_count].is_healable = healable;
    m_detected_gaps[m_gap_count].detected_at = TimeCurrent();
    
    m_gap_count++;
    return true;
}

//+------------------------------------------------------------------+
//| Check if gap is within broker boundaries                       |
//+------------------------------------------------------------------+
bool CBoundaryAwareGapDetector::IsGapWithinBoundaries(const string symbol, ENUM_TIMEFRAMES tf, datetime gap_start, datetime gap_end)
{
    if(m_boundary_manager == NULL) return false;
    
    SBrokerBoundary boundary = m_boundary_manager.GetBoundaryInfo(symbol, tf);
    if(boundary.symbol == "") return false;
    
    // Gap must be completely within broker boundaries
    return (gap_start >= boundary.first_available && gap_end <= boundary.last_available);
}

//+------------------------------------------------------------------+
//| Check if gap can be healed                                      |
//+------------------------------------------------------------------+
bool CBoundaryAwareGapDetector::CanGapBeHealed(const string symbol, ENUM_TIMEFRAMES tf, datetime gap_start, datetime gap_end)
{
    // Gap can be healed if:
    // 1. It's within broker boundaries
    if(!IsGapWithinBoundaries(symbol, tf, gap_start, gap_end)) return false;
    
    // 2. The broker should have this data available
    MqlRates rates[];
    int available_bars = CopyRates(symbol, tf, gap_start, gap_end, rates);
    
    // If broker has the data, we can heal the gap
    return (available_bars > 0);
}

//+------------------------------------------------------------------+
//| Calculate expected bars in time range                          |
//+------------------------------------------------------------------+
int CBoundaryAwareGapDetector::CalculateExpectedBars(ENUM_TIMEFRAMES tf, datetime start, datetime end)
{
    int tf_seconds = PeriodSeconds(tf);
    if(tf_seconds <= 0 || end <= start) return 0;
    
    return (int)((end - start) / tf_seconds);
}

//+------------------------------------------------------------------+
//| Check if time is within market hours                           |
//+------------------------------------------------------------------+
bool CBoundaryAwareGapDetector::IsTimeWithinMarketHours(datetime check_time)
{
    // For now, assume all times are valid
    // In a real implementation, this would check market open hours
    // and exclude weekends/holidays
    
    MqlDateTime dt;
    TimeToStruct(check_time, dt);
    
    // Exclude weekends
    if(dt.day_of_week == 0 || dt.day_of_week == 6) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Get healable gap count                                          |
//+------------------------------------------------------------------+
int CBoundaryAwareGapDetector::GetHealableGapCount()
{
    int healable_count = 0;
    
    for(int i = 0; i < m_gap_count; i++)
    {
        if(m_detected_gaps[i].is_healable && m_detected_gaps[i].within_broker_boundaries)
        {
            healable_count++;
        }
    }
    
    return healable_count;
}

//+------------------------------------------------------------------+
//| Generate gap report                                             |
//+------------------------------------------------------------------+
string CBoundaryAwareGapDetector::GenerateGapReport()
{
    string report = "=== BOUNDARY-AWARE GAP DETECTION REPORT ===\n";
    report += StringFormat("Total Gaps Detected: %d\n", m_gap_count);
    report += StringFormat("Healable Gaps: %d\n", GetHealableGapCount());
    report += "\nGap Details:\n";
    
    for(int i = 0; i < MathMin(m_gap_count, 20); i++) // Show first 20 gaps
    {
        SGapInfo gap = m_detected_gaps[i];
        report += StringFormat("Gap %d: %s %s | %s to %s | %d bars | %s | %s\n",
                              i + 1,
                              gap.symbol,
                              TimeframeToString(gap.timeframe),
                              TimeToString(gap.gap_start),
                              TimeToString(gap.gap_end),
                              gap.missing_bars,
                              gap.within_broker_boundaries ? "WITHIN BOUNDS" : "OUTSIDE BOUNDS",
                              gap.is_healable ? "HEALABLE" : "NOT HEALABLE");
    }
    
    if(m_gap_count > 20)
    {
        report += StringFormat("... and %d more gaps\n", m_gap_count - 20);
    }
    
    return report;
}

//+------------------------------------------------------------------+
//| Get highest priority gap for healing                           |
//+------------------------------------------------------------------+
SGapInfo CBoundaryAwareGapDetector::GetHighestPriorityGap()
{
    SGapInfo empty_gap = {0};
    SGapInfo best_gap = {0};
    int best_priority = -1;
    
    for(int i = 0; i < m_gap_count; i++)
    {
        if(!m_detected_gaps[i].is_healable || !m_detected_gaps[i].within_broker_boundaries)
            continue;
        
        // Priority based on: recent timeframes, smaller gaps first, recent detection
        int priority = 0;
        
        // Higher priority for shorter timeframes
        if(m_detected_gaps[i].timeframe == PERIOD_M1) priority += 100;
        else if(m_detected_gaps[i].timeframe == PERIOD_M5) priority += 80;
        else if(m_detected_gaps[i].timeframe == PERIOD_M15) priority += 60;
        else if(m_detected_gaps[i].timeframe == PERIOD_H1) priority += 40;
        
        // Higher priority for smaller gaps (easier to heal)
        if(m_detected_gaps[i].missing_bars <= 5) priority += 50;
        else if(m_detected_gaps[i].missing_bars <= 20) priority += 30;
        else if(m_detected_gaps[i].missing_bars <= 50) priority += 10;
        
        // Higher priority for recent gaps
        if(TimeCurrent() - m_detected_gaps[i].gap_end < 86400) priority += 20; // Last 24 hours
        
        if(priority > best_priority)
        {
            best_priority = priority;
            best_gap = m_detected_gaps[i];
        }
    }
    
    return best_gap.symbol != "" ? best_gap : empty_gap;
}

//+------------------------------------------------------------------+
//| Convert timeframe to string                                     |
//+------------------------------------------------------------------+
string CBoundaryAwareGapDetector::TimeframeToString(ENUM_TIMEFRAMES tf)
{
    switch(tf)
    {
        case PERIOD_M1: return "M1";
        case PERIOD_M5: return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_H1: return "H1";
        case PERIOD_H4: return "H4";
        case PERIOD_D1: return "D1";
        default: return "UNKNOWN";
    }
}
