//+------------------------------------------------------------------+
//| DatabaseOperations.mqh - Database Info and Data Retrieval      |
//| Handles all database queries and data formatting                |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Database Operations Helper Class                                |
//+------------------------------------------------------------------+
class CDatabaseOperations
{
public:
    //--- Constructor
    CDatabaseOperations(void) {}
    ~CDatabaseOperations(void) {}
    
    //--- Core Database Info Methods
    string GetDatabaseInfo(int db_handle, string db_name);
    string GetCandleDataInfo(int db_handle, string db_name);
    string GetDetailedBreakdown(int db_handle, string db_name);
    string GetComprehensiveBreakdown(int db_handle, string db_name);
    
    //--- Display Methods
    void DisplayDBInfo(int db_handle, string db_name);
    void DisplayAllCandleData(int db_handle, string db_name);
    void DisplayAssetData(int db_handle, string table_name, string symbol);
    
    //--- Utility Methods
    string TimeframeToString(int timeframe);
    
private:
    //--- Helper methods
    string FindActiveTable(int db_handle);
    void GetUniqueAssets(int db_handle, string table_name, string &assets[]);
    int CountTotalEntries(int db_handle, string table_name);
};

//+------------------------------------------------------------------+
//| Get database server information                                  |
//+------------------------------------------------------------------+
string CDatabaseOperations::GetDatabaseInfo(int db_handle, string db_name)
{
    string info = "";
    
    if(db_handle == INVALID_HANDLE) {
        return "Database not available: " + db_name;
    }
    
    info += "Server: SQLite Local Database\n";
    info += "Filename: " + db_name + "\n";
    
    // Timezone information
    MqlDateTime dt;
    TimeCurrent(dt);
    int gmt_offset = (int)((TimeCurrent() - TimeGMT()) / 3600);
    string local_timezone = StringFormat("GMT%s%d", (gmt_offset >= 0 ? "+" : ""), gmt_offset);
    info += "Timezone: " + local_timezone + "\n";
    info += "Local Time: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\n";
    
    // Read DBInfo as key-value pairs
    string broker_name = "", db_timezone_val = "", schema_version = "", database_type = "", database_version = "", created_at = "", setup_by = "";
    int dbinfo_request = DatabasePrepare(db_handle, "SELECT key, value FROM DBInfo");
    if(dbinfo_request != INVALID_HANDLE) {
        while(DatabaseRead(dbinfo_request)) {
            string key = "", value = "";
            DatabaseColumnText(dbinfo_request, 0, key);
            DatabaseColumnText(dbinfo_request, 1, value);
            if(key == "broker_name") broker_name = value;
            else if(key == "timezone") db_timezone_val = value;
            else if(key == "schema_version") schema_version = value;
            else if(key == "database_type") database_type = value;
            else if(key == "database_version") database_version = value;
            else if(key == "created_at") created_at = value;
            else if(key == "setup_by") setup_by = value;
        }
        DatabaseFinalize(dbinfo_request);
    }
    
    info += "Source: " + db_name + "\n";
    info += "Broker: " + (broker_name != "" ? broker_name : "MISSING") + "\n";
    info += "Timezone: UTC\n";
    info += "Schema: " + (schema_version != "" ? schema_version : (database_version != "" ? database_version : "MISSING"));
    
    return info;
}

//+------------------------------------------------------------------+
//| Get candle data information                                      |
//+------------------------------------------------------------------+
string CDatabaseOperations::GetCandleDataInfo(int db_handle, string db_name)
{
    string info = "";
    
    if(db_handle == INVALID_HANDLE) {
        return "Database not available for candle data";
    }
    
    // Find the appropriate table name
    string active_table = FindActiveTable(db_handle);
    
    if(active_table == "") {
        return "No candle data tables found";
    }
    
    info += "Table: " + active_table + "\n";
    
    // Get unique assets count
    string assets[];
    GetUniqueAssets(db_handle, active_table, assets);
    info += "Assets in DB: " + IntegerToString(ArraySize(assets)) + "\n";
    
    // Get unique timeframes
    string tf_query = StringFormat("SELECT DISTINCT timeframe FROM %s ORDER BY timeframe", active_table);
    int request = DatabasePrepare(db_handle, tf_query);
    
    if(request != INVALID_HANDLE) {
        string timeframes_str = "";
        while(DatabaseRead(request)) {
            long tf = 0;
            DatabaseColumnLong(request, 0, tf);
            if(timeframes_str != "") timeframes_str += ", ";
            timeframes_str += TimeframeToString((int)tf);
        }
        DatabaseFinalize(request);
        info += "Timeframes: " + timeframes_str + "\n";
    }
    
    // Get total entries
    int total_entries = CountTotalEntries(db_handle, active_table);
    info += "Total Entries: " + IntegerToString(total_entries);
    
    return info;
}

