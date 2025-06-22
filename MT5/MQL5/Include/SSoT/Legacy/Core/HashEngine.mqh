//+------------------------------------------------------------------+
//| SSoT Hash Engine                                                 |
//| Cryptographic hashing for Chain of Trust validation             |
//+------------------------------------------------------------------+
#property copyright "ATH Trading System"
#property version   "3.00"

#ifndef SSOT_HASH_ENGINE_MQH
#define SSOT_HASH_ENGINE_MQH

#include "DataStructures.mqh"

//+------------------------------------------------------------------+
//| Hash Calculator                                                  |
//| Single Responsibility: Calculate SHA-256 hashes for candles     |
//+------------------------------------------------------------------+
class CHashCalculator
{
private:
    uchar           m_buffer[];
    int             m_buffer_size;
    bool            m_include_spread;
    bool            m_include_tick_volume;
    
public:
                    CHashCalculator(bool include_spread = true, bool include_tick_volume = true);
                   ~CHashCalculator(void);
    
    // Hash calculation
    string          CalculateCandleHash(const CandleRecord &candle);
    string          CalculateOHLCVHash(datetime timestamp, double open, double high, 
                                     double low, double close, long volume);
    string          CalculateChainHash(const string current_hash, const string previous_hash);
    
    // Validation helpers
    bool            ValidateHash(const CandleRecord &candle);
    bool            CompareHashes(const string hash1, const string hash2);
    
    // Configuration
    void            SetIncludeSpread(bool include) { m_include_spread = include; }
    void            SetIncludeTickVolume(bool include) { m_include_tick_volume = include; }
    bool            GetIncludeSpread(void) const { return m_include_spread; }
    bool            GetIncludeTickVolume(void) const { return m_include_tick_volume; }
    
    // Performance metrics
    static int      GetHashCalculationsCount(void) { return s_hash_count; }
    static void     ResetHashCount(void) { s_hash_count = 0; }
    static double   GetAverageHashTime(void) { return s_total_time / fmax(1, s_hash_count); }
    
private:
    string          BytesToHex(const uchar &data[]);
    bool            SerializeCandleData(const CandleRecord &candle, uchar &output[]);
    void            ResizeBuffer(int required_size);
    
    // Performance tracking
    static int      s_hash_count;
    static double   s_total_time;
    uint            m_start_tick;
    
    void            StartTiming(void) { m_start_tick = GetTickCount(); }
    void            StopTiming(void);
};

//+------------------------------------------------------------------+
//| Chain Hash Manager                                               |
//| Single Responsibility: Manage blockchain-style hash chains      |
//+------------------------------------------------------------------+
class CChainHashManager
{
private:
    CHashCalculator* m_calculator;
    string          m_genesis_hash;
    bool            m_own_calculator;
    
public:
                    CChainHashManager(CHashCalculator* calculator = NULL);
                   ~CChainHashManager(void);
    
    // Chain operations
    bool            InitializeChain(const string genesis_hash = "");
    string          CalculateChainPosition(const CandleRecord &candle, const string previous_hash);
    bool            ValidateChainPosition(const CandleRecord &candle);
    
    // Chain verification
    bool            VerifyChainIntegrity(const CandleRecord &candles[], int count, int &first_invalid_index);
    bool            VerifyChainSegment(const CandleRecord &candles[], int start_index, int end_index);
    
    // Genesis block
    string          GetGenesisHash(void) const { return m_genesis_hash; }
    void            SetGenesisHash(const string hash) { m_genesis_hash = hash; }
    string          GenerateGenesisHash(const string seed = "");
    
    // Chain reconstruction
    bool            RecalculateChainHashes(CandleRecord &candles[], int count);
    bool            RepairChainBreak(CandleRecord &candles[], int break_index);
    
private:
    string          CalculatePositionalHash(const CandleRecord &candle, const string previous_hash);
    bool            IsValidChainLink(const CandleRecord &current, const CandleRecord &previous);
};

//+------------------------------------------------------------------+
//| Hash Validation Engine                                          |
//| Single Responsibility: Validate hashes against broker data      |
//+------------------------------------------------------------------+
class CHashValidator
{
private:
    CHashCalculator* m_calculator;
    bool            m_own_calculator;
    
    // Validation statistics
    int             m_validations_performed;
    int             m_validations_passed;
    int             m_validations_failed;
    double          m_total_validation_time;
    
public:
                    CHashValidator(CHashCalculator* calculator = NULL);
                   ~CHashValidator(void);
    
    // Single candle validation
    bool            ValidateCandleHash(const CandleRecord &candle);
    bool            ValidateAgainstBroker(const CandleRecord &stored_candle, 
                                        const MqlRates &broker_candle);
    
