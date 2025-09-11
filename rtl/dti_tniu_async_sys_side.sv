module dti_tniu_async_sys_side
    import dti_pack::*;
#(
    parameter integer unsigned ASYNC_FIFO_DEPTH = 10    
)(
    input   logic                                       clk                                        ,
    input   logic                                       rst_n                                      ,
    // REQ_data channel
    output  logic                                       req_tvalid                                 ,
    output  logic   [AXIS_DATA_WIDTH-1:0]               req_tdata                                  ,
    output  logic   [AXIS_KEEP_WIDTH-1:0]               req_tkeep                                  ,
    output  logic                                       req_tlast                                  ,
    output  logic   [TBU_NUM_WIDTH-1  :0]               req_ttid                                   ,
    input   logic                                       req_tready                                 , //custom rdy
    // RSP_data channel
    input   logic                                       rsp_tvalid                                 ,
    input   logic   [CUSTOM_DATA_WIDTH-1:0]             rsp_tdata                                  ,
    input   logic   [CUSTOM_KEEP_WIDTH-1:0]             rsp_tkeep                                  ,
    input   logic                                       rsp_tlast                                  ,
    input   logic   [TBU_NUM_WIDTH-1    :0]             rsp_ttid                                   ,
    output  logic                                       rsp_tready                                 , //dti rdy
    // async fifo req
    input  logic    [ASYNC_FIFO_DEPTH-1 :0]             req_wptr_async                             ,
    output logic    [ASYNC_FIFO_DEPTH-1 :0]             req_rptr_async                             ,
    output logic    [ASYNC_FIFO_DEPTH-1 :0]             req_rptr_sync                              ,
    input  logic    [90+6+6+1+1         :0]             req_pld_sync                               ,
    // async fifo rsp
    output logic    [ASYNC_FIFO_DEPTH-1 :0]             rsp_wptr_async                             ,
    input  logic    [ASYNC_FIFO_DEPTH-1 :0]             rsp_rptr_async                             ,
    input  logic    [ASYNC_FIFO_DEPTH-1 :0]             rsp_rptr_sync                              ,
    output logic    [90+6+6+1+1         :0]             rsp_pld_sync
);

    logic                                            req_valid          ;
    logic  [CUSTOM_DATA_WIDTH+CUSTOM_KEEP_WIDTH-1:0] req_payload        ;
    logic                                            req_last           ;
    logic  [TBU_NUM_WIDTH-1                      :0] req_srcid          ;
    logic  [TBU_NUM_WIDTH-1                      :0] req_tgtid          ;
    logic                                            req_qos            ; //tie 1
    logic                                            req_threshold      ;
    logic                                            req_ready          ; //async rdy
    logic                                            rsp_valid          ;
    logic  [CUSTOM_DATA_WIDTH+CUSTOM_KEEP_WIDTH-1:0] rsp_payload        ;
    logic                                            rsp_last           ;
    logic  [TBU_NUM_WIDTH-1                      :0] rsp_srcid          ;
    logic  [TBU_NUM_WIDTH-1                      :0] rsp_tgtid          ;
    logic                                            rsp_qos            ; //tie 1
    logic                                            rsp_threshold      ;
    logic                                            rsp_ready          ; //async rdy
    logic [90+6+6+1+1-1                          :0] req_pld_vector     ;
    logic [90+6+6+1+1-1                          :0] rsp_pld_vector     ;
    logic                                            async_rsp_stall    ;
    logic                                            async_rsp_clear    ;
    logic                                            async_rsp_full_zero;
    logic                                            req_async_clear    ;
    logic                                            req_async_stall    ;
    logic                                            req_async_idle     ;
    logic                                            req_async_full_zero;


    //=================================================
    // CONV
    //================================================= 
    gnpd_to_dti_conv u_gnpd_to_dti_conv (
    .req_valid             (req_valid     ),
    .req_ready             (req_ready     ),
    .req_payload           (req_payload   ),
    .req_srcid             (req_srcid     ),
    .req_tgtid             (req_tgtid     ),
    .req_qos               (req_qos       ), //tie1
    .req_last              (req_last      ),
    .req_threshold         (req_threshold ), //tie1
    .rsp_valid             (rsp_valid     ),
    .rsp_ready             (rsp_ready     ),
    .rsp_payload           (rsp_payload   ),
    .rsp_srcid             (rsp_srcid     ),
    .rsp_tgtid             (rsp_tgtid     ),
    .rsp_qos               (rsp_qos       ), //tie 1
    .rsp_last              (rsp_last      ),
    .rsp_threshold         (rsp_threshold ), //tie 1
    .rsp_tvalid            (rsp_tvalid    ),
    .rsp_tdata             (rsp_tdata     ),
    .rsp_tkeep             (rsp_tkeep     ),
    .rsp_tlast             (rsp_tlast     ),
    .rsp_ttid              (rsp_ttid      ),
    .rsp_tready            (rsp_tready    ), //custom rdy                 
    .req_tvalid            (req_tvalid    ),
    .req_tdata             (req_tdata     ),
    .req_tkeep             (req_tkeep     ),
    .req_tlast             (req_tlast     ),
    .req_ttid              (req_ttid      ),
    .req_tready            (req_tready    )  //dti rdy
    );
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