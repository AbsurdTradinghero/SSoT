//+------------------------------------------------------------------+
//| SSoT Database Engine                                             |
//| Core database operations for Chain of Trust system              |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "3.00"

#ifndef SSOT_DATABASE_ENGINE_MQH
#define SSOT_DATABASE_ENGINE_MQH

#include "DataStructures.mqh"

//+------------------------------------------------------------------+
//| Database Connection Manager                                      |
//| Single Responsibility: Manage SQLite database connections       |
//+------------------------------------------------------------------+
class CDatabaseConnection
{
private:
    int             m_handle;
    string          m_database_path;
    bool            m_is_connected;
    DatabaseConfig  m_config;
    datetime        m_last_activity;
    
public:
                    CDatabaseConnection(void);
                   ~CDatabaseConnection(void);
    
    // Connection management
    bool            Connect(const string database_path, const DatabaseConfig &config);
    bool            Disconnect(void);
    bool            IsConnected(void) const { return m_is_connected; }
    int             GetHandle(void) const { return m_handle; }
    
    // Connection health
    bool            Ping(void);
    datetime        GetLastActivity(void) const { return m_last_activity; }
    
    // Configuration
    bool            SetWALMode(bool enable);
    bool            SetCacheSize(int size_mb);
    bool            SetTimeout(int timeout_ms);
    
private:
    bool            InitializeDatabase(void);
    bool            CreateTables(void);
    void            UpdateActivity(void) { m_last_activity = TimeCurrent(); }
};

//+------------------------------------------------------------------+
//| Schema Manager                                                   |
//| Single Responsibility: Database schema creation and migration   |
//+------------------------------------------------------------------+
class CSchemaManager
{
private:
    CDatabaseConnection* m_connection;
    string          m_table_prefix;
    
public:
                    CSchemaManager(CDatabaseConnection* connection, const string table_prefix = "ssot_");
                   ~CSchemaManager(void);
    
    // Schema operations
    bool            CreateSchema(void);
    bool            DropSchema(void);
    bool            ValidateSchema(void);
    
    // Table management
    bool            CreateCandleTable(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool            CreateMetadataTable(void);
    bool            CreateValidationTable(void);
    
    // Migration support
    bool            GetSchemaVersion(int &version);
    bool            MigrateSchema(int target_version);
    
private:
    string          GetCandleTableName(const string symbol, ENUM_TIMEFRAMES timeframe);
    string          GetCreateCandleTableSQL(const string table_name);
    string          GetCreateMetadataTableSQL(void);
    string          GetCreateValidationTableSQL(void);
};

//+------------------------------------------------------------------+
//| CRUD Operations Manager                                          |
//| Single Responsibility: Create, Read, Update, Delete operations  |
//+------------------------------------------------------------------+
class CCRUDOperations
{
private:
    CDatabaseConnection* m_connection;
    string          m_table_prefix;
    
    // Prepared statements cache
    int             m_stmt_insert_candle;
    int             m_stmt_select_candle;
    int             m_stmt_update_validation;
    int             m_stmt_count_records;
    
public:
                    CCRUDOperations(CDatabaseConnection* connection, const string table_prefix = "ssot_");
                   ~CCRUDOperations(void);
    
    // Candle operations
    OperationResult InsertCandle(const CandleRecord &candle);
    OperationResult UpdateCandle(const CandleRecord &candle);
    OperationResult SelectCandle(const string symbol, ENUM_TIMEFRAMES timeframe, 
                                datetime timestamp, CandleRecord &candle);
    OperationResult DeleteCandle(const string symbol, ENUM_TIMEFRAMES timeframe, datetime timestamp);
    
    // Batch operations
    OperationResult InsertCandleBatch(const CandleRecord &candles[]);
    OperationResult UpdateValidationBatch(const string symbol, ENUM_TIMEFRAMES timeframe,
                                         const long positions[], bool is_validated, bool is_complete);
    
