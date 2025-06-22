//+------------------------------------------------------------------+
//| Database_Scheme.mqh                                             |
//| Single Source of Truth for Database Schema Management           |
//| V6 - Unified Database System                                    |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "6.00"

#ifndef DATABASE_SCHEME_MQH
#define DATABASE_SCHEME_MQH

//+------------------------------------------------------------------+
//| Schema Type Enumeration - Defines all possible schema variations|
//+------------------------------------------------------------------+
enum ENUM_SCHEMA_TYPE
{
    SCHEMA_TYPE_MAIN_PRODUCTION,     // Full production schema with all fields
    SCHEMA_TYPE_TEST_INPUT,          // Simplified input schema for testing (OHLCV only)
    SCHEMA_TYPE_TEST_OUTPUT,         // Full schema for test output validation
    SCHEMA_TYPE_PERFORMANCE,         // Optimized schema for performance testing
    SCHEMA_TYPE_ARCHIVE,             // Archive schema with additional metadata
    SCHEMA_TYPE_MINIMAL,             // Minimal schema for basic operations
    SCHEMA_TYPE_LEGACY_COMPATIBLE    // Compatible with legacy implementations
};

//+------------------------------------------------------------------+
//| Field Type Enumeration for table building                       |
//+------------------------------------------------------------------+
enum ENUM_FIELD_TYPE
{
    FIELD_TYPE_INTEGER,
    FIELD_TYPE_INTEGER_PK_AUTO,     // INTEGER PRIMARY KEY AUTOINCREMENT
    FIELD_TYPE_TEXT,
    FIELD_TYPE_TEXT_NOT_NULL,
    FIELD_TYPE_REAL,
    FIELD_TYPE_REAL_NOT_NULL,
    FIELD_TYPE_INTEGER_NOT_NULL,
    FIELD_TYPE_INTEGER_DEFAULT_0,
    FIELD_TYPE_INTEGER_DEFAULT_NOW,
    FIELD_TYPE_TEXT_PRIMARY_KEY
};

//+------------------------------------------------------------------+
//| Schema Configuration Structure                                   |
//+------------------------------------------------------------------+
struct SchemaConfig
{
    ENUM_SCHEMA_TYPE    schema_type;            // Type of schema to create
    string              table_prefix;           // Table naming prefix (default: "")
    bool                enable_auto_increment;  // Use auto-increment ID
    bool                enable_validation_fields; // Include validation metadata
    bool                enable_hash_fields;     // Include hash fields
    bool                enable_metadata_tracking; // Include metadata tables
    bool                optimize_for_performance; // Performance optimizations
    int                 target_schema_version;  // Schema version
    bool                verbose_logging;        // Detailed logging
};

//+------------------------------------------------------------------+
//| Table Field Definition Structure                                 |
//+------------------------------------------------------------------+
struct FieldDefinition
{
    string              name;           // Field name
    ENUM_FIELD_TYPE     type;          // Field type
    string              default_value;  // Default value (if any)
    bool                is_primary_key; // Primary key flag
    bool                is_unique;      // Unique constraint
    string              foreign_table;  // Foreign key table
    string              foreign_field;  // Foreign key field
};

//+------------------------------------------------------------------+
//| Table Definition Structure                                       |
//+------------------------------------------------------------------+
struct TableDefinition
{
    string              table_name;     // Table name
    FieldDefinition     fields[];       // Field definitions
    string              unique_constraints[]; // Multi-field unique constraints
    string              indexes[];      // Index definitions
};

//+------------------------------------------------------------------+
//| Programmatic SQL Builder Class                                  |
//+------------------------------------------------------------------+
class CTableBuilder
{
private:
    string              m_table_name;
    FieldDefinition     m_fields[];
    string              m_unique_constraints[];
    string              m_indexes[];
    bool                m_if_not_exists;
    
public:
                        CTableBuilder();
                       ~CTableBuilder();
    
    // Table configuration
    void                TableName(string name);
    void                IfNotExists(bool flag = true);
    
    // Field management
    void                AddField(string name, ENUM_FIELD_TYPE type);
    void                AddFieldWithDefault(string name, ENUM_FIELD_TYPE type, string default_value);
    void                AddPrimaryKey(string field_name, bool auto_increment = false);
    void                AddForeignKey(string field, string ref_table, string ref_field);
    
