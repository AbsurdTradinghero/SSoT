//+------------------------------------------------------------------+
//| SSoT Real-time Monitor & Test Framework                         |
//| Dual-database testing and real-time monitoring system          |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "3.00"

#ifndef SSOT_MONITOR_TEST_ENGINE_MQH
#define SSOT_MONITOR_TEST_ENGINE_MQH

#include "Core\DataStructures.mqh"
#include "Core\DatabaseEngine.mqh"
#include "Core\ChainManager.mqh"

//+------------------------------------------------------------------+
//| Test Database Manager                                           |
//| Single Responsibility: Manage dual-database test environment   |
//+------------------------------------------------------------------+
class CTestDatabaseManager
{
private:
    CDatabaseEngine*   m_input_db;      // Simulated broker database (SSoT_input)
    CDatabaseEngine*   m_output_db;     // Our target database (SSoT_output)
    bool              m_own_databases;
    
    TestModeConfig    m_config;
    bool              m_test_mode_active;
    
    // Test data management
    string            m_test_symbol;
    ENUM_TIMEFRAMES   m_test_timeframe;
    datetime          m_test_start_time;
    datetime          m_test_end_time;
    
public:
                      CTestDatabaseManager(void);
                     ~CTestDatabaseManager(void);
    
    // Test environment setup
    bool              InitializeTestEnvironment(const TestModeConfig &config);
    bool              ShutdownTestEnvironment(void);
    bool              IsTestModeActive(void) const { return m_test_mode_active; }
    
    // Database access
    CDatabaseEngine*  GetInputDatabase(void) { return m_input_db; }
    CDatabaseEngine*  GetOutputDatabase(void) { return m_output_db; }
    
    // Test data generation
    bool              GenerateTestData(const string symbol, ENUM_TIMEFRAMES timeframe,
                                     datetime start_time, datetime end_time, int candle_count);
    bool              LoadTestDataFromFile(const string filename);
    bool              SaveTestDataToFile(const string filename);
    
    // Broker simulation
    bool              SimulateBrokerData(const string symbol, ENUM_TIMEFRAMES timeframe,
                                       const CandleRecord &candles[], int count);
    bool              SimulateBrokerUpdate(const string symbol, ENUM_TIMEFRAMES timeframe,
                                         datetime timestamp, const CandleRecord &new_candle);
    bool              SimulateBrokerRevision(const string symbol, ENUM_TIMEFRAMES timeframe,
                                           datetime timestamp, const CandleRecord &revised_candle);
    
    // Data comparison
    struct SyncComparisonResult
    {
        bool          perfect_sync;
        int           total_records_compared;
        int           mismatched_records;
        int           missing_in_output;
        int           extra_in_output;
        double        sync_percentage;
        datetime      comparison_timestamp;
        string        detailed_report;
    };
    
