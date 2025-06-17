# SSoT (Single Source of Truth) Chain-of-Trust Database System
## Comprehensive Engineering Documentation v5.0

---

## 🎯 **EXECUTIVE SUMMARY**

The **SSoT (Single Source of Truth) Chain-of-Trust Database System** is a sophisticated, enterprise-grade financial data integrity framework that creates and maintains a **perfect, verifiable mirror** of broker data. Unlike simple data collection systems, SSoT implements a **blockchain-inspired validation mechanism** that ensures absolute data integrity through cryptographic hashing and chain validation.

**System Version**: v4.10  
**Architecture**: Lean Orchestrator + Advanced Control Panel  
**Core Innovation**: Chain-of-Trust validation with dual-flag integrity system  
**Control Interface**: Visual Test Panel (Gold Standard)  

---

## 🏗️ **SYSTEM ARCHITECTURE**

### **The Chain-of-Trust Concept**

The SSoT system solves the fundamental challenge in algorithmic trading: **"How do you trust your data?"** It creates a local database that is cryptographically proven to be a perfect replica of the broker's Single Source of Truth.

#### **Three Pillars of Data Integrity**

**1. Smart Data Acquisition**
- **Initial Backfill**: Deep historical data fetch with immediate cryptographic hashing
- **Real-Time Monitoring**: Continuous new candle detection and acquisition
- **Enriched Storage**: Each candle stored with SHA-256 hash and dual validation flags

**2. Blockchain-Inspired Validation**
- **Content Validation (`is_validated`)**: Cryptographic proof that candle content matches broker data
- **Chain Integrity (`is_complete`)**: Sequential validation ensuring unbroken timeline
- **Cascade Invalidation**: Any change in chain forces re-validation of all subsequent candles

**3. Autonomous Self-Healing**
- **Continuous Monitoring**: Automated detection of gaps and inconsistencies
- **Targeted Backfilling**: Precise fetching of only missing data
- **Autonomous Recovery**: System restarts automatically detect and repair disruptions

---

## 📁 **PROJECT STRUCTURE**

```
d:\VSCode\MT5Dev3/
├── src/SSoT_EA.mq5                     # Development source
├── mt5/
│   ├── MetaEditor64.exe                # MQL5 compiler
│   ├── terminal64.exe                  # MT5 platform
│   └── MQL5/
│       ├── Experts/
│       │   └── SSoT.mq5               # Main Orchestrator EA (v4.10)
│       └── Include/SSoT/              # Comprehensive Framework
│           ├── Core/                   # Core system components
│           │   ├── CoreOrchestrator.mqh
│           │   ├── DatabaseManager.mqh
│           │   └── DataFetcher.mqh
│           ├── Testing/                # Control Panel System
│           │   ├── TestPanel_Simple.mqh    # 🏆 GOLD STANDARD CONTROL PANEL
│           │   ├── TestPanel_Visual.mqh
│           │   └── MonitorTestEngine.mqh
│           ├── DatabaseSetup.mqh       # Database schema management
│           ├── LegacyCore.mqh         # Proven algorithms
│           └── SymbolParser.mqh       # Multi-symbol support
├── build/
│   └── ide_exact_compile.ps1          # Recommended compilation
├── docs/Marton/                       # Engineering documentation
└── databases/                         # 3-Tier Database System
    ├── sourcedb.sqlite                # Main Chain-of-Trust database
    ├── SSoT_input.db                 # Test mode input (OHLCTV)
    └── SSoT_output.db                # Test mode output (enhanced)
```

---

## 🎮 **CONTROL PANEL: THE GOLD STANDARD**

### **TestPanel_Simple.mqh - The System's Command Center**

The **Test Panel** is the **sole point of control** for the entire SSoT sandbox test environment. It serves as the **gold standard** interface providing comprehensive monitoring and control capabilities.

#### **Core Capabilities**

**🔍 Real-Time Database Monitoring**
```mql5
// Complete database status display
void DisplayDatabaseOverview(void);
void DisplayAllCandleData(int db_handle, string db_name);
void DisplayAssetData(int db_handle, string table_name, string symbol);
```

**🎛️ Dual-Mode Operation**
- **LIVE MODE**: Monitors single production database (`sourcedb.sqlite`)
- **TEST MODE**: Controls 3-database test flow for validation

**📊 Comprehensive Status Display**
```
[DATA] ================================================================
[DATA] SSoT TEST PANEL v4.06 - DATABASE MONITOR
[DATA] ================================================================
[DATA] Mode: [TEST] TEST MODE
[DATA] DATABASE 1: MAIN (sourcedb.sqlite)
[DATA]   DBInfo: SQLite Local Database, GMT+1, 1,247 entries
[DATA]   AllCandleData: EURUSD M1: 500, M5: 247, H1: 124
[DATA] DATABASE 2: TEST INPUT (SSoT_input.db) 
[DATA] DATABASE 3: TEST OUTPUT (SSoT_output.db)
[DATA] ================================================================
```