    // Constraints and indexes
    void                AddUniqueConstraint(string fields);
    void                AddIndex(string index_name, string fields);
    
    // SQL generation
    string              BuildCreateTableSQL();
    string              BuildIndexSQL();
    void                Reset();
    
private:
    string              GetFieldTypeSQL(ENUM_FIELD_TYPE type);
    string              GetFieldDefinitionSQL(const FieldDefinition &field);
};

//+------------------------------------------------------------------+
//| Unified Schema Manager - Single Source of Truth                 |
//+------------------------------------------------------------------+
class CSchemaManager
{
private:
    SchemaConfig        m_config;
    CTableBuilder*      m_table_builder;
    string              m_last_error;
    
public:
                        CSchemaManager();
                       ~CSchemaManager();
    
    // Initialization
    bool                Initialize(const SchemaConfig &config);
    string              GetLastError() const { return m_last_error; }
    
    // Main schema creation interface
    bool                CreateCompleteSchema(int db_handle);
    bool                ValidateSchema(int db_handle);
    
    // Individual table creation
    bool                CreateCandleDataTable(int db_handle);
    bool                CreateMetadataTable(int db_handle);
    bool                CreateValidationTable(int db_handle);
    
    // Index creation
    bool                CreateAllIndexes(int db_handle);
    bool                CreatePerformanceIndexes(int db_handle);
    
    // Schema information
    int                 GetSchemaVersion(int db_handle);
    bool                IsSchemaCompatible(int db_handle);
    string              GetSchemaSQL(string table_name = "");
    
    // Utility methods
    static SchemaConfig GetDefaultConfig(ENUM_SCHEMA_TYPE schema_type);
    static string       GetSchemaTypeString(ENUM_SCHEMA_TYPE schema_type);
    
private:
    // Schema building methods
    TableDefinition     BuildCandleDataTableDefinition();
    TableDefinition     BuildMetadataTableDefinition();
    TableDefinition     BuildValidationTableDefinition();
    
    // Internal helpers
    bool                ExecuteSQL(int db_handle, string sql);
    void                SetError(string error_message);
    string              ApplyTablePrefix(string table_name);
};

//+------------------------------------------------------------------+
//| Implementation: CTableBuilder                                   |
//+------------------------------------------------------------------+
CTableBuilder::CTableBuilder() : m_if_not_exists(true)
{
    ArrayResize(m_fields, 0);
    ArrayResize(m_unique_constraints, 0);
    ArrayResize(m_indexes, 0);
}

CTableBuilder::~CTableBuilder()
{
    Reset();
}

void CTableBuilder::TableName(string name)
{
    m_table_name = name;
}

void CTableBuilder::IfNotExists(bool flag = true)
{
    m_if_not_exists = flag;
}

void CTableBuilder::AddField(string name, ENUM_FIELD_TYPE type)
{
    int size = ArraySize(m_fields);
    ArrayResize(m_fields, size + 1);
    
    m_fields[size].name = name;
    m_fields[size].type = type;
    m_fields[size].default_value = "";
    m_fields[size].is_primary_key = (type == FIELD_TYPE_INTEGER_PK_AUTO || type == FIELD_TYPE_TEXT_PRIMARY_KEY);
    m_fields[size].is_unique = false;
    m_fields[size].foreign_table = "";
    m_fields[size].foreign_field = "";
}

void CTableBuilder::AddFieldWithDefault(string name, ENUM_FIELD_TYPE type, string default_value)
{
    AddField(name, type);
    int last_index = ArraySize(m_fields) - 1;
    m_fields[last_index].default_value = default_value;
}

void CTableBuilder::AddUniqueConstraint(string fields)
{
    int size = ArraySize(m_unique_constraints);
    ArrayResize(m_unique_constraints, size + 1);
    m_unique_constraints[size] = fields;
}

void CTableBuilder::AddIndex(string index_name, string fields)
{
    int size = ArraySize(m_indexes);
    ArrayResize(m_indexes, size + 1);
    m_indexes[size] = StringFormat("CREATE INDEX IF NOT EXISTS %s ON %s (%s)", index_name, m_table_name, fields);
}