    SyncComparisonResult CompareDatabases(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool              ValidateOneToOneSync(const string symbol, ENUM_TIMEFRAMES timeframe);
    
    // Test scenarios
    bool              RunMissingDataTest(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool              RunDataCorruptionTest(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool              RunBrokerRevisionTest(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool              RunNetworkInterruptionTest(const string symbol, ENUM_TIMEFRAMES timeframe);
    
private:
    bool              CreateTestDatabases(void);
    void              DestroyTestDatabases(void);
    bool              ValidateTestConfiguration(const TestModeConfig &config);
    CandleRecord      GenerateRandomCandle(datetime timestamp, const string symbol, ENUM_TIMEFRAMES timeframe);
};

//+------------------------------------------------------------------+
//| Real-time Monitor                                               |
//| Single Responsibility: Monitor sync status and performance     |
//+------------------------------------------------------------------+
class CRealTimeMonitor
{
private:
    CDatabaseEngine*   m_database;
    CChainManager*     m_chain_manager;
    bool              m_own_components;
    
    // Monitoring state
    bool              m_monitoring_active;
    datetime          m_monitoring_start_time;
    string            m_monitored_symbol;
    ENUM_TIMEFRAMES   m_monitored_timeframe;
    
    // Real-time metrics
    struct RealTimeMetrics
    {
        // Sync metrics
        double        sync_accuracy_percentage;
        long          records_synchronized;
        long          sync_failures;
        datetime      last_sync_time;
        double        average_sync_latency_ms;
        
        // Performance metrics
        double        throughput_records_per_second;
        double        validation_speed_per_second;
        double        chain_completion_rate;
        
        // Health metrics
        bool          chain_healthy;
        long          chain_breaks_detected;
        long          gaps_detected;
        long          repairs_performed;
        
        // System metrics
        double        cpu_usage_percentage;
        long          memory_usage_mb;
        long          database_size_mb;
        
        datetime      metrics_timestamp;
    };
    
    RealTimeMetrics   m_current_metrics;
    RealTimeMetrics   m_metrics_history[100]; // Last 100 readings
    int               m_metrics_history_count;
    
public:
                      CRealTimeMonitor(CDatabaseEngine* database = NULL, CChainManager* chain_manager = NULL);
                     ~CRealTimeMonitor(void);
    
    // Monitoring control
    bool              StartMonitoring(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool              StopMonitoring(void);
    bool              IsMonitoring(void) const { return m_monitoring_active; }
    
    // Real-time updates
    bool              UpdateMetrics(void);
    bool              ProcessNewCandle(const CandleRecord &candle);
    bool              ProcessSyncEvent(bool success, double latency_ms);
    
    // Metrics access
    RealTimeMetrics   GetCurrentMetrics(void) const { return m_current_metrics; }
    bool              GetMetricsHistory(RealTimeMetrics &history[], int &count);
    
    // Performance analysis
    struct PerformanceTrend
    {
        bool          improving;
        double        trend_percentage;
        string        trend_description;
        datetime      analysis_timestamp;
    };
    
    PerformanceTrend  AnalyzeSyncTrend(void);
    PerformanceTrend  AnalyzeThroughputTrend(void);
    PerformanceTrend  AnalyzeHealthTrend(void);
    
    // Alert system
    enum ENUM_ALERT_LEVEL
    {
        ALERT_INFO,
        ALERT_WARNING,
        ALERT_ERROR,
        ALERT_CRITICAL
    };
    
    struct Alert
    {
        ENUM_ALERT_LEVEL level;
        string          message;
        string          source_component;
        datetime        timestamp;
        bool            acknowledged;
    };
    
    bool              CheckAlertConditions(Alert &alerts[], int &alert_count);
    bool              IsAlertCondition(ENUM_ALERT_LEVEL level, const string condition);
    
    // Reporting
    string            GenerateStatusReport(void);
    string            GeneratePerformanceReport(void);
    bool              ExportMetricsToCSV(const string filename);
    
private:
    bool              CreateComponents(void);
    void              DestroyComponents(void);
    void              UpdateMetricsHistory(const RealTimeMetrics &metrics);
    double            CalculateTrend(const double values[], int count);
    void              ResetMetrics(void);
};

//+------------------------------------------------------------------+
//| Test Framework Controller                                       |
//| Single Responsibility: Orchestrate testing scenarios           |
//+------------------------------------------------------------------+
class CTestFramework
{
private:
    CTestDatabaseManager* m_test_db_manager;
    CRealTimeMonitor*     m_monitor;
    CChainManager*        m_chain_manager;
    bool                 m_own_components;
    
    // Test execution state
    bool                 m_test_running;
    string               m_current_test_name;
    datetime             m_test_start_time;
    
    // Test results
    struct TestResult
    {
        string          test_name;
        bool            passed;
        double          execution_time_ms;
        string          error_message;
        int             candles_processed;
        double          sync_accuracy;
        datetime        test_timestamp;
    };
    
    TestResult          m_test_results[50]; // Last 50 test results
    int                 m_test_results_count;
    
public:
                        CTestFramework(void);
                       ~CTestFramework(void);
    
    // Framework initialization
    bool                InitializeFramework(const TestModeConfig &config);
    bool                ShutdownFramework(void);
    bool                IsFrameworkReady(void);
    
    // Test execution
    bool                RunSingleTest(const string test_name, const string symbol, ENUM_TIMEFRAMES timeframe);
    bool                RunTestSuite(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool                RunStressTest(const string symbol, ENUM_TIMEFRAMES timeframe, int duration_minutes);
    
    // Individual test scenarios
    bool                TestBasicSync(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool                TestChainIntegrity(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool                TestGapDetection(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool                TestBrokerDataRevision(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool                TestNetworkInterruption(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool                TestHighFrequencyUpdates(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool                TestDatabaseCorruption(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool                TestMemoryLeak(const string symbol, ENUM_TIMEFRAMES timeframe);
    
    // Performance testing
    bool                TestThroughputLimits(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool                TestConcurrentAccess(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool                TestLargeDatasetHandling(const string symbol, ENUM_TIMEFRAMES timeframe);
    
    // Test result management
    TestResult          GetLastTestResult(void);
    bool                GetTestResults(TestResult &results[], int &count);
    double              GetTestSuiteSuccessRate(void);
    
    // Reporting
    string              GenerateTestReport(void);
    bool                ExportTestResultsToCSV(const string filename);
    bool                GenerateHTMLReport(const string filename);
    
    // Continuous testing
    bool                StartContinuousTesting(const string symbol, ENUM_TIMEFRAMES timeframe, 
                                             int test_interval_minutes = 60);
    bool                StopContinuousTesting(void);
    bool                IsContinuousTestingActive(void);
    
private:
    bool                CreateComponents(const TestModeConfig &config);
    void                DestroyComponents(void);
    bool                PrepareTestData(const string symbol, ENUM_TIMEFRAMES timeframe, int candle_count);
    TestResult          ExecuteTest(const string test_name, bool (*test_function)());
    void                RecordTestResult(const TestResult &result);
    bool                ValidateTestEnvironment(void);
};

//+------------------------------------------------------------------+
//| Monitor & Test Engine - Main Coordinator                       |
//| Single Responsibility: Coordinate monitoring and testing       |
//+------------------------------------------------------------------+
class CMonitorTestEngine
{
private:
    CTestDatabaseManager*  m_test_db_manager;
    CRealTimeMonitor*      m_monitor;
    CTestFramework*        m_test_framework;
    bool                  m_own_components;
    
    // Engine state
    bool                  m_initialized;
    bool                  m_test_mode;
    bool                  m_production_mode;
    
    TestModeConfig        m_test_config;
    
public:
                         CMonitorTestEngine(void);
                        ~CMonitorTestEngine(void);
    
    // Engine initialization
    bool                 InitializeForTesting(const TestModeConfig &config);
    bool                 InitializeForProduction(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool                 Shutdown(void);
    bool                 IsInitialized(void) const { return m_initialized; }
    
    // Mode management
    bool                 SwitchToTestMode(const TestModeConfig &config);
    bool                 SwitchToProductionMode(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool                 IsTestMode(void) const { return m_test_mode; }
    bool                 IsProductionMode(void) const { return m_production_mode; }
    
    // High-level operations
    bool                 ValidateSync(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool                 RunComprehensiveTest(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool                 StartRealTimeMonitoring(const string symbol, ENUM_TIMEFRAMES timeframe);
    bool                 StopRealTimeMonitoring(void);
    
    // Status and reporting
    struct SystemStatus
    {
        bool             system_healthy;
        bool             sync_accurate;
        double           sync_percentage;
        double           performance_score;
        int              active_alerts;
        datetime         last_update;
        string           status_message;
    };
    
    SystemStatus         GetSystemStatus(void);
    string               GenerateComprehensiveReport(void);
    
    // Component access
    CTestDatabaseManager* GetTestDatabaseManager(void) { return m_test_db_manager; }
    CRealTimeMonitor*     GetRealTimeMonitor(void) { return m_monitor; }
    CTestFramework*       GetTestFramework(void) { return m_test_framework; }
    
private:
    bool                 CreateComponents(void);
    void                 DestroyComponents(void);
    bool                 ValidateConfiguration(void);
};

#endif // SSOT_MONITOR_TEST_ENGINE_MQH
