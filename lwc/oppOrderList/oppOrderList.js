import { LightningElement, track, api, wire } from 'lwc';
import getOrderList from '@salesforce/apex/lgt_DataFactory.getOrderNumber';
import { getRecord } from 'lightning/uiRecordApi';
const FIELDS = ['Order__c.Name', 'Order__c.Status__c', 'Order__c.Status__c', 'Order__c.Data_Missing_Codes__c', 'Order__c.Order_Pending_Date__c', 'Order__c.Opportunity_Coordinator__c', 'Order__c.Status_Reason__c', 'Order__c.Data_Missing_Comments__c'];

export default class OppOrderList extends LightningElement {
    @api orderid;
    @track orderlist;
    @track hasrecords = false;
    @track error;


    @wire(getOrderList, { opportunityId: '$orderid' }) wiredOrderList({ error, data }) {

        if (data) {
            // alert('data=>'+data);
            this.error = undefined;
            if (data !== undefined && data.length > 0) {
                this.hasrecords = true;
                this.orderlist = data;
            }
            // console.log('test=> ' + JSON.stringify(this.orderlist));
        } else if (error) {
            this.error = error;
            this.orderlist = undefined;
        }
    }

    // seconblock
    @track hasuirecs = false;
    @track newlistrecs;
    @api showcard = false;


    // eslint-disable-next-line no-unused-vars
    @wire(getRecord, { recordId: '$orderid', fields: FIELDS }) orderRec({ error, data }) {

        if (data !== undefined) {
            console.log(JSON.stringify(data));
            this.hasuirecs = true;
            this.newlistrecs = data;
        }
    }
    get linkurl(){
        return '/'+ this.newlistrecs.id;
    }

}