//+------------------------------------------------------------------+
//| Find active candle data table                                   |
//+------------------------------------------------------------------+
string CDatabaseOperations::FindActiveTable(int db_handle)
{
    string table_names[] = {"AllCandleData", "candle_data", "ohlctv_data", "enhanced_data"};
    
    for(int i = 0; i < ArraySize(table_names); i++) {
        string check_query = StringFormat("SELECT name FROM sqlite_master WHERE type='table' AND name='%s'", table_names[i]);
        int request = DatabasePrepare(db_handle, check_query);
        
        if(request != INVALID_HANDLE) {
            if(DatabaseRead(request)) {
                DatabaseFinalize(request);
                return table_names[i];
            }
            DatabaseFinalize(request);
        }
    }
    
    return "";
}

//+------------------------------------------------------------------+
//| Get unique assets from table                                    |
//+------------------------------------------------------------------+
void CDatabaseOperations::GetUniqueAssets(int db_handle, string table_name, string &assets[])
{
    ArrayResize(assets, 0);
    
    // Try different column names
    string column_name = (table_name == "AllCandleData") ? "asset_symbol" : "symbol";
    string assets_query = StringFormat("SELECT DISTINCT %s FROM %s ORDER BY %s", column_name, table_name, column_name);
    int request = DatabasePrepare(db_handle, assets_query);
    
    if(request == INVALID_HANDLE) {
        return;
    }
    
    while(DatabaseRead(request)) {
        string symbol;
        DatabaseColumnText(request, 0, symbol);
        int size = ArraySize(assets);
        ArrayResize(assets, size + 1);
        assets[size] = symbol;
    }
    DatabaseFinalize(request);
}

//+------------------------------------------------------------------+
//| Count total entries in table                                    |
//+------------------------------------------------------------------+
int CDatabaseOperations::CountTotalEntries(int db_handle, string table_name)
{
    string total_query = StringFormat("SELECT COUNT(*) FROM %s", table_name);
    int request = DatabasePrepare(db_handle, total_query);
    if(request != INVALID_HANDLE) {
        if(DatabaseRead(request)) {
            long total_entries = 0;
            DatabaseColumnLong(request, 0, total_entries);
            DatabaseFinalize(request);
            return (int)total_entries;
        }
        DatabaseFinalize(request);
    }
    return 0;
}

