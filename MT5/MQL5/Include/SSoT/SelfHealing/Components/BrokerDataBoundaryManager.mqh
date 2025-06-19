//+------------------------------------------------------------------+
//| BrokerDataBoundaryManager.mqh                                   |
//| Manages broker data boundaries for complete 1-1 sync           |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"
#property strict

//--- Broker data boundary structure
struct SBrokerBoundary
{
    string              symbol;
    ENUM_TIMEFRAMES     timeframe;
    datetime            first_available;    // Earliest data point from broker
    datetime            last_available;     // Latest data point from broker
    datetime            first_in_db;        // Earliest data in our database
    datetime            last_in_db;         // Latest data in our database
    int                 total_broker_bars;  // Total bars available from broker
    int                 total_db_bars;      // Total bars in our database
    bool                is_synchronized;    // True if 100% synced within boundaries
    datetime            last_boundary_check; // When boundaries were last verified
};

//+------------------------------------------------------------------+
//| Broker Data Boundary Manager Class                             |
//| Purpose: Detect broker data limits and ensure complete sync    |
//+------------------------------------------------------------------+
class CBrokerDataBoundaryManager
{
private:
    SBrokerBoundary     m_boundaries[100];  // Support up to 100 symbol/timeframe pairs
    int                 m_boundary_count;
    int                 m_database_handle;
    datetime            m_last_global_check;
    
    // Boundary detection methods
    bool                DetectBrokerBoundaries(const string symbol, ENUM_TIMEFRAMES tf, SBrokerBoundary &boundary);
    bool                DetectDatabaseBoundaries(const string symbol, ENUM_TIMEFRAMES tf, SBrokerBoundary &boundary);
    bool                VerifyCompleteness(SBrokerBoundary &boundary);
    
    // Database queries
    datetime            GetFirstBarInDatabase(const string symbol, ENUM_TIMEFRAMES tf);
    datetime            GetLastBarInDatabase(const string symbol, ENUM_TIMEFRAMES tf);
    int                 CountBarsInDatabase(const string symbol, ENUM_TIMEFRAMES tf, datetime from, datetime to);
    
    // Broker queries
    datetime            GetFirstAvailableFromBroker(const string symbol, ENUM_TIMEFRAMES tf);
    datetime            GetLastAvailableFromBroker(const string symbol, ENUM_TIMEFRAMES tf);
    int                 CountAvailableBarsFromBroker(const string symbol, ENUM_TIMEFRAMES tf, datetime from, datetime to);
    
public:
    //--- Constructor/Destructor
    CBrokerDataBoundaryManager();
    ~CBrokerDataBoundaryManager();
    
    //--- Initialization
    bool                Initialize(int database_handle);
    void                Cleanup();
    
    //--- Boundary Management
    bool                RegisterSymbolTimeframe(const string symbol, ENUM_TIMEFRAMES tf);
    bool                UpdateBoundaries(const string symbol, ENUM_TIMEFRAMES tf);
    bool                UpdateAllBoundaries();
    
    //--- Sync Validation
    bool                IsCompletelyInSync(const string symbol, ENUM_TIMEFRAMES tf);
    bool                IsWithinBrokerBoundaries(const string symbol, ENUM_TIMEFRAMES tf, datetime check_time);
    double              GetSyncPercentage(const string symbol, ENUM_TIMEFRAMES tf);
    
    //--- Gap Detection within Boundaries
    bool                FindGapsWithinBoundaries(const string symbol, ENUM_TIMEFRAMES tf, datetime &gap_starts[], datetime &gap_ends[]);
    bool                HasGapsInBoundaries(const string symbol, ENUM_TIMEFRAMES tf);
    int                 CountMissingBarsInBoundaries(const string symbol, ENUM_TIMEFRAMES tf);
    
    //--- Boundary Information
    SBrokerBoundary     GetBoundaryInfo(const string symbol, ENUM_TIMEFRAMES tf);
    datetime            GetSyncWindowStart(const string symbol, ENUM_TIMEFRAMES tf);
    datetime            GetSyncWindowEnd(const string symbol, ENUM_TIMEFRAMES tf);
    
    //--- Reporting
    string              GenerateBoundaryReport(const string symbol, ENUM_TIMEFRAMES tf);
    string              GenerateGlobalSyncReport();
    bool                ExportBoundaryData(const string filename);
    
