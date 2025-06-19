//+------------------------------------------------------------------+
//| SymbolParser.mqh - Configuration String Parsing Utilities       |
//| Handles parsing of symbol lists, timeframes, and configurations |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Symbol Parser Utility Class                                     |
//| Static methods for parsing configuration strings                |
//+------------------------------------------------------------------+
class CSymbolParser
{
public:
    //--- Symbol parsing
    static bool       ParseSymbols(const string symbols_config, string &symbols_array[]);
    static bool       ValidateSymbol(const string symbol);
    static string     CleanSymbolString(const string symbol);
    
    //--- Timeframe parsing
    static bool       ParseTimeframes(const string timeframes_config, ENUM_TIMEFRAMES &timeframes_array[]);
    static ENUM_TIMEFRAMES StringToTimeframe(const string tf_string);
    static string     TimeframeToString(const ENUM_TIMEFRAMES timeframe);
    static bool       ValidateTimeframe(const ENUM_TIMEFRAMES timeframe);
    
    //--- General parsing utilities
    static int        SplitString(const string str_input, const string delimiter, string &result[]);
    static string     TrimString(const string str_input);
    static bool       IsValidSymbolChar(const ushort char_code);
    
    //--- Configuration validation
    static bool       ValidateSymbolConfig(const string symbols_config);
    static bool       ValidateTimeframeConfig(const string timeframes_config);
};

//+------------------------------------------------------------------+
//| Parse symbols configuration string                               |
//+------------------------------------------------------------------+
static bool CSymbolParser::ParseSymbols(const string symbols_config, string &symbols_array[])
{
    if(StringLen(symbols_config) == 0) {
        Print("❌ ERROR: Empty symbols configuration");
        return false;
    }
    
    // Split by comma
    string temp_symbols[];
    int count = SplitString(symbols_config, ",", temp_symbols);
    
    if(count <= 0) {
        Print("❌ ERROR: Failed to parse symbols configuration: ", symbols_config);
        return false;
    }
    
    // Clean and validate each symbol
    string valid_symbols[];
    int valid_count = 0;
    
    for(int i = 0; i < count; i++) {
        string clean_symbol = CleanSymbolString(temp_symbols[i]);
        
        if(ValidateSymbol(clean_symbol)) {
            ArrayResize(valid_symbols, valid_count + 1);
            valid_symbols[valid_count] = clean_symbol;
            valid_count++;
        } else {
            Print("⚠️ WARNING: Invalid symbol skipped: '", temp_symbols[i], "'");
        }
    }
    
    if(valid_count == 0) {
        Print("❌ ERROR: No valid symbols found in configuration");
        return false;
    }
    
    // Copy valid symbols to output array
    ArrayResize(symbols_array, valid_count);
    ArrayCopy(symbols_array, valid_symbols);
    
    Print("✅ Parsed ", valid_count, " valid symbols from configuration");
    return true;
}

//+------------------------------------------------------------------+
//| Parse timeframes configuration string                            |
//+------------------------------------------------------------------+
static bool CSymbolParser::ParseTimeframes(const string timeframes_config, ENUM_TIMEFRAMES &timeframes_array[])
{
    if(StringLen(timeframes_config) == 0) {
        Print("❌ ERROR: Empty timeframes configuration");
        return false;
    }
    
    // Split by comma
    string temp_timeframes[];
    int count = SplitString(timeframes_config, ",", temp_timeframes);
    
    if(count <= 0) {
        Print("❌ ERROR: Failed to parse timeframes configuration: ", timeframes_config);
        return false;
    }
    
    // Parse and validate each timeframe
    ENUM_TIMEFRAMES valid_timeframes[];
    int valid_count = 0;
    
    for(int i = 0; i < count; i++) {
        string clean_tf = TrimString(temp_timeframes[i]);
        ENUM_TIMEFRAMES tf = StringToTimeframe(clean_tf);
        
        if(ValidateTimeframe(tf)) {
            ArrayResize(valid_timeframes, valid_count + 1);
            valid_timeframes[valid_count] = tf;
            valid_count++;
        } else {
            Print("⚠️ WARNING: Invalid timeframe skipped: '", temp_timeframes[i], "'");
        }
    }
    
    if(valid_count == 0) {
        Print("❌ ERROR: No valid timeframes found in configuration");
        return false;
    }
    
    // Copy valid timeframes to output array
    ArrayResize(timeframes_array, valid_count);
    ArrayCopy(timeframes_array, valid_timeframes);
    
    Print("✅ Parsed ", valid_count, " valid timeframes from configuration");
    return true;
}

