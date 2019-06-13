import { LightningElement, track, api, wire } from 'lwc';
import getWrapperObject from '@salesforce/apex/lgt_UIHandler.getWrapperData';

export default class CpqMainPage extends LightningElement {
    @api opptyId;
    @track wrapperRecord;
    @track hasrecords = false;
    @track error;


    @wire(getWrapperObject, { opportunityId: '$opptyId' }) wiredOrderList({ error, data }) {

        if (data) {
            // alert('data=>'+data);
            this.error = undefined;
            if (data !== undefined && data.length > 0) {
                this.hasrecords = true;
                this.wrapperRecord = data;
                // eslint-disable-next-line no-debugger
                debugger;
            }
            // console.log('test=> ' + JSON.stringify(this.orderlist));
        } else if (error) {
            this.error = error;
            this.wrapperRecord = undefined;
        }
    }

}