string CTableBuilder::GetFieldTypeSQL(ENUM_FIELD_TYPE type)
{
    switch(type)
    {
        case FIELD_TYPE_INTEGER:             return "INTEGER";
        case FIELD_TYPE_INTEGER_PK_AUTO:     return "INTEGER PRIMARY KEY AUTOINCREMENT";
        case FIELD_TYPE_TEXT:                return "TEXT";
        case FIELD_TYPE_TEXT_NOT_NULL:       return "TEXT NOT NULL";
        case FIELD_TYPE_REAL:                return "REAL";
        case FIELD_TYPE_REAL_NOT_NULL:       return "REAL NOT NULL";
        case FIELD_TYPE_INTEGER_NOT_NULL:    return "INTEGER NOT NULL";
        case FIELD_TYPE_INTEGER_DEFAULT_0:   return "INTEGER DEFAULT 0";
        case FIELD_TYPE_INTEGER_DEFAULT_NOW: return "INTEGER DEFAULT (strftime('%s', 'now'))";
        case FIELD_TYPE_TEXT_PRIMARY_KEY:    return "TEXT PRIMARY KEY";
        default:                             return "TEXT";
    }
}

string CTableBuilder::GetFieldDefinitionSQL(const FieldDefinition &field)
{
    string sql = field.name + " " + GetFieldTypeSQL(field.type);
    
    if(field.default_value != "" && field.type != FIELD_TYPE_INTEGER_DEFAULT_0 && field.type != FIELD_TYPE_INTEGER_DEFAULT_NOW)
    {
        sql += " DEFAULT " + field.default_value;
    }
    
    if(field.foreign_table != "" && field.foreign_field != "")
    {
        sql += StringFormat(" REFERENCES %s(%s)", field.foreign_table, field.foreign_field);
    }
    
    return sql;
}

string CTableBuilder::BuildCreateTableSQL()
{
    if(m_table_name == "" || ArraySize(m_fields) == 0)
        return "";
    
    string sql = "CREATE TABLE ";
    if(m_if_not_exists) sql += "IF NOT EXISTS ";
    sql += m_table_name + " (";
    
    // Add field definitions
    for(int i = 0; i < ArraySize(m_fields); i++)
    {
        if(i > 0) sql += ", ";
        sql += GetFieldDefinitionSQL(m_fields[i]);
    }
    
    // Add unique constraints
    for(int i = 0; i < ArraySize(m_unique_constraints); i++)
    {
        sql += ", UNIQUE(" + m_unique_constraints[i] + ")";
    }
    
    sql += ");";
    return sql;
}

string CTableBuilder::BuildIndexSQL()
{
    string sql = "";
    for(int i = 0; i < ArraySize(m_indexes); i++)
    {
        if(i > 0) sql += " ";
        sql += m_indexes[i] + ";";
    }
    return sql;
}

void CTableBuilder::Reset()
{
    m_table_name = "";
    ArrayResize(m_fields, 0);
    ArrayResize(m_unique_constraints, 0);
    ArrayResize(m_indexes, 0);
    m_if_not_exists = true;
}

//+------------------------------------------------------------------+
//| Implementation: CSchemaManager                                  |
//+------------------------------------------------------------------+
CSchemaManager::CSchemaManager()
{
    m_table_builder = new CTableBuilder();
    m_last_error = "";
}

CSchemaManager::~CSchemaManager()
{
    if(m_table_builder != NULL)
    {
        delete m_table_builder;
        m_table_builder = NULL;
    }
}

bool CSchemaManager::Initialize(const SchemaConfig &config)
{
    m_config = config;
    m_last_error = "";
    
    if(m_config.verbose_logging)
    {
        Print("🔧 SchemaManager: Initializing with schema type: ", GetSchemaTypeString(config.schema_type));
    }
    
    return true;
}

