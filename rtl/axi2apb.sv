module AXI4L_APB_bridge #(
    parameter int REQ_FIFO_LEN = 8,
    parameter int RSP_FIFO_LEN = 8
)
(
    input logic clk_i,
    input logic rstn_i,

    // ---------- AXI4L I/O ----------

    // AXI4L address read (ar) channel
    input logic [31:0]  axi_ar_addr_i,
    //input logic [3:0]   axi_ar_cache_i,
    //input logic [2:0]   axi_ar_prot_i,
    input logic         axi_ar_valid_i,

    output logic        axi_ar_ready_o,

    // AXI4L data read (dr) channel
    input logic         axi_dr_ready_i,

    output logic [31:0] axi_dr_data_o,
    output logic        axi_dr_resp_o,
    output logic        axi_dr_valid_o,

    // AXI4L address write (aw) channel
    input logic [31:0]  axi_aw_addr_i,
    //input logic [3:0]   axi_aw_cache_i,
    //input logic [2:0]   axi_aw_prot_i,
    input logic         axi_aw_valid_i,

    output logic        axi_aw_ready_o,

    // AXI4L data write (dw) channel
    input logic [31:0]  axi_dw_data_i,
    input logic [3:0]   axi_dw_strobe_i,
    input logic         axi_dw_valid_i,

    output logic        axi_dw_ready_o,

    // AXI4L response write (rw) channel
    input logic         axi_rw_ready_i,

    output logic        axi_rw_resp_o,
    output logic        axi_rw_valid_o,

    // ---------- APB I/O ----------

    // APB control (c) channel
    //input logic         apb_c_ready_i,

    output logic [31:0] apb_c_addr_o,
    //output logic [APB_SSEL_LEN-1:0] apb_c_ssel_o,
    //output logic        apb_c_enable_o, 
    output logic        apb_c_write_o,

    // APB data (d) channel
    input logic [31:0]  apb_d_read_i,

    output logic [31:0] apb_d_write_o,
    output logic [3:0]  apb_d_strobe_o,

    // APB err & prot (ep) channel
    input logic         apb_ep_slverr_i,

    //output logic [2:0]  apb_ep_prot_o,

    // APB master handshake
    input apb_master_req_ready,
    input apb_master_rrsp_valid_i,
    input apb_master_wrsp_valid_i,

    output apb_master_req_valid,
    output apb_master_rrsp_ready_o,
    output apb_master_wrsp_ready_o
);

logic prt;      // Req FIFO with arbiter priority (0-r/1-w)
logic grant;    // Req FIFO with arbiter grant (0-r/1-w)

// ---------- FIFOs for incoming data from AXI4L ----------

// Read request FIFO
logic r_req_fifo_full;
logic r_req_fifo_empty;
logic r_req_fifo_address;
logic r_req_rd_en;
assign axi_ar_ready_o = ~r_req_fifo_full;
assign r_req_wr_en = axi_ar_valid_i && axi_ar_ready_o;
fifo #(REQ_FIFO_LEN,32) r_req_fifo (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(r_req_wr_en),
    .rd_en_i(r_req_rd_en),
    .w_data_i(axi_ar_addr_i),
    .r_data_o(r_req_fifo_address),
    .full_o(r_req_fifo_full),
    .empty_o(r_req_fifo_empty)
);

// Write request FIFO
logic w_req_fifo_full;
logic w_req_fifo_empty;
logic w_req_fifo_address;
logic w_req_rd_en;
assign axi_aw_ready_o = ~w_req_fifo_full;
assign w_req_wr_en = axi_aw_valid_i && axi_aw_ready_o;
fifo #(REQ_FIFO_LEN,32) w_req_fifo (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(w_req_wr_en),
    .rd_en_i(w_req_rd_en),
    .w_data_i(axi_aw_addr_i),
    .r_data_o(w_req_fifo_address),
    .full_o(w_req_fifo_full),
    .empty_o(w_req_fifo_empty)
);

// Write data FIFO
logic w_data_fifo_full;
logic w_data_fifo_empty;
logic w_data_fifo_data
logic w_data_rd_en;
assign axi_dw_ready_o = ~w_data_fifo_full;
assign w_data_wr_en = axi_dw_valid_i && axi_dw_ready_o;
fifo #(REQ_FIFO_LEN,32) w_data_fifo (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(w_data_wr_en),
    .rd_en_i(w_data_rd_en),
    .w_data_i(axi_dw_data_i),
    .r_data_o(w_data_fifo_data),
    .full_o(w_data_fifo_full),
    .empty_o(w_data_fifo_empty)
);

// Write strobe FIFO
logic w_strobe_fifo_full;
logic w_strobe_fifo_empty; 
logic w_strobe_fifo_strobe;
fifo #(REQ_FIFO_LEN, 4) w_strobe_fifo (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(w_data_wr_en),
    .rd_en_i(w_data_rd_en),
    .w_data_i(axi_dw_strobe_i),
    .r_data_o(w_strobe_fifo_strobe),
    .full_o(w_strobe_fifo_full),
    .empty_o(w_strobe_fifo_empty)
);