    // Query operations
    OperationResult GetCandleCount(const string symbol, ENUM_TIMEFRAMES timeframe, long &count);
    OperationResult GetTimeRange(const string symbol, ENUM_TIMEFRAMES timeframe,
                                datetime &first_time, datetime &last_time);
    OperationResult GetUnvalidatedCandles(const string symbol, ENUM_TIMEFRAMES timeframe,
                                        CandleRecord &candles[], int max_count = 100);
    
    // Chain operations
    OperationResult GetCandleByPosition(const string symbol, ENUM_TIMEFRAMES timeframe,
                                      long position, CandleRecord &candle);
    OperationResult GetNextUncompletedCandle(const string symbol, ENUM_TIMEFRAMES timeframe,
                                           CandleRecord &candle);
    
private:
    bool            PrepareStatements(void);
    void            CleanupStatements(void);
    string          GetTableName(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool            BindCandleParameters(int statement, const CandleRecord &candle);
};

//+------------------------------------------------------------------+
//| Transaction Manager                                              |
//| Single Responsibility: Database transaction management          |
//+------------------------------------------------------------------+
class CTransactionManager
{
private:
    CDatabaseConnection* m_connection;
    bool            m_in_transaction;
    int             m_operation_count;
    int             m_batch_size;
    datetime        m_transaction_start;
    
public:
                    CTransactionManager(CDatabaseConnection* connection, int batch_size = 100);
                   ~CTransactionManager(void);
    
    // Transaction control
    bool            BeginTransaction(void);
    bool            CommitTransaction(void);
    bool            RollbackTransaction(void);
    
    // Auto-batching
    bool            ExecuteInBatch(void);
    bool            ForceCommit(void);
    
    // Status
    bool            IsInTransaction(void) const { return m_in_transaction; }
    int             GetOperationCount(void) const { return m_operation_count; }
    double          GetTransactionDuration(void) const;
    
    // Batch management
    void            SetBatchSize(int size) { m_batch_size = size; }
    int             GetBatchSize(void) const { return m_batch_size; }
    
private:
    void            ResetCounters(void);
};

//+------------------------------------------------------------------+
//| Database Engine - Main Coordinator                              |
//| Single Responsibility: Coordinate all database operations       |
//+------------------------------------------------------------------+
class CDatabaseEngine
{
private:
    CDatabaseConnection*    m_connection;
    CSchemaManager*         m_schema;
    CCRUDOperations*        m_crud;
    CTransactionManager*    m_transaction;
    
    DatabaseConfig          m_config;
    bool                    m_initialized;
    PerformanceMetrics      m_metrics;
    
public:
                           CDatabaseEngine(void);
                          ~CDatabaseEngine(void);
    
    // Initialization
    bool                   Initialize(const string database_path, const DatabaseConfig &config);
    bool                   Shutdown(void);
    bool                   IsInitialized(void) const { return m_initialized; }
    
    // High-level operations
    OperationResult        StoreCandle(const CandleRecord &candle);
    OperationResult        RetrieveCandle(const string symbol, ENUM_TIMEFRAMES timeframe,
                                        datetime timestamp, CandleRecord &candle);
    OperationResult        ValidateCandle(const string symbol, ENUM_TIMEFRAMES timeframe,
                                        long position, bool is_validated, bool is_complete);
    
    // Batch operations
    OperationResult        StoreCandleBatch(const CandleRecord &candles[]);
    OperationResult        GetUnvalidatedBatch(const string symbol, ENUM_TIMEFRAMES timeframe,
                                             CandleRecord &candles[], int max_count = 100);
    
    // Chain operations
    OperationResult        GetChainStatus(const string symbol, ENUM_TIMEFRAMES timeframe,
                                        long &total_records, long &validated_records, long &completed_records);
    OperationResult        FindChainBreaks(const string symbol, ENUM_TIMEFRAMES timeframe,
                                         long &broken_positions[], int max_breaks = 100);
    
