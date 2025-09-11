module dti_pr_async_top_side
    import dti_pack::*;
    #(
        parameter ASYNC_FIFO_DEPTH = 16
    )
    (
    input   logic                                              clk           ,
    input   logic                                              rst_n         ,
    // RSP_data channel
    input   logic                                              rsp_valid     ,
    input   logic   [CUSTOM_DATA_WIDTH+CUSTOM_KEEP_WIDTH-1:0]  rsp_payload   ,
    input   logic                                              rsp_last      ,
    input   logic   [TBU_NUM_WIDTH-1                      :0]  rsp_srcid     ,
    input   logic   [TBU_NUM_WIDTH-1                      :0]  rsp_tgtid     ,
    input   logic                                              rsp_qos       , //tie 1
    output  logic                                              rsp_threshold ,
    output  logic                                              rsp_ready     , //async rdy
    // REQ_data channel
    output  logic                                              req_valid     ,
    output  logic   [CUSTOM_DATA_WIDTH+CUSTOM_KEEP_WIDTH-1:0]  req_payload   ,
    output  logic                                              req_last      ,
    output  logic   [TBU_NUM_WIDTH-1                      :0]  req_srcid     ,
    output  logic   [TBU_NUM_WIDTH-1                      :0]  req_tgtid     ,
    output  logic                                              req_qos       , //tie 1
    input   logic                                              req_threshold ,
    input   logic                                              req_ready     , //custom rdy
    // async fifo req
    input  logic    [ASYNC_FIFO_DEPTH-1                   :0]  req_wptr_async,
    output logic    [ASYNC_FIFO_DEPTH-1                   :0]  req_rptr_async,
    output logic    [ASYNC_FIFO_DEPTH-1                   :0]  req_rptr_sync ,
    input  logic    [90+6+6+1+1                           :0]  req_pld_sync  ,
    // async fifo rsp
    output logic    [ASYNC_FIFO_DEPTH-1                   :0]  rsp_wptr_async,
    input  logic    [ASYNC_FIFO_DEPTH-1                   :0]  rsp_rptr_async,
    input  logic    [ASYNC_FIFO_DEPTH-1                   :0]  rsp_rptr_sync ,
    output logic    [90+6+6+1+1                           :0]  rsp_pld_sync
    );

    logic [90+6+6+1+1-1:0]  req_pld_vector     ;
    logic                   req_async_clear    ;
    logic                   req_async_stall    ;
    logic                   req_async_full_zero;
    logic                   req_async_idle     ;
    logic [90+6+6+1+1-1:0]  rsp_pld_vector     ;
    logic                   async_rsp_stall    ;
    logic                   async_rsp_clear    ;
    logic                   async_rsp_full_zero;
    //===========================================================================
    // async fifo req mst
    //===========================================================================
    assign req_last      = req_pld_vector[0];
    assign req_qos       = req_pld_vector[1];
    assign req_tgtid     = req_pld_vector[7:2];
    assign req_srcid     = req_pld_vector[13:8];
    assign req_payload   = req_pld_vector[103:14];

    afifo_mst #(
        .DATA_WIDTH         (90+6+6+1+1             ),
        .FIFO_DEPTH         (ASYNC_FIFO_DEPTH       ))
    u_dti_pr_async_fifo_mst (
        .clk                (clk                    ),
        .rst_n              (rst_n                  ),
        .stall              (req_async_stall        ),
        .clear              (req_async_clear        ),
        .full_zero          (req_async_full_zero    ),
        .idle               (req_async_idle         ),

        .m_vld              (req_valid              ),
        .m_pld              (req_pld_vector         ),
        .m_rdy              (req_ready              ),

        .wptr_async         (req_wptr_async         ),

        .rptr_async         (req_rptr_async         ),
        .rptr_sync          (req_rptr_sync          ),
        .pld_sync           (req_pld_sync           )
    );
    //===========================================================================
    // async fifo rsp slv
    //===========================================================================
    assign rsp_pld_vector = {rsp_payload,rsp_srcid,rsp_tgtid,rsp_qos,rsp_last};
    assign rsp_threshold  = 1'b1; //tie 1

    afifo_slv #(
        .DATA_WIDTH         (90+6+6+1+1          ),
        .FIFO_DEPTH         (ASYNC_FIFO_DEPTH    ))
    u_dti_pr_async_fifo_slv (
        .clk                (clk                    ),
        .rst_n              (rst_n                  ),
        .stall              (async_rsp_stall        ),
        .clear              (async_rsp_clear        ),
        .full_zero          (async_rsp_full_zero    ),

        .s_vld              (rsp_valid              ),
        .s_pld              (rsp_pld_vector         ),
        .s_rdy              (rsp_ready              ),

        .wptr_async         (rsp_wptr_async         ),
        
        .rptr_async         (rsp_rptr_async         ),
        .rptr_sync          (rsp_rptr_sync          ),
        .pld_sync           (rsp_pld_sync           )
    );

endmodule 
    