# **Module: DatabaseManager**

Version: 1.00  
Author: ATH Trading System  
File: DatabaseManager.mqh

## **1\. Overview**

The **Database Manager** (CDatabaseManager) is a comprehensive class that serves as the primary interface for all database interactions within the SSoT (Single Source of Truth) system. It abstracts the complexity of managing database connections, executing queries, and ensuring data is stored in a structured and consistent manner.

A key feature of this manager is its dual-mode capability. It can operate in a standard production mode, interacting with a single main database, or be initialized in a "Test Mode" which utilizes separate input and output databases. This design is crucial for validating data processing pipelines, allowing for the clear separation of raw input data and processed, validated output data during testing and verification cycles.

Its responsibilities include:

1. **Connection Management:** Opening, closing, and providing handles for one or more database connections.  
2. **Schema Enforcement:** Creating and validating the necessary table structures and indexes upon initialization.  
3. **Data Persistence:** Providing standardized methods for inserting and retrieving market data.  
4. **Integrity and Maintenance:** Offering utilities for data validation and database optimization.

## **2\. Public API Reference**

### **Initialization & Connection Management**

bool Initialize(string main\_db\_name, bool enable\_test\_mode \= false, string test\_input\_db \= "", string test\_output\_db \= "")

* **Description:** Initializes the database manager. It opens the main database connection and, if enable\_test\_mode is true, opens connections to the test input and output databases. It also ensures the required table structures are created.  
* **Parameters:**  
  * main\_db\_name: The file name of the primary production database (e.g., "SourceDB.sqlite").  
  * enable\_test\_mode: A flag to activate the test mode.  
  * test\_input\_db: File name for the test database that holds raw input data.  
  * test\_output\_db: File name for the test database that holds processed output data.  
* **Returns:** true if all required connections are successfully opened and structured.

void CloseAllDatabases()

* **Description:** Properly closes all open database connections. This is automatically called by the destructor.

### **Getters**

int GetMainHandle() const

* **Description:** Returns the handle to the main production database.  
* **Returns:** An integer handle or INVALID\_HANDLE.

int GetTestInputHandle() const

* **Description:** In test mode, returns the handle to the test input database.  
* **Returns:** An integer handle or INVALID\_HANDLE.

int GetTestOutputHandle() const

* **Description:** In test mode, returns the handle to the test output database.  
* **Returns:** An integer handle or INVALID\_HANDLE.

bool IsTestModeActive() const

* **Description:** Checks if the manager was initialized in test mode.  
* **Returns:** true if test mode is active.

### **Data Operations**

bool InsertMarketData(...)

* **Description:** Inserts or replaces a single bar of market data into the **main database**.  
* **Parameters:** Standard OHLCVT data, plus an optional verification\_hash.

bool GetLastBarTime(const string symbol, ENUM\_TIMEFRAMES timeframe, datetime \&last\_time)

* **Description:** Retrieves the timestamp of the most recent bar for a given symbol and timeframe from the **main database**.  
* **Parameters:** last\_time is passed by reference and will contain the result.  
* **Returns:** true if a time was successfully retrieved.

bool GetMarketData(...)

* **Description:** Retrieves an array of market data for a specific symbol, timeframe, and date range from the **main database**.  
* **Parameters:** Arrays are passed by reference and will be filled with data.

bool InsertTestInputData(...)

* **Description:** In test mode, inserts a bar of raw OHLCVT data into the **test input database**.

bool InsertTestOutputData(...)

* **Description:** In test mode, inserts a bar of processed data, including metadata like hash and validation flags, into the **test output database**.

### **Utility & Maintenance**

bool ValidateDatabaseIntegrity()

* **Description:** Performs a basic check to ensure the main tables exist in the **main database**.  
* **Returns:** true if the schema appears valid.

bool OptimizeDatabases()

* **Description:** Runs VACUUM and ANALYZE commands on all active databases to improve performance and reclaim disk space.  
* **Returns:** true if the optimization commands execute successfully.

string GetDatabaseStats()

* **Description:** Returns a formatted string containing the record count for all active databases.

bool ExecuteQuery(const string query, int database\_handle \= INVALID\_HANDLE)

* **Description:** Executes a raw SQL query on a specified database. If no handle is provided, it defaults to the main database.  
* **Returns:** true if the query execution succeeds.