SchemaConfig CSchemaManager::GetDefaultConfig(ENUM_SCHEMA_TYPE schema_type)
{
    SchemaConfig config;
    config.schema_type = schema_type;
    config.table_prefix = "";
    config.target_schema_version = 1;
    config.verbose_logging = true;
    
    switch(schema_type)
    {
        case SCHEMA_TYPE_MAIN_PRODUCTION:
            config.enable_auto_increment = true;
            config.enable_validation_fields = true;
            config.enable_hash_fields = true;
            config.enable_metadata_tracking = true;
            config.optimize_for_performance = false;
            break;
            
        case SCHEMA_TYPE_TEST_INPUT:
            config.enable_auto_increment = false;
            config.enable_validation_fields = false;
            config.enable_hash_fields = false;
            config.enable_metadata_tracking = false;
            config.optimize_for_performance = true;
            break;
            
        case SCHEMA_TYPE_TEST_OUTPUT:
            config.enable_auto_increment = false;
            config.enable_validation_fields = true;
            config.enable_hash_fields = true;
            config.enable_metadata_tracking = false;
            config.optimize_for_performance = false;
            break;
            
        case SCHEMA_TYPE_PERFORMANCE:
            config.enable_auto_increment = false;
            config.enable_validation_fields = false;
            config.enable_hash_fields = true;
            config.enable_metadata_tracking = false;
            config.optimize_for_performance = true;
            break;
            
        default:
            config.enable_auto_increment = true;
            config.enable_validation_fields = true;
            config.enable_hash_fields = true;
            config.enable_metadata_tracking = true;
            config.optimize_for_performance = false;
            break;
    }
    
    return config;
}

string CSchemaManager::GetSchemaTypeString(ENUM_SCHEMA_TYPE schema_type)
{
    switch(schema_type)
    {
        case SCHEMA_TYPE_MAIN_PRODUCTION:     return "MAIN_PRODUCTION";
        case SCHEMA_TYPE_TEST_INPUT:          return "TEST_INPUT";
        case SCHEMA_TYPE_TEST_OUTPUT:         return "TEST_OUTPUT";
        case SCHEMA_TYPE_PERFORMANCE:         return "PERFORMANCE";
        case SCHEMA_TYPE_ARCHIVE:             return "ARCHIVE";
        case SCHEMA_TYPE_MINIMAL:             return "MINIMAL";
        case SCHEMA_TYPE_LEGACY_COMPATIBLE:   return "LEGACY_COMPATIBLE";
        default:                              return "UNKNOWN";
    }
}

bool CSchemaManager::CreateCompleteSchema(int db_handle)
{
    if(db_handle == INVALID_HANDLE)
    {
        SetError("Invalid database handle");
        return false;
    }
    
    if(m_config.verbose_logging)
    {
        Print("🏗️ SchemaManager: Creating complete schema (", GetSchemaTypeString(m_config.schema_type), ")");
    }
    
    // Create main candle data table
    if(!CreateCandleDataTable(db_handle))
    {
        SetError("Failed to create candle data table");
        return false;
    }
    
    // Create metadata table if enabled
    if(m_config.enable_metadata_tracking)
    {
        if(!CreateMetadataTable(db_handle))
        {
            SetError("Failed to create metadata table");
            return false;
        }
    }
    
    // Create validation table if validation fields are enabled
    if(m_config.enable_validation_fields)
    {
        if(!CreateValidationTable(db_handle))
        {
            SetError("Failed to create validation table");
            return false;
        }
    }
    
    // Create all indexes
    if(!CreateAllIndexes(db_handle))
    {
        SetError("Failed to create indexes");
        return false;
    }
    
    if(m_config.verbose_logging)
    {
        Print("✅ SchemaManager: Complete schema created successfully");
    }
    
    return true;
}