// ---------- FIFOs for incoming data from APB ----------

// Read data FIFO
logic r_data_fifo_full;
logic r_data_fifo_empty;
assign axi_dr_valid_o = ~r_data_fifo_empty;
assign apb_master_rrsp_ready_o = ~r_data_fifo_full;
assign r_data_rd_en = axi_dr_valid_o && axi_dr_ready_i;
assign r_data_wr_en = apb_master_rrsp_valid_i && apb_master_rrsp_ready_o;
fifo #(RSP_FIFO_LEN,32) r_data_fifo (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(r_data_wr_en),
    .rd_en_i(r_data_rd_en),
    .w_data_i(apb_d_read_i),
    .r_data_o(axi_dr_data_o),
    .full_o(r_data_fifo_full),
    .empty_o(r_data_fifo_empty)
);

// Read response FIFO
logic r_slverr_fifo_full;
logic r_slverr_fifo_empty;
fifo #(RSP_FIFO_LEN,1) r_slverr_fifo (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(r_data_wr_en),
    .rd_en_i(r_data_rd_en),
    .w_data_i(apb_ep_slverr_i),
    .r_data_o(axi_dr_resp_o),
    .full_o(r_slverr_fifo_full),
    .empty_o(r_slverr_fifo_empty)
);

// Write response FIFO
logic w_slverr_fifo_full;
logic w_slverr_fifo_empty;
assign axi_rw_valid_o = ~w_slverr_fifo_empty;
assign apb_master_wrsp_ready_o = ~w_slverr_fifo_full;
assign w_slverr_rd_en = axi_rw_valid_o && axi_rw_ready_i;
assign w_slverr_wr_en = apb_master_wrsp_valid_i && apb_master_wrsp_ready_o;
fifo #(RSP_FIFO_LEN,1) w_slverr_fifo (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(w_slverr_wr_en),
    .rd_en_i(w_slverr_rd_en),
    .w_data_i(apb_ep_slverr_i),
    .r_data_o(axi_rw_resp_o),
    .full_o(w_slverr_fifo_full),
    .empty_o(w_slverr_fifo_empty)
);

// ---------- Request arbiter ----------
assign expr = {prt, grant, r_req_fifo_empty, w_req_fifo_empty};

// Set APB request data
always_comb begin
    case (grant)
        '0:     // APB read request
                apb_c_addr_o = r_req_fifo_address;
                apb_c_write_o = '0;
                apb_d_write_o = '0;
                apb_d_strobe_o = '0;

        1'b1:   // APB write request
                apb_c_addr_o = w_req_fifo_address;
                apb_c_write_o = 1'b1;
                apb_d_write_o = w_data_fifo_data;
                apb_d_strobe_o = w_strobe_fifo_strobe; 
    endcase
end

// Arbiter selector (round robin with priority and availability criteria)
always_ff (@posedge clk_i) begin
    if ~rstn_i begin
        apb_master_req_valid <= '0;
        prt <= '0;
        grant <= '0;
        r_req_rd_en <= '0;
        w_req_rd_en <= '0;
        w_data_rd_en <= '0;
    end else begin
        // Data is valid and either has to halt (grant and valid do not change)
        // or change upon ready/valid handshake
        if (apb_master_req_valid && apb_master_req_ready) begin
            if (grant) begin 
                w_req_rd_en <= 1;
                w_data_rd_en <= 1;
            end else begin
                r_req_rd_en <= 1;
            end
        end
    end  
end

always_ff (@posedge clk_i) begin
    if ((apb_master_req_valid && apb_master_req_ready) || ~apb_master_req_valid) begin
        casez (expr) 
            // First 2 bits are last priority and last request grant (as in last clk cycle)
            // Last 2 bits are current read and write FIFO requests availability (empty status)
            4'b??11:    apb_master_req_valid <= '0; // No data, both req FIFOs empty
            4'b00?0:    prt <= 1'b1;    
                        grant <= 1'b1;
                        apb_master_req_valid <= '1;
            4'b?001:    prt <= 1'b1;    
                        grant <= '0;
                        apb_master_req_valid <= '1;           
            4'b010?:    prt <= 1'b1;    
                        grant <= '0;
                        apb_master_req_valid <= '1;            
            4'b?110:    prt <= '0;      
                        grant <= 1'b1;
                        apb_master_req_valid <= '1;
            4'b10?0:    prt <= '0;      
                        grant <= 1'b1;
                        apb_master_req_valid <= '1;
            4'b110?:    prt <= '0;     
                        grant <= '0;
                        apb_master_req_valid <= '1;
        endcase 
    end
end
    
endmodule
