import { LightningElement, track, wire, api } from 'lwc';
import relatedOrderList from '@salesforce/apex/Order_WorkstepIssuesController.getWorkstepIssuesByOrderID';
import GREENFLAG from '@salesforce/resourceUrl/greenflag';
import REDFLAG from '@salesforce/resourceUrl/redflag'
export default class Salesownedwsionrelatedorderflag extends LightningElement {
    @api orderid;
    @track error;
    @track baseUrl;
    @api showcard = false;
    // @track hasred = false;
    // @track hasgreen = true;
    // greenflag = window.location.origin.concat('/img/samples/flag_green.gif');
    // redflag = window.location.origin.concat('/img/samples/flag_red.gif');

    @wire(relatedOrderList, { orderID: '$orderid' }) wiredwsirolist({ error, data }) {
        if (data=== undefined || data.length === 0) {
            // this.baseUrl = window.location.origin.concat('/img/samples/flag_green.gif');
            this.baseUrl = GREENFLAG;
        } if (data!== undefined && data.length > 0) {
            // this.baseUrl = window.location.origin.concat('/img/samples/flag_red.gif');
            this.baseUrl = REDFLAG;
        }
        else if (error) {
            this.error = error;
        }
    }

}