## **3\. Database Schema**

### **3.1. Main Database (main\_db)**

This is the primary data store for production use.

Table: AllCandleData  
This table holds the complete, validated market data, considered the "Single Source of Truth".

| Column | Type | Description |
| :---- | :---- | :---- |
| id | INTEGER | Primary key for the row. |
| asset\_symbol | TEXT | The financial instrument (e.g., "EURUSD"). |
| timeframe | TEXT | The chart period (e.g., "M1", "H1"). |
| timestamp | INTEGER | The UNIX timestamp for the start of the bar. |
| open | REAL | The opening price. |
| high | REAL | The highest price. |
| low | REAL | The lowest price. |
| close | REAL | The closing price. |
| tick\_volume | INTEGER | The tick volume. |
| real\_volume | INTEGER | The real volume, if available. |
| hash | TEXT | A hash of the candle data for integrity verification. |
| is\_validated | INTEGER | A boolean flag (0 or 1\) indicating if the data has been verified. |
| is\_complete | INTEGER | A boolean flag indicating if the bar is considered complete. |
| validation\_time | INTEGER | The UNIX timestamp of the last validation. |

Table: DBInfo  
This table stores key-value metadata about the database itself.

| Column | Type | Description |
| :---- | :---- | :---- |
| key | TEXT | The name of the metadata field (e.g., "database\_version"). |
| value | TEXT | The value of the metadata field. |
| updated\_at | INTEGER | The UNIX timestamp of the last update. |

### **3.2. Test Mode Databases**

**Test Input Database (test\_input\_db)**

* **Purpose:** To store raw, unprocessed data that serves as the input for a data validation or processing pipeline.  
* **Schema:** Contains a simplified AllCandleData table with only the core OHLCVT columns (asset\_symbol, timeframe, timestamp, open, high, low, close, tick\_volume, real\_volume).

**Test Output Database (test\_output\_db)**

* **Purpose:** To store the results of the data pipeline. This allows for direct comparison against the expected output.  
* **Schema:** Contains a full AllCandleData table identical to the main database schema, including all metadata columns (hash, is\_validated, etc.).

## **4\. Workflow & Usage Example**

### **Step 1: Initialization**

Initialize the manager in OnInit. Choose between production or test mode.

\#include \<DatabaseManager.mqh\>

CDatabaseManager g\_DBManager;  
bool g\_IsTestRun \= true; // Set via input parameter

void OnInit()  
{  
    bool success \= false;  
    if (g\_IsTestRun)  
    {  
        // Initialize in test mode with separate input/output databases  
        success \= g\_DBManager.Initialize(  
            "SourceDB.sqlite",   
            true,   
            "TestInput.sqlite",   
            "TestOutput.sqlite"  
        );  
    }  
    else  
    {  
        // Initialize in standard production mode  
        success \= g\_DBManager.Initialize("SourceDB.sqlite");  
    }

    if (\!success)  
    {  
        Print("Database Manager failed to initialize\!");  
        ExpertRemove();  
    }  
}

### **Step 2: Using the Manager**

Use the class methods to interact with the database(s). The manager directs the operations to the correct database based on the method called.

void OnTick()  
{  
    // Example: Inserting data  
    MqlRates rates\[\];  
    CopyRates(\_Symbol, \_Period, 0, 1, rates);

    if (g\_DBManager.IsTestModeActive())  
    {  
        // In a test, you might insert raw data to the input DB  
        g\_DBManager.InsertTestInputData(  
            \_Symbol, \_Period, rates\[0\].time, rates\[0\].open, rates\[0\].high,  
            rates\[0\].low, rates\[0\].close, rates\[0\].tick\_volume  
        );  
    }  
    else  
    {  
        // In production, insert fully processed data to the main DB  
        g\_DBManager.InsertMarketData(  
            \_Symbol, \_Period, rates\[0\].time, rates\[0\].open, rates\[0\].high,  
            rates\[0\].low, rates\[0\].close, rates\[0\].tick\_volume, 0, "some\_hash"  
        );  
    }  
}

### **Step 3: Cleanup**

The destructor handles closing connections, but it's good practice to have an explicit cleanup call in OnDeinit.

void OnDeinit(const int reason)  
{  
    g\_DBManager.CloseAllDatabases();  
    Print("Database connections closed.");  
}  
