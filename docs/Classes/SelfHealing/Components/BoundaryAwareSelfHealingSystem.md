# **Module: BoundaryAwareSelfHealingSystem**

Version: 1.00  
Author: ATH Trading System  
File: BoundaryAwareSelfHealingSystem.mqh

## **1\. Overview**

The **Boundary-Aware Self-Healing System** is a high-level orchestration engine designed to ensure and maintain a perfect 1-to-1 synchronization of historical data between a trading broker and a local database. It integrates several lower-level modules to create a fully automated, hands-off data integrity solution.

This system operates by:

1. **Respecting Broker Boundaries:** It uses the CBrokerDataBoundaryManager to understand the exact data history that a broker can provide, preventing futile attempts to download data that doesn't exist.  
2. **Detecting Gaps:** It employs the CBoundaryAwareGapDetector to precisely identify any missing segments of data within the known broker boundaries.  
3. **Healing Gaps:** It utilizes the CBoundaryConstrainedHealer to intelligently download and insert the missing data, thus "healing" the gaps.

The entire process is managed through a state machine, which can be run automatically at set intervals or triggered manually. The system is highly configurable and provides detailed statistics and reporting on its operations, offering full transparency into the health of the historical dataset.

## **2\. Core Components & Data Structures**

### **2.1. Integrated Modules**

| Module | Header | Role |
| :---- | :---- | :---- |
| CBrokerDataBoundaryManager | BrokerDataBoundaryManager.mqh | Detects the earliest and latest available data from the broker. |
| CBoundaryAwareGapDetector | BoundaryAwareGapDetector.mqh | Identifies missing bar data within the established broker boundaries. |
| CBoundaryConstrainedHealer | BoundaryConstrainedHealer.mqh | Downloads and inserts missing data to fill the detected gaps. |

### **2.2. BOUNDARY\_HEALING\_STATUS Enumeration**

This enum defines the possible states of the system's state machine.

| State | Description |
| :---- | :---- |
| BOUNDARY\_HEALING\_IDLE | The system is initialized and waiting for a task. |
| BOUNDARY\_HEALING\_SCANNING | A high-level scan operation is in progress. |
| BOUNDARY\_HEALING\_DETECTING\_BOUNDARIES | Actively querying the broker for data limits. |
| BOUNDARY\_HEALING\_DETECTING\_GAPS | Actively scanning the database for missing bars. |
| BOUNDARY\_HEALING\_HEALING\_GAPS | Actively downloading data to fill identified gaps. |
| BOUNDARY\_HEALING\_VALIDATING | Re-checking sync percentages after a healing operation. |
| BOUNDARY\_HEALING\_COMPLETE | The last operation finished successfully. |
| BOUNDARY\_HEALING\_ERROR | An error occurred during the last operation. |

### **2.3. SBoundaryHealingStats Structure**

This structure aggregates key performance indicators and statistics for the system.

| Member | Type | Description |
| :---- | :---- | :---- |
| total\_symbols\_tracked | int | Count of symbol/timeframe pairs being monitored. |
| total\_boundaries\_detected | int | Number of pairs for which boundaries were successfully detected. |
| total\_gaps\_found | int | Total number of data gaps identified across all pairs. |
| total\_gaps\_healed | int | Total number of gaps successfully filled. |
| total\_healing\_operations | int | Count of all healing attempts (successful or not). |
| successful\_operations | int | Count of successful healing operations. |
| overall\_sync\_percentage | double | The average data completeness across all tracked pairs. |
| last\_full\_scan | datetime | Timestamp of the last comprehensive scan. |
| system\_start\_time | datetime | Timestamp when the system was initialized. |
| current\_operation | string | A human-readable description of the current task. |

## **3\. Public API Reference**

### **System Management**

bool Initialize(int database\_handle)

* **Description:** Initializes the system and its core components. **Must be called first.**  
* **Parameters:** database\_handle (int): A valid handle to an open database.  
* **Returns:** true on success.

bool RegisterSymbolTimeframe(const string symbol, ENUM\_TIMEFRAMES tf)

* **Description:** Adds a symbol/timeframe pair to the list of assets to be monitored and healed.  
* **Returns:** true on success.

bool Start()

