# ALU & Register Bank Verification Environment

A class-based SystemVerilog verification environment for a digital ALU integrated with a Register Bank, developed during the Technion Chip Design & Verification program.

##  The Design (DUT)
The Device Under Test (DUT) consists of two main integrated blocks:
* **Register Bank:** A configurable memory array holding operands and results, supporting synchronous reads and writes.
* **ALU:** Executes arithmetic and logic operations (ADD, SUB, MUL, DIV) based on opcodes driven from the register bank or external stimulus.

##  Testbench Architecture & Two-Monitor Split
The testbench uses a layered OOP architecture with a strict separation between data generation, driving, and sampling.
To handle the design efficiently, the monitoring path is split into two specialized monitors - monitor in for and monitor out.

* **Generator:** Creates randomized and directed transactions with constraints to test corner cases.
* **Driver:** Receives transactions and drives the stimulus into the DUT via the interface pins.
* **ALU Monitor:** Passively samples the ALU input and output pins, captures execution stages, and sends the data to the scoreboard for arithmetic validation.
* **Register Bank Monitor:** Tracks the register file states, read/write commands, and addresses to monitor data integrity and state updates inside the memory array.
* **Scoreboard:** Receives transactions from both monitors, compares actual DUT outputs against a golden reference model, and checks for data mismatches.

## Key Features Tested
* **Functional Correctness:** Verification of all ALU operations across full data ranges.
* **Dual-Monitor Tracking:** Independent verification of register-file state updates vs. arithmetic execution.
* **Constrained Random Verification (CRV):** Automated testing of design limits and hazard conditions.

## Tools
* **Language:** SystemVerilog (OOP)
* **Simulators:** QuestaSim / ModelSim
