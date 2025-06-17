//+------------------------------------------------------------------+
//| IntegrityValidator.mqh - Data integrity validation and detection |
//| Focused class for hash-based corruption detection               |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "1.0.0"

#ifndef SSOT_INTEGRITY_VALIDATOR_MQH
#define SSOT_INTEGRITY_VALIDATOR_MQH

#include <SSoT/HashUtils.mqh>

//+------------------------------------------------------------------+
//| Integrity Issue Types                                            |
//+------------------------------------------------------------------+
enum ENUM_INTEGRITY_ISSUE
{
    INTEGRITY_HASH_MISMATCH,    // Stored hash doesn't match calculated hash
    INTEGRITY_MISSING_HASH,     // Hash field is empty or null
    INTEGRITY_INVALID_OHLC,     // OHLC data violates basic rules
    INTEGRITY_INVALID_VOLUME,   // Volume data is invalid
    INTEGRITY_INVALID_TIMESTAMP,// Timestamp is invalid or out of sequence
    INTEGRITY_DUPLICATE_RECORD, // Duplicate records found
    INTEGRITY_ORPHANED_DATA     // Data without proper relationships
};

//+------------------------------------------------------------------+
//| Integrity Validation Result                                     |
//+------------------------------------------------------------------+
struct SIntegrityResult
{
    string                    database_name;
    string                    symbol;
    string                    timeframe;
    datetime                  timestamp;
    ENUM_INTEGRITY_ISSUE      issue_type;
    string                    stored_hash;
    string                    calculated_hash;
    string                    issue_description;
    int                       severity; // 1=low, 2=medium, 3=high, 4=critical
    bool                      auto_repairable;
    datetime                  detected_time;
};

//+------------------------------------------------------------------+
//| Validation Configuration                                         |
//+------------------------------------------------------------------+
struct SValidationConfig
{
    bool                      validate_hashes;
    bool                      validate_ohlc_rules;
    bool                      validate_volume_data;
    bool                      validate_timestamps;
    bool                      check_duplicates;
    int                       sample_rate_percent; // 1-100
    bool                      deep_validation;
    int                       batch_size;
};

//+------------------------------------------------------------------+
//| Integrity Validator Class                                       |
//+------------------------------------------------------------------+
class CIntegrityValidator
{
private:
    int                       m_main_db;
    int                       m_test_input_db;
    int                       m_test_output_db;
    SValidationConfig         m_config;
    SIntegrityResult          m_detected_issues[];
    bool                      m_initialized;
    
    // Validation statistics
    int                       m_total_records_checked;
    int                       m_total_issues_found;
    int                       m_hash_mismatches;
    int                       m_ohlc_violations;
    int                       m_duplicate_records;
    datetime                  m_last_validation_time;

public:
    CIntegrityValidator();
    ~CIntegrityValidator();
      // Initialization
    bool Initialize(int main_db, int test_input_db, int test_output_db);
    void Configure(SValidationConfig &config);
    
    // Main validation methods
    int DetectCorruption();
    int ValidateDatabase(int db_handle, string db_name);
    int ValidateSymbolData(int db_handle, string symbol, string timeframe);
    
    // Specific validation types
    int ValidateHashes(int db_handle, string symbol = "", string timeframe = "");
    int ValidateOHLCRules(int db_handle, string symbol = "", string timeframe = "");
    int ValidateVolumeData(int db_handle, string symbol = "", string timeframe = "");
    int ValidateTimestamps(int db_handle, string symbol = "", string timeframe = "");
    int DetectDuplicates(int db_handle);
    
    // Individual record validation
    bool ValidateRecord(int db_handle, const string &symbol, const string &timeframe, datetime timestamp);
    bool ValidateOHLCValues(double open, double high, double low, double close);
    bool ValidateVolumeValues(long tick_volume, long real_volume);
    bool ValidateHashValue(const string &stored_hash, const string &calculated_hash);    
    // Hash operations
    string RecalculateHash(double open, double high, double low, double close, long volume, datetime timestamp);
    bool VerifyStoredHash(int db_handle, string symbol, string timeframe, datetime timestamp);
    