    // Gap detection
    GapDetectionResult     DetectGaps(const string symbol, ENUM_TIMEFRAMES timeframe);
    OperationResult        GetMissingTimeSlots(const string symbol, ENUM_TIMEFRAMES timeframe,
                                             datetime start_time, datetime end_time,
                                             datetime &missing_times[]);
    
    // Performance and monitoring
    PerformanceMetrics     GetMetrics(void) const { return m_metrics; }
    void                   ResetMetrics(void);
    bool                   OptimizeDatabase(void);
    
    // Test mode support
    bool                   SetupTestDatabases(const TestModeConfig &config);
    bool                   SyncTestDatabases(void);
    OperationResult        CompareTestDatabases(void);
    
private:
    bool                   CreateComponents(void);
    void                   DestroyComponents(void);
    void                   UpdateMetrics(const OperationResult &result);
    bool                   ValidateConfiguration(const DatabaseConfig &config);
};

//+------------------------------------------------------------------+
//| Implementation: CDatabaseConnection                             |
//+------------------------------------------------------------------+
CDatabaseConnection::CDatabaseConnection(void) : m_handle(INVALID_HANDLE), 
                                                  m_is_connected(false),
                                                  m_last_activity(0)
{
}

CDatabaseConnection::~CDatabaseConnection(void)
{
    Disconnect();
}

bool CDatabaseConnection::Connect(const string database_path, const DatabaseConfig &config)
{
    if(m_is_connected)
        Disconnect();
    
    m_config = config;
    m_database_path = database_path;
    
    // Open database
    m_handle = DatabaseOpen(database_path, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE);
    
    if(m_handle == INVALID_HANDLE)
    {
        Print("Failed to open database: ", database_path, " Error: ", GetLastError());
        return false;
    }
    
    m_is_connected = true;
    UpdateActivity();
    
    // Initialize database settings
    if(!InitializeDatabase())
    {
        Disconnect();
        return false;
    }
    
    Print("Database connected successfully: ", database_path);
    return true;
}

bool CDatabaseConnection::Disconnect(void)
{
    if(m_handle != INVALID_HANDLE)
    {
        DatabaseClose(m_handle);
        m_handle = INVALID_HANDLE;
    }
    
    m_is_connected = false;
    m_last_activity = 0;
    return true;
}

bool CDatabaseConnection::InitializeDatabase(void)
{
    // Set WAL mode if requested
    if(m_config.enable_wal_mode)
        SetWALMode(true);
    
    // Set cache size
    if(m_config.cache_size_mb > 0)
        SetCacheSize(m_config.cache_size_mb);
    
    // Set timeout
    if(m_config.timeout_ms > 0)
        SetTimeout(m_config.timeout_ms);
    
    // Enable foreign keys if requested
    if(m_config.enable_foreign_keys)
    {
        if(!DatabaseExecute(m_handle, "PRAGMA foreign_keys = ON"))
        {
            Print("Failed to enable foreign keys");
            return false;
        }
    }
    
    return true;
}

bool CDatabaseConnection::SetWALMode(bool enable)
{
    string sql = enable ? "PRAGMA journal_mode = WAL" : "PRAGMA journal_mode = DELETE";
    bool result = DatabaseExecute(m_handle, sql);
    if(result) UpdateActivity();
    return result;
}

bool CDatabaseConnection::SetCacheSize(int size_mb)
{
    string sql = StringFormat("PRAGMA cache_size = -%d", size_mb * 1024); // Negative = KB
    bool result = DatabaseExecute(m_handle, sql);
    if(result) UpdateActivity();
    return result;
}

bool CDatabaseConnection::SetTimeout(int timeout_ms)
{
    string sql = StringFormat("PRAGMA busy_timeout = %d", timeout_ms);
    bool result = DatabaseExecute(m_handle, sql);
    if(result) UpdateActivity();
    return result;
}

bool CDatabaseConnection::Ping(void)
{
    if(!m_is_connected) return false;
    
    bool result = DatabaseExecute(m_handle, "SELECT 1");
    if(result) UpdateActivity();
    return result;
}

#endif // SSOT_DATABASE_ENGINE_MQH
