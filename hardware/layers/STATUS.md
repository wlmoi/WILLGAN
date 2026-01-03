# WGAN Hardware - Status & Next Steps

## Current Status (Jan 3, 2026)

### ✅ Completed & Working
- **Layer 1 Generator** (`layer1_generator_v2.v`): 64 inputs → 256 outputs (Q5.10)
- **Layer 2 Generator** (`layer2_generator_v2.v`): 256 inputs → 256 outputs with LeakyReLU
- **Testbenches**: G_layer1_tb.v, G_layer2_tb.v, G_layer3_tb.v exist
- **Activation Functions**: relu.v, tanh.v, leaky_relu.v available
- **Memory Files**: Weight and bias files in mem/ directory

### ⚠️ Current Issue
- **Layer 3 Generator** (`layer3_generator_v2.v`): 256 inputs → 784 outputs
  - Compilation: ✅ Works
  - Memory Loading: ✅ Works
  - Output Writing: ❌ **Bit-slice assignment issue in iverilog**
    - Outputs showing as 'x' (unknown values)
    - Problem: Dynamic bit-slicing to reg outputs may not work in iverilog
    - Workaround needed: Use output array instead of flat bitslicing

### 📋 Files Cleaned Up
Removed ~35 temporary/debug files:
- test_*.v files (failed debug versions)
- layer3_generator_opt*.v, generator_v2_final.v, etc. (old attempts)
- *.out build artifacts
- *.vcd debug traces

## Action Items - Priority Order

### 1. Fix Layer 3 Output (CRITICAL)
```
Issue: flat_output bit-slicing not working
Solution: Rewrite using:
  - Output buffer array + combinational assignment, OR
  - Direct whole-register assignment instead of bit slicing
```

### 2. Create Complete Generator Pipeline
```
Path: 64-bit seed
  → Layer1 (64 → 256)
  → ReLU
  → Layer2 (256 → 256) 
  → ReLU
  → Layer3 (256 → 784)
  → Tanh
  → 784-bit output (28×28 image)
```

### 3. Verification
- Test each layer independently with G_layer*_tb.v
- Compare outputs with reference CSV files in reference/ directory
- Use gen_disc_data.py for test vector generation if needed

## Key Files to Keep/Focus On
```
generators/
├── layer1_generator_v2.v (64→256, working)
├── layer2_generator_v2.v (256→256, working)
└── layer3_generator_v2.v (256→784, NEEDS FIX)

activations/
├── relu.v
├── tanh.v
└── leaky_relu.v

memory/
├── epoch300_G_l*.mem (weights & biases)
└── layer2_relu_output.mem

testbenches/
├── G_layer1_tb.v
├── G_layer2_tb.v
├── G_layer3_tb.v
└── G_layer3_opt_tb.v

reference/
└── G_layer3_output.csv (expected outputs)
```

## Next Session
1. Debug Layer3 output issue
2. Create unified generator.v combining all stages
3. Add ReLU/Tanh activation blocks
4. Full pipeline test with reference comparison