TableDefinition CSchemaManager::BuildCandleDataTableDefinition()
{    TableDefinition table;
    table.table_name = "AllCandleData";
    
    // Clear arrays
    ArrayResize(table.fields, 0);
    ArrayResize(table.unique_constraints, 0);
    ArrayResize(table.indexes, 0);
    
    int field_count = 0;
    
    // Auto-increment ID (if enabled)
    if(m_config.enable_auto_increment)
    {
        ArrayResize(table.fields, ++field_count);
        table.fields[field_count-1].name = "id";
        table.fields[field_count-1].type = FIELD_TYPE_INTEGER_PK_AUTO;
    }
    
    // Core OHLCV fields (always present)
    string core_fields[] = {"asset_symbol", "timeframe", "timestamp", "open", "high", "low", "close", "tick_volume", "real_volume"};
    ENUM_FIELD_TYPE core_types[] = {FIELD_TYPE_TEXT_NOT_NULL, FIELD_TYPE_TEXT_NOT_NULL, FIELD_TYPE_INTEGER_NOT_NULL, 
                                   FIELD_TYPE_REAL_NOT_NULL, FIELD_TYPE_REAL_NOT_NULL, FIELD_TYPE_REAL_NOT_NULL, 
                                   FIELD_TYPE_REAL_NOT_NULL, FIELD_TYPE_INTEGER_NOT_NULL, FIELD_TYPE_INTEGER_NOT_NULL};
    
    for(int i = 0; i < ArraySize(core_fields); i++)
    {
        ArrayResize(table.fields, ++field_count);
        table.fields[field_count-1].name = core_fields[i];
        table.fields[field_count-1].type = core_types[i];
    }
    
    // Hash field (if enabled)
    if(m_config.enable_hash_fields)
    {
        ArrayResize(table.fields, ++field_count);
        table.fields[field_count-1].name = "hash";
        table.fields[field_count-1].type = FIELD_TYPE_TEXT_NOT_NULL;
    }
    
    // Validation fields (if enabled)
    if(m_config.enable_validation_fields)
    {
        string validation_fields[] = {"is_validated", "is_complete", "is_InitialSynced", "validation_time"};
        ENUM_FIELD_TYPE validation_types[] = {FIELD_TYPE_INTEGER_DEFAULT_0, FIELD_TYPE_INTEGER_DEFAULT_0, FIELD_TYPE_INTEGER_DEFAULT_0, FIELD_TYPE_INTEGER_DEFAULT_0};
        
        for(int i = 0; i < ArraySize(validation_fields); i++)
        {
            ArrayResize(table.fields, ++field_count);
            table.fields[field_count-1].name = validation_fields[i];
            table.fields[field_count-1].type = validation_types[i];
        }
    }
    
    // Unique constraint
    ArrayResize(table.unique_constraints, 1);
    table.unique_constraints[0] = "asset_symbol, timeframe, timestamp";
    
    // Standard indexes
    ArrayResize(table.indexes, 0);
    int index_count = 0;
    
    ArrayResize(table.indexes, ++index_count);
    table.indexes[index_count-1] = "idx_symbol_timeframe ON " + table.table_name + "(asset_symbol, timeframe)";
    
    ArrayResize(table.indexes, ++index_count);
    table.indexes[index_count-1] = "idx_timestamp ON " + table.table_name + "(timestamp)";
    
    // Performance indexes (if enabled)
    if(m_config.optimize_for_performance)
    {
        ArrayResize(table.indexes, ++index_count);
        table.indexes[index_count-1] = "idx_symbol_timestamp ON " + table.table_name + "(asset_symbol, timestamp)";
        
        if(m_config.enable_validation_fields)
        {
            ArrayResize(table.indexes, ++index_count);
            table.indexes[index_count-1] = "idx_validated ON " + table.table_name + "(is_validated)";
            
            ArrayResize(table.indexes, ++index_count);
            table.indexes[index_count-1] = "idx_initial_sync ON " + table.table_name + "(is_InitialSynced)";
            
            ArrayResize(table.indexes, ++index_count);
            table.indexes[index_count-1] = "idx_validation_status ON " + table.table_name + "(is_validated, is_complete, is_InitialSynced)";
        }
    }
    
    return table;
}

bool CSchemaManager::CreateCandleDataTable(int db_handle)
{
    TableDefinition table = BuildCandleDataTableDefinition();
    
    // Build and execute CREATE TABLE
    m_table_builder.Reset();
    m_table_builder.TableName(table.table_name);
    
    for(int i = 0; i < ArraySize(table.fields); i++)
    {
        m_table_builder.AddField(table.fields[i].name, table.fields[i].type);
    }
    
    for(int i = 0; i < ArraySize(table.unique_constraints); i++)
    {
        m_table_builder.AddUniqueConstraint(table.unique_constraints[i]);
    }    string create_sql = m_table_builder.BuildCreateTableSQL();
    if(!ExecuteSQL(db_handle, create_sql))
    {
        SetError("Failed to create table: " + table.table_name);
        return false;
    }
    
    // Create indexes (skip validation indexes for now to debug)
    for(int i = 0; i < ArraySize(table.indexes); i++)
    {
        // Skip validation-related indexes if they're causing issues
        if(StringFind(table.indexes[i], "is_validated") >= 0)
        {
            if(m_config.verbose_logging)
            {
                Print("⚠️ Skipping validation index: ", table.indexes[i]);
            }
            continue;
        }
        
        string index_sql = "CREATE INDEX IF NOT EXISTS " + table.indexes[i];
        if(!ExecuteSQL(db_handle, index_sql))
        {
            SetError("Failed to create index: " + table.indexes[i]);
            return false;
        }
    }
    
    if(m_config.verbose_logging)
    {
        Print("✅ Created table: ", table.table_name, " with ", ArraySize(table.fields), " fields and ", ArraySize(table.indexes), " indexes");
    }
    
    return true;
}

