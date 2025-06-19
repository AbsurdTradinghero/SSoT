# SSoT System Complete Workflow Documentation

## System Overview
The Single Source of Truth (SSoT) Expert Advisor is built on a **Lean OOP Orchestrator Pattern** where the main EA (`SSoT.mq5`) acts as a pure orchestrator, delegating all business logic to specialized classes.

## Core Architecture Principles
1. **Zero Business Logic in Main EA** - SSoT.mq5 only handles object creation and event delegation
2. **True OOP Delegation** - Each component has clear responsibilities
3. **Modular Design** - Components can be developed/tested independently
4. **Self-Healing System** - Automatic detection and correction of data issues
5. **Dual Database Support** - Live production and test mode capabilities

---

## Component Hierarchy & Responsibilities

### 🎯 **Primary Components**

| Component | File Location | Primary Role | Dependencies |
|-----------|---------------|--------------|--------------|
| **Main EA** | `SSoT.mq5` | Pure orchestrator - zero business logic | All orchestrator components |
| **System Orchestrator** | `Core/SystemOrchestrator.mqh` | Central business logic coordinator | DatabaseManager, ChainOfTrust, SymbolParser |
| **Control Panel** | `UI/ControlPanel.mqh` | User interface and visual monitoring | StatusDisplay, DatabaseManager |
| **Self-Healing Orchestrator** | `SelfHealing/SelfHealingOrchestrator.mqh` | Automatic system healing coordinator | All healing components |
| **New Bar Detector** | `Core/NewBarDetector.mqh` | Real-time market data event detection | ChainOfTrust |

### 🔧 **Support Components**

| Component | File Location | Primary Role | Used By |
|-----------|---------------|--------------|---------|
| **Chain of Trust** | `Core/ChainOfTrust.mqh` | Data validation and integrity | SystemOrchestrator, NewBarDetector |
| **Database Setup** | `Database/DatabaseSetup.mqh` | Database schema initialization | SystemOrchestrator |
| **Database Manager** | `Database/DatabaseManager.mqh` | Database operations abstraction | SystemOrchestrator, ControlPanel |
| **Symbol Parser** | `Utilities/SymbolParser.mqh` | Configuration parsing utilities | SystemOrchestrator |

### 🩺 **Self-Healing Components**

| Component | File Location | Primary Role | Orchestrated By |
|-----------|---------------|--------------|-----------------|
| **Gap Detector** | `SelfHealing/Components/GapDetector.mqh` | Detect missing data gaps | SelfHealingOrchestrator |
| **Integrity Validator** | `SelfHealing/Components/IntegrityValidator.mqh` | Validate data consistency | SelfHealingOrchestrator |
| **Recovery Engine** | `SelfHealing/Components/RecoveryEngine.mqh` | Execute healing operations | SelfHealingOrchestrator |
| **Performance Monitor** | `SelfHealing/Components/PerformanceMonitor.mqh` | Monitor system performance | SelfHealingOrchestrator |

---

## 📋 Complete System Workflow - Chronological Order

### **Phase 1: System Initialization (OnInit)**

| Step | Caller | Called Method/Class | Purpose | Success Action | Failure Action |
|------|-------|---------------------|---------|----------------|----------------|
| 1 | `SSoT.mq5::OnInit()` | `new CSystemOrchestrator()` | Create main business logic coordinator | Continue to step 2 | Return INIT_FAILED |
| 2 | `SSoT.mq5::OnInit()` | `g_system_orchestrator.Initialize()` | Initialize all business logic | Continue to step 3 | Cleanup and INIT_FAILED |
| 2a | `CSystemOrchestrator::Initialize()` | `ParseSymbols()` | Parse symbol configuration | Continue | Return false |
| 2b | `CSystemOrchestrator::Initialize()` | `ParseTimeframes()` | Parse timeframe configuration | Continue | Return false |
| 2c | `CSystemOrchestrator::Initialize()` | `OpenDatabases()` | Open main/test databases | Continue | Return false |
| 2d | `CSystemOrchestrator::Initialize()` | `CDatabaseSetup::SetupAllDatabases()` | Create database schemas | Continue | Return false |
| 2e | `CSystemOrchestrator::Initialize()` | `CChainOfTrust::ValidateDatabase()` | Verify database integrity | Continue | Return false |
| 3 | `SSoT.mq5::OnInit()` | `new CControlPanel()` | Create UI coordinator (if enabled) | Continue to step 4 | Log warning, continue |
| 3a | `SSoT.mq5::OnInit()` | `g_control_panel.InitializeWithOrchestrator()` | Link UI to business logic | Continue | Delete panel, continue |
| 4 | `SSoT.mq5::OnInit()` | `new CSelfHealingOrchestrator()` | Create healing coordinator (if enabled) | Continue to step 5 | Log warning, continue |
| 4a | `SSoT.mq5::OnInit()` | `g_self_healing.Initialize()` | Initialize healing system | Continue | Delete healer, continue |
| 5 | `SSoT.mq5::OnInit()` | `new CNewBarDetector()` | Create market event detector | Continue to step 6 | Continue without detector |
| 5a | `SSoT.mq5::OnInit()` | `g_bar_detector.Initialize()` | Initialize bar detection | Continue | Continue |
| 6 | `SSoT.mq5::OnInit()` | `EventSetTimer(1)` | Start system timer | Return INIT_SUCCEEDED | Return INIT_SUCCEEDED |