//+------------------------------------------------------------------+
//| Display database info to console                                |
//+------------------------------------------------------------------+
void CDatabaseOperations::DisplayDBInfo(int db_handle, string db_name)
{
    if(db_handle == INVALID_HANDLE) {
        Print("[DATA]   ERROR: Database not available: " + db_name);
        return;
    }
    
    Print("[DATA]   DBInfo:");
    Print("[DATA]      Server: SQLite Local Database");
    Print("[DATA]      Filename: " + db_name);
    
    // Timezone information
    MqlDateTime dt;
    TimeCurrent(dt);
    int gmt_offset = (int)((TimeCurrent() - TimeGMT()) / 3600);
    string local_timezone = StringFormat("GMT%s%d", (gmt_offset >= 0 ? "+" : ""), gmt_offset);
    Print("[DATA]      Timezone: " + local_timezone);
    Print("[DATA]      Local Time: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
    
    // Read DBInfo as key-value pairs
    string broker_name = "", db_timezone_val = "", schema_version = "", database_type = "", database_version = "", created_at = "", setup_by = "";
    int dbinfo_request = DatabasePrepare(db_handle, "SELECT key, value FROM DBInfo");
    if(dbinfo_request != INVALID_HANDLE) {
        while(DatabaseRead(dbinfo_request)) {
            string key = "", value = "";
            DatabaseColumnText(dbinfo_request, 0, key);
            DatabaseColumnText(dbinfo_request, 1, value);
            if(key == "broker_name") broker_name = value;
            else if(key == "timezone") db_timezone_val = value;
            else if(key == "schema_version") schema_version = value;
            else if(key == "database_type") database_type = value;
            else if(key == "database_version") database_version = value;
            else if(key == "created_at") created_at = value;
            else if(key == "setup_by") setup_by = value;
        }
        DatabaseFinalize(dbinfo_request);
    }
    Print("[DATA]      - Source: " + db_name);
    Print("[DATA]      - Broker: " + (broker_name != "" ? broker_name : "MISSING"));
    Print("[DATA]      - Timezone: UTC");
    Print("[DATA]      - Schema: " + (schema_version != "" ? schema_version : (database_version != "" ? database_version : "MISSING")));
}

//+------------------------------------------------------------------+
//| Display all candle data information                             |
//+------------------------------------------------------------------+
void CDatabaseOperations::DisplayAllCandleData(int db_handle, string db_name)
{
    if(db_handle == INVALID_HANDLE) {
        Print("[DATA]   ERROR: Database not available for candle data");
        return;
    }
    
    Print("[DATA]   AllCandleData:");
    
    // Find the appropriate table name
    string active_table = FindActiveTable(db_handle);
    
    if(active_table == "") {
        Print("[DATA]      INFO: No candle data tables found");
        return;
    }
    
    Print("[DATA]      Table: " + active_table);
    
    // Get unique assets (symbols)
    string assets[];
    GetUniqueAssets(db_handle, active_table, assets);
    Print("[DATA]      ASSETS: Assets in DB: " + IntegerToString(ArraySize(assets)));
    
    // Get unique timeframes
    string tf_query = StringFormat("SELECT DISTINCT timeframe FROM %s ORDER BY timeframe", active_table);
    int request = DatabasePrepare(db_handle, tf_query);
    
    if(request != INVALID_HANDLE) {
        string timeframes_str = "";
        while(DatabaseRead(request)) {
            long tf = 0;
            DatabaseColumnLong(request, 0, tf);
            if(timeframes_str != "") timeframes_str += ", ";
            timeframes_str += TimeframeToString((int)tf);
        }
        DatabaseFinalize(request);
        Print("[DATA]      TIMEFRAMES: Timeframes: " + timeframes_str);
    }
    
    // Get total entries
    int total_entries = CountTotalEntries(db_handle, active_table);
    Print("[DATA]      [DATA] Total Entries: " + IntegerToString(total_entries));
    
    // Overall candle counts by timeframe
    string tf_count_str = "";
    string tf_query2 = StringFormat("SELECT timeframe, COUNT(*) FROM %s GROUP BY timeframe ORDER BY timeframe", active_table);
    int req2 = DatabasePrepare(db_handle, tf_query2);
    if(req2 != INVALID_HANDLE) {
        while(DatabaseRead(req2)) {
            long tf=0, cnt=0;
            DatabaseColumnLong(req2, 0, tf);
            DatabaseColumnLong(req2, 1, cnt);
            if(tf_count_str != "") tf_count_str += ", ";
            tf_count_str += TimeframeToString((int)tf) + ": " + IntegerToString(cnt);
        }
        DatabaseFinalize(req2);
        Print("[DATA]      Candle Counts by Timeframe: " + tf_count_str);
    }

    // Display entries organized by timeframes for each asset
    for(int i = 0; i < ArraySize(assets); i++) {
        DisplayAssetData(db_handle, active_table, assets[i]);
    }
}

//+------------------------------------------------------------------+
//| Display data for specific asset                                 |
//+------------------------------------------------------------------+
void CDatabaseOperations::DisplayAssetData(int db_handle, string table_name, string symbol)
{
    Print("[DATA]      ASSET: Asset: " + symbol);
    
    // Get timeframes and entry counts for this symbol
    string tf_query = StringFormat(
        "SELECT timeframe, COUNT(*) as entries FROM %s WHERE symbol='%s' GROUP BY timeframe ORDER BY timeframe", 
        table_name, symbol);
    
    int request = DatabasePrepare(db_handle, tf_query);
    
    if(request == INVALID_HANDLE) {
        Print("[DATA]         ERROR: Failed to query timeframes for " + symbol);
        return;
    }
    
    while(DatabaseRead(request)) {
        long timeframe = 0, entries = 0;
        DatabaseColumnLong(request, 0, timeframe);
        DatabaseColumnLong(request, 1, entries);
        
        string tf_string = TimeframeToString((int)timeframe);
        Print("[DATA]         [DATA] " + tf_string + ": " + IntegerToString(entries) + " entries");
    }
    
    DatabaseFinalize(request);
}

//+------------------------------------------------------------------+
//| Convert timeframe number to string                              |
//+------------------------------------------------------------------+
string CDatabaseOperations::TimeframeToString(int timeframe)
{
    // Handle MT5 period constants
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
        default: return "TF" + IntegerToString(timeframe);
    }
}

