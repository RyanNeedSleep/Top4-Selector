# Top4 Selector

A SystemVerilog implementation of a 32-input Top-4 selector. Each input block contains four 8-lane groups; the DUT outputs the four largest signed 9-bit values.

## Requirements

- Python 3
- [Icarus Verilog](https://steveicarus.github.io/iverilog/) on `PATH`
- Optional: [GTKWave](https://gtkwave.github.io/gtkwave/) for waveform viewing

## Setup and run

Create and activate a virtual environment, then install the Python dependencies:

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

Run the cocotb test:

```sh
make
```

The active cocotb test is `tb.cocotb.test_top4_txn`. It generates random input transactions and inter-transaction idle cycles, then verifies the results with a concurrent driver, monitor, queue-based scoreboard, reference model, and timeout.

## View waveforms

```sh
make WAVES=1
gtkwave sim_build/Top4.fst
```

Useful signals:

```text
clk rst_n blkIn
wena wgroup wbank rbank merge_start
out_valid outrank result
idata0_dbg ... idata7_dbg
```

## Layout

```text
src/                 Active SystemVerilog RTL
tb/cocotb/           cocotb transaction-based testbench
tb/sv/               Standalone SystemVerilog testbenches
tb/legacy/           Older testbench experiments
requirements.txt     Python dependencies
Makefile             Icarus Verilog and cocotb configuration
```
