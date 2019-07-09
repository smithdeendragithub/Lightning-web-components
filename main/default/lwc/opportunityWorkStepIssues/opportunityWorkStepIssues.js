import { LightningElement, track, api, wire } from 'lwc';
import getWSIRelatedOrderList from '@salesforce/apex/Order_WorkstepIssuesController.getWorkstepIssuesByOrderID';
const columns = [
    { label: 'Order', fieldName: 'OrderName', type: 'url' },
    { label: 'SubOrder', fieldName: 'SubOrderName', type: 'url' },
    { label: 'Workstep Issue', fieldName: 'Name' },
    { label: 'Workstep', fieldName: 'WorkstepName' },
    { label: 'Reason', fieldName: 'Reason' },
    { label: 'Status', fieldName: 'Status' },
    { label: 'Owner', fieldName: 'OwnerName' },
    { label: 'Expected Followup Date', fieldName: 'ExpectedFollowUpDate', type: 'date' },
    { label: 'Estimated Resolution', fieldName: 'EstimatedResolution', type: 'date' }
];

export default class OpportunityWorkStepIssues extends LightningElement {
    @api orderid;
    @api sowsiList;
    @track error;
    @track columns = columns;
    @track hasrecords = false;
    //wsirolist;
    @api showcard = false;

    @wire(getWSIRelatedOrderList, { orderID: '$orderid' }) wiredwsirolist({ error, data }) {
        if (data) {
            this.sowsiList = data;
            this.error = undefined;
            if(data !== undefined && data.length > 0){
                this.hasrecords = true;
            }
        } else if (error) {
            this.error = error;
            this.sowsiList = undefined;
        }
    }

}