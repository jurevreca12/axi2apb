from forastero.io import IORole, io_suffix_style
from forastero import BaseBench

from cocotb_tools.runner import get_runner

from base import get_rtl_files
from base import WAVES, ASSERTIONS, LANGUAGE, RTL_DIRS

from axi4lite.io import AXI4LiteWriteAddressIO
from axi4lite.io import AXI4LiteWriteDataIO
from axi4lite.io import AXI4LiteWriteResponseIO
from axi4lite.io import AXI4LiteReadAddressIO
from axi4lite.io import AXI4LiteReadResponseIO
from axi4lite.initiator import AXI4LiteReadAddressInitiator
from axi4lite.target import AXI4LiteReadResponseTarget
from axi4lite.monitor import AXI4LiteReadResponseMonitor
from axi4lite.sequences import axi4lite_ar_backpressure
from axi4lite.sequences import axi4lite_r_backpressure
from axi4lite.sequences import axi4lite_read_seq

from apb.io import ApbIO

class Axi2ApbTb(BaseBench):
    def __init__(self, dut):
        super().__init__(dut, clk=dut.clk_i, rst=dut.rstn_i, rst_active_high=False)
        axi_aw_io = AXI4LiteWriteAddressIO(dut, "axi", IORole.RESPONDER, io_style=io_suffix_style)
        axi_w_io = AXI4LiteWriteDataIO(dut, "axi", IORole.RESPONDER, io_style=io_suffix_style) 
        axi_b_io = AXI4LiteWriteResponseIO(dut, "axi", IORole.INITIATOR, io_style=io_suffix_style) 
        axi_ar_io = AXI4LiteReadAddressIO(dut, "axi", IORole.RESPONDER, io_style=io_suffix_style)
        axi_r_io = AXI4LiteReadResponseIO(dut, "axi", IORole.INITIATOR, io_style=io_suffix_style)
        apb_io = ApbIO(dut, "apb", IORole.INITIATOR, io_style=io_suffix_style)

        self.register("axi_read_req_drv", AXI4LiteReadAddressInitiator(self, axi_ar_io, self.clk, self.rst))
        self.register("axi_read_rsp_rdy_drv", AXI4LiteReadResponseTarget(self, axi_r_io, self.clk, self.rst))
        self.register("axi_read_rsp_mon", AXI4LiteReadResponseMonitor(self, axi_r_io, self.clk, self.rst))



@Axi2ApbTb.testcase(
    reset_wait_during=2,
    reset_wait_after=0,
    timeout=1000,
    shutdown_delay=1,
    shutdown_loops=1,
)
async def smoke(tb: Axi2ApbTb, log):
    log.info(f"Smoke test")

@Axi2ApbTb.testcase(
    reset_wait_during=2,
    reset_wait_after=0,
    timeout=1000,
    shutdown_delay=1,
    shutdown_loops=1,
)
async def single_read_nobp(tb: Axi2ApbTb, log):
    log.info(f"Testing a single AXI read transaction.")
    log.info(f"Scheduling no backpressure on the response driver")
    tb.schedule(axi4lite_r_backpressure(driver=tb.axi_read_rsp_rdy_drv, backpressure=0.0), blocking=False)
    log.info(f"Scheduling a read request.")
    results=[]
    tb.schedule(
        axi4lite_read_seq(
            ar_drv=tb.axi_read_req_drv,
            r_mon=tb.axi_read_rsp_mon,
            address=0x42,
            buffer=results
        )
    )

if __name__ == "__main__":
    build_args = ["-Wno-fatal", "--no-stop-fail"]
    if WAVES:
        build_args += ["--trace-fst"]
    if ASSERTIONS:
        build_args += ["-DASSERTIONS"]
    runner = get_runner("verilator")
    runner.build(
        sources=get_rtl_files(LANGUAGE),
        includes=[],
        build_args=build_args,
        hdl_toplevel="axi2apb",
        parameters={},
        always=True,
        waves=False, # we use buildargs to get fst waves (instead of vcd)
    )
    runner.test(
        hdl_toplevel="axi2apb",
        test_module="test_axi2apb",
    )
