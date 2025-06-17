//+------------------------------------------------------------------+
//| BoundaryConstrainedHealer.mqh                                   |
//| Healing engine that operates strictly within broker boundaries |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"
#property strict

#include "BrokerDataBoundaryManager.mqh"
#include "BoundaryAwareGapDetector.mqh"

//--- Healing operation result
struct SHealingOperation
{
    string              symbol;
    ENUM_TIMEFRAMES     timeframe;
    datetime            heal_start;
    datetime            heal_end;
    int                 bars_requested;
    int                 bars_received;
    int                 bars_inserted;
    bool                success;
    string              error_message;
    datetime            operation_time;
    int                 duration_ms;
};

//+------------------------------------------------------------------+
//| Boundary-Constrained Healer Class                              |
//| Purpose: Heal gaps only within validated broker boundaries     |
//+------------------------------------------------------------------+
class CBoundaryConstrainedHealer
{
private:
    CBrokerDataBoundaryManager* m_boundary_manager;
    CBoundaryAwareGapDetector*  m_gap_detector;
    int                         m_database_handle;
    SHealingOperation           m_healing_history[100]; // Track last 100 operations
    int                         m_history_count;
    
    // Core healing methods
    bool                        HealSpecificGap(const SGapInfo &gap);
    bool                        FetchAndInsertBrokerData(const string symbol, ENUM_TIMEFRAMES tf, datetime start, datetime end);
    bool                        ValidateHealingConstraints(const string symbol, ENUM_TIMEFRAMES tf, datetime start, datetime end);
    
    // Data insertion
    bool                        InsertMarketData(const string symbol, ENUM_TIMEFRAMES tf, const MqlRates &rate);
    bool                        VerifyInsertedData(const string symbol, ENUM_TIMEFRAMES tf, datetime start, datetime end);
    
    // Safety checks
    bool                        IsHealingSafe(const string symbol, ENUM_TIMEFRAMES tf);
    bool                        CheckDataIntegrity(const string symbol, ENUM_TIMEFRAMES tf, datetime start, datetime end);
    
public:
    //--- Constructor/Destructor
    CBoundaryConstrainedHealer();
    ~CBoundaryConstrainedHealer();
    
    //--- Initialization
    bool                        Initialize(int database_handle, CBrokerDataBoundaryManager* boundary_manager, CBoundaryAwareGapDetector* gap_detector);
    void                        Cleanup();
    
    //--- Healing Operations
    bool                        HealHighestPriorityGap();
    bool                        HealAllGapsForSymbol(const string symbol, ENUM_TIMEFRAMES tf);
    bool                        HealSpecificTimeRange(const string symbol, ENUM_TIMEFRAMES tf, datetime start, datetime end);
    bool                        PerformBoundarySync(const string symbol, ENUM_TIMEFRAMES tf);
    
    //--- Validation and Verification
    bool                        ValidateFullSync(const string symbol, ENUM_TIMEFRAMES tf);
    double                      CalculateSyncCompleteness(const string symbol, ENUM_TIMEFRAMES tf);
    bool                        VerifyDataQuality(const string symbol, ENUM_TIMEFRAMES tf, datetime start, datetime end);
    
    //--- Reporting
    string                      GenerateHealingReport();
    SHealingOperation           GetLastOperation() const;
    int                         GetSuccessfulHealingCount();
    double                      GetHealingSuccessRate();
    