    //--- Healing Constraints
    bool                ValidateHealingTarget(const string symbol, ENUM_TIMEFRAMES tf, datetime target_time);
    bool                GetHealingConstraints(const string symbol, ENUM_TIMEFRAMES tf, datetime &min_time, datetime &max_time);
    bool                IsHealingNeededInBoundaries(const string symbol, ENUM_TIMEFRAMES tf);

private:
    //--- Internal helpers
    int                 FindBoundaryIndex(const string symbol, ENUM_TIMEFRAMES tf);
    bool                CreateBoundaryEntry(const string symbol, ENUM_TIMEFRAMES tf);
    string              TimeframeToString(ENUM_TIMEFRAMES tf);
    bool                ValidateSymbolTimeframe(const string symbol, ENUM_TIMEFRAMES tf);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CBrokerDataBoundaryManager::CBrokerDataBoundaryManager()
{
    m_boundary_count = 0;
    m_database_handle = INVALID_HANDLE;
    m_last_global_check = 0;
    
    // Initialize boundary array
    for(int i = 0; i < 100; i++)
    {
        m_boundaries[i].symbol = "";
        m_boundaries[i].timeframe = PERIOD_CURRENT;
        m_boundaries[i].first_available = 0;
        m_boundaries[i].last_available = 0;
        m_boundaries[i].first_in_db = 0;
        m_boundaries[i].last_in_db = 0;
        m_boundaries[i].total_broker_bars = 0;
        m_boundaries[i].total_db_bars = 0;
        m_boundaries[i].is_synchronized = false;
        m_boundaries[i].last_boundary_check = 0;
    }
}

//+------------------------------------------------------------------+
//| Destructor                                                      |
//+------------------------------------------------------------------+
CBrokerDataBoundaryManager::~CBrokerDataBoundaryManager()
{
    Cleanup();
}

//+------------------------------------------------------------------+
//| Initialize the boundary manager                                 |
//+------------------------------------------------------------------+
bool CBrokerDataBoundaryManager::Initialize(int database_handle)
{
    if(database_handle == INVALID_HANDLE)
    {
        Print("[BOUNDARY] ERROR: Invalid database handle");
        return false;
    }
    
    m_database_handle = database_handle;
    m_last_global_check = TimeCurrent();
    
    Print("[BOUNDARY] Broker Data Boundary Manager initialized");
    return true;
}

//+------------------------------------------------------------------+
//| Cleanup resources                                               |
//+------------------------------------------------------------------+
void CBrokerDataBoundaryManager::Cleanup()
{
    m_boundary_count = 0;
    m_database_handle = INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| Register a symbol/timeframe pair for boundary tracking         |
//+------------------------------------------------------------------+
bool CBrokerDataBoundaryManager::RegisterSymbolTimeframe(const string symbol, ENUM_TIMEFRAMES tf)
{
    // Check if already registered
    int index = FindBoundaryIndex(symbol, tf);
    if(index >= 0)
    {
        Print("[BOUNDARY] Symbol/timeframe already registered: ", symbol, " ", TimeframeToString(tf));
        return true;
    }
    
    // Create new boundary entry
    if(!CreateBoundaryEntry(symbol, tf))
    {
        Print("[BOUNDARY] ERROR: Failed to create boundary entry for ", symbol, " ", TimeframeToString(tf));
        return false;
    }
    
    // Immediately detect boundaries
    if(!UpdateBoundaries(symbol, tf))
    {
        Print("[BOUNDARY] WARNING: Failed to detect initial boundaries for ", symbol, " ", TimeframeToString(tf));
    }
    
    Print("[BOUNDARY] Registered: ", symbol, " ", TimeframeToString(tf));
    return true;
}

//+------------------------------------------------------------------+
//| Update boundaries for specific symbol/timeframe                |
//+------------------------------------------------------------------+
bool CBrokerDataBoundaryManager::UpdateBoundaries(const string symbol, ENUM_TIMEFRAMES tf)
{
    int index = FindBoundaryIndex(symbol, tf);
    if(index < 0)
    {
        Print("[BOUNDARY] ERROR: Symbol/timeframe not registered: ", symbol, " ", TimeframeToString(tf));
        return false;
    }
    
    SBrokerBoundary boundary = m_boundaries[index];
    
    // Detect broker boundaries
    if(!DetectBrokerBoundaries(symbol, tf, boundary))
    {
        Print("[BOUNDARY] ERROR: Failed to detect broker boundaries for ", symbol, " ", TimeframeToString(tf));
        return false;
    }
    
    // Detect database boundaries
    if(!DetectDatabaseBoundaries(symbol, tf, boundary))
    {
        Print("[BOUNDARY] ERROR: Failed to detect database boundaries for ", symbol, " ", TimeframeToString(tf));
        return false;
    }
    
    // Verify completeness
    VerifyCompleteness(boundary);
    
    // Update the boundary record
    boundary.last_boundary_check = TimeCurrent();
    m_boundaries[index] = boundary;
    
    Print("[BOUNDARY] Updated boundaries for ", symbol, " ", TimeframeToString(tf), 
          " | Broker: ", TimeToString(boundary.first_available), " to ", TimeToString(boundary.last_available),
          " | DB: ", TimeToString(boundary.first_in_db), " to ", TimeToString(boundary.last_in_db),
          " | Sync: ", boundary.is_synchronized ? "YES" : "NO");
    
    return true;
}

//+------------------------------------------------------------------+
//| Detect broker data boundaries                                   |
//+------------------------------------------------------------------+
bool CBrokerDataBoundaryManager::DetectBrokerBoundaries(const string symbol, ENUM_TIMEFRAMES tf, SBrokerBoundary &boundary)
{
    // Get first available bar from broker
    boundary.first_available = GetFirstAvailableFromBroker(symbol, tf);
    if(boundary.first_available == 0)
    {
        Print("[BOUNDARY] ERROR: Cannot determine first available bar for ", symbol, " ", TimeframeToString(tf));
        return false;
    }
    
    // Get last available bar from broker (current time)
    boundary.last_available = GetLastAvailableFromBroker(symbol, tf);
    if(boundary.last_available == 0)
    {
        Print("[BOUNDARY] ERROR: Cannot determine last available bar for ", symbol, " ", TimeframeToString(tf));
        return false;
    }
    
    // Count total available bars from broker
    boundary.total_broker_bars = CountAvailableBarsFromBroker(symbol, tf, boundary.first_available, boundary.last_available);
    
    Print("[BOUNDARY] Broker boundaries for ", symbol, " ", TimeframeToString(tf), ": ",
          TimeToString(boundary.first_available), " to ", TimeToString(boundary.last_available),
          " (", boundary.total_broker_bars, " bars)");
    
    return true;
}

//+------------------------------------------------------------------+
//| Detect database boundaries                                      |
//+------------------------------------------------------------------+
bool CBrokerDataBoundaryManager::DetectDatabaseBoundaries(const string symbol, ENUM_TIMEFRAMES tf, SBrokerBoundary &boundary)
{
    // Get database boundaries
    boundary.first_in_db = GetFirstBarInDatabase(symbol, tf);
    boundary.last_in_db = GetLastBarInDatabase(symbol, tf);
    
    // Count bars in database within broker boundaries
    if(boundary.first_available > 0 && boundary.last_available > 0)
    {
        boundary.total_db_bars = CountBarsInDatabase(symbol, tf, boundary.first_available, boundary.last_available);
    }
    else
    {
        boundary.total_db_bars = 0;
    }
    
    Print("[BOUNDARY] Database boundaries for ", symbol, " ", TimeframeToString(tf), ": ",
          TimeToString(boundary.first_in_db), " to ", TimeToString(boundary.last_in_db),
          " (", boundary.total_db_bars, " bars within broker window)");
    
    return true;
}

//+------------------------------------------------------------------+
//| Verify data completeness within boundaries                     |
//+------------------------------------------------------------------+
bool CBrokerDataBoundaryManager::VerifyCompleteness(SBrokerBoundary &boundary)
{
    // Check if we have complete data within broker boundaries
    bool complete_coverage = (boundary.first_in_db <= boundary.first_available && 
                             boundary.last_in_db >= boundary.last_available);
    
    bool bar_count_match = (boundary.total_db_bars >= boundary.total_broker_bars * 0.99); // Allow 1% tolerance
    
    boundary.is_synchronized = (complete_coverage && bar_count_match);
    
    if(!boundary.is_synchronized)
    {
        Print("[BOUNDARY] SYNC ISSUE: ", boundary.symbol, " ", TimeframeToString(boundary.timeframe),
              " | Coverage: ", complete_coverage ? "OK" : "INCOMPLETE",
              " | Bars: ", boundary.total_db_bars, "/", boundary.total_broker_bars,
              " (", DoubleToString((double)boundary.total_db_bars / boundary.total_broker_bars * 100.0, 1), "%)");
    }
    
    return boundary.is_synchronized;
}

//+------------------------------------------------------------------+
//| Get first available bar from broker                            |
//+------------------------------------------------------------------+
datetime CBrokerDataBoundaryManager::GetFirstAvailableFromBroker(const string symbol, ENUM_TIMEFRAMES tf)
{
    // Request maximum historical data to find the earliest available
    MqlRates rates[];
    int bars_copied = CopyRates(symbol, tf, 0, 50000, rates); // Try to get a lot of history
    
    if(bars_copied <= 0)
    {
        Print("[BOUNDARY] ERROR: No historical data available for ", symbol, " ", TimeframeToString(tf));
        return 0;
    }
    
    // The first element should be the earliest available
    datetime first_available = rates[0].time;
    
    Print("[BOUNDARY] First available from broker: ", symbol, " ", TimeframeToString(tf), " = ", TimeToString(first_available));
    return first_available;
}

//+------------------------------------------------------------------+
//| Get last available bar from broker                             |
//+------------------------------------------------------------------+
datetime CBrokerDataBoundaryManager::GetLastAvailableFromBroker(const string symbol, ENUM_TIMEFRAMES tf)
{
    // Get the most recent bar
    MqlRates rates[];
    int bars_copied = CopyRates(symbol, tf, 0, 1, rates);
    
    if(bars_copied <= 0)
    {
        Print("[BOUNDARY] ERROR: No current data available for ", symbol, " ", TimeframeToString(tf));
        return 0;
    }
    
    datetime last_available = rates[0].time;
    
    Print("[BOUNDARY] Last available from broker: ", symbol, " ", TimeframeToString(tf), " = ", TimeToString(last_available));
    return last_available;
}

//+------------------------------------------------------------------+
//| Count available bars from broker                               |
//+------------------------------------------------------------------+
int CBrokerDataBoundaryManager::CountAvailableBarsFromBroker(const string symbol, ENUM_TIMEFRAMES tf, datetime from, datetime to)
{
    if(from >= to) return 0;
    
    // Calculate theoretical bar count based on timeframe
    int timeframe_seconds = PeriodSeconds(tf);
    if(timeframe_seconds <= 0) return 0;
    
    int theoretical_bars = (int)((to - from) / timeframe_seconds);
    
    // Try to get actual data to verify
    MqlRates rates[];
    int actual_bars = CopyRates(symbol, tf, from, to, rates);
    
    // Return the more conservative estimate
    return MathMin(theoretical_bars, actual_bars > 0 ? actual_bars : theoretical_bars);
}

//+------------------------------------------------------------------+
//| Check if completely in sync within boundaries                  |
//+------------------------------------------------------------------+
bool CBrokerDataBoundaryManager::IsCompletelyInSync(const string symbol, ENUM_TIMEFRAMES tf)
{
    int index = FindBoundaryIndex(symbol, tf);
    if(index < 0) return false;
    
    return m_boundaries[index].is_synchronized;
}

//+------------------------------------------------------------------+
//| Get sync percentage                                             |
//+------------------------------------------------------------------+
double CBrokerDataBoundaryManager::GetSyncPercentage(const string symbol, ENUM_TIMEFRAMES tf)
{
    int index = FindBoundaryIndex(symbol, tf);
    if(index < 0) return 0.0;
    
    SBrokerBoundary boundary = m_boundaries[index];
    
    if(boundary.total_broker_bars <= 0) return 0.0;
    
    return (double)boundary.total_db_bars / boundary.total_broker_bars * 100.0;
}

//+------------------------------------------------------------------+
//| Generate boundary report                                        |
//+------------------------------------------------------------------+
string CBrokerDataBoundaryManager::GenerateBoundaryReport(const string symbol, ENUM_TIMEFRAMES tf)
{
    int index = FindBoundaryIndex(symbol, tf);
    if(index < 0) return "Boundary not found";
    
    SBrokerBoundary boundary = m_boundaries[index];
    
    string report = "=== BOUNDARY REPORT ===\n";
    report += StringFormat("Symbol/Timeframe: %s %s\n", symbol, TimeframeToString(tf));
    report += StringFormat("Broker Window: %s to %s\n", TimeToString(boundary.first_available), TimeToString(boundary.last_available));
    report += StringFormat("Database Window: %s to %s\n", TimeToString(boundary.first_in_db), TimeToString(boundary.last_in_db));
    report += StringFormat("Broker Bars: %d\n", boundary.total_broker_bars);
    report += StringFormat("Database Bars: %d\n", boundary.total_db_bars);
    report += StringFormat("Sync Status: %s\n", boundary.is_synchronized ? "COMPLETE" : "INCOMPLETE");
    report += StringFormat("Sync Percentage: %.2f%%\n", GetSyncPercentage(symbol, tf));
    report += StringFormat("Last Check: %s\n", TimeToString(boundary.last_boundary_check));
    
    return report;
}

//+------------------------------------------------------------------+
//| Find boundary index for symbol/timeframe                       |
//+------------------------------------------------------------------+
int CBrokerDataBoundaryManager::FindBoundaryIndex(const string symbol, ENUM_TIMEFRAMES tf)
{
    for(int i = 0; i < m_boundary_count; i++)
    {
        if(m_boundaries[i].symbol == symbol && m_boundaries[i].timeframe == tf)
        {
            return i;
        }
    }
    return -1;
}

//+------------------------------------------------------------------+
//| Create new boundary entry                                       |
//+------------------------------------------------------------------+
bool CBrokerDataBoundaryManager::CreateBoundaryEntry(const string symbol, ENUM_TIMEFRAMES tf)
{
    if(m_boundary_count >= 100)
    {
        Print("[BOUNDARY] ERROR: Maximum boundary entries reached (100)");
        return false;
    }
    
    m_boundaries[m_boundary_count].symbol = symbol;
    m_boundaries[m_boundary_count].timeframe = tf;
    m_boundaries[m_boundary_count].first_available = 0;
    m_boundaries[m_boundary_count].last_available = 0;
    m_boundaries[m_boundary_count].first_in_db = 0;
    m_boundaries[m_boundary_count].last_in_db = 0;
    m_boundaries[m_boundary_count].total_broker_bars = 0;
    m_boundaries[m_boundary_count].total_db_bars = 0;
    m_boundaries[m_boundary_count].is_synchronized = false;
    m_boundaries[m_boundary_count].last_boundary_check = 0;
    
    m_boundary_count++;
    return true;
}

//+------------------------------------------------------------------+
//| Convert timeframe to string                                     |
//+------------------------------------------------------------------+
string CBrokerDataBoundaryManager::TimeframeToString(ENUM_TIMEFRAMES tf)
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
//| Get first bar in database                                       |
//+------------------------------------------------------------------+
datetime CBrokerDataBoundaryManager::GetFirstBarInDatabase(const string symbol, ENUM_TIMEFRAMES tf)
{
    if(m_database_handle == INVALID_HANDLE) return 0;
    
    string query = StringFormat("SELECT MIN(timestamp) FROM market_data WHERE symbol='%s' AND timeframe=%d", 
                                symbol, tf);
    
    int request = DatabasePrepare(m_database_handle, query);
    if(request == INVALID_HANDLE) return 0;
    
    datetime first_time = 0;
    if(DatabaseRead(request))
    {
        first_time = (datetime)DatabaseColumnLong(request, 0);
    }
    
    DatabaseFinalize(request);
    return first_time;
}

//+------------------------------------------------------------------+
//| Get last bar in database                                        |
//+------------------------------------------------------------------+
datetime CBrokerDataBoundaryManager::GetLastBarInDatabase(const string symbol, ENUM_TIMEFRAMES tf)
{
    if(m_database_handle == INVALID_HANDLE) return 0;
    
    string query = StringFormat("SELECT MAX(timestamp) FROM market_data WHERE symbol='%s' AND timeframe=%d", 
                                symbol, tf);
    
    int request = DatabasePrepare(m_database_handle, query);
    if(request == INVALID_HANDLE) return 0;
    
    datetime last_time = 0;
    if(DatabaseRead(request))
    {
        last_time = (datetime)DatabaseColumnLong(request, 0);
    }
    
    DatabaseFinalize(request);
    return last_time;
}

//+------------------------------------------------------------------+
//| Count bars in database within time range                       |
//+------------------------------------------------------------------+
int CBrokerDataBoundaryManager::CountBarsInDatabase(const string symbol, ENUM_TIMEFRAMES tf, datetime from, datetime to)
{
    if(m_database_handle == INVALID_HANDLE) return 0;
    
    string query = StringFormat("SELECT COUNT(*) FROM market_data WHERE symbol='%s' AND timeframe=%d AND timestamp BETWEEN %d AND %d", 
                                symbol, tf, from, to);
    
    int request = DatabasePrepare(m_database_handle, query);
    if(request == INVALID_HANDLE) return 0;
    
    int count = 0;
    if(DatabaseRead(request))
    {
        count = (int)DatabaseColumnLong(request, 0);
    }
    
    DatabaseFinalize(request);
    return count;
}
