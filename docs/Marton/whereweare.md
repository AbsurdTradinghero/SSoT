PLease first read carefully the following dacuments:
docs\Marton\SSCoT
docs\Marton\SSoT_Complete_System_Documentation.md
docs\Marton\Complete_Compilation_Guide.md

this are important documents to understanf on what and how we work here

you find the current EA Here: MT5\MQL5\Experts\SSoT.mq5
and some legacy project here:
MT5\MQL5\Experts\Legacy

especially SSoT_legacy.mq5 is important since it is the most complete and tested EA but lacks of resfactoring.

WE are currently workin on a development and testing panel. This panel is the center piece of our system it act as integrated testing & development envirnment. SSoT can be ran in live and test mode. in live mode we run the SSCoT and collect data from Broker into the sourcedb. in test mode we create two aditional databases SSCoT_input and SSCoT_output. This two databases act as our sandbox environment and we can develop and test our data acquisition system and tinker with this database and make sure that our algorihm self-heal and maintain a 1-1 sync during stress test

Here is a review of how the sandbox environment operates, the key components involved, the current development status (based on your documentation and project structure), and a suggested progress tracker for achieving MVP.

---

## Sandbox Environment Review

### How the Sandbox Environment Works

- **Purpose:**  
  The sandbox environment is designed to safely develop, test, and validate the SSoT system’s data acquisition, validation, and self-healing algorithms without affecting live broker data.

- **Operation Modes:**  
  - **Live Mode:**  
    - The system runs the SSCoT, collecting data from the broker into the `sourcedb.sqlite`.
  - **Test Mode (Sandbox):**  
    - Two additional databases are created: `SSCoT_input` and `SSCoT_output`.
    - These act as isolated sandboxes, allowing you to simulate data acquisition, run stress tests, and validate the self-healing and synchronization logic.
    - The system can be stress-tested by introducing faults or inconsistencies, then observing and verifying the self-healing process.

- **Central Component:**  
  - The **Development & Testing Panel** is the main interface for controlling, monitoring, and interacting with both live and sandbox environments. It allows switching modes, running tests, and visualizing results.

---

### Key Players in the Sandbox System

1. **Development & Testing Panel:**  
   - The control center for switching between live/test modes, running tests, and visualizing system state.

2. **SSoT EA (SSoT.mq5):**  
   - The orchestrator that manages data flow, validation, and self-healing logic.

3. **Databases:**  
   - `sourcedb.sqlite`: Live broker data.
   - `SSCoT_input`: Test input data for sandbox runs.
   - `SSCoT_output`: Output of the SSoT system in test mode, used for validation and comparison.

4. **Validation & Self-Healing Algorithms:**  
   - Core logic that ensures data integrity, detects gaps, and repairs the chain as needed.

5. **Legacy EA (SSoT_legacy.mq5):**  
   - Reference implementation for tested logic, useful for regression testing and feature parity.

---

### Current Development Status (Based on Provided Context)

- **Core architecture and database flow are defined and operational.**
- **Legacy EA is feature-complete and well-tested, but not refactored.**
- **Current EA is under active development, with focus on modularity and maintainability.**
- **Development & Testing Panel is being built as the main interface, but may not be fully complete yet.**
- **Test mode and sandbox database logic are in place, but ongoing work is likely needed for robust automation, visualization, and stress testing.**

---

## Suggested Progress Tracker for MVP

1. **Panel MVP**
   - [ ] Basic UI for switching between live and test modes
   - [ ] Controls for starting/stopping tests and viewing logs
   - [ ] Visualization of database states and validation results

2. **Database Integration**
   - [ ] Automated creation and management of `SSCoT_input` and `SSCoT_output` in test mode
   - [ ] Reliable data flow between broker, input, and output databases

3. **Validation & Self-Healing**
   - [ ] Implementation of dual-flag validation (is_validated, is_complete)
   - [ ] Automated detection and repair of data gaps/broken chains
   - [ ] Stress test scenarios and recovery validation

4. **Testing & Regression**
   - [ ] Side-by-side comparison with legacy EA for feature parity
   - [ ] Automated test cases for common failure and recovery scenarios

5. **Documentation & Usability**
   - [ ] Clear user guide for the panel and sandbox workflow
   - [ ] Inline documentation and error reporting

---

Would you like a more detailed breakdown of any of these areas, or should I help you set up a concrete progress tracker (e.g., as a markdown checklist or project board)?

can you review SSoT find where the databases are initialized and upgrade the script that all requirments are met. work as much as possible independent /autonoumusly I will jump only if really necessry. make sure that you always compile and debug under the compilation guidlines and only use the script provided here to compile/debug build\ide_exact_compile.ps1