TableDefinition CSchemaManager::BuildMetadataTableDefinition()
{    TableDefinition table;
    table.table_name = "DBInfo";
    
    ArrayResize(table.fields, 5);
    
    table.fields[0].name = "key";
    table.fields[0].type = FIELD_TYPE_TEXT_PRIMARY_KEY;
    table.fields[0].default_value = "";
    
    table.fields[1].name = "value";
    table.fields[1].type = FIELD_TYPE_TEXT_NOT_NULL;
    table.fields[1].default_value = "";
    
    table.fields[2].name = "category";
    table.fields[2].type = FIELD_TYPE_TEXT;
    table.fields[2].default_value = "'general'";
    
    table.fields[3].name = "created_at";
    table.fields[3].type = FIELD_TYPE_INTEGER_DEFAULT_NOW;
    table.fields[3].default_value = "";
    
    table.fields[4].name = "updated_at";
    table.fields[4].type = FIELD_TYPE_INTEGER_DEFAULT_NOW;
    table.fields[4].default_value = "";
    
    // Add category index
    ArrayResize(table.indexes, 1);
    table.indexes[0] = "idx_dbinfo_category ON " + table.table_name + "(category)";
    
    ArrayResize(table.unique_constraints, 0);
    
    return table;
}

bool CSchemaManager::CreateMetadataTable(int db_handle)
{
    TableDefinition table = BuildMetadataTableDefinition();
    
    m_table_builder.Reset();
    m_table_builder.TableName(table.table_name);
    
    for(int i = 0; i < ArraySize(table.fields); i++)
    {
        // For types that have built-in defaults, don't use AddFieldWithDefault
        if(table.fields[i].type == FIELD_TYPE_INTEGER_DEFAULT_NOW || 
           table.fields[i].type == FIELD_TYPE_INTEGER_DEFAULT_0)
        {
            m_table_builder.AddField(table.fields[i].name, table.fields[i].type);
        }
        else if(table.fields[i].default_value != "")
        {
            m_table_builder.AddFieldWithDefault(table.fields[i].name, table.fields[i].type, table.fields[i].default_value);
        }
        else
        {
            m_table_builder.AddField(table.fields[i].name, table.fields[i].type);
        }
    }
    
    // Add indexes
    for(int i = 0; i < ArraySize(table.indexes); i++)
    {
        string index_parts[];
        StringSplit(table.indexes[i], " ON ", index_parts);
        if(ArraySize(index_parts) >= 2)
        {
            string index_name = index_parts[0];
            string fields_part = index_parts[1];
            StringReplace(fields_part, table.table_name + "(", "");
            StringReplace(fields_part, ")", "");
            m_table_builder.AddIndex(index_name, fields_part);
        }
    }
    
    string create_sql = m_table_builder.BuildCreateTableSQL();
    if(!ExecuteSQL(db_handle, create_sql))
    {
        SetError("Failed to create metadata table");
        return false;
    }
    
    // Create indexes
    string index_sql = m_table_builder.BuildIndexSQL();
    if(index_sql != "")
    {
        ExecuteSQL(db_handle, index_sql);
    }
    
    // Insert initial metadata with proper categories
    string metadata_inserts[] = {
        StringFormat("INSERT OR REPLACE INTO %s (key, value, category) VALUES ('database_version', '%d', 'config')", 
                    table.table_name, m_config.target_schema_version),
        StringFormat("INSERT OR REPLACE INTO %s (key, value, category) VALUES ('schema_type', '%s', 'config')", 
                    table.table_name, GetSchemaTypeString(m_config.schema_type)),
        StringFormat("INSERT OR REPLACE INTO %s (key, value, category) VALUES ('created_at', strftime('%%s', 'now'), 'audit')", 
                    table.table_name)
    };
    
    for(int i = 0; i < ArraySize(metadata_inserts); i++)
    {
        ExecuteSQL(db_handle, metadata_inserts[i]);
    }
    
    if(m_config.verbose_logging)
    {
        Print("✅ Created metadata table: ", table.table_name);
    }
    
    return true;
}

