import { LightningElement, track, api, wire } from 'lwc';
import getOrderList from '@salesforce/apex/lgt_DataFactory.getOrderNumber';

export default class OppOrderList extends LightningElement {
    @api orderid;
    @track orderlist;
    @track hasrecords = false;
    @track error;
    @wire(getOrderList, { opportunityId: '$orderid' }) wiredOrderList({ error, data }) {
        if (data) {
            // alert('data=>'+data);
            this.orderlist = data;
            this.error = undefined;
            if (data !== undefined && data.length > 0) {
                this.hasrecords = true;
            }
        } else if (error) {
            alert('error=>' + error);
            this.error = error;
            this.orderlist = undefined;
        }
    }

}