//+------------------------------------------------------------------+
//| Convert string to timeframe enum                                |
//+------------------------------------------------------------------+
static ENUM_TIMEFRAMES CSymbolParser::StringToTimeframe(const string tf_string)
{
    string clean_tf = TrimString(tf_string);
    StringToUpper(clean_tf);
    
    if(clean_tf == "M1") return PERIOD_M1;
    if(clean_tf == "M2") return PERIOD_M2;
    if(clean_tf == "M3") return PERIOD_M3;
    if(clean_tf == "M4") return PERIOD_M4;
    if(clean_tf == "M5") return PERIOD_M5;
    if(clean_tf == "M6") return PERIOD_M6;
    if(clean_tf == "M10") return PERIOD_M10;
    if(clean_tf == "M12") return PERIOD_M12;
    if(clean_tf == "M15") return PERIOD_M15;
    if(clean_tf == "M20") return PERIOD_M20;
    if(clean_tf == "M30") return PERIOD_M30;
    if(clean_tf == "H1") return PERIOD_H1;
    if(clean_tf == "H2") return PERIOD_H2;
    if(clean_tf == "H3") return PERIOD_H3;
    if(clean_tf == "H4") return PERIOD_H4;
    if(clean_tf == "H6") return PERIOD_H6;
    if(clean_tf == "H8") return PERIOD_H8;
    if(clean_tf == "H12") return PERIOD_H12;
    if(clean_tf == "D1") return PERIOD_D1;
    if(clean_tf == "W1") return PERIOD_W1;
    if(clean_tf == "MN1") return PERIOD_MN1;
    
    return PERIOD_CURRENT; // Invalid timeframe marker
}

//--- Additional implementation methods
static string CSymbolParser::TimeframeToString(const ENUM_TIMEFRAMES timeframe)
{
    switch(timeframe) {
        case PERIOD_M1: return "M1";
        case PERIOD_M2: return "M2";
        case PERIOD_M3: return "M3";
        case PERIOD_M4: return "M4";
        case PERIOD_M5: return "M5";
        case PERIOD_M6: return "M6";
        case PERIOD_M10: return "M10";
        case PERIOD_M12: return "M12";
        case PERIOD_M15: return "M15";
        case PERIOD_M20: return "M20";
        case PERIOD_M30: return "M30";
        case PERIOD_H1: return "H1";
        case PERIOD_H2: return "H2";
        case PERIOD_H3: return "H3";
        case PERIOD_H4: return "H4";
        case PERIOD_H6: return "H6";
        case PERIOD_H8: return "H8";
        case PERIOD_H12: return "H12";
        case PERIOD_D1: return "D1";
        case PERIOD_W1: return "W1";
        case PERIOD_MN1: return "MN1";
        default: return "INVALID";
    }
}

static bool CSymbolParser::ValidateSymbol(const string symbol)
{
    if(StringLen(symbol) < 3 || StringLen(symbol) > 12) {
        return false;
    }
    
    // Check for valid characters (alphanumeric, some special chars)
    for(int i = 0; i < StringLen(symbol); i++) {
        ushort char_code = StringGetCharacter(symbol, i);
        if(!IsValidSymbolChar(char_code)) {
            return false;
        }
    }
    
    return true;
}

static bool CSymbolParser::ValidateTimeframe(const ENUM_TIMEFRAMES timeframe)
{
    return (timeframe != PERIOD_CURRENT && timeframe != 0);
}

static string CSymbolParser::CleanSymbolString(const string symbol)
{
    string clean = TrimString(symbol);
    StringToUpper(clean);
    return clean;
}

static int CSymbolParser::SplitString(const string str_input, const string delimiter, string &result[])
{
    ArrayFree(result);
    
    if(StringLen(str_input) == 0) return 0;
    
    string temp = str_input;
    int count = 0;
    int pos = 0;
    
    while(true) {
        pos = StringFind(temp, delimiter);
        
        if(pos == -1) {
            // Last part
            if(StringLen(temp) > 0) {
                ArrayResize(result, count + 1);
                result[count] = temp;
                count++;
            }
            break;
        }
        
        // Extract part
        string part = StringSubstr(temp, 0, pos);
        if(StringLen(part) > 0) {
            ArrayResize(result, count + 1);
            result[count] = part;
            count++;
        }
        
        // Continue with remainder
        temp = StringSubstr(temp, pos + StringLen(delimiter));
    }
    
    return count;
}

static string CSymbolParser::TrimString(const string str_input)
{
    if(StringLen(str_input) == 0) return "";
    
    string result = str_input;
    
    // Trim left
    while(StringLen(result) > 0 && (StringGetCharacter(result, 0) == ' ' || 
                                   StringGetCharacter(result, 0) == '\t' ||
                                   StringGetCharacter(result, 0) == '\n' ||
                                   StringGetCharacter(result, 0) == '\r')) {
        result = StringSubstr(result, 1);
    }
    
    // Trim right
    while(StringLen(result) > 0 && (StringGetCharacter(result, StringLen(result) - 1) == ' ' || 
                                   StringGetCharacter(result, StringLen(result) - 1) == '\t' ||
                                   StringGetCharacter(result, StringLen(result) - 1) == '\n' ||
                                   StringGetCharacter(result, StringLen(result) - 1) == '\r')) {
        result = StringSubstr(result, 0, StringLen(result) - 1);
    }
    
    return result;
}

static bool CSymbolParser::IsValidSymbolChar(const ushort char_code)
{
    // A-Z, 0-9, and some special characters
    return ((char_code >= 'A' && char_code <= 'Z') ||
            (char_code >= '0' && char_code <= '9') ||
            char_code == '.' || char_code == '_' || char_code == '#');
}

static bool CSymbolParser::ValidateSymbolConfig(const string symbols_config)
{
    string symbols[];
    return ParseSymbols(symbols_config, symbols);
}

static bool CSymbolParser::ValidateTimeframeConfig(const string timeframes_config)
{
    ENUM_TIMEFRAMES timeframes[];
    return ParseTimeframes(timeframes_config, timeframes);
}