    // Issue management
    int GetDetectedIssuesCount() const { return ArraySize(m_detected_issues); }
    SIntegrityResult GetIssue(int index);
    int GetAllIssues(SIntegrityResult &issues[]);
    int GetIssuesByType(SIntegrityResult &issues[], ENUM_INTEGRITY_ISSUE issue_type);
    
    // Reporting
    string GetValidationReport();
    string GetIntegrityStatistics();
    
private:
    // Internal validation logic
    void AddDetectedIssue(const string &db_name, const string &symbol, const string &timeframe,
                         datetime timestamp, ENUM_INTEGRITY_ISSUE issue_type,
                         const string &description, int severity = 2);
    
    // Database query helpers
    bool GetRandomSample(int db_handle, const string &symbol, const string &timeframe, 
                        string &sample_records[], int sample_size);
    bool GetAllRecords(int db_handle, const string &symbol, const string &timeframe,
                      string &all_records[]);
    
    // Validation helpers
    int CalculateIssueSeverity(ENUM_INTEGRITY_ISSUE issue_type, const string &symbol);
    bool IsAutoRepairable(ENUM_INTEGRITY_ISSUE issue_type);
    string GetIssueDescription(ENUM_INTEGRITY_ISSUE issue_type);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CIntegrityValidator::CIntegrityValidator()
{
    m_main_db = INVALID_HANDLE;
    m_test_input_db = INVALID_HANDLE;
    m_test_output_db = INVALID_HANDLE;
    m_initialized = false;
    
    m_total_records_checked = 0;
    m_total_issues_found = 0;
    m_hash_mismatches = 0;
    m_ohlc_violations = 0;
    m_duplicate_records = 0;
    m_last_validation_time = 0;
    
    // Default configuration
    m_config.validate_hashes = true;
    m_config.validate_ohlc_rules = true;
    m_config.validate_volume_data = true;
    m_config.validate_timestamps = true;
    m_config.check_duplicates = true;
    m_config.sample_rate_percent = 5; // Validate 5% of records for performance
    m_config.deep_validation = false;
    m_config.batch_size = 1000;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CIntegrityValidator::~CIntegrityValidator()
{
    ArrayResize(m_detected_issues, 0);
}

//+------------------------------------------------------------------+
//| Initialize the integrity validator                               |
//+------------------------------------------------------------------+
bool CIntegrityValidator::Initialize(int main_db, int test_input_db, int test_output_db)
{
    if(main_db == INVALID_HANDLE) {
        Print("❌ IntegrityValidator: Invalid main database handle");
        return false;
    }
    
    m_main_db = main_db;
    m_test_input_db = test_input_db;
    m_test_output_db = test_output_db;
    m_initialized = true;
    
    Print("✅ IntegrityValidator: Initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Detect corruption in all databases                              |
//+------------------------------------------------------------------+
int CIntegrityValidator::DetectCorruption()
{
    if(!m_initialized) {
        Print("❌ IntegrityValidator: Not initialized");
        return -1;
    }
    
    Print("🔍 IntegrityValidator: Starting corruption detection...");
    
    // Clear previous results
    ArrayResize(m_detected_issues, 0);
    m_total_issues_found = 0;
    m_total_records_checked = 0;
    
    int total_issues = 0;
    
    // Validate main database
    total_issues += ValidateDatabase(m_main_db, "Main");
    
    // Validate test databases if available
    if(m_test_input_db != INVALID_HANDLE) {
        total_issues += ValidateDatabase(m_test_input_db, "TestInput");
    }
    
    if(m_test_output_db != INVALID_HANDLE) {
        total_issues += ValidateDatabase(m_test_output_db, "TestOutput");
    }
    
    m_last_validation_time = TimeCurrent();
    m_total_issues_found = total_issues;
    
    Print("🔍 IntegrityValidator: Corruption detection complete - ", total_issues, " issues found");
    
    return total_issues;
}

//+------------------------------------------------------------------+
//| Validate specific database                                       |
//+------------------------------------------------------------------+
int CIntegrityValidator::ValidateDatabase(int db_handle, string db_name)
{
    if(db_handle == INVALID_HANDLE) {
        return 0;
    }
    
    Print("🔍 Validating database: ", db_name);
    
    int database_issues = 0;
    
    // Get list of symbols in database
    string symbols[];
    string query = "SELECT DISTINCT asset_symbol FROM AllCandleData ORDER BY asset_symbol";
    int request = DatabasePrepare(db_handle, query);
    
    if(request != INVALID_HANDLE) {
        int symbol_count = 0;
        while(DatabaseRead(request)) {
            string symbol;
            DatabaseColumnText(request, 0, symbol);
            ArrayResize(symbols, symbol_count + 1);
            symbols[symbol_count] = symbol;
            symbol_count++;
        }
        DatabaseFinalize(request);
        
        // Validate each symbol
        for(int i = 0; i < ArraySize(symbols); i++) {
            // Get timeframes for this symbol
            string timeframes[];
            string tf_query = StringFormat(
                "SELECT DISTINCT timeframe FROM AllCandleData WHERE asset_symbol='%s' ORDER BY timeframe",
                symbols[i]
            );
            
            int tf_request = DatabasePrepare(db_handle, tf_query);
            if(tf_request != INVALID_HANDLE) {
                int tf_count = 0;
                while(DatabaseRead(tf_request)) {
                    string timeframe;
                    DatabaseColumnText(tf_request, 0, timeframe);
                    ArrayResize(timeframes, tf_count + 1);
                    timeframes[tf_count] = timeframe;
                    tf_count++;
                }
                DatabaseFinalize(tf_request);
                
                // Validate each symbol/timeframe combination
                for(int j = 0; j < ArraySize(timeframes); j++) {
                    database_issues += ValidateSymbolData(db_handle, symbols[i], timeframes[j]);
                }
            }
        }
    }
    
    // Check for duplicates at database level
    if(m_config.check_duplicates) {
        database_issues += DetectDuplicates(db_handle);
    }
    
    Print("📊 ", db_name, ": ", database_issues, " integrity issues found");
    return database_issues;
}

//+------------------------------------------------------------------+
//| Validate symbol/timeframe data                                   |
//+------------------------------------------------------------------+
int CIntegrityValidator::ValidateSymbolData(int db_handle, string symbol, string timeframe)
{
    int symbol_issues = 0;
    
    // Validate hashes if enabled
    if(m_config.validate_hashes) {
        symbol_issues += ValidateHashes(db_handle, symbol, timeframe);
    }
    
    // Validate OHLC rules if enabled
    if(m_config.validate_ohlc_rules) {
        symbol_issues += ValidateOHLCRules(db_handle, symbol, timeframe);
    }
    
    // Validate volume data if enabled
    if(m_config.validate_volume_data) {
        symbol_issues += ValidateVolumeData(db_handle, symbol, timeframe);
    }
    
    // Validate timestamps if enabled
    if(m_config.validate_timestamps) {
        symbol_issues += ValidateTimestamps(db_handle, symbol, timeframe);
    }
    
    return symbol_issues;
}

//+------------------------------------------------------------------+
//| Validate hash integrity                                          |
//+------------------------------------------------------------------+
int CIntegrityValidator::ValidateHashes(int db_handle, string symbol, string timeframe)
{
    string where_clause = "";
    if(symbol != "" && timeframe != "") {
        where_clause = StringFormat(" WHERE asset_symbol='%s' AND timeframe='%s'", symbol, timeframe);
    }
    
    string query = StringFormat(
        "SELECT asset_symbol, timeframe, timestamp, open, high, low, close, tick_volume, hash "
        "FROM AllCandleData%s ORDER BY timestamp",
        where_clause
    );
    
    int request = DatabasePrepare(db_handle, query);
    if(request == INVALID_HANDLE) {
        return 0;
    }
    
    int hash_issues = 0;
    int records_checked = 0;
    
    while(DatabaseRead(request)) {
        // Use sampling if configured
        if(m_config.sample_rate_percent < 100) {
            if((MathRand() % 100) >= m_config.sample_rate_percent) {
                continue;
            }
        }
        
        string db_symbol, db_timeframe, stored_hash;
        datetime timestamp;
        double open, high, low, close;
        long tick_volume;
        
        DatabaseColumnText(request, 0, db_symbol);
        DatabaseColumnText(request, 1, db_timeframe);
        DatabaseColumnLong(request, 2, timestamp);
        DatabaseColumnDouble(request, 3, open);
        DatabaseColumnDouble(request, 4, high);
        DatabaseColumnDouble(request, 5, low);
        DatabaseColumnDouble(request, 6, close);
        DatabaseColumnLong(request, 7, tick_volume);
        DatabaseColumnText(request, 8, stored_hash);
        
        records_checked++;
        m_total_records_checked++;
        
        // Calculate expected hash
        string calculated_hash = CalculateHash(open, high, low, close, tick_volume, timestamp);
        
        // Check for missing hash
        if(stored_hash == "" || stored_hash == "0") {
            AddDetectedIssue("Database", db_symbol, db_timeframe, timestamp,
                           INTEGRITY_MISSING_HASH, "Hash field is empty", 2);
            hash_issues++;
            m_hash_mismatches++;
        }
        // Check for hash mismatch
        else if(stored_hash != calculated_hash) {
            string description = StringFormat("Hash mismatch: stored='%s', calculated='%s'",
                                            stored_hash, calculated_hash);
            AddDetectedIssue("Database", db_symbol, db_timeframe, timestamp,
                           INTEGRITY_HASH_MISMATCH, description, 3);
            hash_issues++;
            m_hash_mismatches++;
        }
    }
    
    DatabaseFinalize(request);
    
    if(records_checked > 0) {
        double error_rate = (double)hash_issues / records_checked * 100.0;
        Print("🔍 Hash validation: ", records_checked, " records checked, ", hash_issues, 
              " issues (", DoubleToString(error_rate, 1), "% error rate)");
    }
    
    return hash_issues;
}

//+------------------------------------------------------------------+
//| Validate OHLC rules                                              |
//+------------------------------------------------------------------+
int CIntegrityValidator::ValidateOHLCRules(int db_handle, string symbol, string timeframe)
{
    string where_clause = "";
    if(symbol != "" && timeframe != "") {
        where_clause = StringFormat(" WHERE asset_symbol='%s' AND timeframe='%s'", symbol, timeframe);
    }
    
    string query = StringFormat(
        "SELECT asset_symbol, timeframe, timestamp, open, high, low, close "
        "FROM AllCandleData%s ORDER BY timestamp",
        where_clause
    );
    
    int request = DatabasePrepare(db_handle, query);
    if(request == INVALID_HANDLE) {
        return 0;
    }
    
    int ohlc_issues = 0;
    int records_checked = 0;
    
    while(DatabaseRead(request)) {
        // Use sampling if configured
        if(m_config.sample_rate_percent < 100) {
            if((MathRand() % 100) >= m_config.sample_rate_percent) {
                continue;
            }
        }
        
        string db_symbol, db_timeframe;
        datetime timestamp;
        double open, high, low, close;
        
        DatabaseColumnText(request, 0, db_symbol);
        DatabaseColumnText(request, 1, db_timeframe);
        DatabaseColumnLong(request, 2, timestamp);
        DatabaseColumnDouble(request, 3, open);
        DatabaseColumnDouble(request, 4, high);
        DatabaseColumnDouble(request, 5, low);
        DatabaseColumnDouble(request, 6, close);
        
        records_checked++;
        m_total_records_checked++;
        
        // Validate OHLC rules
        if(!ValidateOHLCValues(open, high, low, close)) {
            string description = StringFormat("Invalid OHLC: O=%.5f H=%.5f L=%.5f C=%.5f",
                                            open, high, low, close);
            AddDetectedIssue("Database", db_symbol, db_timeframe, timestamp,
                           INTEGRITY_INVALID_OHLC, description, 3);
            ohlc_issues++;
            m_ohlc_violations++;
        }
    }
    
    DatabaseFinalize(request);
    
    Print("🔍 OHLC validation: ", records_checked, " records checked, ", ohlc_issues, " violations");
    return ohlc_issues;
}

//+------------------------------------------------------------------+
//| Validate OHLC values                                             |
//+------------------------------------------------------------------+
bool CIntegrityValidator::ValidateOHLCValues(double open, double high, double low, double close)
{
    // Basic OHLC validation rules
    if(open <= 0 || high <= 0 || low <= 0 || close <= 0) {
        return false; // All prices must be positive
    }
    
    if(high < open || high < close || high < low) {
        return false; // High must be the highest
    }
    
    if(low > open || low > close || low > high) {
        return false; // Low must be the lowest
    }
    
    // Check for unrealistic price relationships
    double price_range = high - low;
    double avg_price = (open + close) / 2.0;
    
    if(price_range > avg_price * 0.5) { // Range > 50% of average price
        return false; // Unrealistic price range
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Validate volume data                                             |
//+------------------------------------------------------------------+
int CIntegrityValidator::ValidateVolumeData(int db_handle, string symbol, string timeframe)
{
    // Simplified volume validation - check for negative or zero volumes
    string where_clause = "";
    if(symbol != "" && timeframe != "") {
        where_clause = StringFormat(" WHERE asset_symbol='%s' AND timeframe='%s'", symbol, timeframe);
    }
    
    string query = StringFormat(
        "SELECT COUNT(*) FROM AllCandleData%s AND (tick_volume <= 0 OR real_volume < 0)",
        where_clause
    );
    
    int request = DatabasePrepare(db_handle, query);
    if(request == INVALID_HANDLE) {
        return 0;
    }
    
    int volume_issues = 0;
    if(DatabaseRead(request)) {
        DatabaseColumnLong(request, 0, volume_issues);
    }
    
    DatabaseFinalize(request);
    
    if(volume_issues > 0) {
        Print("🔍 Volume validation: ", volume_issues, " invalid volume records found");
    }
    
    return volume_issues;
}

//+------------------------------------------------------------------+
//| Validate timestamp sequence                                      |
//+------------------------------------------------------------------+
int CIntegrityValidator::ValidateTimestamps(int db_handle, string symbol, string timeframe)
{
    // Check for duplicate timestamps or invalid sequences
    string where_clause = "";
    if(symbol != "" && timeframe != "") {
        where_clause = StringFormat(" WHERE asset_symbol='%s' AND timeframe='%s'", symbol, timeframe);
    }
    
    // Check for duplicate timestamps
    string query = StringFormat(
        "SELECT asset_symbol, timeframe, timestamp, COUNT(*) as cnt "
        "FROM AllCandleData%s GROUP BY asset_symbol, timeframe, timestamp HAVING cnt > 1",
        where_clause
    );
    
    int request = DatabasePrepare(db_handle, query);
    if(request == INVALID_HANDLE) {
        return 0;
    }
    
    int timestamp_issues = 0;
    while(DatabaseRead(request)) {
        string db_symbol, db_timeframe;
        datetime timestamp;
        long count;
        
        DatabaseColumnText(request, 0, db_symbol);
        DatabaseColumnText(request, 1, db_timeframe);
        DatabaseColumnLong(request, 2, timestamp);
        DatabaseColumnLong(request, 3, count);
        
        AddDetectedIssue("Database", db_symbol, db_timeframe, timestamp,
                       INTEGRITY_DUPLICATE_RECORD, 
                       StringFormat("Duplicate timestamp found (%d occurrences)", count), 2);
        timestamp_issues++;
        m_duplicate_records++;
    }
    
    DatabaseFinalize(request);
    
    if(timestamp_issues > 0) {
        Print("🔍 Timestamp validation: ", timestamp_issues, " duplicate timestamps found");
    }
    
    return timestamp_issues;
}

//+------------------------------------------------------------------+
//| Detect duplicate records                                         |
//+------------------------------------------------------------------+
int CIntegrityValidator::DetectDuplicates(int db_handle)
{
    return ValidateTimestamps(db_handle, "", "");
}

//+------------------------------------------------------------------+
//| Add detected issue to the list                                  |
//+------------------------------------------------------------------+
void CIntegrityValidator::AddDetectedIssue(string db_name, string symbol, string timeframe,
                                          datetime timestamp, ENUM_INTEGRITY_ISSUE issue_type,
                                          string description, int severity)
{
    int size = ArraySize(m_detected_issues);
    ArrayResize(m_detected_issues, size + 1);
    
    m_detected_issues[size].database_name = db_name;
    m_detected_issues[size].symbol = symbol;
    m_detected_issues[size].timeframe = timeframe;
    m_detected_issues[size].timestamp = timestamp;
    m_detected_issues[size].issue_type = issue_type;
    m_detected_issues[size].issue_description = description;
    m_detected_issues[size].severity = severity;
    m_detected_issues[size].auto_repairable = IsAutoRepairable(issue_type);
    m_detected_issues[size].detected_time = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Check if issue is auto-repairable                               |
//+------------------------------------------------------------------+
bool CIntegrityValidator::IsAutoRepairable(ENUM_INTEGRITY_ISSUE issue_type)
{
    switch(issue_type) {
        case INTEGRITY_HASH_MISMATCH:
        case INTEGRITY_MISSING_HASH:
            return true; // Hashes can be recalculated
            
        case INTEGRITY_DUPLICATE_RECORD:
            return true; // Duplicates can be removed
            
        case INTEGRITY_INVALID_OHLC:
        case INTEGRITY_INVALID_VOLUME:
        case INTEGRITY_INVALID_TIMESTAMP:
            return false; // These need manual review or data refetch
              default:
            return false;
    }
}

//+------------------------------------------------------------------+
//| Get specific issue by index                                      |
//+------------------------------------------------------------------+
SIntegrityResult CIntegrityValidator::GetIssue(int index)
{
    SIntegrityResult empty = {};
    if(index < 0 || index >= ArraySize(m_detected_issues)) {
        return empty;
    }
    return m_detected_issues[index];
}

//+------------------------------------------------------------------+
//| Get all detected issues                                          |
//+------------------------------------------------------------------+
int CIntegrityValidator::GetAllIssues(SIntegrityResult &issues[])
{
    int count = ArraySize(m_detected_issues);
    ArrayResize(issues, count);
    
    for(int i = 0; i < count; i++) {
        issues[i] = m_detected_issues[i];
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Get issues by specific type                                      |
//+------------------------------------------------------------------+
int CIntegrityValidator::GetIssuesByType(SIntegrityResult &issues[], ENUM_INTEGRITY_ISSUE issue_type)
{
    int count = 0;
    int total = ArraySize(m_detected_issues);
    
    // First pass: count matching issues
    for(int i = 0; i < total; i++) {
        if(m_detected_issues[i].issue_type == issue_type) {
            count++;
        }
    }
    
    // Resize output array
    ArrayResize(issues, count);
    
    // Second pass: copy matching issues
    int idx = 0;
    for(int i = 0; i < total; i++) {
        if(m_detected_issues[i].issue_type == issue_type) {
            issues[idx++] = m_detected_issues[i];
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Get validation report                                            |
//+------------------------------------------------------------------+
string CIntegrityValidator::GetValidationReport()
{
    string report = "=== INTEGRITY VALIDATION REPORT ===\n";
    report += "Last validation: " + TimeToString(m_last_validation_time) + "\n";
    report += "Records checked: " + IntegerToString(m_total_records_checked) + "\n";
    report += "Total issues found: " + IntegerToString(m_total_issues_found) + "\n";
    report += "Hash mismatches: " + IntegerToString(m_hash_mismatches) + "\n";
    report += "OHLC violations: " + IntegerToString(m_ohlc_violations) + "\n";
    report += "Duplicate records: " + IntegerToString(m_duplicate_records) + "\n\n";
    
    if(ArraySize(m_detected_issues) > 0) {
        report += "DETECTED ISSUES:\n";
        for(int i = 0; i < MathMin(10, ArraySize(m_detected_issues)); i++) { // Show first 10
            SIntegrityResult issue = m_detected_issues[i];
            report += StringFormat("- %s %s [%s]: %s (Severity: %d)\n",
                                 issue.symbol, issue.timeframe,
                                 TimeToString(issue.timestamp),
                                 issue.issue_description,
                                 issue.severity);
        }
        
        if(ArraySize(m_detected_issues) > 10) {
            report += StringFormat("... and %d more issues\n", ArraySize(m_detected_issues) - 10);
        }
    } else {
        report += "✅ No integrity issues detected\n";
    }
    
    return report;
}

#endif // SSOT_INTEGRITY_VALIDATOR_MQH