    // Batch validation
    int             ValidateCandleBatch(CandleRecord &candles[], int count, 
                                      bool &validation_results[]);
    bool            ValidateChainHashes(const CandleRecord &candles[], int count);
    
    // Broker comparison
    bool            CompareToBrokerData(const string symbol, ENUM_TIMEFRAMES timeframe,
                                      datetime start_time, datetime end_time,
                                      int &mismatches_found);
    
    // Validation reporting
    struct ValidationReport
    {
        int         total_validated;
        int         passed;
        int         failed;
        double      success_rate;
        double      average_time_ms;
        datetime    validation_timestamp;
        string      symbol;
        ENUM_TIMEFRAMES timeframe;
    };
    
    ValidationReport GetValidationReport(void);
    void            ResetValidationStats(void);
    
    // Hash mismatch handling
    struct HashMismatch
    {
        datetime    timestamp;
        string      stored_hash;
        string      calculated_hash;
        string      symbol;
        ENUM_TIMEFRAMES timeframe;
        CandleRecord stored_candle;
        MqlRates    broker_candle;
    };
    
    bool            DetectHashMismatches(const string symbol, ENUM_TIMEFRAMES timeframe,
                                       datetime start_time, datetime end_time,
                                       HashMismatch &mismatches[], int max_mismatches = 100);
    
private:
    bool            FetchBrokerCandle(const string symbol, ENUM_TIMEFRAMES timeframe,
                                    datetime timestamp, MqlRates &candle);
    void            UpdateValidationStats(bool passed, double time_ms);
    string          GenerateValidationId(const CandleRecord &candle);
};

//+------------------------------------------------------------------+
//| Hash Engine - Main Coordinator                                  |
//| Single Responsibility: Coordinate all hashing operations        |
//+------------------------------------------------------------------+
class CHashEngine
{
private:
    CHashCalculator*    m_calculator;
    CChainHashManager*  m_chain_manager;
    CHashValidator*     m_validator;
    
    bool               m_initialized;
    
    // Configuration
    bool               m_include_spread_in_hash;
    bool               m_include_tick_volume_in_hash;
    string             m_genesis_hash;
    
public:
                       CHashEngine(void);
                      ~CHashEngine(void);
    
    // Initialization
    bool               Initialize(bool include_spread = true, bool include_tick_volume = true,
                                const string genesis_hash = "");
    bool               Shutdown(void);
    bool               IsInitialized(void) const { return m_initialized; }
    
    // High-level hash operations
    string             HashCandle(const CandleRecord &candle);
    bool               ValidateCandle(const CandleRecord &candle);
    bool               ValidateAgainstBroker(const CandleRecord &candle, const string symbol);
    
    // Chain operations
    bool               CalculateChainHashes(CandleRecord &candles[], int count);
    bool               ValidateChainIntegrity(const CandleRecord &candles[], int count);
    bool               RepairChain(CandleRecord &candles[], int count);
    
    // Batch operations
    bool               HashCandleBatch(CandleRecord &candles[], int count);
    int                ValidateCandleBatch(CandleRecord &candles[], int count, 
                                         bool &results[]);
    
    // Broker synchronization
    struct SyncResult
    {
        bool           success;
        int            candles_checked;
        int            mismatches_found;
        int            candles_updated;
        double         sync_time_ms;
        datetime       sync_timestamp;
    };
    
    SyncResult         SynchronizeWithBroker(const string symbol, ENUM_TIMEFRAMES timeframe,
                                           datetime start_time, datetime end_time,
                                           CandleRecord &candles[], int max_candles);
    
    // Performance monitoring
    struct HashPerformance
    {
        int            total_hashes_calculated;
        double         average_hash_time_ms;
        int            validations_performed;
        double         validation_success_rate;
        double         chain_verification_time_ms;
    };
    
    HashPerformance    GetPerformanceMetrics(void);
    void               ResetPerformanceMetrics(void);
    
    // Configuration
    void               SetIncludeSpread(bool include);
    void               SetIncludeTickVolume(bool include);
    void               SetGenesisHash(const string hash);
    
    bool               GetIncludeSpread(void) const { return m_include_spread_in_hash; }
    bool               GetIncludeTickVolume(void) const { return m_include_tick_volume_in_hash; }
    string             GetGenesisHash(void) const { return m_genesis_hash; }
    
private:
    bool               CreateComponents(void);
    void               DestroyComponents(void);
    bool               ValidateConfiguration(void);
};

