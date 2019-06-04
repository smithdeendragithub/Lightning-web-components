import { LightningElement, track, api, wire } from 'lwc';
import { getFieldDisplayValue } from 'lightning/uiRecordApi';


export default class PrintOrderSummary extends LightningElement {
    @api recordId;

    get sfOppId() {
        return getFieldDisplayValue({id: '$recordId'}, 'Opportunity.SF_Opportunity_ID__c');
    }


}