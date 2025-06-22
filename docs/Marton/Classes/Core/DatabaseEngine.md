# **Module: DatabaseEngine**

Version: 3.00  
Author: ATH Trading System  
File: SSoT\_Database\_Engine.mqh

## **1\. Overview**

The **Database Engine** (CDatabaseEngine) represents the heart of the SSoT (Single Source of Truth) system's data layer. It is a high-level coordinator class that orchestrates all database activities by managing a suite of specialized, single-responsibility components.

This version (3.00) marks a complete architectural redesign, moving away from monolithic managers to a clean, component-based model. This approach enhances testability, maintainability, and clarity by delegating specific tasks to dedicated classes.

The engine's primary responsibilities are:

1. **Lifecycle Management:** Handling the initialization, configuration, and shutdown of all underlying database components.  
2. **Coordination:** Acting as the single public-facing entry point for all database operations, routing requests to the appropriate component (e.g., schema, CRUD, transactions).  
3. **High-Level Abstraction:** Providing a simplified API for complex operations like chain validation, gap detection, and batch data storage.  
4. **Performance & Metrics:** Aggregating performance metrics from database operations and providing methods for database maintenance.  
5. **Test Mode Orchestration:** Managing the setup and synchronization of a three-database environment for rigorous data pipeline testing.

## **2\. Architecture: The Component Model**

The CDatabaseEngine does not perform low-level database work itself. Instead, it coordinates four specialized components, each with a single, clear responsibility:

| Component | Class | Responsibility |
| :---- | :---- | :---- |
| **Connection Manager** | CDatabaseConnection | Manages the low-level SQLite connection, including opening/closing the file, setting performance PRAGMAs (e.g., WAL mode, cache size), and handling disconnects. |
| **Schema Manager** | CSchemaManager | Manages the database schema. It is responsible for creating, dropping, and validating all tables and indexes. It will also handle future schema migrations. |
| **CRUD Manager** | CCRUDOperations | Handles all Create, Read, Update, and Delete (CRUD) operations. It uses prepared statements for performance and provides methods for all data interactions, from single candles to complex queries. |
| **Transaction Manager** | CTransactionManager | Manages database transactions (BEGIN, COMMIT, ROLLBACK). It includes logic for auto-batching multiple operations into a single transaction to maximize performance. |

This separation of concerns is the foundational design principle of the engine.

## **3\. Public API Reference**

### **Initialization & Shutdown**

bool Initialize(const string database\_path, const DatabaseConfig \&config)

* **Description:** Initializes the entire database engine. It creates all underlying components, establishes a connection using CDatabaseConnection, and validates the schema using CSchemaManager. **This is the primary entry point and must be called first.**  
* **Returns:** true if all components initialize successfully.

bool Shutdown()

* **Description:** Properly disconnects from the database and destroys all components. Called automatically by the destructor.  
* **Returns:** true on success.

### **High-Level Data Operations**

These methods provide a simplified interface for common tasks.

OperationResult StoreCandle(const CandleRecord \&candle)

* **Description:** Stores a single candle record in the database.

OperationResult RetrieveCandle(...)

* **Description:** Retrieves a single candle record by its timestamp.

OperationResult ValidateCandle(...)

* **Description:** Updates the validation flags (is\_validated, is\_complete) for a specific candle, identified by its position (row ID).

### **Batch Operations**

These methods leverage the CTransactionManager for high-performance bulk operations.

OperationResult StoreCandleBatch(const CandleRecord \&candles\[\])

* **Description:** Stores an array of candle records in a single, optimized transaction.

OperationResult GetUnvalidatedBatch(...)

* **Description:** Retrieves a batch of candle records that have not yet been marked as fully validated, ready for processing.

### **Chain & Gap Operations**

OperationResult GetChainStatus(...)

* **Description:** Gets a summary of the chain's health, including total, validated, and completed record counts.

OperationResult FindChainBreaks(...)

* **Description:** Scans the data and returns the positions (row IDs) of any records that break the chain of trust.

GapDetectionResult DetectGaps(...)

* **Description:** Performs a comprehensive gap analysis on the data for a given instrument.

### **Performance & Maintenance**

PerformanceMetrics GetMetrics() const

* **Description:** Returns a structure containing the latest performance metrics.

bool OptimizeDatabase()

* **Description:** Runs maintenance commands (VACUUM, ANALYZE) on the database to improve performance.

### **Test Mode Support**

bool SetupTestDatabases(const TestModeConfig \&config)

* **Description:** Initializes the engine with two additional test databases (SSoT\_in and SSoT\_out).

bool SyncTestDatabases()

* **Description:** Orchestrates the flow of data between the three databases for pipeline validation.

OperationResult CompareTestDatabases()

* **Description:** Compares the final state of the output database against the source database to verify integrity.

## **4\. Workflow & Usage Example**

This example demonstrates how to use the CDatabaseEngine in a standard MQL5 Expert Advisor.

### **Step 1: Initialization**

In OnInit, create an instance of the engine and initialize it with the database path and configuration.

\#include \<SSoT/Database/DatabaseEngine.mqh\>

// Global instance of the entire database engine  
CDatabaseEngine g\_DatabaseEngine;

void OnInit()  
{  
    // Configure the database settings  
    DatabaseConfig config;  
    config.enable\_wal\_mode \= true;  
    config.cache\_size\_mb \= 256;  
    config.timeout\_ms \= 5000;

    string db\_path \= TerminalInfoString(TERMINAL\_COMMONDATA\_PATH) \+ "\\\\SSoT\_V3.sqlite";

    // Initialize the engine. This single call sets up all components.  
    if (\!g\_DatabaseEngine.Initialize(db\_path, config))  
    {  
        Print("CRITICAL: Database Engine failed to initialize\!");  
        ExpertRemove();  
        return;  
    }  
}

### **Step 2: Storing Data**

Use the high-level methods to interact with the database. The engine handles the complexity of transactions and CRUD operations internally.

void StoreNewCandles(CandleRecord \&candles\_to\_store\[\])  
{  
    // The engine handles beginning and committing the transaction.  
    OperationResult result \= g\_DatabaseEngine.StoreCandleBatch(candles\_to\_store);

    if (result.success)  
    {  
        PrintFormat("%d candles stored successfully in %.2f ms.",   
            result.rows\_affected, result.duration\_ms);  
    }  
    else  
    {  
        Print("Failed to store candle batch. Error: ", result.error\_message);  
    }  
}

### **Step 3: Checking Chain Health**

Periodically check the integrity of your data.

void OnTimer()  
{  
    long total \= 0, validated \= 0, completed \= 0;  
      
    // Get the status for a specific data series  
    OperationResult result \= g\_DatabaseEngine.GetChainStatus("EURUSD", PERIOD\_H1, total, validated, completed);  
      
    if (result.success)  
    {  
        PrintFormat("EURUSD H1 Chain Status: %d Total, %d Validated, %d Complete",  
            total, validated, completed);  
    }  
}

### **Step 4: Shutdown**

The destructor handles cleanup, but an explicit call in OnDeinit is good practice.

void OnDeinit(const int reason)  
{  
    g\_DatabaseEngine.Shutdown();  
    Print("Database Engine shut down.");  
}

## **5\. Dependencies**

* **\<SSoT/Core/DataStructures.mqh\>**: Requires the central data structures file which defines DatabaseConfig, CandleRecord, OperationResult, etc.