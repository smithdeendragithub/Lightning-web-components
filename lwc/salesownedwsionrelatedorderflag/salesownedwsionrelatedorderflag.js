import { LightningElement, track, wire, api } from 'lwc';
import getWSIRelatedOrderList from '@salesforce/apex/Order_WorkstepIssuesController.getWorkstepIssuesByOrderID';

export default class Salesownedwsionrelatedorderflag extends LightningElement {
    @api orderid;
    @track wsirolist;
    @track error;
    logUrl ="";


    @wire(getWSIRelatedOrderList, { orderID: '$orderid' })
    wiredwsirolist({ error, data }) {
        var baseUrl = window.location.origin;
        if (data) {
            this.wsirolist = data;
            this.error = undefined;
            this.logUrl = baseUrl.concat('/img/samples/flag_red.gif');
        } else if (error) {
            this.error = error;
            this.wsirolist = undefined;
            this.logUrl = baseUrl.concat('/img/samples/flag_green.gif');
        }
       
        // console.log('smith'); 
        // console.log('window.location.origin => ' + window.location.origin);
        // console.log('this.logUrl'+this.logUrl);
    }

}