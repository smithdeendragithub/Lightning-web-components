import { LightningElement, track, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import OPPID_FIELD from '@salesforce/schema/Opportunity.SF_Opportunity_ID__c';
import ORDER_FIELD from '@salesforce/schema/Opportunity.Order__c';
import ORDERNUMBER_FIELD from '@salesforce/schema/Order__c.Name';


export default class PrintOrderSummary extends LightningElement {
    @api recordId;
    @track sfOppId;
    @track order = '';
    @track orderNumber;
    @track orderNumberDisplay;

    @wire(getRecord, {recordId: '$recordId', fields: [OPPID_FIELD, ORDER_FIELD]})
    opportunityRecord({error, data}) {
        if (data !== undefined ) {
            this.order = data.fields.Order__c.value;
            this.sfOppId = "Opportunity [" + data.fields.SF_Opportunity_ID__c.value + "]";
            console.log(JSON.stringify(data));
        }
    }

    @wire(getRecord, {recordId: '$order', fields: [ORDERNUMBER_FIELD]})
    orderRecord({error, data}) {
        if (data !== undefined) {
            this.orderNumber = data.fields.Name.value;
            this.orderNumberDisplay = this.orderNumber + " - Solutions";
        }
    }
}