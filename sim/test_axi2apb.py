from forastero.io import IORole, io_suffix_style
from forastero import BaseBench

from axi4lite.io import AXI4LiteWriteAddressIO
from axi4lite.io import AXI4LiteWriteDataIO
from axi4lite.io import AXI4LiteWriteResponseIO
from axi4lite.io import AXI4LiteReadAddressIO
from axi4lite.io import AXI4LiteReadResponseIO

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