//+------------------------------------------------------------------+
//| Get detailed breakdown for reports                              |
//+------------------------------------------------------------------+
string CDatabaseOperations::GetDetailedBreakdown(int db_handle, string db_name)
{
    string breakdown = "";
    
    if(db_handle == INVALID_HANDLE) {
        return "Database not available: " + db_name;
    }
    
    breakdown += "=== " + db_name + " ===\n";
    breakdown += GetDatabaseInfo(db_handle, db_name) + "\n";
    breakdown += GetCandleDataInfo(db_handle, db_name) + "\n";
    
    return breakdown;
}

//+------------------------------------------------------------------+
//| Get comprehensive breakdown with all details                    |
//+------------------------------------------------------------------+
string CDatabaseOperations::GetComprehensiveBreakdown(int db_handle, string db_name)
{
    string breakdown = "";
    
    if(db_handle == INVALID_HANDLE) {
        return "Database not available: " + db_name;
    }
    
    breakdown += "=== COMPREHENSIVE BREAKDOWN: " + db_name + " ===\n\n";
    
    // Basic database info
    breakdown += GetDatabaseInfo(db_handle, db_name) + "\n\n";
    
    // Find active table
    string active_table = FindActiveTable(db_handle);
    if(active_table == "") {
        breakdown += "No candle data tables found\n";
        return breakdown;
    }
    
    breakdown += "=== DETAILED CANDLE DATA ANALYSIS ===\n";
    breakdown += "Active Table: " + active_table + "\n\n";
    
    // Get comprehensive asset and timeframe breakdown
    string assets[];
    GetUniqueAssets(db_handle, active_table, assets);
    
    breakdown += "=== BREAKDOWN BY SYMBOL ===\n";
    breakdown += "TOTAL SYMBOLS: " + IntegerToString(ArraySize(assets)) + "\n\n";
    
    // For each symbol, show timeframe breakdown
    for(int i = 0; i < ArraySize(assets) && i < 20; i++) { // Show up to 20 symbols
        string symbol = assets[i];
        breakdown += "* " + symbol + ":\n";
        
        // Get timeframes and counts for this symbol
        string tf_query = StringFormat(
            "SELECT timeframe, COUNT(*) as entries FROM %s WHERE symbol='%s' GROUP BY timeframe ORDER BY timeframe", 
            active_table, symbol);
        
        int tf_request = DatabasePrepare(db_handle, tf_query);
        
        if(tf_request != INVALID_HANDLE) {
            long symbol_total = 0;
            while(DatabaseRead(tf_request)) {
                long timeframe = 0, entries = 0;
                DatabaseColumnLong(tf_request, 0, timeframe);
                DatabaseColumnLong(tf_request, 1, entries);
                symbol_total += entries;
                
                string tf_string = TimeframeToString((int)timeframe);
                breakdown += "  - " + tf_string + ": " + IntegerToString(entries) + " records\n";
            }
            DatabaseFinalize(tf_request);
            breakdown += "  SYMBOL TOTAL: " + IntegerToString(symbol_total) + " records\n\n";
        } else {
            breakdown += "  - Error querying timeframes for this symbol\n\n";
        }
    }
    
    // Add summary if more symbols exist
    if(ArraySize(assets) > 20) {
        breakdown += "[" + IntegerToString(ArraySize(assets) - 20) + " more symbols not shown - use console for full details]\n";
    }
    
    return breakdown;
}
