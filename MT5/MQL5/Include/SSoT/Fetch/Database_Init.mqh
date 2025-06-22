//+------------------------------------------------------------------+
//| Database_Init.mqh                                               |
//| Single Source of Truth for Database Initialization              |
//| V6 - Unified Database System                                    |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "6.00"

#ifndef DATABASE_INIT_MQH
#define DATABASE_INIT_MQH

#include "Database_Scheme.mqh"

//+------------------------------------------------------------------+
//| Database Type Enumeration                                       |
//+------------------------------------------------------------------+
enum ENUM_DATABASE_TYPE
{
    DB_TYPE_MAIN_PRODUCTION,     // Main production database
    DB_TYPE_TEST_INPUT,          // Test input database (broker simulation)
    DB_TYPE_TEST_OUTPUT,         // Test output database (validation)
    DB_TYPE_ARCHIVE,             // Archive database
    DB_TYPE_PERFORMANCE_TEST     // Performance testing database
};

//+------------------------------------------------------------------+
//| Database Connection Configuration                               |
//+------------------------------------------------------------------+
struct DatabaseConnectionConfig
{
    string              database_name;          // Database file name
    ENUM_DATABASE_TYPE  database_type;          // Type of database
    ENUM_SCHEMA_TYPE    schema_type;            // Schema type to use
    
    // Connection settings
    bool                enable_wal_mode;        // Write-Ahead Logging
    int                 cache_size_mb;          // Cache size in MB
    int                 timeout_ms;             // Timeout in milliseconds
    bool                enable_foreign_keys;    // Foreign key support
    
    // Optimization settings
    bool                optimize_for_performance; // Performance optimization
    bool                auto_vacuum;            // Auto vacuum
    int                 page_size;              // Page size
    
    // Logging
    bool                verbose_logging;        // Detailed logging
};

//+------------------------------------------------------------------+
//| Database Connection Result                                       |
//+------------------------------------------------------------------+
struct DatabaseConnectionResult
{
    bool                success;                // Connection success
    int                 database_handle;        // Database handle
    string              error_message;          // Error description
    double              initialization_time_ms; // Time taken to initialize
    int                 schema_version;         // Schema version created
    string              database_path;          // Full database path
};

//+------------------------------------------------------------------+
//| Multi-Database Configuration                                    |
//+------------------------------------------------------------------+
struct MultiDatabaseConfig
{
    DatabaseConnectionConfig main_db_config;       // Main database config
    DatabaseConnectionConfig test_input_config;    // Test input config
    DatabaseConnectionConfig test_output_config;   // Test output config
    
    bool                enable_test_mode;       // Enable test databases
    bool                validate_all_schemas;   // Validate all schemas after creation
    bool                sync_schemas;           // Keep schemas synchronized
    string              base_directory;        // Base directory for databases
};

//+------------------------------------------------------------------+
//| Unified Database Initializer - Single Source of Truth          |
//+------------------------------------------------------------------+
class CDatabaseInitializer
{
private:
    CSchemaManager*     m_schema_manager;
    string              m_last_error;
    bool                m_verbose_logging;
    
    // Connection handles tracking
    int                 m_main_db_handle;
    int                 m_test_input_handle;
    int                 m_test_output_handle;
    
public:
                       CDatabaseInitializer();
                      ~CDatabaseInitializer();
    
    // Single database initialization
    DatabaseConnectionResult InitializeDatabase(const DatabaseConnectionConfig &config);
    
    // Multi-database initialization (main + test)
    bool               InitializeMultipleDatabases(const MultiDatabaseConfig &config,
                                                   DatabaseConnectionResult &main_result,
                                                   DatabaseConnectionResult &test_input_result,
                                                   DatabaseConnectionResult &test_output_result);
    
    // Quick initialization methods
    DatabaseConnectionResult InitializeMainDatabase(string db_name, bool enable_wal = true, int cache_mb = 64);
    DatabaseConnectionResult InitializeTestInputDatabase(string db_name);
    DatabaseConnectionResult InitializeTestOutputDatabase(string db_name);
    
    // Validation and verification
    bool               ValidateDatabase(int db_handle, ENUM_SCHEMA_TYPE expected_schema);
    bool               ValidateAllDatabases();
    
