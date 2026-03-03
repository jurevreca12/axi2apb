# SPDX-License-Identifier: MIT
# Copyright (c) 2023-2024 Vypercore. All Rights Reserved

import functools
from random import Random

from cocotb.utils import get_sim_time
from forastero.bench import BaseBench
from forastero.monitor import MonitorEvent

from .initiator import (
    AXI4LiteReadResponseInitiator,
    AXI4LiteWriteResponseInitiator,
)
from .monitor import (
    AXI4LiteReadAddressMonitor,
    AXI4LiteWriteAddressMonitor,
    AXI4LiteWriteDataMonitor,
)
from .transaction import (
    AXI4LiteReadAddress,
    AXI4LiteReadResponse,
    AXI4LiteWriteAddress,
    AXI4LiteWriteData,
    AXI4LiteWriteResponse,
)


class AXI4LiteMemoryModel:
    def __init__(
        self,
        tb: BaseBench,
        awreq: AXI4LiteWriteAddressMonitor,
        wreq: AXI4LiteWriteDataMonitor,
        arreq: AXI4LiteReadAddressMonitor,
        brsp: AXI4LiteWriteResponseInitiator,
        rrsp: AXI4LiteReadResponseInitiator,
        error_noninit: True,
        rand_noninit: True,
        response_delay: tuple[int, int] = (0, 0),
    ) -> None:
        # Hold references
        self.awreq = awreq
        self.wreq = wreq
        self.arreq = arreq
        self.brsp = brsp
        self.rrsp = rrsp
        self.error_noninit = error_noninit
        self.rand_noninit = rand_noninit
        self.response_delay = response_delay
        # Fork logging and random from testbench
        self.log = tb.fork_log("axi4lmem")
        self.random = Random(tb.random.random())
        # Calculate widths and masks
        self.bit_width = self.wreq.io.width("wdata")
        self.byte_width = (self.bit_width + 7) // 8
        self.mask = (1 << self.bit_width) - 1
        # Create memory
        self.memory = {}
        # Queues
        self.q_awreq: list[AXI4LiteWriteAddress] = []
        self.q_wreq: list[AXI4LiteWriteData] = []
        # Subscribe to events
        self.awreq.subscribe(MonitorEvent.CAPTURE, self._handle)
        self.wreq.subscribe(MonitorEvent.CAPTURE, self._handle)
        self.arreq.subscribe(MonitorEvent.CAPTURE, self._handle)

    @functools.lru_cache  # noqa: B019
    def _bit_strobe(self, byte_strobe: int) -> int:
        return sum(
            ((0xFF << (i * 8)) if ((byte_strobe >> i) & 0x1) else 0)
            for i in range(int(self.byte_width))
        )

    def read(self, address: int, check: bool = True) -> int:
        if address not in self.memory:
            if check and self.error_noninit:
                raise Exception(f"Read from uninitialised address: 0x{address:016X}")
            elif self.rand_noninit:
                self.memory[address] = self.random.getrandbits(self.bit_width)
            else:
                self.memory[address] = 0
        return self.memory[address]

    def write(self, address: int, data: int, strobe: int) -> None:
        current = self.read(address, check=False)
        bit_strobe = self._bit_strobe(strobe)
        if bit_strobe == self.mask:
            self.memory[address] = data
        else:
            value = (data & bit_strobe) | (current & (self.mask ^ bit_strobe))
            self.memory[address] = value

    def _handle(self, component, event, obj) -> None:
        # Queue AW/W requests, immediately respond to AR requests
        match obj:
            case AXI4LiteWriteAddress():
                self.q_awreq.append(obj)
            case AXI4LiteWriteData():
                self.q_wreq.append(obj)
            case AXI4LiteReadAddress():
                self.rrsp.enqueue(
                    AXI4LiteReadResponse(
                        data=self.read(obj.address),
                        deliver_at_ns=get_sim_time(units="ns")
                        + self.random.randint(*self.response_delay),
                    )
                )
        # Once a matching AW and W request are available, respond
        if self.q_awreq and self.q_wreq:
            awreq = self.q_awreq.pop(0)
            wreq = self.q_wreq.pop(0)
            self.write(awreq.address, wreq.data, wreq.strobe)
            self.brsp.enqueue(
                AXI4LiteWriteResponse(
                    deliver_at_ns=get_sim_time(units="ns")
                    + self.random.randint(*self.response_delay),
                )
            )
