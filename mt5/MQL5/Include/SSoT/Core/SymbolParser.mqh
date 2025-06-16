//+------------------------------------------------------------------+
//| SymbolParser.mqh - Symbol and Timeframe Parsing Library        |
//| Extracted from SSoT_Lean for cleaner architecture               |
//+------------------------------------------------------------------+
#ifndef SSOT_SYMBOL_PARSER_MQH
#define SSOT_SYMBOL_PARSER_MQH

//+------------------------------------------------------------------+
//| Symbol Parser Class                                              |
//+------------------------------------------------------------------+
class CSymbolParser
{
private:
    string          m_symbols[];
    ENUM_TIMEFRAMES m_timeframes[];
    
public:
    CSymbolParser();
    ~CSymbolParser();
    
    // Parsing functions
    bool            ParseSymbols(const string symbol_list);
    bool            ParseTimeframes(const string timeframe_list);
    bool            ParseInputParameters(const string symbol_list, const string timeframe_list);
    
    // Accessors
    int             GetSymbolsCount() { return ArraySize(m_symbols); }
    int             GetTimeframesCount() { return ArraySize(m_timeframes); }
    string          GetSymbol(int index);
    ENUM_TIMEFRAMES GetTimeframe(int index);
    
    // Copy arrays (for external access)
    void            CopySymbols(string &symbols[]);
    void            CopyTimeframes(ENUM_TIMEFRAMES &timeframes[]);
    
    // Utility functions
    static ENUM_TIMEFRAMES StringToTimeframe(const string tf_str);
    static string   TimeframeToString(ENUM_TIMEFRAMES timeframe);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSymbolParser::CSymbolParser()
{
    ArrayResize(m_symbols, 0);
    ArrayResize(m_timeframes, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSymbolParser::~CSymbolParser()
{
    ArrayFree(m_symbols);
    ArrayFree(m_timeframes);
}

//+------------------------------------------------------------------+
//| Parse symbols from comma-separated string                        |
//+------------------------------------------------------------------+
bool CSymbolParser::ParseSymbols(const string symbol_list)
{
    string symbol_array[];
    int symbols_count = StringSplit(symbol_list, ',', symbol_array);
    if(symbols_count <= 0) {
        Print("❌ SymbolParser: No symbols found in list: ", symbol_list);
        return false;
    }
    
    ArrayResize(m_symbols, symbols_count);
    for(int i = 0; i < symbols_count; i++) {
        StringTrimLeft(symbol_array[i]);
        StringTrimRight(symbol_array[i]);
        m_symbols[i] = symbol_array[i];
    }
    
    Print("✅ SymbolParser: Parsed ", symbols_count, " symbols");
    return true;
}

//+------------------------------------------------------------------+
//| Parse timeframes from comma-separated string                     |
//+------------------------------------------------------------------+
bool CSymbolParser::ParseTimeframes(const string timeframe_list)
{
    string tf_array[];
    int tf_count = StringSplit(timeframe_list, ',', tf_array);
    if(tf_count <= 0) {
        Print("❌ SymbolParser: No timeframes found in list: ", timeframe_list);
        return false;
    }
    
    ArrayResize(m_timeframes, tf_count);
    for(int i = 0; i < tf_count; i++) {
        StringTrimLeft(tf_array[i]);
        StringTrimRight(tf_array[i]);
        m_timeframes[i] = StringToTimeframe(tf_array[i]);
        
        if(m_timeframes[i] == PERIOD_CURRENT) {
            Print("⚠️ SymbolParser: Unknown timeframe: ", tf_array[i]);
        }
    }
    
    Print("✅ SymbolParser: Parsed ", tf_count, " timeframes");
    return true;
}

//+------------------------------------------------------------------+
//| Parse both symbols and timeframes                                |
//+------------------------------------------------------------------+
bool CSymbolParser::ParseInputParameters(const string symbol_list, const string timeframe_list)
{
    if(!ParseSymbols(symbol_list)) {
        return false;
    }
    
    if(!ParseTimeframes(timeframe_list)) {
        return false;
    }
    
    Print("✅ SymbolParser: Configuration parsed successfully");
    Print(StringFormat("📊 Monitoring: %d symbols, %d timeframes", 
          ArraySize(m_symbols), ArraySize(m_timeframes)));
    
    return true;
}

//+------------------------------------------------------------------+
//| Get symbol by index                                              |
//+------------------------------------------------------------------+
string CSymbolParser::GetSymbol(int index)
{
    if(index >= 0 && index < ArraySize(m_symbols)) {
        return m_symbols[index];
    }
    return "";
}

//+------------------------------------------------------------------+
//| Get timeframe by index                                           |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES CSymbolParser::GetTimeframe(int index)
{
    if(index >= 0 && index < ArraySize(m_timeframes)) {
        return m_timeframes[index];
    }
    return PERIOD_CURRENT;
}

//+------------------------------------------------------------------+
//| Copy symbols array for external access                           |
//+------------------------------------------------------------------+
void CSymbolParser::CopySymbols(string &symbols[])
{
    int count = ArraySize(m_symbols);
    ArrayResize(symbols, count);
    for(int i = 0; i < count; i++) {
        symbols[i] = m_symbols[i];
    }
}

//+------------------------------------------------------------------+
//| Copy timeframes array for external access                        |
//+------------------------------------------------------------------+
void CSymbolParser::CopyTimeframes(ENUM_TIMEFRAMES &timeframes[])
{
    int count = ArraySize(m_timeframes);
    ArrayResize(timeframes, count);
    for(int i = 0; i < count; i++) {
        timeframes[i] = m_timeframes[i];
    }
}

//+------------------------------------------------------------------+
//| Convert string to timeframe enum                                 |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES CSymbolParser::StringToTimeframe(const string tf_str)
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
    
    Print("⚠️ SymbolParser: Unknown timeframe string: ", tf_str);
    return PERIOD_CURRENT;
}

//+------------------------------------------------------------------+
//| Convert timeframe enum to string                                 |
//+------------------------------------------------------------------+
string CSymbolParser::TimeframeToString(ENUM_TIMEFRAMES timeframe)
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
        default:         return "UNKNOWN";
    }
}

#endif // SSOT_SYMBOL_PARSER_MQH
