# SSoT Self-Healing MQL5 Syntax Fix Plan

## Current Status
- Self-healing system is commented out due to compilation errors
- Multiple syntax issues across all self-healing classes
- Core issues: array syntax, reference parameters, include guards

## Strategic Approach

### Phase 1: Create Simplified Core Classes (30 minutes)
Instead of fixing every syntax error in the complex classes, create simplified, working versions:

1. **SimpleHealingLogger.mqh** - Basic logging with MQL5-compatible syntax
2. **SimpleGapDetector.mqh** - Core gap detection without complex features  
3. **SimpleSelfHealingManager.mqh** - Minimal orchestration class
4. **SimpleIntegration.mqh** - Basic integration wrapper

### Phase 2: Test Integration (15 minutes)
- Test compilation with simplified classes
- Enable in SSoT.mq5 with minimal functionality
- Verify basic operation

### Phase 3: Gradual Enhancement (Future)
- Add features incrementally while maintaining compilation
- Test each addition before moving to next

## Key MQL5 Syntax Rules to Follow

1. **No const references**: Use value parameters or pointers
2. **Array parameters**: Use `array[]` or `array&[]` syntax
3. **Include guards**: Always use `#ifndef/#define/#endif`
4. **No array return types**: Return count and use reference parameters
5. **Simple enums**: Avoid complex enum operations

## Implementation Plan

Start with minimal working classes that compile and provide basic functionality.
Focus on core self-healing: gap detection, basic logging, simple recovery.