    // Database connection management
    bool               CloseDatabase(int &db_handle);
    bool               CloseAllDatabases();
    
    // DBInfo management
    bool               PopulateDBInfo(int db_handle, string broker_name = "", 
                                     string server_name = "", int timezone = -100);
    bool               UpdateAssetInfo(int db_handle, string &assets[], 
                                      string &timeframes[], int &counts[]);
    
    // Configuration helpers
    static DatabaseConnectionConfig GetDefaultMainConfig(string db_name);
    static DatabaseConnectionConfig GetDefaultTestInputConfig(string db_name);
    static DatabaseConnectionConfig GetDefaultTestOutputConfig(string db_name);
    static MultiDatabaseConfig GetDefaultMultiConfig(string main_db, string test_input_db, string test_output_db);
    
    // Information
    string             GetLastError() const { return m_last_error; }
    int                GetMainDatabaseHandle() const { return m_main_db_handle; }
    int                GetTestInputHandle() const { return m_test_input_handle; }
    int                GetTestOutputHandle() const { return m_test_output_handle; }
    
private:
    // Internal initialization methods
    DatabaseConnectionResult CreateAndConfigureDatabase(const DatabaseConnectionConfig &config);
    bool               ConfigureDatabaseSettings(int db_handle, const DatabaseConnectionConfig &config);
    bool               CreateDatabaseSchema(int db_handle, const DatabaseConnectionConfig &config);
    
    // Utility methods
    void               SetError(string error_message);
    string             GetDatabaseTypeString(ENUM_DATABASE_TYPE db_type);
    string             GenerateFullPath(string db_name, string base_directory = "");
};

//+------------------------------------------------------------------+
//| Implementation: CDatabaseInitializer                            |
//+------------------------------------------------------------------+
CDatabaseInitializer::CDatabaseInitializer()
{
    m_schema_manager = new CSchemaManager();
    m_last_error = "";
    m_verbose_logging = true;
    m_main_db_handle = INVALID_HANDLE;
    m_test_input_handle = INVALID_HANDLE;
    m_test_output_handle = INVALID_HANDLE;
}

CDatabaseInitializer::~CDatabaseInitializer()
{
    CloseAllDatabases();
    
    if(m_schema_manager != NULL)
    {
        delete m_schema_manager;
        m_schema_manager = NULL;
    }
}

DatabaseConnectionResult CDatabaseInitializer::InitializeDatabase(const DatabaseConnectionConfig &config)
{
    DatabaseConnectionResult result;
    result.success = false;
    result.database_handle = INVALID_HANDLE;
    result.error_message = "";
    result.initialization_time_ms = 0;
    result.schema_version = 0;
    result.database_path = "";
    
    ulong start_time = GetMicrosecondCount();
    
    if(m_verbose_logging)
    {        Print(StringFormat("🚀 Initializing %s database: %s", 
                GetDatabaseTypeString(config.database_type), config.database_name));
    }
    
    // Create and configure database
    result = CreateAndConfigureDatabase(config);
    
    if(result.success)
    {
        // Track the handle based on database type
        switch(config.database_type)
        {
            case DB_TYPE_MAIN_PRODUCTION:
                m_main_db_handle = result.database_handle;
                break;
            case DB_TYPE_TEST_INPUT:
                m_test_input_handle = result.database_handle;
                break;
            case DB_TYPE_TEST_OUTPUT:
                m_test_output_handle = result.database_handle;
                break;
        }
    }
    
    ulong end_time = GetMicrosecondCount();
    result.initialization_time_ms = (end_time - start_time) / 1000.0;
    
    if(result.success)
    {
        Print(StringFormat("✅ Database initialized successfully in %.2f ms", result.initialization_time_ms));
    }
    else
    {
        Print(StringFormat("❌ Database initialization failed: %s", result.error_message));
    }
    
    return result;
}