### **Phase 2: Runtime Operations**

#### **OnTick() Event Flow**
| Step | Caller | Called Method/Class | Purpose | Frequency |
|------|-------|---------------------|---------|-----------|
| 1 | `SSoT.mq5::OnTick()` | `g_bar_detector.OnTick()` | Detect new market bars | Every tick |
| 1a | `CNewBarDetector::OnTick()` | `CheckForNewBars()` | Check all symbol/timeframe combinations | Every tick |
| 1b | `CNewBarDetector::CheckForNewBars()` | `CSystemOrchestrator::OnNewBar()` | Notify orchestrator of new bars | When new bar detected |

#### **OnTimer() Event Flow (Every 1 Second)**
| Step | Caller | Called Method/Class | Purpose | Condition |
|------|-------|---------------------|---------|-----------|
| 1 | `SSoT.mq5::OnTimer()` | `g_system_orchestrator.OnTimer()` | Execute business logic updates | Always |
| 1a | `CSystemOrchestrator::OnTimer()` | `PerformValidation()` | Validate data integrity | Every ValidationInterval seconds |
| 1b | `CSystemOrchestrator::OnTimer()` | `ExecuteTestModeFlow()` | Run test mode operations | If test mode enabled |
| 1c | `CSystemOrchestrator::OnTimer()` | `SyncMarketData()` | Synchronize with broker data | Continuous |
| 2 | `SSoT.mq5::OnTimer()` | `g_control_panel.OnTimer()` | Update UI displays | If panel enabled |
| 2a | `CControlPanel::OnTimer()` | `UpdateDisplays()` | Refresh visual elements | Every PanelUpdateInterval seconds |
| 2b | `CControlPanel::OnTimer()` | `UpdateStatus()` | Update system status | Continuous |
| 3 | `SSoT.mq5::OnTimer()` | `g_self_healing.OnTimer()` | Run healing checks | If healing enabled |
| 3a | `CSelfHealingOrchestrator::OnTimer()` | `PerformHealthCheck()` | Check system health | Every HealthCheckInterval seconds |
| 3b | `CSelfHealingOrchestrator::OnTimer()` | `ExecuteHealing()` | Fix detected issues | When issues found |

#### **OnChartEvent() Flow**
| Step | Caller | Called Method/Class | Purpose | Trigger |
|------|-------|---------------------|---------|---------|
| 1 | `SSoT.mq5::OnChartEvent()` | `g_control_panel.OnChartEvent()` | Handle UI interactions | User clicks/interactions |
| 2 | `SSoT.mq5::OnChartEvent()` | `g_system_orchestrator.OnChartEvent()` | Handle system events | Chart events needing business logic |

### **Phase 3: Data Processing Workflows**

#### **New Bar Processing**
| Step | Trigger | Component | Action | Next Step |
|------|---------|-----------|--------|-----------|
| 1 | Market tick | `CNewBarDetector` | Compare current bar time with stored | If different, continue |
| 2 | New bar detected | `CNewBarDetector` | Call `OnNewBar(symbol, timeframe)` | Notify orchestrator |
| 3 | New bar notification | `CSystemOrchestrator` | Fetch OHLCV data from broker | Store in database |
| 4 | Data acquired | `CSystemOrchestrator` | Calculate verification hash | Validate with ChainOfTrust |
| 5 | Data validated | `CSystemOrchestrator` | Insert into main database | Update last sync time |
| 6 | Test mode active | `CSystemOrchestrator` | Insert into test input DB | Process enhanced metadata |
| 7 | Enhanced processing | `CSystemOrchestrator` | Calculate indicators/metrics | Store in test output DB |

