//+------------------------------------------------------------------+
//| SymbolParser.mqh                                                |
//| Handles symbol and timeframe parsing for SSoT system            |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Symbol Parser Class                                              |
//+------------------------------------------------------------------+
class CSymbolParser
{
private:
    string          m_symbols[];
    ENUM_TIMEFRAMES m_timeframes[];
    
public:
    // Constructor
    CSymbolParser() {}
    
    // Main parsing functions
    bool ParseInputParameters(string symbols_str, string timeframes_str);
    
    // Getters
    void GetSymbols(string &symbols[]) { ArrayCopy(symbols, m_symbols); }
    void GetTimeframes(ENUM_TIMEFRAMES &timeframes[]) { ArrayCopy(timeframes, m_timeframes); }
    int GetSymbolsCount() const { return ArraySize(m_symbols); }
    int GetTimeframesCount() const { return ArraySize(m_timeframes); }
    string GetSymbol(int index) const { return (index >= 0 && index < ArraySize(m_symbols)) ? m_symbols[index] : ""; }
    ENUM_TIMEFRAMES GetTimeframe(int index) const { return (index >= 0 && index < ArraySize(m_timeframes)) ? m_timeframes[index] : PERIOD_CURRENT; }
    
    // Utility functions
    static ENUM_TIMEFRAMES StringToTimeframe(string tf_str);
    static string TimeframeToString(ENUM_TIMEFRAMES tf);
};

//+------------------------------------------------------------------+
//| Parse input parameters into arrays                               |
//+------------------------------------------------------------------+
bool CSymbolParser::ParseInputParameters(string symbols_str, string timeframes_str)
{
    // Parse symbols
    string symbol_array[];
    int symbols_count = StringSplit(symbols_str, ',', symbol_array);
    if(symbols_count <= 0) {
        Print("❌ No symbols found in input string: ", symbols_str);
        return false;
    }
    
    ArrayResize(m_symbols, symbols_count);
    for(int i = 0; i < symbols_count; i++) {
        StringTrimLeft(symbol_array[i]);
        StringTrimRight(symbol_array[i]);
        m_symbols[i] = symbol_array[i];
        Print("📊 Parsed symbol: ", m_symbols[i]);
    }
    
    // Parse timeframes
    string tf_array[];
    int tf_count = StringSplit(timeframes_str, ',', tf_array);
    if(tf_count <= 0) {
        Print("❌ No timeframes found in input string: ", timeframes_str);
        return false;
    }
    
    ArrayResize(m_timeframes, tf_count);
    for(int i = 0; i < tf_count; i++) {
        StringTrimLeft(tf_array[i]);
        StringTrimRight(tf_array[i]);
        m_timeframes[i] = StringToTimeframe(tf_array[i]);
        Print("⏰ Parsed timeframe: ", tf_array[i], " -> ", EnumToString(m_timeframes[i]));
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Convert string to timeframe enum                                 |
//+------------------------------------------------------------------+
static ENUM_TIMEFRAMES CSymbolParser::StringToTimeframe(string tf_str)
{
    if(tf_str == "M1")  return PERIOD_M1;
    if(tf_str == "M5")  return PERIOD_M5;
    if(tf_str == "M15") return PERIOD_M15;
    if(tf_str == "M30") return PERIOD_M30;
    if(tf_str == "H1")  return PERIOD_H1;
    if(tf_str == "H4")  return PERIOD_H4;
    if(tf_str == "D1")  return PERIOD_D1;
    if(tf_str == "W1")  return PERIOD_W1;
    if(tf_str == "MN1") return PERIOD_MN1;
    
    Print("⚠️ Unknown timeframe string: ", tf_str, " - using PERIOD_CURRENT");
    return PERIOD_CURRENT;
}

//+------------------------------------------------------------------+
//| Convert timeframe enum to string                                 |
//+------------------------------------------------------------------+
static string CSymbolParser::TimeframeToString(ENUM_TIMEFRAMES tf)
{
    switch(tf) {
        case PERIOD_M1:  return "M1";
        case PERIOD_M5:  return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1:  return "H1";
        case PERIOD_H4:  return "H4";
        case PERIOD_D1:  return "D1";
        case PERIOD_W1:  return "W1";
        case PERIOD_MN1: return "MN1";
        default:         return "CURRENT";
    }
}
