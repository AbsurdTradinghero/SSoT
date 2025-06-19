# **Module: BrokerDataBoundaryManager**

Version: 1.00  
Author: ATH Trading System  
File: BrokerDataBoundaryManager.mqh

## **1\. Overview**

The **Broker Data Boundary Manager** is a critical infrastructure component designed to ensure the integrity and completeness of historical market data. It acts as a bridge between the data available directly from the trading broker and the data stored in a local database.

Its core responsibility is to detect the absolute start and end boundaries of the broker's available data for any given financial instrument and timeframe. It then compares these boundaries against the data present in the local database to verify a perfect 1-to-1 synchronization. This process is fundamental for preventing trading algorithms, backtests, or analytical tools from operating on incomplete datasets, which could lead to flawed conclusions or trading decisions.

The manager provides a clear and immediate status on data synchronization, identifies gaps, and offers the necessary intelligence to drive data-healing or downloading processes.

## **2\. Class & Data Structure**

### **2.1. CBrokerDataBoundaryManager Class**

This is the main class that encapsulates all the logic for managing, detecting, and reporting on data boundaries. It serves as the primary interface for any system component needing to query data availability and synchronization status.

### **2.2. SBrokerBoundary Structure**

This data structure is the heart of the manager. It holds a snapshot of the data landscape for a single symbol/timeframe pair.

| Member | Type | Description |
| :---- | :---- | :---- |
| symbol | string | The financial instrument (e.g., "EURUSD"). |
| timeframe | ENUM\_TIMEFRAMES | The chart period (e.g., PERIOD\_H1). |
| first\_available | datetime | Earliest bar timestamp available from the broker. |
| last\_available | datetime | Latest bar timestamp available from the broker. |
| first\_in\_db | datetime | Earliest bar timestamp in the local database. |
| last\_in\_db | datetime | Latest bar timestamp in the local database. |
| total\_broker\_bars | int | Total number of bars the broker provides in the window. |
| total\_db\_bars | int | Total number of bars the database holds in the window. |
| is\_synchronized | bool | **True** if the database is 100% in sync with the broker. |
| last\_boundary\_check | datetime | Timestamp of the last time these boundaries were verified. |

## **3\. Public API Reference**

This section details the public methods available to interact with the CBrokerDataBoundaryManager.

### **Initialization & Cleanup**

bool Initialize(int database\_handle)

* **Description:** Initializes the manager with a live database connection. **Must be called first.**  
* **Parameters:**  
  * database\_handle (int): A valid handle to an open database.  
* **Returns:** true on success, false on failure.

void Cleanup()

* **Description:** Resets the manager and releases resources.

### **Boundary Management**

bool RegisterSymbolTimeframe(const string symbol, ENUM\_TIMEFRAMES tf)

* **Description:** Registers a symbol/timeframe pair for tracking and performs an initial boundary check.  
* **Returns:** true if registration is successful.

bool UpdateBoundaries(const string symbol, ENUM\_TIMEFRAMES tf)

* **Description:** Forces a refresh of the boundary information for a specific pair. Useful after data-healing operations.  
* **Returns:** true if the update is successful.

bool UpdateAllBoundaries()

* **Description:** Iterates and updates all registered pairs.  
* **Returns:** true if all updates are successful.

### **Synchronization Validation**

bool IsCompletelyInSync(const string symbol, ENUM\_TIMEFRAMES tf)

* **Description:** A quick check to see if a pair's data is complete.  
* **Returns:** true if synchronized, otherwise false.

double GetSyncPercentage(const string symbol, ENUM\_TIMEFRAMES tf)

* **Description:** Calculates the data completeness as a percentage.  
* **Returns:** A double from 0.0 to 100.0.

### **Information & Reporting**

SBrokerBoundary GetBoundaryInfo(const string symbol, ENUM\_TIMEFRAMES tf)

* **Description:** Retrieves the full SBrokerBoundary data structure for a pair.  
* **Returns:** The SBrokerBoundary struct.

string GenerateBoundaryReport(const string symbol, ENUM\_TIMEFRAMES tf)

* **Description:** Creates a human-readable report for a single pair's sync status.  
* **Returns:** A formatted string report.

string GenerateGlobalSyncReport()

* **Description:** Creates a summary report for all registered pairs.  
* **Returns:** A formatted string report.

## **4\. Workflow & Usage Example**

This outlines the standard operational flow for integrating the manager into an MQL5 Expert Advisor.

### **Step 1: Initialization**

Initialize the manager during the EA's OnInit phase with a valid database handle.

\#include \<BrokerDataBoundaryManager.mqh\>

CBrokerDataBoundaryManager g\_BoundaryManager;  
int g\_db\_handle;

void OnInit()  
{  
    // Assume DatabaseOpen() provides a valid handle  
    g\_db\_handle \= DatabaseOpen("History.sqlite");  
    if (\!g\_BoundaryManager.Initialize(g\_db\_handle))  
    {  
        Print("Boundary Manager Failed to Initialize\!");  
        ExpertRemove();  
        return;  
    }  
}

### **Step 2: Register Symbols**

Register all required symbol/timeframe pairs after initialization.

void OnReady() // Can be a custom function or part of OnInit  
{  
    g\_BoundaryManager.RegisterSymbolTimeframe("EURUSD", PERIOD\_H1);  
    g\_BoundaryManager.RegisterSymbolTimeframe("GBPUSD", PERIOD\_H1);  
}

### **Step 3: Validate Sync Status**

Before executing critical logic, check if the required data is synchronized.

void OnTick()  
{  
    if (\!g\_BoundaryManager.IsCompletelyInSync("EURUSD", PERIOD\_H1))  
    {  
        Print("EURUSD H1 data is out of sync. Pausing operations.");  
          
        // Optional: Generate a report for diagnostics  
        string report \= g\_BoundaryManager.GenerateBoundaryReport("EURUSD", PERIOD\_H1);  
        Print(report);  
          
        // Here you would trigger a data download/healing module  
        return;  
    }  
      
    // Continue with normal trading logic  
}

### **Step 4: Cleanup**

Release resources when the EA is terminated.

void OnDeinit(const int reason)  
{  
    g\_BoundaryManager.Cleanup();  
    DatabaseClose(g\_db\_handle);  
}

## **5\. Dependencies & System Requirements**

* **Database Schema:** A SQL-based database is required. The manager assumes a table named market\_data with at least the following columns: symbol (TEXT), timeframe (INTEGER), and timestamp (INTEGER/DATETIME).  
* **MQL5 Environment:** This module is built for the MQL5 language and relies on its standard library functions (CopyRates, Database\*, etc.).  
* **External Healing Logic:** This manager is a diagnostic tool. It **identifies** data gaps but does not fix them. A separate module for downloading and inserting missing historical data is required to act on the information provided by this manager.