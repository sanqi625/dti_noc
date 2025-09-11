module dti_pr_top 
    import dti_pack::*;
    (
    input   logic                                       clk                                         ,
    input   logic                                       rst_n                                       ,
    // DTI_PR_adapter
    input   logic                                       patial_reset                                ,
    output  logic                                       idle                                        ,
    // REQ_data channel
    input   logic                                       req_tvalid                                  ,
    input   logic   [AXIS_DATA_WIDTH-1:0]               req_tdata                                   ,
    input   logic   [AXIS_KEEP_WIDTH-1:0]               req_tkeep                                   ,
    input   logic                                       req_tlast                                   ,
    input   logic   [TBU_NUM_WIDTH-1  :0]               req_tid                                     ,
    output  logic                                       req_tready                                  , //custom rdy
    // RSP_data channel
    output  logic                                       rsp_tvalid                                  ,
    output  logic   [CUSTOM_DATA_WIDTH-1:0]             rsp_tdata                                   ,
    output  logic   [CUSTOM_KEEP_WIDTH-1:0]             rsp_tkeep                                   ,
    output  logic                                       rsp_tlast                                   ,
    output  logic   [TBU_NUM_WIDTH-1    :0]             rsp_tid                                     ,
    input   logic                                       rsp_tready                                  , //dti rdy
    // DTI_to_custom
    output logic                                        req_valid                                   ,
    input  logic                                        req_ready                                   ,
    output logic    [89:0]                              req_payload                                 ,
    output logic    [5:0]                               req_srcid                                   ,
    output logic    [5:0]                               req_tgtid                                   ,
    output logic                                        req_qos                                     , //tie1
    output logic                                        req_last                                    ,
    input  logic                                        req_threshold                               , //tie1
    // custom_to_DTI                                                        
    input  logic                                        rsp_valid                                   ,
    output logic                                        rsp_ready                                   ,
    input  logic    [89:0]                              rsp_payload                                 ,
    input  logic    [5:0]                               rsp_srcid                                   ,
    input  logic    [5:0]                               rsp_tgtid                                   ,
    input  logic                                        rsp_qos                                     , //tie 1
    input  logic                                        rsp_last                                    ,
    output logic                                        rsp_threshold                                 //tie 1
    );
    // Inter connection
    logic                                        conv_req_valid         ;
    logic                                        conv_req_ready         ;
    logic    [AXIS_DATA_WIDTH-1:0]               conv_req_data          ;
    logic    [AXIS_KEEP_WIDTH-1:0]               conv_req_keep          ;
    logic    [TBU_NUM_WIDTH-1  :0]               conv_req_tid           ;
    logic                                        conv_req_last          ;                                                     
    logic                                        conv_rsp_valid         ;
    logic                                        conv_rsp_ready         ;
    logic    [CUSTOM_DATA_WIDTH-1:0]             conv_rsp_data          ;
    logic    [CUSTOM_KEEP_WIDTH-1:0]             conv_rsp_keep          ;
    logic    [TBU_NUM_WIDTH-1    :0]             conv_rsp_tid           ;
    logic                                        conv_rsp_last          ;
    // dti_to_conv
    dti_pr u_dti_pr (
    .clk             (clk             ) ,
    .rst_n           (rst_n           ) ,
    .patial_reset    (patial_reset    ) ,
    .idle            (idle            ) ,
    .req_tvalid      (req_tvalid      ) ,
    .req_tdata       (req_tdata       ) ,
    .req_tkeep       (req_tkeep       ) ,
    .req_tlast       (req_tlast       ) ,
    .req_tid         (req_tid         ) ,
    .req_tready      (req_tready      ) , //custom rdy
    .rsp_tvalid      (rsp_tvalid      ) ,
    .rsp_tdata       (rsp_tdata       ) ,
    .rsp_tkeep       (rsp_tkeep       ) ,
    .rsp_tlast       (rsp_tlast       ) ,
    .rsp_tid         (rsp_tid         ) ,
    .rsp_tready      (rsp_tready      ) , //dti rdy
    .req_valid       (conv_req_valid  ) ,
    .req_ready       (conv_req_ready  ) ,
    .req_data        (conv_req_data   ) ,
    .req_keep        (conv_req_keep   ) ,
    .req_tid         (conv_req_tid    ) ,
    .req_last        (conv_req_last   ) ,                 
    .rsp_valid       (conv_rsp_valid  ) ,
    .rsp_ready       (conv_rsp_ready  ) ,
    .rsp_data        (conv_rsp_data   ) ,
    .rsp_keep        (conv_rsp_keep   ) ,
    .rsp_tid         (conv_rsp_tid    ) ,
    .rsp_last        (conv_rsp_last   )                     
    );
    // conv_to_gnpd
    dti_gnpd_conv u_dti_gnpd_conv (
    .req_tvalid      (conv_req_tvalid ),
    .req_tdata       (conv_req_tdata  ),
    .req_tkeep       (conv_req_tkeep  ),
    .req_tlast       (conv_req_tlast  ),
    .req_tid         (conv_req_tid    ),
    .req_tready      (conv_req_tready ), //custom rdy
    .rsp_tvalid      (conv_rsp_tvalid ),
    .rsp_tdata       (conv_rsp_tdata  ),
    .rsp_tkeep       (conv_rsp_tkeep  ),
    .rsp_tlast       (conv_rsp_tlast  ),
    .rsp_tid         (conv_rsp_tid    ),
    .rsp_tready      (conv_rsp_tready ), //dti rdy
    .req_valid       (req_valid       ),
    .req_ready       (req_ready       ),
    .req_payload     (req_payload     ),
    .req_srcid       (req_srcid       ),
    .req_tgtid       (req_tgtid       ),
    .req_qos         (req_qos         ), //tie1
    .req_last        (req_last        ),
    .req_threshold   (req_threshold   ), //tie1                
    .rsp_valid       (rsp_valid       ),
    .rsp_ready       (rsp_ready       ),
    .rsp_payload     (rsp_payload     ),
    .rsp_srcid       (rsp_srcid       ),
    .rsp_tgtid       (rsp_tgtid       ),
    .rsp_qos         (rsp_qos         ), //tie 1
    .rsp_last        (rsp_last        ),
    .rsp_threshold   (rsp_threshold   )  //tie 1
    );
endmodule