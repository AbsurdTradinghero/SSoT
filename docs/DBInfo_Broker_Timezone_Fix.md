# DBInfo Broker Name and Timezone Fix

## Issue Description
The DBInfo table was missing broker name and timezone information in the display, even though they were being stored in the database.

## Root Causes Identified

### 1. **Missing Server Name Reading**
- The code was storing `server_name` in DBInfo but not reading it back
- Database queries only looked for `broker_name`, `timezone`, etc. but not `server_name`

### 2. **Hardcoded Timezone Display**
- The timezone was being read from DBInfo but then overridden with hardcoded "UTC" in display
- Both `GetDatabaseInfo()` and `DisplayDBInfo()` methods had this issue

### 3. **Missing Server Name in DatabaseSetup**
- The `InsertMetadata()` method in DatabaseSetup.mqh was only storing `broker_name` but not `server_name`

## Fixes Implemented

### 1. **Enhanced DatabaseSetup.mqh**
```mql5
// Added server name insertion
string server_name = AccountInfoString(ACCOUNT_SERVER);
if(server_name == "" || server_name == NULL) server_name = "MISSING";
sql = StringFormat("INSERT OR REPLACE INTO DBInfo (key, value, updated_at) VALUES ('server_name', '%s', %lld);", server_name, current_time);

// Enhanced success message
PrintFormat("✅ DatabaseSetup: Metadata inserted for %s (Broker: %s, Server: %s, Timezone: %s)", 
           db_type, broker_name, server_name, timezone_info);
```

### 2. **Enhanced DatabaseOperations.mqh**

#### **GetDatabaseInfo() Method:**
```mql5
// Added server_name variable and reading
string broker_name = "", server_name = "", db_timezone_val = "", ...;

// Added server_name reading from DBInfo
else if(key == "server_name") server_name = value;

// Enhanced display output
info += "Broker: " + (broker_name != "" ? broker_name : "MISSING") + "\n";
info += "Server: " + (server_name != "" ? server_name : "MISSING") + "\n";
info += "Timezone: " + (db_timezone_val != "" ? db_timezone_val : "UTC") + "\n";
```

#### **DisplayDBInfo() Method:**
```mql5
// Added server_name variable and reading (same as above)
// Enhanced console output
Print("[DATA]      - Broker: " + (broker_name != "" ? broker_name : "MISSING"));
Print("[DATA]      - Server: " + (server_name != "" ? server_name : "MISSING"));
Print("[DATA]      - Timezone: " + (db_timezone_val != "" ? db_timezone_val : "UTC"));
```

#### **UpdateDBInfoSummary() Method:**
```mql5
// Added broker info refresh during summary updates
string broker_name = AccountInfoString(ACCOUNT_COMPANY);
if(broker_name == "" || broker_name == NULL) broker_name = "MISSING";
sql = StringFormat("INSERT OR REPLACE INTO DBInfo (key, value, updated_at) VALUES ('broker_name', '%s', %lld)", 
                  broker_name, current_time);

// Added server info refresh
string server_name = AccountInfoString(ACCOUNT_SERVER);
if(server_name == "" || server_name == NULL) server_name = "MISSING";
sql = StringFormat("INSERT OR REPLACE INTO DBInfo (key, value, updated_at) VALUES ('server_name', '%s', %lld)", 
                  server_name, current_time);

// Added timezone refresh
MqlDateTime dt;
TimeCurrent(dt);
int gmt_offset = (int)((TimeCurrent() - TimeGMT()) / 3600);
string timezone_info = StringFormat("GMT%s%d", (gmt_offset >= 0 ? "+" : ""), gmt_offset);
sql = StringFormat("INSERT OR REPLACE INTO DBInfo (key, value, updated_at) VALUES ('timezone', '%s', %lld)", 
                  timezone_info, current_time);

// Enhanced success message
Print("✅ DBInfo summary updated successfully (Broker: ", broker_name, ", Server: ", server_name, ", Timezone: ", timezone_info, ")");
```

## Expected Results

### **Database Display Now Shows:**
```
Server: SQLite Local Database
Filename: sourcedb.sqlite
Source: sourcedb.sqlite
Broker: [Actual Broker Name]
Server: [Actual Server Name]
Timezone: [Actual Timezone like GMT+2]
Schema: 1.0
```

### **Console Output Now Shows:**
```
[DATA]      - Source: sourcedb.sqlite
[DATA]      - Broker: [Actual Broker Name]
[DATA]      - Server: [Actual Server Name] 
[DATA]      - Timezone: [Actual Timezone like GMT+2]
[DATA]      - Schema: 1.0
```

### **DBInfo Table Now Contains:**
```sql
INSERT INTO DBInfo VALUES 
  ('broker_name', '[Actual Broker]', timestamp),
  ('server_name', '[Actual Server]', timestamp),
  ('timezone', 'GMT+2', timestamp),
  ('schema_version', '1.0', timestamp),
  ('tracked_symbols', 'EURUSD', timestamp),
  ('tracked_timeframes', 'M1,M5,M15,H1', timestamp);
```

## Benefits

### 1. **Complete Broker Information**
- Shows both broker name and server name for full identification
- Useful for distinguishing between demo/live accounts and different servers

### 2. **Accurate Timezone Display**
- Shows actual MT5 server timezone instead of hardcoded "UTC"
- Important for understanding data timestamps and trading hours

### 3. **Consistent Data Handling**
- All DBInfo fields are now properly stored and retrieved
- Data refresh during summary updates keeps information current

### 4. **Better Debugging**
- Clear identification of broker/server environment
- Timezone information helps with timestamp interpretation

## File Changes Made

### Modified Files:
- ✅ `DatabaseSetup.mqh` - Enhanced metadata insertion
- ✅ `DatabaseOperations.mqh` - Fixed reading and display methods
- ✅ Compilation successful with 0 errors, 0 warnings

### Methods Enhanced:
- ✅ `CDatabaseSetup::InsertMetadata()` - Now stores server_name
- ✅ `CDatabaseOperations::GetDatabaseInfo()` - Reads and displays server_name and timezone
- ✅ `CDatabaseOperations::DisplayDBInfo()` - Shows complete broker information
- ✅ `CDatabaseOperations::UpdateDBInfoSummary()` - Refreshes broker/server/timezone info

## Testing Status
- ✅ Compilation successful
- ✅ All DBInfo fields now properly handled
- ✅ Enhanced visual and console output
- ✅ Ready for runtime testing

The SSoT EA now provides complete and accurate broker/server/timezone information in the DBInfo display, eliminating the missing broker name and timezone issues.
