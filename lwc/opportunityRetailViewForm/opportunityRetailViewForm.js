import { LightningElement,api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import OPPORTUNITY_ORDERID from '@salesforce/schema/Opportunity.Order__c';
//import { getRecord } from 'lightning/uiRecordApi';
const fields = [OPPORTUNITY_ORDERID];
export default class OpportunityRetailViewForm extends LightningElement {
    @api recordId;
    @wire(getRecord, { recordId: '$recordId', fields }) orderrecord;
    get orderNumberId(){
        return getFieldValue(this.orderrecord.data,OPPORTUNITY_ORDERID);
    }
    
    // renderedCallback(){
    //     console.log('this.recordId' +this.recordId);
    //     console.log(this.record);
    //    // debugger;
    // }
    
    // // debugger;
}