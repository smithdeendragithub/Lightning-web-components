import { LightningElement, api,wire } from 'lwc';
import getWSIRelatedOrderList from '@salesforce/apex/Order_WorkstepIssuesController.getWorkstepIssuesByOrderID';

export default class OpportunityWorkStepIssues extends LightningElement {
    @api orderid;
    @api sowsiList;
    wsirolist;

    @wire(getWSIRelatedOrderList, { orderID: '$orderid' })
    wiredwsirolist({ error, data }) {
        if (data) {
            this.wsirolist = data;
            this.error = undefined;
            console.log(JSON.stringify(this.wsirolist));
        } else if (error) {
            this.error = error;
            this.wsirolist = undefined;
            console.log(JSON.stringify(this.wsirolist));
        }
    }
}