//+------------------------------------------------------------------+
//| NewBarDetector.mqh - Optimized New Bar Detection System         |
//| Handles new bar detection for multiple symbols and timeframes   |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"
#property strict

#include <SSoT/Core/ChainOfTrust.mqh>

//+------------------------------------------------------------------+
//| New Bar Detection Class                                         |
//| Optimized for minimal logging and high performance             |
//+------------------------------------------------------------------+
class CNewBarDetector
{
private:
    string            m_symbols[];
    ENUM_TIMEFRAMES   m_timeframes[];
    datetime          m_last_bar_times[];
    int               m_new_bar_count;
    
public:
    //--- Constructor/Destructor
    CNewBarDetector();
    ~CNewBarDetector();
    
    //--- Initialization
    bool              Initialize(const string &symbols[], const ENUM_TIMEFRAMES &timeframes[]);
    void              Reset();
    
    //--- Detection
    bool              CheckForNewBars();
    int               GetNewBarCount() const { return m_new_bar_count; }
    
private:
    //--- Internal helpers
    int               GetArrayIndex(int symbol_index, int timeframe_index);
    void              UpdateLastBarTime(int symbol_index, int timeframe_index, datetime bar_time);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CNewBarDetector::CNewBarDetector()
{
    m_new_bar_count = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                      |
//+------------------------------------------------------------------+
CNewBarDetector::~CNewBarDetector()
{
    // Nothing to clean up
}

//+------------------------------------------------------------------+
//| Initialize new bar detector                                     |
//+------------------------------------------------------------------+
bool CNewBarDetector::Initialize(const string &symbols[], const ENUM_TIMEFRAMES &timeframes[])
{
    // Copy symbols and timeframes
    ArrayResize(m_symbols, ArraySize(symbols));
    ArrayResize(m_timeframes, ArraySize(timeframes));
    ArrayCopy(m_symbols, symbols);
    ArrayCopy(m_timeframes, timeframes);
    
    // Initialize last bar times array
    int total_combinations = ArraySize(m_symbols) * ArraySize(m_timeframes);
    ArrayResize(m_last_bar_times, total_combinations);
    ArrayInitialize(m_last_bar_times, 0);
    
    Print("📊 NewBarDetector: Initialized for ", total_combinations, " symbol/timeframe combinations");
    return true;
}

//+------------------------------------------------------------------+
//| Reset detection state                                           |
//+------------------------------------------------------------------+
void CNewBarDetector::Reset()
{
    ArrayInitialize(m_last_bar_times, 0);
    m_new_bar_count = 0;
}

//+------------------------------------------------------------------+
//| Check for new bars across all symbols and timeframes           |
//+------------------------------------------------------------------+
bool CNewBarDetector::CheckForNewBars()
{
    bool new_bar_detected = false;
    
    // Optimization: Cache array sizes to avoid repeated function calls
    int symbols_count = ArraySize(m_symbols);
    int timeframes_count = ArraySize(m_timeframes);
    
    for(int i = 0; i < symbols_count; i++) {
        for(int j = 0; j < timeframes_count; j++) {
            string symbol = m_symbols[i];
            ENUM_TIMEFRAMES tf = m_timeframes[j];
            
            // Get current bar time
            datetime current_bar_time = iTime(symbol, tf, 0);
            
            // Skip if invalid time
            if(current_bar_time <= 0) continue;
            
            // Get array index for this combination
            int array_index = GetArrayIndex(i, j);
            
            // Check if this is a new bar
            if(m_last_bar_times[array_index] > 0 && current_bar_time != m_last_bar_times[array_index]) {
                m_new_bar_count++;
                Print("📊 New bar (#", m_new_bar_count, "): ", symbol, " ", CChainOfTrust::TimeframeToString(tf), " at ", TimeToString(current_bar_time));
                new_bar_detected = true;
            }
            
            // Update last bar time
            m_last_bar_times[array_index] = current_bar_time;
        }
    }
    
    return new_bar_detected;
}

//+------------------------------------------------------------------+
//| Get array index for symbol/timeframe combination               |
//+------------------------------------------------------------------+
int CNewBarDetector::GetArrayIndex(int symbol_index, int timeframe_index)
{
    return symbol_index * ArraySize(m_timeframes) + timeframe_index;
}

//+------------------------------------------------------------------+
//| Update last bar time for specific symbol/timeframe             |
//+------------------------------------------------------------------+
void CNewBarDetector::UpdateLastBarTime(int symbol_index, int timeframe_index, datetime bar_time)
{
    int array_index = GetArrayIndex(symbol_index, timeframe_index);
    if(array_index >= 0 && array_index < ArraySize(m_last_bar_times)) {
        m_last_bar_times[array_index] = bar_time;
    }
}
