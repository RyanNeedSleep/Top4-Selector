from typing import Sequence

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ReadOnly, RisingEdge
from cocotb.types import LogicArray


DATA_WIDTH = 9


def to_data_t(value: int) -> LogicArray:
    """Convert a signed integer to 9-bit two's complement."""
    return LogicArray.from_signed(value, DATA_WIDTH)


async def reset_dut(dut) -> None:
    dut.rst_n.value = 0
    dut.blkIn.value = 0

    for lane in range(8):
        dut.idata[lane].value = to_data_t(0)

    for _ in range(2):
        await RisingEdge(dut.clk)

    await FallingEdge(dut.clk)
    dut.rst_n.value = 1


async def send_block(dut, values: Sequence[int]) -> None:
    assert len(values) == 32

    for group in range(4):
        await FallingEdge(dut.clk)

        dut.blkIn.value = 1 if group == 0 else 0

        for lane in range(8):
            index = group * 8 + lane
            dut.idata[lane].value = to_data_t(values[index])


async def collect_top4(dut) -> list[int]:
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

    return outputs


@cocotb.test()
async def test_one_block(dut) -> None:
    cocotb.start_soon(
        Clock(dut.clk, 10, unit="ns").start()
    )

    await reset_dut(dut)

    # group 0: 0, 4, 8, ..., 28
    # group 1: 1, 5, 9, ..., 29
    # group 2: 2, 6, 10, ..., 30
    # group 3: 3, 7, 11, ..., 31
    values = [
        group + 4 * lane
        for group in range(4)
        for lane in range(8)
    ]

    expected = sorted(values, reverse=True)[:4]

    await send_block(dut, values)
    actual = await collect_top4(dut)

    assert actual == expected, (
        f"Top-4 mismatch: expected {expected}, got {actual}"
    )
