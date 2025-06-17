//+------------------------------------------------------------------+
//|                                                   CandleCount.mq5 |
//|      Logs how many bars are available for given symbols          |
//+------------------------------------------------------------------+
#property script_show_inputs

input string SymbolsList = "EURUSD,GBPUSD,USDJPY";
input int UseTimeframe = PERIOD_H1;  // Timeframe input

void OnStart()
{
    string symbols[];
    int symbolCount = StringSplit(SymbolsList, ',', symbols);

    for (int i = 0; i < symbolCount; i++)
    {
        string rawSymbol = symbols[i];
        StringTrimLeft(rawSymbol);
        StringTrimRight(rawSymbol);
        string symbol = rawSymbol;

        if (!SymbolSelect(symbol, true))
        {
            Print("Failed to select symbol: ", symbol);
            continue;
        }

        datetime times[];
        int bars = CopyTime(symbol, (ENUM_TIMEFRAMES)UseTimeframe, 0, WHOLE_ARRAY, times);

        if (bars > 0)
        {
            PrintFormat("Symbol: %s | Timeframe: %s | Bars Available: %d",
                        symbol, EnumToString((ENUM_TIMEFRAMES)UseTimeframe), bars);
        }
        else
        {
            PrintFormat("Failed to retrieve bars for %s %s. Error: %d",
                        symbol, EnumToString((ENUM_TIMEFRAMES)UseTimeframe), GetLastError());
        }
    }
}