bool CSchemaManager::CreateValidationTable(int db_handle)
{
    // For now, validation metadata is included in the main table
    // This method is placeholder for future separate validation tracking
    return true;
}

bool CSchemaManager::CreateAllIndexes(int db_handle)
{
    // Indexes are created along with tables in this implementation
    return true;
}

bool CSchemaManager::ExecuteSQL(int db_handle, string sql)
{
    if(m_config.verbose_logging)
    {
        Print("🔍 SQL: ", sql);
    }
    
    bool result = DatabaseExecute(db_handle, sql);
    if(!result)
    {
        string error_msg = "SQL execution failed: " + sql;
        
        // Get SQLite error message if available
        int error_code = GetLastError();
        if(error_code != 0)
        {
            error_msg += " (Error code: " + IntegerToString(error_code) + ")";
        }
        
        Print("❌ ", error_msg);
        SetError(error_msg);
    }
    
    return result;
}

void CSchemaManager::SetError(string error_message)
{
    m_last_error = error_message;
    Print("❌ SchemaManager Error: ", error_message);
}

string CSchemaManager::ApplyTablePrefix(string table_name)
{
    if(m_config.table_prefix == "")
        return table_name;
    else
        return m_config.table_prefix + table_name;
}

string CSchemaManager::GetSchemaSQL(string table_name = "")
{
    if(table_name == "" || table_name == "AllCandleData")
    {
        TableDefinition table = BuildCandleDataTableDefinition();
        
        m_table_builder.Reset();
        m_table_builder.TableName(table.table_name);
        
        for(int i = 0; i < ArraySize(table.fields); i++)
        {
            m_table_builder.AddField(table.fields[i].name, table.fields[i].type);
        }
        
        for(int i = 0; i < ArraySize(table.unique_constraints); i++)
        {
            m_table_builder.AddUniqueConstraint(table.unique_constraints[i]);
        }
        
        return m_table_builder.BuildCreateTableSQL();
    }
    
    return "";
}

int CSchemaManager::GetSchemaVersion(int db_handle)
{
    string sql = StringFormat("SELECT value FROM %s WHERE key = 'database_version'", ApplyTablePrefix("DBInfo"));
    int request = DatabasePrepare(db_handle, sql);
    
    if(request == INVALID_HANDLE)
        return 0;
    
    int version = 0;
    if(DatabaseRead(request))
    {
        string version_str;
        DatabaseColumnText(request, 0, version_str);
        version = (int)StringToInteger(version_str);
    }
    
    DatabaseFinalize(request);
    return version;
}

bool CSchemaManager::IsSchemaCompatible(int db_handle)
{
    int current_version = GetSchemaVersion(db_handle);
    return (current_version >= m_config.target_schema_version);
}

bool CSchemaManager::ValidateSchema(int db_handle)
{
    if (db_handle <= 0)
    {
        SetError("Invalid database handle for schema validation");
        return false;
    }    // Check if core tables exist
    string tables[] = {
        "AllCandleData",
        "DBInfo"
    };
    
    for (int i = 0; i < ArraySize(tables); i++)
    {
        string sql = "SELECT name FROM sqlite_master WHERE type='table' AND name='" + tables[i] + "'";
        int request = DatabasePrepare(db_handle, sql);
        
        if (request < 0)
        {
            SetError("Failed to prepare table existence query for: " + tables[i]);
            return false;
        }
        
        bool table_exists = false;
        if (DatabaseRead(request))
        {
            table_exists = true;
        }
        
        DatabaseFinalize(request);
        
        if (!table_exists)
        {
            SetError("Required table missing: " + tables[i]);
            return false;
        }
    }
    
    // Validate schema version compatibility
    if (!IsSchemaCompatible(db_handle))
    {
        SetError("Schema version incompatible");
        return false;
    }
    
    return true;
}

#endif // DATABASE_SCHEME_MQH
