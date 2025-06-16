//+------------------------------------------------------------------+
//| HashUtils.mqh - Hash Calculation Utilities                      |
//| Contains FNV-1a hash calculation function extracted from         |
//| SSoT_EA.mq5 for Phase 1 Code Modularization                     |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.0.0"

//+------------------------------------------------------------------+
//| Calculate FNV-1a hash for data integrity (Task 6)               |
//| Extracted from SSoT_EA.mq5 - CalculateHash function             |
//+------------------------------------------------------------------+
string CalculateHash(double open, double high, double low, double close, long volume, long timestamp)
{
    string concat = StringFormat("%.5f%.5f%.5f%.5f%I64d%I64d", open, high, low, close, volume, timestamp);
    
    uint hash = 2166136261;
    int len = StringLen(concat);
    for(int i = 0; i < len; i++)
    {
        hash ^= StringGetCharacter(concat, i);
        hash *= 16777619;
    }
    
    return StringFormat("%u", hash);
}

//+------------------------------------------------------------------+
//| Hash validation helper functions                                 |
//+------------------------------------------------------------------+
bool ValidateHashFormat(string hash)
{
    if(StringLen(hash) == 0)
        return false;
    
    // Check if hash is a valid numeric string
    for(int i = 0; i < StringLen(hash); i++)
    {
        ushort ch = StringGetCharacter(hash, i);
        if(ch < '0' || ch > '9')
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Compare two hashes for validation                                |
//+------------------------------------------------------------------+
bool CompareHashes(string hash1, string hash2)
{
    return (hash1 == hash2);
}

//+------------------------------------------------------------------+
//| O-1: Enhanced hash calculation ignoring real_volume              |
//| This reduces false mismatches when real_volume differs but       |
//| OHLC and timestamp remain unchanged                              |
//+------------------------------------------------------------------+
string CalculateHashOptimized(double open, double high, double low, double close, long tick_volume, long timestamp)
{
    // O-1 Enhancement: Only use tick_volume, ignore real_volume for consistency
    string concat = StringFormat("%.5f%.5f%.5f%.5f%I64d%I64d", open, high, low, close, tick_volume, timestamp);
    
    uint hash = 2166136261;
    int len = StringLen(concat);
    for(int i = 0; i < len; i++)
    {
        hash ^= StringGetCharacter(concat, i);
        hash *= 16777619;
    }
    
    return StringFormat("%u", hash);
}

//+------------------------------------------------------------------+
//| Generate optimized hash for MqlRates structure (O-1)            |
//+------------------------------------------------------------------+
string CalculateHashFromRatesOptimized(const MqlRates &rates)
{
    // Use tick_volume instead of real_volume for better consistency
    return CalculateHashOptimized(rates.open, rates.high, rates.low, rates.close, rates.tick_volume, rates.time);
}

//+------------------------------------------------------------------+
//| Generate hash for MqlRates structure                             |
//+------------------------------------------------------------------+
string CalculateHashFromRates(const MqlRates &rates)
{
    return CalculateHash(rates.open, rates.high, rates.low, rates.close, rates.tick_volume, rates.time);
}
