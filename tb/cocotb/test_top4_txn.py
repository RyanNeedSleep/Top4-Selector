import random
from dataclasses import dataclass

import cocotb
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import Combine, FallingEdge, ReadOnly, RisingEdge, with_timeout
from cocotb.types import LogicArray

DATA_WIDTH = 9


@dataclass
class InputTransaction:
    values: list[int]

    def __post_init__(self):
        assert len(self.values) == 32
        for v in self.values:
            assert -256 <= v <= 255


@dataclass
class OutputTransaction:
    values: list[int]

    def __post_init__(self):
        assert len(self.values) == 4
        for v in self.values:
            assert -256 <= v <= 255


def to_data_t(value: int) -> LogicArray:
    return LogicArray.from_signed(value, DATA_WIDTH)


def reference_model(tx: InputTransaction) -> OutputTransaction:
    return OutputTransaction(values=sorted(tx.values, reverse=True)[:4])



async def reset_dut(dut) -> None:
    dut.rst_n.value = 0
    dut.blkIn.value = 0

    for lane in range(8):
        dut.idata[lane].value = to_data_t(0)

    for _ in range(2):
        await RisingEdge(dut.clk)

    await FallingEdge(dut.clk)
    dut.rst_n.value = 1

async def drive_transactions(
    dut,
    txs: list[InputTransaction],
    gaps: list[int]
) -> None:

    for i, tx in enumerate(txs):
        dut._log.info("Driving tx %d", i)
        await send_transaction(dut, tx)
        if i < len(txs) - 1:
            await drive_idle_cycles(dut, gaps[i])




async def collect_transactions_to_queue(
    dut,
    actual_queue: Queue,
    count: int
) -> None:

    for i in range(count):
        dut._log.info("Collecting tx %d", i)
        out_tx = await collect_transaction(dut)
        await actual_queue.put(out_tx)



async def send_transaction(dut, tx: InputTransaction) -> None:
    for group in range(4):
        await FallingEdge(dut.clk)

        dut.blkIn.value = 1 if group == 0 else 0

        for lane in range(8):
            index = group * 8 + lane
            dut.idata[lane].value = to_data_t(tx.values[index])


async def collect_transaction(dut) -> OutputTransaction:
    outputs: list[int] = []

    while len(outputs) < 4:
        await RisingEdge(dut.clk)
        await ReadOnly()

        if int(dut.out_valid.value) == 1:
            rank = dut.outrank.value.to_unsigned()
            value = dut.result.value.to_signed()

            expected_rank = len(outputs)

            assert rank == expected_rank, (
                f"OutRank error: expected {expected_rank}, got {rank}"
            )

            dut._log.info(
                "outrank=%d result=%d",
                rank,
                value,
            )

            outputs.append(value)

    return OutputTransaction(values=outputs)


def make_random_input_transaction(rng: random.Random) -> InputTransaction:
    values = [
        rng.randint(-256, 255)
        for _ in range(32)
    ]
    return InputTransaction(values=values)


async def scoreboard(
    expected_queue: Queue,
    actual_queue: Queue,
    count: int
) -> None:

    for i in range(count):
        expected = await expected_queue.get()
        actual = await actual_queue.get()

        assert actual == expected, (
            f"Scoreboard mismatch at tx {i}:\n"
            f"expected = {expected}\n"
            f"actual   = {actual}"
        )


async def drive_idle_cycles(dut, count) -> None:
    for _ in range(count):
        await FallingEdge(dut.clk)
        dut._log.info("Idle cycle inserted...")

        dut.blkIn.value = 0

        for lane in range(8):
            dut.idata[lane].value = to_data_t(0)




@cocotb.test()
async def test_concurrent_transactions(dut) -> None:

    seed = 42
    rng = random.Random(seed)
    dut._log.info("Using random seed=%d", seed)

    NUM_TX = 10
    dut._log.info("Total Num of Test Transaction: %d", NUM_TX)

    cocotb.start_soon(
        Clock(dut.clk, 10, unit="ns").start()
    )

    expected_queue = Queue()
    actual_queue = Queue()


    timeout_time = 2
    timeout_unit = "us"

    max_gap_cycles = 5
    gaps = [
        rng.randint(0, max_gap_cycles)
        for _ in range(NUM_TX - 1)
    ]

    dut._log.info("Inter-transaction gaps: %s", gaps)



    await reset_dut(dut)

    txs = [
        make_random_input_transaction(rng)
        for _ in range(NUM_TX)
    ]

    expected_txs = [
        reference_model(t)
        for t in txs
    ]

    for t in expected_txs:
        await expected_queue.put(t)

    scoreboard_task = cocotb.start_soon(
        scoreboard(expected_queue, actual_queue, NUM_TX)
    )
    monitor_task = cocotb.start_soon(
        collect_transactions_to_queue(dut, actual_queue, NUM_TX)
    )

    driver_task = cocotb.start_soon(
        drive_transactions(dut, txs, gaps)
    )


    await with_timeout(
        Combine(
            driver_task,
            monitor_task,
            scoreboard_task
        ),
        timeout_time,
        timeout_unit
    )
