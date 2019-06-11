import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import OPPORTUNITY_ORDERID from '@salesforce/schema/Opportunity.Order__c';
//import { getRecord } from 'lightning/uiRecordApi';
// const fields = [OPPORTUNITY_ORDERID];
// const FIELDS = ['Order__c.Name', 'Order__c.Status__c', 'Order__c.Status__c', 'Order__c.Data_Missing_Codes__c', 'Order__c.Order_Pending_Date__c', 'Order__c.Opportunity_Coordinator__c', 'Order__c.Status_Reason__c', 'Order__c.Data_Missing_Comments__c'];
const fields = [OPPORTUNITY_ORDERID,
    'Opportunity.Order__c',
    'Opportunity.KeyAges__c',
    'Opportunity.Zayo_Reference_Opportunity__c',
    'Opportunity.Slides__c',
    'Opportunity.Owner.Name',
    'Opportunity.Sales_Channel__c',
    'Opportunity.Account.Name',
    'Opportunity.Care_Organization__c',
    'Opportunity.Name',
    'Opportunity.Oppty_Sub_Type__c',
    'Opportunity.Sell_To_Through__c',
    'Opportunity.Case__r.CaseNumber',
    'Opportunity.New_MRR_del__c',
    'Opportunity.CPQ_Total__c',
    'Opportunity.Current_MRR_del__c',
    'Opportunity.Turndown_Product__c',
    'Opportunity.Net_Difference__c',
    'Opportunity.StageName',
    'Opportunity.CloseDate',
    'Opportunity.ForecastCategoryName',
    'Opportunity.Contract_Signed_Date__c',
    'Opportunity.LOA_Signed_By__r.Name',
    'Opportunity.Customer_Requested_Due_Date__c',
    'Opportunity.Amount',
    'Opportunity.NRR_Amount__c',
    'Opportunity.Term__c',
    'Opportunity.Contract_Term_End_Date__c',
    'Opportunity.Coterminous_Contract_Months__c',
    'Opportunity.Total_Contract_Amount__c',
    'Opportunity.CPE_Amount__c',
    'Opportunity.Opportunity_Product__c',
    'Opportunity.UC_Specialist__r.Name',
    'Opportunity.Related_Opportunites__r.Name',
    'Opportunity.Initial_Appointment_Set_Date__c',
    'Opportunity.Initial_Appointment_Held_Date__c',
    'Opportunity.Proposal_Meeting_Set_Date__c',
    'Opportunity.Proposal_Meeting_Held_Date__c',
    'Opportunity.Proposal_Letter__c',
    'Opportunity.NextStep',
    'Opportunity.Vendor_Registration__c',
    'Opportunity.Business_Objectives__c',
    'Opportunity.Proposed_Solutions__c',
    'Opportunity.LeadSource',
    'Opportunity.Referred_By__c',
    'Opportunity.Product_Interest__c',
    'Opportunity.Lead_Notes__c',
    'Opportunity.Campaign.Name',
    'Opportunity.Winning_ICB__r.Name',
    'Opportunity.Current_Provider__c',
    'Opportunity.Current_Provider_LD__c',
    'Opportunity.Description_Custom__c',
    'Opportunity.E_Rate_Opportunity__c',
    'Opportunity.E_Rate_Must_Win__c',
    'Opportunity.E_Rate_Funding_Year__c',
    'Opportunity.Date_470_Filed__c',
    'Opportunity.Allowable_Contract_Date__c',
    'Opportunity.X470__c',
    'Opportunity.Service_Type__c',
    'Opportunity.Bid__c',
    'Opportunity.Bid_Results__c',
    'Opportunity.E_Rate_Process_Status__c',
    'Opportunity.Reason_for_No_Bid__c',
    'Opportunity.X470_Number_Link__c',
    'Opportunity.Split_Owner_1__r.Name',
    'Opportunity.Split_Percent_1__c',
    'Opportunity.Split_Amount_1__c',
    'Opportunity.Opportunity_Parent__r.Name',
    'Opportunity.Split_Owner_2__r.Name',
    'Opportunity.Split_Percent_2__c',
    'Opportunity.Split_Amount_2__c',
    'Opportunity.Lost_Reason__c',
    'Opportunity.Current_Competitors__c',
    'Opportunity.Lost_Reason_Other_Explanation__c',
    'Opportunity.CreatedBy.Name',
    'Opportunity.LastModifiedBy.Name',
    'Opportunity.Account2__r.Name',
    'Opportunity.Service_Country__c',
    'Opportunity.SF_Opportunity_ID__c',
    'Opportunity.Legacy_Opportunity_ID__c',
    'Opportunity.RecordType.Name',
    'Opportunity.Type','Opportunity.Probability',
];

const activeOnes = ['Opp_Metrics', 'oppinfo', 'oppactit', 'addinfo', 'erinfo', 'spopse', 'loopinfo', 'ordst', 'saowwois', 'sysinfo'];
export default class OpportunityRetailViewForm extends LightningElement {
    @api recordId;
    @track activeSections = activeOnes;

    @track hasuirecs = false;
    @track newlistrecs;
    // eslint-disable-next-line no-unused-vars
    @wire(getRecord, { recordId: '$recordId', fields }) orderrecord({ error, data }) {

        if (data !== undefined) {
            this.hasuirecs = true;
            this.newlistrecs = data;
        }
    }
    get orderNumberId() {
        return getFieldValue(this.orderrecord.data, OPPORTUNITY_ORDERID);
    }
}