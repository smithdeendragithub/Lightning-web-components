import { LightningElement, track, wire, api } from 'lwc';
import getWSIRelatedOrderList from '@salesforce/apex/Order_WorkstepIssuesController.getWorkstepIssuesByOrderID';

export default class Salesownedwsionrelatedorderflag extends LightningElement {
    @api orderid;
    @track wsirolist;
    @track error;
    @track baseUrl = '';
    // @api redflag = window.location.origin.concat('/img/samples/flag_red.gif');
    // @api greenflag = window.location.origin.concat('/img/samples/flag_green.gif');

    @wire(getWSIRelatedOrderList, { orderID: '$orderid' })
    wiredwsirolist({ error, data }) {
        if (data) {
            this.wsirolist = data;
            this.error = undefined;
            this.baseUrl = window.location.origin.concat('/img/samples/flag_red.gif') ;
        } else if (error) {
            this.error = error;
            this.wsirolist = undefined;
            this.baseUrl = window.location.origin.concat('/img/samples/flag_green.gif');
        }
       
        // console.log('smith'); 
        // console.log('window.location.origin => ' + window.location.origin);
        // console.log('this.logUrl'+this.baseUrl);
        // console.log('<img src='+this.baseUrl+'/>')
    }
}