**🎯 Visual Panel Interface**
- Real-time database status display
- Interactive button controls
- Clipboard export functionality
- Chart event handling for user interaction

---

## 🧪 **3-TIER TEST ENVIRONMENT**

### **The Sandbox Test Flow**

The SSoT system implements a sophisticated **3-database test environment** that validates data integrity through controlled flows:

```
1. PRODUCTION DATA → sourcedb.sqlite (Main Chain-of-Trust DB)
   ↓ Controlled Test Flow
2. sourcedb.sqlite → SSoT_input.db (Raw OHLCTV Test Data)
   ↓ Enhancement Processing  
3. SSoT_input.db → SSoT_output.db (Enhanced with Metadata)
   ↓ Validation & Integrity Checks
4. VERIFICATION: Chain integrity validation across all databases
```

#### **Database Specifications**

**1. sourcedb.sqlite (Main Production)**
- **Purpose**: Primary Chain-of-Trust database
- **Content**: Full OHLCTV data with cryptographic hashes
- **Validation**: Dual-flag system (`is_validated`, `is_complete`)
- **Status**: Real-time broker synchronization

**2. SSoT_input.db (Test Input)**
- **Purpose**: Isolated test environment for raw data
- **Content**: Clean OHLCTV data extracted from main database
- **Usage**: Test algorithm performance without affecting production
- **Size**: ~40KB (optimized test dataset)

**3. SSoT_output.db (Test Output)**
- **Purpose**: Enhanced test results with metadata
- **Content**: Processed data with additional calculated fields
- **Features**: Integrity checks, validation timestamps
- **Size**: ~48KB (enhanced with metadata)

---

## 💻 **MAIN ORCHESTRATOR EA (SSoT.mq5)**

### **Lean Architecture Design**

The main EA is a **lean orchestrator** that delegates complex operations to specialized modules while maintaining minimal core logic:

```mql5
//+------------------------------------------------------------------+
//| SSoT.mq5 - Single Source of Truth EA v4.10                      |
//| Truly lean orchestrator with only essential event handlers      |
//+------------------------------------------------------------------+

// Key Features:
// ✅ 3-Database connection management with fallback strategies
// ✅ Intelligent database opening (READ/WRITE → READONLY → LOCAL)
// ✅ Test Panel integration (CTestPanel)
// ✅ Configurable symbols and timeframes
// ✅ Autonomous timer-based monitoring
// ✅ Chart event forwarding to control panel
```

#### **Configuration Parameters**

```mql5
input group "=== Main Configuration ==="
input string    SystemSymbols = "EURUSD,GBPUSD,USDJPY";        // Multi-symbol support
input string    SystemTimeframes = "M1,M5,M15,H1";             // Multi-timeframe monitoring
input bool      EnableTestMode = true;                        // 3-database test mode

input group "=== Database Settings ==="
input string    MainDatabase = "sourcedb.sqlite";              // Chain-of-Trust database
input string    TestInputDB = "SSoT_input.db";                 // Test input database
input string    TestOutputDB = "SSoT_output.db";               // Test output database

input group "=== Processing Settings ==="
input int       MaxBarsToFetch = 1000;                         // Historical depth
input bool      EnableLogging = true;                          // Detailed logging
input int       ValidationInterval = 300;                      // Validation frequency
input int       TestFlowInterval = 3600;                       // Test flow frequency
```

#### **Core Event Handlers**

**OnInit() - System Initialization**
- Multi-database connection with intelligent fallback strategies
- Test Panel instantiation and initialization
- Symbol/timeframe parsing and validation
- Comprehensive database status reporting

**OnTimer() - Main Processing Loop**
- Test Panel status updates every 30 seconds
- Database overview display through control panel
- Autonomous monitoring and maintenance

**OnChartEvent() - User Interaction**
- Forwards all chart events to Test Panel for button handling
- Enables interactive control through visual interface

---

## 🔧 **DEVELOPMENT WORKFLOW**

### **Compilation (IDE-Exact Method)**

```powershell
# Recommended compilation approach
.\build\ide_exact_compile.ps1 "SSoT.mq5"

# Expected output:
# ✅ SSoT.mq5 - COMPILATION SUCCESSFUL
# 📊 Generated: SSoT.ex5 (Size: ~28KB)
# 🔍 Errors: 0, Warnings: 0
```

### **Deployment Process**

**1. System Launch**
```powershell
# Start MT5 with portable configuration
.\mt5\terminal64.exe /portable
```

**2. EA Deployment**
- Attach `SSoT.ex5` to any chart
- Configure input parameters as needed
- Test Panel automatically initializes

