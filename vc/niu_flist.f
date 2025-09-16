$DTI_PR/rtl/dti_pr_iniu_define.sv

`ifndef EXCLUDE_FOUNDATION_IP
    -f $FCIP_DIR/vc/fcip.f
    -f $LWNOC_LOWPOWER_COMPONENT/src/vc/lwnoc_lp_core.f
`endif

-f $DTI_PR/vc/iniu_flist.f 
-f $DTI_PR/vc/tniu_flist.f

$DTI_PR/rtl/dti_pr_iniu_async_sys_side.sv
$DTI_PR/rtl/dti_pr_iniu_async_top_side.sv
$DTI_PR/rtl/dti_tniu_async_sys_side.sv
$DTI_PR/rtl/dti_tniu_async_top_side.sv