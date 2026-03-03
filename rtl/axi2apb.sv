module axi2apb #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter int BRESP_WIDTH = 1,
  parameter int RRESP_WIDTH = 1,
  parameter int APB_SLAVES = 1,
  localparam int StrbWidth = DATA_WIDTH / 8
)
(
    input logic clk_i,
    input logic rstn_i,

    // AXI4Lite - Write Request Channel
    input  logic                   axi_awvalid_i,
    output logic                   axi_awready_o,
    input  logic [ADDR_WIDTH-1:0]  axi_awaddr_i,
    input  logic [2:0]             axi_awprot_i,

    // AXI4Lite - Write Data Channel
    input  logic                   axi_wvalid_i,
    output logic                   axi_wready_o,
    input  logic [DATA_WIDTH-1:0]  axi_wdata_i,
    input  logic [3:0]             axi_wstrb_i,

    // AXI4Lite - Write Response Channel
    output logic                   axi_bvalid_o,
    input  logic                   axi_bready_i,
    output logic [BRESP_WIDTH-1:0] axi_bresp_o,


    // AXI4Lite - Read Request Channel
    input  logic                   axi_arvalid_i,
    output logic                   axi_arready_o,
    input  logic [ADDR_WIDTH-1:0]  axi_araddr_i,
    input  logic [2:0]             axi_arprot_i,

    // AXI4Lite - Read Data Channel
    output logic                   axi_rvalid_o,
    input  logic                   axi_rready_i,
    output logic [DATA_WIDTH-1:0]  axi_rdata_o,
    output logic [RRESP_WIDTH-1:0] axi_rresp_o,

    // APB
    output logic [ADDR_WIDTH-1:0]  apb_paddr_o,
    output logic [2:0]             apb_pprot_o,
    output logic [APB_SLAVES-1:0]  apb_psel_o,
    output logic                   apb_penable_o,
    output logic                   apb_pwrite_o,
    output logic [DATA_WIDTH-1:0]  apb_pwdata_o,
    output logic [StrbWidth-1:0]   apb_pstrb_o,

    input  logic                   apb_pready_i,
    input  logic [DATA_WIDTH-1:0]  apb_prdata_i,
    input  logic                   apb_pslverr_i
);
    assign axi_awready_o = '0;
    assign axi_wready_o = '0;
    assign axi_bvalid_o = '0;
    assign axi_bresp_o = '0;
    assign axi_arready_o = 1'b1;
    assign axi_rvalid_o = '0;
    assign axi_rdata_o = '0;
    assign axi_rresp_o = '0;

    assign apb_paddr_o = '0;
    assign apb_pprot_o = '0;
    assign apb_psel_o = '0;
    assign apb_penable_o = '0;
    assign apb_pwrite_o = '0;
    assign apb_pwdata_o = '0;
    assign apb_pstrb_o = '0;
  
endmodule
