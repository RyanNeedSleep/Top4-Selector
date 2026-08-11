# Tpo4-Selector

A SystemVerilog implementation of a 32-input Top-4 selector. Inputs arrive as four 8-lane groups; the DUT outputs the four largest signed 9-bit values.

## Requirements

- Python 3
- [Icarus Verilog](https://steveicarus.github.io/iverilog/)
- [cocotb](https://www.cocotb.org/)
- Optional: [GTKWave](https://gtkwave.github.io/gtkwave/) for waveform viewing

## Run the test

```sh
make
```

The active cocotb test is configured in `Makefile`:

```make
COCOTB_TEST_MODULES = test_top4_txn
COCOTB_TOPLEVEL = Top4
```

`test_top4_txn.py` drives random input transactions with random inter-transaction idle cycles. It uses a reference model, transaction queues, a concurrent driver/monitor/scoreboard flow, and a whole-test timeout.

## View waveforms

Generate an FST waveform while running the test:

```sh
make WAVES=1
```

Open the generated waveform:

```sh
gtkwave sim_build/Top4.fst
```

Useful signals to inspect:

```text
clk rst_n blkIn
wena wgroup wbank rbank merge_start
out_valid outrank result
idata0_dbg ... idata7_dbg
```

## Main files

```text
Top4.sv            Top-level DUT
sort8.sv            8-input sorting network
Regset.sv           Banked storage for sorted groups
write_ctrl.sv       Input/write controller
merge_ctrl.sv       Top-4 merge controller
CompTree.sv         Four-way maximum comparator tree
test_top4_txn.py    cocotb transaction-based testbench
Makefile            Simulator and cocotb configuration
```
>>>>>>> 093dda4 (Add concurrent Top4 verification flow and documentation)
