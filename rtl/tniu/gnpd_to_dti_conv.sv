module gnpd_to_dti_conv 
    import dti_pack::*;
    (
    // REQ_data channel
    input  logic                                        req_valid                                   ,
    output logic                                        req_ready                                   ,
    input  logic    [89:0]                              req_payload                                 ,
    input  logic    [5:0]                               req_srcid                                   ,
    input  logic    [5:0]                               req_tgtid                                   ,
    input  logic                                        req_qos                                     , //tie1
    input  logic                                        req_last                                    ,
    output logic                                        req_threshold                               , //tie1
    // RSP_data channel
    output logic                                        rsp_valid                                   ,
    input  logic                                        rsp_ready                                   ,
    output logic    [89:0]                              rsp_payload                                 ,
    output logic    [5:0]                               rsp_srcid                                   ,
    output logic    [5:0]                               rsp_tgtid                                   ,
    output logic                                        rsp_qos                                     , //tie 1
    output logic                                        rsp_last                                    ,
    input  logic                                        rsp_threshold                               , //tie 1
    // DTI_to_custom
    input   logic                                       rsp_tvalid                                  ,
    input   logic   [79:0]                              rsp_tdata                                   ,
    input   logic   [9:0]                               rsp_tkeep                                   ,
    input   logic                                       rsp_tlast                                   ,
    input   logic   [5:0]                               rsp_ttid                                    ,
    output  logic                                       rsp_tready                                  , //dti rdy
    // custom_to_DTI                                                        
    output  logic                                       req_tvalid                                  ,
    output  logic   [79:0]                              req_tdata                                   ,
    output  logic   [9:0]                               req_tkeep                                   ,
    output  logic                                       req_tlast                                   ,
    output  logic   [5:0]                               req_ttid                                    ,
    input   logic                                       req_tready                                    //custom rdy
    );

    // custom to DTI
    assign req_tvalid    = req_valid;
    assign req_tdata     = req_payload[89:10];
    assign req_tkeep     = req_payload[9:0];
    assign req_tlast     = req_last;
    assign req_ttid      = req_srcid;
    assign req_threshold = 1'b1; //tie1
    assign req_ready     = req_tready;

    // DTI to custom
    assign rsp_valid     = rsp_tvalid;
    assign rsp_payload   = {rsp_tdata,rsp_tkeep};
    assign rsp_srcid     = rsp_ttid;
    assign rsp_tgtid     = 6'd0;
    assign rsp_qos       = 1'b1; //tie1
    assign rsp_last      = rsp_tlast;
    assign rsp_tready    = rsp_ready;

endmodule