DatabaseConnectionResult CDatabaseInitializer::CreateAndConfigureDatabase(const DatabaseConnectionConfig &config)
{
    DatabaseConnectionResult result;
    result.success = false;
    result.database_handle = INVALID_HANDLE;
    result.error_message = "";
    result.schema_version = 0;
    result.database_path = GenerateFullPath(config.database_name);
    
    // Open database connection
    result.database_handle = DatabaseOpen(result.database_path, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
    
    if(result.database_handle == INVALID_HANDLE)
    {
        result.error_message = StringFormat("Failed to open database: %s (Error: %d)", 
                                          result.database_path, GetLastError());
        SetError(result.error_message);
        return result;
    }
    
    if(m_verbose_logging)
    {
        Print(StringFormat("📂 Database file opened: %s", result.database_path));
    }
    
    // Configure database settings
    if(!ConfigureDatabaseSettings(result.database_handle, config))
    {
        result.error_message = "Failed to configure database settings";
        SetError(result.error_message);
        DatabaseClose(result.database_handle);
        result.database_handle = INVALID_HANDLE;
        return result;
    }
    
    // Create database schema
    if(!CreateDatabaseSchema(result.database_handle, config))
    {
        result.error_message = "Failed to create database schema";
        SetError(result.error_message);
        DatabaseClose(result.database_handle);
        result.database_handle = INVALID_HANDLE;
        return result;
    }
    
    // Get schema version
    result.schema_version = m_schema_manager.GetSchemaVersion(result.database_handle);
    result.success = true;
    
    // Populate required DBInfo fields
    if(result.success)
    {
        if(!PopulateDBInfo(result.database_handle))
        {
            result.success = false;
            Print("Failed to populate DBInfo fields");
        }
    }
    
    return result;
}

bool CDatabaseInitializer::ConfigureDatabaseSettings(int db_handle, const DatabaseConnectionConfig &config)
{
    if(m_verbose_logging)
    {
        Print("⚙️ Configuring database settings...");
    }
    
    // Enable WAL mode if requested
    if(config.enable_wal_mode)
    {
        if(!DatabaseExecute(db_handle, "PRAGMA journal_mode = WAL"))
        {
            SetError("Failed to enable WAL mode");
            return false;
        }
        if(m_verbose_logging) Print("✅ WAL mode enabled");
    }
    
    // Set cache size
    if(config.cache_size_mb > 0)
    {
        string cache_sql = StringFormat("PRAGMA cache_size = -%d", config.cache_size_mb * 1024);
        if(!DatabaseExecute(db_handle, cache_sql))
        {
            SetError("Failed to set cache size");
            return false;
        }
        if(m_verbose_logging) Print(StringFormat("✅ Cache size set to %d MB", config.cache_size_mb));
    }
    
    // Set timeout
    if(config.timeout_ms > 0)
    {
        string timeout_sql = StringFormat("PRAGMA busy_timeout = %d", config.timeout_ms);
        if(!DatabaseExecute(db_handle, timeout_sql))
        {
            SetError("Failed to set timeout");
            return false;
        }
        if(m_verbose_logging) Print(StringFormat("✅ Timeout set to %d ms", config.timeout_ms));
    }
    
    // Enable foreign keys if requested
    if(config.enable_foreign_keys)
    {
        if(!DatabaseExecute(db_handle, "PRAGMA foreign_keys = ON"))
        {
            SetError("Failed to enable foreign keys");
            return false;
        }
        if(m_verbose_logging) Print("✅ Foreign keys enabled");
    }
    
    // Set page size if specified
    if(config.page_size > 0)
    {
        string page_sql = StringFormat("PRAGMA page_size = %d", config.page_size);
        if(!DatabaseExecute(db_handle, page_sql))
        {
            SetError("Failed to set page size");
            return false;
        }
        if(m_verbose_logging) Print(StringFormat("✅ Page size set to %d bytes", config.page_size));
    }
    
    // Enable auto vacuum if requested
    if(config.auto_vacuum)
    {
        if(!DatabaseExecute(db_handle, "PRAGMA auto_vacuum = INCREMENTAL"))
        {
            SetError("Failed to enable auto vacuum");
            return false;
        }
        if(m_verbose_logging) Print("✅ Auto vacuum enabled");
    }
    
    return true;
}

bool CDatabaseInitializer::CreateDatabaseSchema(int db_handle, const DatabaseConnectionConfig &config)
{
    if(m_verbose_logging)
    {        Print(StringFormat("🏗️ Creating schema type: %s", 
                CSchemaManager::GetSchemaTypeString(config.schema_type)));
    }
    
    // Initialize schema manager with appropriate configuration
    SchemaConfig schema_config = CSchemaManager::GetDefaultConfig(config.schema_type);
    schema_config.optimize_for_performance = config.optimize_for_performance;
    schema_config.verbose_logging = config.verbose_logging;
    
    if(!m_schema_manager.Initialize(schema_config))
    {
        SetError("Failed to initialize schema manager");
        return false;
    }
    
    // Create complete schema
    if(!m_schema_manager.CreateCompleteSchema(db_handle))
    {
        SetError("Schema creation failed: " + m_schema_manager.GetLastError());
        return false;
    }
    
    // Populate required DBInfo fields if this is a main or production database
    if(config.database_type == DB_TYPE_MAIN_PRODUCTION || 
       config.schema_type == SCHEMA_TYPE_MAIN_PRODUCTION)
    {
        PopulateDBInfo(db_handle, "", "", -100);
    }
    
    return true;
}

DatabaseConnectionResult CDatabaseInitializer::InitializeMainDatabase(string db_name, bool enable_wal = true, int cache_mb = 64)
{
    DatabaseConnectionConfig config = GetDefaultMainConfig(db_name);
    config.enable_wal_mode = enable_wal;
    config.cache_size_mb = cache_mb;
    
    return InitializeDatabase(config);
}

DatabaseConnectionResult CDatabaseInitializer::InitializeTestInputDatabase(string db_name)
{
    DatabaseConnectionConfig config = GetDefaultTestInputConfig(db_name);
    return InitializeDatabase(config);
}

DatabaseConnectionResult CDatabaseInitializer::InitializeTestOutputDatabase(string db_name)
{
    DatabaseConnectionConfig config = GetDefaultTestOutputConfig(db_name);
    return InitializeDatabase(config);
}

DatabaseConnectionConfig CDatabaseInitializer::GetDefaultMainConfig(string db_name)
{
    DatabaseConnectionConfig config;
    config.database_name = db_name;
    config.database_type = DB_TYPE_MAIN_PRODUCTION;
    config.schema_type = SCHEMA_TYPE_MAIN_PRODUCTION;
    config.enable_wal_mode = true;
    config.cache_size_mb = 64;
    config.timeout_ms = 5000;
    config.enable_foreign_keys = false;
    config.optimize_for_performance = false;
    config.auto_vacuum = true;
    config.page_size = 4096;
    config.verbose_logging = true;
    
    return config;
}

DatabaseConnectionConfig CDatabaseInitializer::GetDefaultTestInputConfig(string db_name)
{
    DatabaseConnectionConfig config;
    config.database_name = db_name;
    config.database_type = DB_TYPE_TEST_INPUT;
    config.schema_type = SCHEMA_TYPE_TEST_INPUT;
    config.enable_wal_mode = false;
    config.cache_size_mb = 32;
    config.timeout_ms = 3000;
    config.enable_foreign_keys = false;
    config.optimize_for_performance = true;
    config.auto_vacuum = false;
    config.page_size = 4096;
    config.verbose_logging = true;
    
    return config;
}

DatabaseConnectionConfig CDatabaseInitializer::GetDefaultTestOutputConfig(string db_name)
{
    DatabaseConnectionConfig config;
    config.database_name = db_name;
    config.database_type = DB_TYPE_TEST_OUTPUT;
    config.schema_type = SCHEMA_TYPE_TEST_OUTPUT;
    config.enable_wal_mode = false;
    config.cache_size_mb = 32;
    config.timeout_ms = 3000;
    config.enable_foreign_keys = false;
    config.optimize_for_performance = false;
    config.auto_vacuum = false;
    config.page_size = 4096;
    config.verbose_logging = true;
    
    return config;
}

bool CDatabaseInitializer::CloseDatabase(int &db_handle)
{
    if(db_handle != INVALID_HANDLE)
    {
        DatabaseClose(db_handle);
        db_handle = INVALID_HANDLE;
        return true;
    }
    return false;
}

bool CDatabaseInitializer::CloseAllDatabases()
{
    bool result = true;
    
    if(!CloseDatabase(m_main_db_handle)) result = false;
    if(!CloseDatabase(m_test_input_handle)) result = false;
    if(!CloseDatabase(m_test_output_handle)) result = false;
    
    if(result && m_verbose_logging)
    {
        Print("🔒 All databases closed successfully");
    }
    
    return result;
}

bool CDatabaseInitializer::ValidateDatabase(int db_handle, ENUM_SCHEMA_TYPE expected_schema)
{
    if(db_handle == INVALID_HANDLE)
    {
        SetError("Invalid database handle for validation");
        return false;
    }
    
    return m_schema_manager.ValidateSchema(db_handle);
}

void CDatabaseInitializer::SetError(string error_message)
{
    m_last_error = error_message;
    Print(error_message);
}

string CDatabaseInitializer::GetDatabaseTypeString(ENUM_DATABASE_TYPE db_type)
{
    switch(db_type)
    {
        case DB_TYPE_MAIN_PRODUCTION:     return "MAIN_PRODUCTION";
        case DB_TYPE_TEST_INPUT:          return "TEST_INPUT";
        case DB_TYPE_TEST_OUTPUT:         return "TEST_OUTPUT";
        case DB_TYPE_ARCHIVE:             return "ARCHIVE";
        case DB_TYPE_PERFORMANCE_TEST:    return "PERFORMANCE_TEST";
        default:                          return "UNKNOWN";
    }
}

string CDatabaseInitializer::GenerateFullPath(string db_name, string base_directory = "")
{
    if(base_directory == "")
    {
        return db_name;
    }
    else
    {
        return base_directory + "\\" + db_name;
    }
}

bool CDatabaseInitializer::InitializeMultipleDatabases(const MultiDatabaseConfig &config,
                                                       DatabaseConnectionResult &main_result,
                                                       DatabaseConnectionResult &test_input_result,
                                                       DatabaseConnectionResult &test_output_result)
{
    Print("🚀 Initializing multiple databases...");
    
    bool overall_success = true;
    
    // Initialize main database
    main_result = InitializeDatabase(config.main_db_config);
    if(!main_result.success)
    {
        overall_success = false;
        Print("Failed to initialize main database");
    }
    
    // Initialize test databases if enabled
    if(config.enable_test_mode)
    {
        test_input_result = InitializeDatabase(config.test_input_config);
        if(!test_input_result.success)
        {
            overall_success = false;
            Print("Failed to initialize test input database");
        }
        
        test_output_result = InitializeDatabase(config.test_output_config);
        if(!test_output_result.success)
        {
            overall_success = false;
            Print("Failed to initialize test output database");
        }
    }
    
    if(overall_success)
    {
        Print("✅ All databases initialized successfully");
    }
    else
    {
        Print("❌ Some databases failed to initialize");
    }
    
    return overall_success;
}

MultiDatabaseConfig CDatabaseInitializer::GetDefaultMultiConfig(string main_db, string test_input_db, string test_output_db)
{
    MultiDatabaseConfig config;
    
    config.main_db_config = GetDefaultMainConfig(main_db);
    config.test_input_config = GetDefaultTestInputConfig(test_input_db);
    config.test_output_config = GetDefaultTestOutputConfig(test_output_db);
    
    config.enable_test_mode = true;
    config.validate_all_schemas = true;
    config.sync_schemas = false;
    config.base_directory = "";
    
    return config;
}

//+------------------------------------------------------------------+
//| Populate required DBInfo fields                                  |
//+------------------------------------------------------------------+
bool CDatabaseInitializer::PopulateDBInfo(int db_handle, string broker_name = "", 
                                          string server_name = "", int timezone = -100)
{
    if(db_handle == INVALID_HANDLE)
    {
        SetError("Invalid database handle for DBInfo population");
        return false;
    }
    
    // Auto-detect broker and server if not provided
    if(broker_name == "")
    {
        broker_name = AccountInfoString(ACCOUNT_COMPANY);
        if(broker_name == "") broker_name = "Unknown";
    }
    
    if(server_name == "")
    {
        server_name = AccountInfoString(ACCOUNT_SERVER);
        if(server_name == "") server_name = "Unknown";
    }
    
     if(timezone == -100)
    {
      datetime server_time = TimeTradeServer();
      datetime gmt_time=TimeGMT();
      timezone = ((int)(server_time - gmt_time)) / 3600;
      Print(StringFormat("🕒 Broker timezone detected: GMT %+d", timezone));
    }
 
    // Prepare DBInfo inserts with categories
    string dbinfo_inserts[] = {
        StringFormat("INSERT OR REPLACE INTO DBInfo (key, value, category) VALUES ('broker_name', '%s', 'broker')", broker_name),
        StringFormat("INSERT OR REPLACE INTO DBInfo (key, value, category) VALUES ('server_name', '%s', 'broker')", server_name),
        StringFormat("INSERT OR REPLACE INTO DBInfo (key, value, category) VALUES ('timezone', '%d', 'config')", timezone),
        "INSERT OR REPLACE INTO DBInfo (key, value, category) VALUES ('assets_available', '[]', 'assets')",
        "INSERT OR REPLACE INTO DBInfo (key, value, category) VALUES ('nr_assets_by_timeframe', '{}', 'assets')",
        "INSERT OR REPLACE INTO DBInfo (key, value, category) VALUES ('first_asset_by_timeframe', '{}', 'assets')",
        "INSERT OR REPLACE INTO DBInfo (key, value, category) VALUES ('last_asset_by_timeframe', '{}', 'assets')",
        StringFormat("INSERT OR REPLACE INTO DBInfo (key, value, category) VALUES ('initialized_at', '%d', 'audit')", (int)TimeLocal())
    };
    
    bool success = true;
    for(int i = 0; i < ArraySize(dbinfo_inserts); i++)
    {
        if(!DatabaseExecute(db_handle, dbinfo_inserts[i]))
        {
            SetError(StringFormat("Failed to insert DBInfo: %s", dbinfo_inserts[i]));
            success = false;
        }
    }
    
    if(success && m_verbose_logging)
    {
        Print(StringFormat("✅ DBInfo populated: %s @ %s (GMT %+d)", broker_name, server_name, timezone));
    }
    
    // Verify timezone inserted
    string sql = "SELECT value FROM DBInfo WHERE key = 'timezone'";
    int request = DatabasePrepare(db_handle, sql);
    if(request != INVALID_HANDLE && DatabaseRead(request))
    {
        string tz_value;
        DatabaseColumnText(request, 0, tz_value);
        Print(StringFormat("🔍 DBInfo timezone field confirmed: %s", tz_value));
    }
    DatabaseFinalize(request);

    return success;
}

//+------------------------------------------------------------------+
//| Update asset information in DBInfo                              |
//+------------------------------------------------------------------+
bool CDatabaseInitializer::UpdateAssetInfo(int db_handle, string &assets[], 
                                           string &timeframes[], int &counts[])
{
    if(db_handle == INVALID_HANDLE)
    {
        SetError("Invalid database handle for asset info update");
        return false;
    }
    
    // Build JSON for assets_available
    string assets_json = "[";
    for(int i = 0; i < ArraySize(assets); i++)
    {
        if(i > 0) assets_json += ",";
        assets_json += "\"" + assets[i] + "\"";
    }
    assets_json += "]";
    
    // Build JSON for nr_assets_by_timeframe (simplified)
    string counts_json = "{";
    for(int i = 0; i < ArraySize(timeframes) && i < ArraySize(counts); i++)
    {
        if(i > 0) counts_json += ",";
        counts_json += "\"" + timeframes[i] + "\":" + IntegerToString(counts[i]);
    }
    counts_json += "}";
    
    string updates[] = {
        StringFormat("UPDATE DBInfo SET value='%s', updated_at=strftime('%%s','now') WHERE key='assets_available'", assets_json),
        StringFormat("UPDATE DBInfo SET value='%s', updated_at=strftime('%%s','now') WHERE key='nr_assets_by_timeframe'", counts_json)
    };
    
    bool success = true;
    for(int i = 0; i < ArraySize(updates); i++)
    {
        if(!DatabaseExecute(db_handle, updates[i]))
        {
            success = false;
        }
    }
    
    return success;
}

#endif // DATABASE_INIT_MQH