//+------------------------------------------------------------------+
//| Static variables initialization                                  |
//+------------------------------------------------------------------+
static int CHashCalculator::s_hash_count = 0;
static double CHashCalculator::s_total_time = 0.0;

//+------------------------------------------------------------------+
//| Implementation: CHashCalculator                                 |
//+------------------------------------------------------------------+
CHashCalculator::CHashCalculator(bool include_spread, bool include_tick_volume) :
    m_buffer_size(1024),
    m_include_spread(include_spread),
    m_include_tick_volume(include_tick_volume)
{
    ArrayResize(m_buffer, m_buffer_size);
}

CHashCalculator::~CHashCalculator(void)
{
    ArrayFree(m_buffer);
}

string CHashCalculator::CalculateCandleHash(const CandleRecord &candle)
{
    StartTiming();
    
    uchar serialized_data[];
    if(!SerializeCandleData(candle, serialized_data))
    {
        StopTiming();
        return "";
    }
    
    uchar hash_bytes[];
    if(!CryptHash(HASH_SHA256, serialized_data, hash_bytes))
    {
        StopTiming();
        Print("Failed to calculate SHA-256 hash");
        return "";
    }
    
    string result = BytesToHex(hash_bytes);
    StopTiming();
    
    return result;
}

string CHashCalculator::CalculateOHLCVHash(datetime timestamp, double open, double high,
                                         double low, double close, long volume)
{
    CandleRecord temp_candle;
    temp_candle.timestamp = timestamp;
    temp_candle.open = open;
    temp_candle.high = high;
    temp_candle.low = low;
    temp_candle.close = close;
    temp_candle.volume = volume;
    temp_candle.tick_volume = volume; // Use same value if not specified
    temp_candle.spread = 0;
    
    return CalculateCandleHash(temp_candle);
}

bool CHashCalculator::SerializeCandleData(const CandleRecord &candle, uchar &output[])
{
    // Calculate required buffer size
    int required_size = sizeof(long) +      // timestamp
                       sizeof(double) * 4 + // OHLC
                       sizeof(long);        // volume
    
    if(m_include_tick_volume)
        required_size += sizeof(long);
    
    if(m_include_spread)
        required_size += sizeof(int);
    
    ArrayResize(output, required_size);
    int pos = 0;
    
    // Serialize timestamp
    long timestamp = (long)candle.timestamp;
    ArrayCopy(output, timestamp, pos, 0, sizeof(long));
    pos += sizeof(long);
    
    // Serialize OHLC (normalize to prevent floating point precision issues)
    double normalized_open = NormalizeDouble(candle.open, 5);
    double normalized_high = NormalizeDouble(candle.high, 5);
    double normalized_low = NormalizeDouble(candle.low, 5);
    double normalized_close = NormalizeDouble(candle.close, 5);
    
    ArrayCopy(output, normalized_open, pos, 0, sizeof(double));
    pos += sizeof(double);
    ArrayCopy(output, normalized_high, pos, 0, sizeof(double));
    pos += sizeof(double);
    ArrayCopy(output, normalized_low, pos, 0, sizeof(double));
    pos += sizeof(double);
    ArrayCopy(output, normalized_close, pos, 0, sizeof(double));
    pos += sizeof(double);
    
    // Serialize volume
    ArrayCopy(output, candle.volume, pos, 0, sizeof(long));
    pos += sizeof(long);
    
    // Optional: tick volume
    if(m_include_tick_volume)
    {
        ArrayCopy(output, candle.tick_volume, pos, 0, sizeof(long));
        pos += sizeof(long);
    }
    
    // Optional: spread
    if(m_include_spread)
    {
        ArrayCopy(output, candle.spread, pos, 0, sizeof(int));
        pos += sizeof(int);
    }
    
    return true;
}

string CHashCalculator::BytesToHex(const uchar &data[])
{
    string result = "";
    int data_size = ArraySize(data);
    
    for(int i = 0; i < data_size; i++)
    {
        result += StringFormat("%02x", data[i]);
    }
    
    return result;
}

void CHashCalculator::StopTiming(void)
{
    uint end_tick = GetTickCount();
    double elapsed = (double)(end_tick - m_start_tick);
    
    s_hash_count++;
    s_total_time += elapsed;
}

bool CHashCalculator::ValidateHash(const CandleRecord &candle)
{
    string calculated_hash = CalculateCandleHash(candle);
    return StringCompare(calculated_hash, candle.hash, false) == 0;
}

bool CHashCalculator::CompareHashes(const string hash1, const string hash2)
{
    return StringCompare(hash1, hash2, false) == 0;
}

#endif // SSOT_HASH_ENGINE_MQH