    //--- Emergency Operations
    bool                        PerformEmergencyResync(const string symbol, ENUM_TIMEFRAMES tf);
    bool                        ForceCompleteRebuild(const string symbol, ENUM_TIMEFRAMES tf);
    
private:
    //--- Internal helpers
    bool                        RecordHealingOperation(const SHealingOperation &operation);
    int                         GetTimeframeSeconds(ENUM_TIMEFRAMES tf);
    string                      TimeframeToString(ENUM_TIMEFRAMES tf);
    bool                        IsMarketOpen(datetime check_time);
    bool                        ShouldSkipBar(const string symbol, ENUM_TIMEFRAMES tf, datetime bar_time);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CBoundaryConstrainedHealer::CBoundaryConstrainedHealer()
{
    m_boundary_manager = NULL;
    m_gap_detector = NULL;
    m_database_handle = INVALID_HANDLE;
    m_history_count = 0;
    
    // Initialize healing history
    for(int i = 0; i < 100; i++)
    {
        m_healing_history[i].symbol = "";
        m_healing_history[i].timeframe = PERIOD_CURRENT;
        m_healing_history[i].heal_start = 0;
        m_healing_history[i].heal_end = 0;
        m_healing_history[i].bars_requested = 0;
        m_healing_history[i].bars_received = 0;
        m_healing_history[i].bars_inserted = 0;
        m_healing_history[i].success = false;
        m_healing_history[i].error_message = "";
        m_healing_history[i].operation_time = 0;
        m_healing_history[i].duration_ms = 0;
    }
}

//+------------------------------------------------------------------+
//| Destructor                                                      |
//+------------------------------------------------------------------+
CBoundaryConstrainedHealer::~CBoundaryConstrainedHealer()
{
    Cleanup();
}

//+------------------------------------------------------------------+
//| Initialize the healer                                           |
//+------------------------------------------------------------------+
bool CBoundaryConstrainedHealer::Initialize(int database_handle, CBrokerDataBoundaryManager* boundary_manager, CBoundaryAwareGapDetector* gap_detector)
{
    if(database_handle == INVALID_HANDLE)
    {
        Print("[HEALER] ERROR: Invalid database handle");
        return false;
    }
    
    if(boundary_manager == NULL)
    {
        Print("[HEALER] ERROR: Boundary manager is NULL");
        return false;
    }
    
    if(gap_detector == NULL)
    {
        Print("[HEALER] ERROR: Gap detector is NULL");
        return false;
    }
    
    m_database_handle = database_handle;
    m_boundary_manager = boundary_manager;
    m_gap_detector = gap_detector;
    
    Print("[HEALER] Boundary-constrained healer initialized");
    return true;
}

//+------------------------------------------------------------------+
//| Cleanup resources                                               |
//+------------------------------------------------------------------+
void CBoundaryConstrainedHealer::Cleanup()
{
    m_history_count = 0;
    m_database_handle = INVALID_HANDLE;
    m_boundary_manager = NULL;
    m_gap_detector = NULL;
}

//+------------------------------------------------------------------+
//| Heal the highest priority gap                                  |
//+------------------------------------------------------------------+
bool CBoundaryConstrainedHealer::HealHighestPriorityGap()
{
    if(m_gap_detector == NULL)
    {
        Print("[HEALER] ERROR: Gap detector not initialized");
        return false;
    }
    
    // Get the highest priority gap
    SGapInfo priority_gap = m_gap_detector.GetHighestPriorityGap();
    if(priority_gap.symbol == "")
    {
        Print("[HEALER] No priority gaps found for healing");
        return true; // Not an error, just nothing to heal
    }
    
    Print("[HEALER] Healing priority gap: ", priority_gap.symbol, " ", TimeframeToString(priority_gap.timeframe),
          " from ", TimeToString(priority_gap.gap_start), " to ", TimeToString(priority_gap.gap_end));
    
    // Heal this specific gap
    return HealSpecificGap(priority_gap);
}

//+------------------------------------------------------------------+
//| Heal a specific gap                                             |
//+------------------------------------------------------------------+
bool CBoundaryConstrainedHealer::HealSpecificGap(const SGapInfo &gap)
{
    uint start_time = GetTickCount();
    SHealingOperation operation;
    
    // Initialize operation record
    operation.symbol = gap.symbol;
    operation.timeframe = gap.timeframe;
    operation.heal_start = gap.gap_start;
    operation.heal_end = gap.gap_end;
    operation.operation_time = TimeCurrent();
    operation.success = false;
    
    // Validate healing constraints
    if(!ValidateHealingConstraints(gap.symbol, gap.timeframe, gap.gap_start, gap.gap_end))
    {
        operation.error_message = "Healing constraints validation failed";
        operation.duration_ms = GetTickCount() - start_time;
        RecordHealingOperation(operation);
        Print("[HEALER] ERROR: Healing constraints failed for ", gap.symbol, " ", TimeframeToString(gap.timeframe));
        return false;
    }
    
    // Safety check
    if(!IsHealingSafe(gap.symbol, gap.timeframe))
    {
        operation.error_message = "Healing safety check failed";
        operation.duration_ms = GetTickCount() - start_time;
        RecordHealingOperation(operation);
        Print("[HEALER] ERROR: Healing safety check failed for ", gap.symbol, " ", TimeframeToString(gap.timeframe));
        return false;
    }
    
    // Perform the actual healing
    bool heal_success = FetchAndInsertBrokerData(gap.symbol, gap.timeframe, gap.gap_start, gap.gap_end);
    
    if(heal_success)
    {
        // Verify the healing was successful
        if(VerifyInsertedData(gap.symbol, gap.timeframe, gap.gap_start, gap.gap_end))
        {
            operation.success = true;
            Print("[HEALER] SUCCESS: Gap healed for ", gap.symbol, " ", TimeframeToString(gap.timeframe),
                  " | Bars inserted: ", operation.bars_inserted);
        }
        else
        {
            operation.error_message = "Data verification failed after insertion";
            Print("[HEALER] ERROR: Data verification failed after healing ", gap.symbol, " ", TimeframeToString(gap.timeframe));
        }
    }
    else
    {
        operation.error_message = "Failed to fetch and insert broker data";
        Print("[HEALER] ERROR: Failed to fetch broker data for ", gap.symbol, " ", TimeframeToString(gap.timeframe));
    }
    
    operation.duration_ms = GetTickCount() - start_time;
    RecordHealingOperation(operation);
    
    return operation.success;
}

//+------------------------------------------------------------------+
//| Fetch data from broker and insert into database                |
//+------------------------------------------------------------------+
bool CBoundaryConstrainedHealer::FetchAndInsertBrokerData(const string symbol, ENUM_TIMEFRAMES tf, datetime start, datetime end)
{
    // Fetch data from broker
    MqlRates rates[];
    int bars_copied = CopyRates(symbol, tf, start, end, rates);
    
    if(bars_copied <= 0)
    {
        Print("[HEALER] ERROR: No data received from broker for ", symbol, " ", TimeframeToString(tf));
        return false;
    }
    
    Print("[HEALER] Received ", bars_copied, " bars from broker for ", symbol, " ", TimeframeToString(tf));
    
    // Insert each bar into database
    int successful_inserts = 0;
    
    for(int i = 0; i < bars_copied; i++)
    {
        // Check if this bar time should be skipped (weekends, holidays, etc.)
        if(ShouldSkipBar(symbol, tf, rates[i].time))
        {
            continue;
        }
        
        // Insert this bar
        if(InsertMarketData(symbol, tf, rates[i]))
        {
            successful_inserts++;
        }
        else
        {
            Print("[HEALER] WARNING: Failed to insert bar at ", TimeToString(rates[i].time));
        }
    }
    
    Print("[HEALER] Successfully inserted ", successful_inserts, "/", bars_copied, " bars");
    
    // Record in the last operation
    if(m_history_count > 0)
    {
        m_healing_history[m_history_count - 1].bars_requested = bars_copied;
        m_healing_history[m_history_count - 1].bars_received = bars_copied;
        m_healing_history[m_history_count - 1].bars_inserted = successful_inserts;
    }
    
    return (successful_inserts > 0);
}

//+------------------------------------------------------------------+
//| Insert market data into database                               |
//+------------------------------------------------------------------+
bool CBoundaryConstrainedHealer::InsertMarketData(const string symbol, ENUM_TIMEFRAMES tf, const MqlRates &rate)
{
    if(m_database_handle == INVALID_HANDLE) return false;
    
    // Prepare INSERT statement with conflict resolution
    string query = StringFormat(
        "INSERT OR REPLACE INTO market_data (symbol, timeframe, timestamp, open_price, high_price, low_price, close_price, volume, spread) VALUES ('%s', %d, %d, %.5f, %.5f, %.5f, %.5f, %d, 0)",
        symbol, tf, rate.time, rate.open, rate.high, rate.low, rate.close, rate.tick_volume
    );
    
    if(!DatabaseExecute(m_database_handle, query))
    {
        Print("[HEALER] ERROR: Failed to insert bar data: ", GetLastError());
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Validate healing constraints                                    |
//+------------------------------------------------------------------+
bool CBoundaryConstrainedHealer::ValidateHealingConstraints(const string symbol, ENUM_TIMEFRAMES tf, datetime start, datetime end)
{
    if(m_boundary_manager == NULL) return false;
    
    // Get boundary information
    SBrokerBoundary boundary = m_boundary_manager.GetBoundaryInfo(symbol, tf);
    if(boundary.symbol == "")
    {
        Print("[HEALER] ERROR: No boundary info available for ", symbol, " ", TimeframeToString(tf));
        return false;
    }
    
    // Healing range must be completely within broker boundaries
    if(start < boundary.first_available || end > boundary.last_available)
    {
        Print("[HEALER] ERROR: Healing range outside broker boundaries");
        Print("[HEALER] Requested: ", TimeToString(start), " to ", TimeToString(end));
        Print("[HEALER] Available: ", TimeToString(boundary.first_available), " to ", TimeToString(boundary.last_available));
        return false;
    }
    
    // Time range must be valid
    if(start >= end)
    {
        Print("[HEALER] ERROR: Invalid time range for healing");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Verify inserted data                                           |
//+------------------------------------------------------------------+
bool CBoundaryConstrainedHealer::VerifyInsertedData(const string symbol, ENUM_TIMEFRAMES tf, datetime start, datetime end)
{
    if(m_database_handle == INVALID_HANDLE) return false;
    
    // Count bars in the healed range
    string query = StringFormat(
        "SELECT COUNT(*) FROM market_data WHERE symbol='%s' AND timeframe=%d AND timestamp BETWEEN %d AND %d",
        symbol, tf, start, end
    );
    
    int request = DatabasePrepare(m_database_handle, query);
    if(request == INVALID_HANDLE) return false;
    
    int bar_count = 0;
    if(DatabaseRead(request))
    {
        bar_count = (int)DatabaseColumnLong(request, 0);
    }
    
    DatabaseFinalize(request);
    
    // Calculate expected bars
    int tf_seconds = GetTimeframeSeconds(tf);
    int expected_bars = (int)((end - start) / tf_seconds);
    
    // Allow some tolerance for market closures
    double completeness = (double)bar_count / expected_bars;
    
    Print("[HEALER] Data verification: ", bar_count, "/", expected_bars, " bars (", 
          DoubleToString(completeness * 100.0, 1), "% complete)");
    
    return (completeness >= 0.8); // 80% completeness is acceptable
}

//+------------------------------------------------------------------+
//| Check if healing is safe                                        |
//+------------------------------------------------------------------+
bool CBoundaryConstrainedHealer::IsHealingSafe(const string symbol, ENUM_TIMEFRAMES tf)
{
    // Basic safety checks
    if(m_database_handle == INVALID_HANDLE) return false;
    if(m_boundary_manager == NULL) return false;
    
    // Check if symbol is available
    if(!SymbolSelect(symbol, true))
    {
        Print("[HEALER] ERROR: Symbol not available: ", symbol);
        return false;
    }
    
    // Check if we're not overloading the system
    static datetime last_healing_time = 0;
    if(TimeCurrent() - last_healing_time < 5) // Minimum 5 seconds between healings
    {
        Print("[HEALER] WARNING: Healing rate limited");
        return false;
    }
    
    last_healing_time = TimeCurrent();
    return true;
}

//+------------------------------------------------------------------+
//| Record healing operation                                        |
//+------------------------------------------------------------------+
bool CBoundaryConstrainedHealer::RecordHealingOperation(const SHealingOperation &operation)
{
    if(m_history_count >= 100)
    {
        // Shift array to make room
        for(int i = 0; i < 99; i++)
        {
            m_healing_history[i] = m_healing_history[i + 1];
        }
        m_history_count = 99;
    }
    
    m_healing_history[m_history_count] = operation;
    m_history_count++;
    
    return true;
}

//+------------------------------------------------------------------+
//| Get successful healing count                                    |
//+------------------------------------------------------------------+
int CBoundaryConstrainedHealer::GetSuccessfulHealingCount()
{
    int success_count = 0;
    
    for(int i = 0; i < m_history_count; i++)
    {
        if(m_healing_history[i].success)
        {
            success_count++;
        }
    }
    
    return success_count;
}

//+------------------------------------------------------------------+
//| Get healing success rate                                        |
//+------------------------------------------------------------------+
double CBoundaryConstrainedHealer::GetHealingSuccessRate()
{
    if(m_history_count == 0) return 100.0;
    
    int successful = GetSuccessfulHealingCount();
    return (double)successful / m_history_count * 100.0;
}

//+------------------------------------------------------------------+
//| Generate healing report                                         |
//+------------------------------------------------------------------+
string CBoundaryConstrainedHealer::GenerateHealingReport()
{
    string report = "=== BOUNDARY-CONSTRAINED HEALING REPORT ===\n";
    report += StringFormat("Total Operations: %d\n", m_history_count);
    report += StringFormat("Successful: %d\n", GetSuccessfulHealingCount());
    report += StringFormat("Success Rate: %.1f%%\n", GetHealingSuccessRate());
    
    if(m_history_count > 0)
    {
        SHealingOperation last_op = m_healing_history[m_history_count - 1];
        report += StringFormat("Last Operation: %s %s at %s (%s)\n",
                              last_op.symbol,
                              TimeframeToString(last_op.timeframe),
                              TimeToString(last_op.operation_time),
                              last_op.success ? "SUCCESS" : "FAILED");
    }
    
    return report;
}

//+------------------------------------------------------------------+
//| Get timeframe in seconds                                        |
//+------------------------------------------------------------------+
int CBoundaryConstrainedHealer::GetTimeframeSeconds(ENUM_TIMEFRAMES tf)
{
    return PeriodSeconds(tf);
}

//+------------------------------------------------------------------+
//| Convert timeframe to string                                     |
//+------------------------------------------------------------------+
string CBoundaryConstrainedHealer::TimeframeToString(ENUM_TIMEFRAMES tf)
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

//+------------------------------------------------------------------+
//| Check if should skip bar (weekends, holidays)                  |
//+------------------------------------------------------------------+
bool CBoundaryConstrainedHealer::ShouldSkipBar(const string symbol, ENUM_TIMEFRAMES tf, datetime bar_time)
{
    MqlDateTime dt;
    TimeToStruct(bar_time, dt);
    
    // Skip weekends for most symbols
    if(dt.day_of_week == 0 || dt.day_of_week == 6)
    {
        return true;
    }
    
    return false;
}
