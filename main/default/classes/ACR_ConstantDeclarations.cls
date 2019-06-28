/** 
 * Class :- ACR_ConstantDeclarations
 * @author :- Perficient.
 * purpose:- Constant declarations for credit/refund implementation
 */
public with sharing class ACR_ConstantDeclarations {
	public static final String HR_ERROR_FUNCTIONALITY_NAME = 'HR Integration Batch Apex';
	public static final String APPROVAL_MATRIX_TRIGGER_ERROR = 'ACR_ApprovalMatrixTriggerHelper';
    public static final String OPERATION_NAME_TRIGGER= 'Update';
    public static final String OPERATION_NAME_BATCH_UPSERT= 'Upsert';
    public static final String SYSTEM_ADMIN='System Administrator';
    public static final String STATUS='Pending';
    public static final String APPROVE ='approve';
    public static final String REJECT ='reject';
    public static final String REASSIGN ='reassign';
    public static final Integer SIZE_OF_ITEMS_TO_APPROVE_PER_PAGE = 4;
    public static final String SUBMIT_PROCESS_ERROR= 'Submit Process Error';
    public static final String OPERATION_NAME_UPDATE_FIELD= 'Update';
  	public static final String SUBMIT_PROCESS_INITIALIZATION= 'Initialization Error';
  	public static final String SUBMIT_PROCESS_USER_DETAILS= 'User Details Check';
  	public static final String SUBMIT_PROCESS_FUNCTIONALITY= 'Approval Processing error';
  	public static final String ITEMS_TO_APPROVE_ERROR= 'Items To Approve Error';
  	public static final String FETCHING_PROCESS_INSTANCE_WORKITEM_ERROR= 'Error in Fetching Process Instance Workitems';
  	public static final String PAGINATION_ERROR='Error in Pagination';
  	public static final String PAGINATION_ERROR_IN_NEXT='Error in Paginations next';
  	public static final String PAGINATION_ERROR_IN_PREVIOUS='Error in Paginations previous';
  	public static final String PROCESS_STEPS_ERROR='Error in Process Steps';
  	public static final String FETCHING_PROCESS_INSTANCE_HISTORY_ERROR= 'Error in Fetching Process Instance History';  	
    public static final String RECORD_TYPE_REFUND = 'Refund';
}