**3. Monitoring Interface**
- **Console Output**: Detailed logging in MT5 Experts tab
- **Visual Panel**: Interactive status display on chart
- **Real-time Updates**: Automatic 30-second refresh cycles

---

## 📊 **VALIDATION MECHANISMS**

### **Dual-Flag Integrity System**

Every candle in the Chain-of-Trust database maintains two critical validation flags:

#### **Flag 1: `is_validated` (Content Integrity)**
- **Purpose**: Cryptographic verification that candle content matches broker data
- **Mechanism**: SHA-256 hash comparison between stored and broker data
- **Validation**: `true` only when hash verification passes
- **Failure Action**: Immediate overwrite with broker's "truth" + re-hash

#### **Flag 2: `is_complete` (Chain Integrity)**
- **Purpose**: Sequential validation ensuring unbroken timeline
- **Mechanism**: Candle at position `t` can only be complete if position `t-1` is fully validated
- **Chain Rule**: `is_complete = true` ONLY IF predecessor is (`is_validated = true` AND `is_complete = true`)
- **Cascade Effect**: Any chain break invalidates ALL subsequent candles

### **Autonomous Self-Healing**

**Gap Detection Algorithm**
```
Expected Candles = (Latest Timestamp - Earliest Timestamp) / Timeframe Interval
If (Actual Record Count ≠ Expected Count) → Gap Detected
```

**Self-Healing Process**
1. **Gap Identification**: Precise missing data detection
2. **Targeted Fetching**: Request only missing candles from broker
3. **Chain Integration**: Insert new candles with `flags = false`
4. **Validation Cycle**: Autonomous validation of new data
5. **Chain Reconstruction**: Re-establish integrity chain

---

## 🎯 **TEST PANEL AS GOLD STANDARD**

### **Why Test Panel is the Control Center**

The **TestPanel_Simple.mqh** serves as the **sole authoritative interface** for the entire SSoT system because:

**🏆 Comprehensive Monitoring**
- Real-time database status across all 3 databases
- Detailed breakdown by symbol, timeframe, and entry count
- Automatic detection of database connectivity issues
- Visual and console-based status reporting

**🎛️ Centralized Control**
- Single interface for LIVE/TEST mode switching
- Interactive buttons for system operations
- Clipboard export for external analysis
- Chart event handling for user commands

**📈 Gold Standard Reporting**
- Authoritative source of system health status
- Standardized output format for all monitoring
- Consistent database information display
- Reliable validation status reporting

**🔄 Autonomous Operation**
- Self-updating displays every 30 seconds
- Automatic database reconnection handling
- Intelligent fallback for display failures
- Continuous health monitoring

---

## 📋 **ENGINEERING HANDOVER CHECKLIST**

### **✅ System Verification**
- [ ] SSoT.mq5 compiles successfully (0 errors, 0 warnings)
- [ ] All 3 databases accessible (sourcedb, input, output)
- [ ] Test Panel initializes and displays status
- [ ] Visual panel creates successfully on chart
- [ ] Database connections established with fallback handling

### **✅ Operational Validation**
- [ ] LIVE mode: Single database monitoring active
- [ ] TEST mode: 3-database flow operational
- [ ] Console logging: Detailed status updates every 30 seconds
- [ ] Visual panel: Interactive interface responding to events
- [ ] Clipboard export: Report generation functional

### **✅ Documentation Access**
- [ ] Complete engineering documentation in `docs/Marton/`
- [ ] Compilation scripts available in `build/`
- [ ] All source code accessible in proper directories
- [ ] Database files present and accessible

---

## 🚀 **OPERATIONAL EXCELLENCE**

### **Performance Metrics**
- **Database Connections**: 3 simultaneous with intelligent fallback
- **Update Frequency**: 30-second monitoring cycles
- **Compilation Time**: < 5 seconds for complete system
- **Memory Footprint**: Minimal with efficient database handling
- **Error Recovery**: Autonomous with comprehensive logging

### **System Reliability**
- **Database Resilience**: READ/WRITE → READONLY → LOCAL fallback strategy
- **Connection Recovery**: Automatic reconnection after disruptions
- **Data Integrity**: Cryptographic validation with blockchain-inspired chain
- **Self-Healing**: Targeted gap detection and repair
- **Audit Trail**: Complete logging of all operations and validations

---

## 📞 **SYSTEM STATUS**

**Current Version**: SSoT v4.10  
**Status**: Production Ready  
**Test Environment**: Fully Operational  
**Control Panel**: Gold Standard Active  
**Documentation**: Complete & Current  
**Last Updated**: June 15, 2025  

---

*This document represents the complete, current state of the SSoT Chain-of-Trust Database System. The Test Panel serves as the authoritative control interface and gold standard for all system operations.*