* **Description:** Starts the system and performs an initial full scan.  
* **Returns:** true if the system starts successfully.

bool Stop()

* **Description:** Halts automated processing.  
* **Returns:** true.

void Cleanup()

* **Description:** Releases all resources and deletes component instances.

### **Main Operations**

bool PerformFullSystemScan()

* **Description:** Executes the complete workflow: Boundary Detection \-\> Gap Detection \-\> Healing \-\> Validation. This is the most comprehensive operation.  
* **Returns:** true if the entire scan completes without critical errors.

bool PerformIncrementalHealing()

* **Description:** A lighter operation designed for frequent execution. It detects and heals a small number of high-priority gaps.  
* **Returns:** true on success.

### **Status and Reporting**

BOUNDARY\_HEALING\_STATUS GetStatus() const

* **Description:** Returns the current status of the system's state machine.

SBoundaryHealingStats GetStatistics() const

* **Description:** Returns the structure containing all current system statistics.

string GenerateSystemReport()

* **Description:** Creates a detailed, multi-line report of the system's status and performance metrics.

string GenerateQuickStatus()

* **Description:** Generates a concise, single-line status string suitable for chart comments or logging.

### **Configuration**

void EnableAutoHealing(bool enable)

* **Description:** Enables or disables the automated healing process that runs on a timer.

void SetScanInterval(int seconds)

* **Description:** Sets the time in seconds between automated healing cycles.

void SetMaxGapsPerCycle(int max\_gaps)

* **Description:** Defines the maximum number of gaps to heal in a single PerformFullSystemScan cycle.

void SetAggressiveMode(bool aggressive)

* **Description:** If true, PerformIncrementalHealing will attempt to heal more gaps per cycle.

### **Manual Controls**

bool ForceCompleteResync(const string symbol, ENUM\_TIMEFRAMES tf)

* **Description:** Triggers a focused, full resynchronization for a single specified pair.

## **4\. Workflow & Usage Example**

This outlines the standard operational flow for integrating the system into an MQL5 Expert Advisor.

### **Step 1: Initialization**

Initialize the system in OnInit with a valid database handle.

\#include \<BoundaryAwareSelfHealingSystem.mqh\>

CBoundaryAwareSelfHealingSystem g\_HealingSystem;  
int g\_db\_handle;

void OnInit()  
{  
    // Assume DatabaseOpen() provides a valid handle  
    g\_db\_handle \= DatabaseOpen("History.sqlite");  
    if (\!g\_HealingSystem.Initialize(g\_db\_handle))  
    {  
        Print("Healing System Failed to Initialize\!");  
        ExpertRemove();  
        return;  
    }  
}

### **Step 2: Configuration and Registration**

Configure the system and register the assets you want to maintain.

void OnPostInit() // A custom function or part of OnInit  
{  
    g\_HealingSystem.SetScanInterval(900); // Scan every 15 minutes  
    g\_HealingSystem.EnableAutoHealing(true);

    g\_HealingSystem.RegisterSymbolTimeframe("EURUSD", PERIOD\_H1);  
    g\_HealingSystem.RegisterSymbolTimeframe("XAUUSD", PERIOD\_M5);  
      
    // Start the system to perform an initial scan  
    g\_HealingSystem.Start();   
}

### **Step 3: Automated Processing (OnTimer)**

The main automated loop should be called from within the OnTimer event.

void OnTimer()  
{  
    // The system's internal timer logic will decide if it's time to run  
    g\_HealingSystem.ProcessAutoHealing();  
      
    // Update a chart comment with the latest status  
    Comment(g\_HealingSystem.GenerateQuickStatus());  
}

### **Step 4: Cleanup**

Release resources when the EA is terminated.

void OnDeinit(const int reason)  
{  
    g\_HealingSystem.Cleanup();  
    DatabaseClose(g\_db\_handle);  
}

## **5\. Dependencies**

* **BrokerDataBoundaryManager.mqh**: Must be present in the same directory or an include path.  
* **BoundaryAwareGapDetector.mqh**: Must be present in the same directory or an include path.  
* **BoundaryConstrainedHealer.mqh**: Must be present in the same directory or an include path.  
* **Database Environment**: Requires a valid database connection handle and a pre-defined table schema that the underlying components can interact with.