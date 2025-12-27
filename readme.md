Act as a Principal FPGA Architect and Verilog Expert.
Your objective is to design a highly optimized, synthesizable WGAN Generator Inference Engine for Xilinx Artix-7/Zynq-7000, using a "Shared Hardware" architecture to minimize DSP and BRAM usage.

## 1. STRICT DATA REPRESENTATION (Q6.10 Fixed-Point)
The entire design must strictly adhere to the **Signed Q6.10 Fixed-Point** format.
- **Total Width:** 16-bit.
- **Bit [15]:** Sign Bit.
- **Bits [14:10]:** Integer Part (5 bits). Range: [-32 to +31].
- **Bits [9:0]:** Fractional Part (10 bits). Precision: ~0.000976.
- **Math Rule:**
  - When multiplying two Q6.10 numbers (16-bit * 16-bit), the raw result is 32-bit (Q12.20).
  - You MUST perform a **Right Arithmetic Shift by 10** (`>>> 10`) on the 32-bit product to realign the decimal point back to Q6.10.
  - Implement **Saturation Logic**: If the result overflows the 16-bit range, clamp it to the max positive (`16'h7FFF`) or max negative (`16'h8000`) value.

## 2. ARCHITECTURE SPECIFICATIONS
Implement a 3-Stage Fully Connected Network using a specific Shared-MAC architecture.
- **Input:** Vector of 64 values (Test with Zero Vector).
- **Stage 1:** 64 Inputs -> 256 Outputs + ReLU.
- **Stage 2:** 256 Inputs -> 256 Outputs + ReLU.
- **Stage 3:** 256 Inputs -> 16 Outputs + Tanh (Use a simple Piecewise Linear Approximation or LUT for Tanh).

## 3. HARDWARE STRATEGY: "Time-Multiplexed Folding"
Do NOT generate parallel logic for all neurons. Use a **Single Compute Engine** reused for all layers.
1.  **Parallelism Factor:** Process **8 MAC operations per clock cycle**.
    - This strikes a balance between speed and area.
    - Do not process 1 at a time (too slow/timeout risk). Do not process 64 (too much area).
2.  **Memory Architecture:**
    - Use inferred Block RAM (BRAM) for Weights.
    - Organize `.mem` files so the FSM can read 8 weights at once (or structure the BRAM width accordingly).
3.  **The Controller (FSM):**
    - The FSM orchestrates the flow: Load Input -> Calculate Layer 1 (Chunks of 8) -> Store to Buffer -> Calculate Layer 2 -> ... -> Output.
    - It must manage Read/Write addresses for the intermediate buffers (Ping-Pong buffering or Shared RAM).

## 4. VERILOG IMPLEMENTATION TASKS
Please provide the following optimized Verilog modules:
1.  **`fixed_point_alu.v`**: A module that handles the Q6.10 multiplication, shifting, and saturation logic.
2.  **`neuron_processing_unit.v`**: A module containing 8 instances of the ALU to process a "chunk" of data.
3.  **`wgan_top.v`**: The top-level module containing the State Machine, BRAM interfaces, and Global Control.
    - Inputs: `clk`, `rst_n`, `start`, `data_in [15:0]`.
    - Outputs: `data_out [15:0]`, `valid`, `busy`.

## 5. ROBUST TESTBENCH & VALIDATION
Create `tb_wgan_verification.v` with the following strict requirements to prevent timeouts and ensure clarity:
1.  **Clock:** 100 MHz (10ns).
2.  **Stimulus:** Apply a RESET, then load an Input Vector consisting of **All Zeros**.
3.  **Layer-by-Layer Debugging (Crucial):**
    - The testbench must "spy" or monitor the completion of each layer.
    - Using `$display`, print the **first 5 output values** of Layer 1, Layer 2, and Layer 3.
    - **Format:** Print both HEX and converted REAL (float) values.
      - *Example Verilog Helper:* `real_val = $itor($signed(reg_val)) / 1024.0;`
4.  **Watchdog:** Terminate simulation if it exceeds 50,000 clock cycles to prevent infinite loops.

## 6. DELIVERABLES
- Complete Verilog Code.
- A brief explanation of how the `>>> 10` shift maintains the Q6.10 precision.
- Instructions on how to format the `.mem` files for the 8-way parallel read.