#### **Self-Healing Workflow**
| Step | Trigger | Component | Action | Remediation |
|------|---------|-----------|--------|-------------|
| 1 | Timer interval | `CSelfHealingOrchestrator` | Run health check | Analyze system state |
| 2 | Health check | `CGapDetector` | Scan for data gaps | Identify missing periods |
| 3 | Health check | `CIntegrityValidator` | Validate data consistency | Check hash mismatches |
| 4 | Health check | `CPerformanceMonitor` | Monitor system performance | Check response times |
| 5 | Issues detected | `CRecoveryEngine` | Execute healing strategy | Fill gaps, fix corruption |
| 6 | Healing complete | `CSelfHealingOrchestrator` | Validate fixes | Re-run health checks |

### **Phase 4: Shutdown (OnDeinit)**

| Step | Caller | Called Method/Class | Purpose | Critical |
|------|-------|---------------------|---------|----------|
| 1 | `SSoT.mq5::OnDeinit()` | `CleanupAndExit()` | Coordinated shutdown | Yes |
| 2 | `CleanupAndExit()` | `g_self_healing.Shutdown()` | Stop healing operations | No |
| 3 | `CleanupAndExit()` | `g_control_panel.Shutdown()` | Close UI components | No |
| 4 | `CleanupAndExit()` | `delete g_bar_detector` | Release detector resources | No |
| 5 | `CleanupAndExit()` | `g_system_orchestrator.Shutdown()` | Close databases, cleanup | Yes |
| 6 | `CleanupAndExit()` | `EventKillTimer()` | Stop system timer | Yes |

---

## 🔄 **Key Interaction Patterns**

### **Orchestrator Pattern**
- **SSoT.mq5** → Creates and delegates to specialized orchestrators
- **CSystemOrchestrator** → Handles all business logic and data operations
- **CSelfHealingOrchestrator** → Manages autonomous system health
- **CControlPanel** → Provides user interface and monitoring

### **Data Flow Pattern**
1. **Market Data** → `CNewBarDetector` → `CSystemOrchestrator` → **Database**
2. **Database** → `CChainOfTrust` → **Validation** → `CSelfHealingOrchestrator`
3. **User Interface** → `CControlPanel` → `CSystemOrchestrator` → **Business Logic**

### **Error Handling Pattern**
1. **Component Error** → **Local Handling** → **Log Warning** → **Continue Operation**
2. **Critical Error** → **Graceful Degradation** → **Self-Healing Trigger** → **Recovery Attempt**
3. **Fatal Error** → **Safe Shutdown** → **Resource Cleanup** → **Error Reporting**

---

## 🎯 **Summary: Who Calls Who**

### **Primary Call Hierarchy**
```
SSoT.mq5 (Main EA)
├── CSystemOrchestrator (Business Logic)
│   ├── CDatabaseManager (Data Operations)
│   ├── CChainOfTrust (Data Validation)
│   ├── CSymbolParser (Configuration)
│   └── CDatabaseSetup (Schema Management)
├── CControlPanel (User Interface)
│   ├── CStatusDisplay (Visual Elements)
│   └── CDatabaseManager (Data Access)
├── CSelfHealingOrchestrator (System Health)
│   ├── CGapDetector (Issue Detection)
│   ├── CIntegrityValidator (Data Integrity)
│   ├── CRecoveryEngine (Problem Resolution)
│   └── CPerformanceMonitor (System Metrics)
└── CNewBarDetector (Market Events)
    └── CChainOfTrust (Data Validation)
```

### **Event-Driven Communication**
- **Market Ticks** → `CNewBarDetector` → `CSystemOrchestrator`
- **Timer Events** → All Orchestrators → Respective Components
- **User Events** → `CControlPanel` → `CSystemOrchestrator`
- **System Issues** → `CSelfHealingOrchestrator` → Recovery Components

This architecture ensures **separation of concerns**, **maintainability**, and **scalability** while providing robust **self-healing capabilities** and comprehensive **data integrity**.
