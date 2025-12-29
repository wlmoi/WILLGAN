Layer2 simulator files copied here for easier testing.

Included scripts:
- compare_layer2_output.py
- compare_full_hw_sw.py
- debug_layer2_neuron.py
- test_conversion_variants.py
- deep_neuron_diagnostics.py
- layer2_generator_hw.py (copy)

Usage:
Run scripts from this folder (they still reference mem files in the repo):

```bash
python compare_layer2_output.py
python compare_full_hw_sw.py
python debug_layer2_neuron.py
python test_conversion_variants.py
python deep_neuron_diagnostics.py
```

Note: these scripts import `layer2_generator_hw` from the same folder; ensure Python path includes this folder or run them from this folder.
