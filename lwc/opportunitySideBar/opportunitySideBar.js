import { LightningElement,api,wire,track} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

export default class OpportunitySideBar extends LightningElement {
    @api recordId;
    @track hasuirecs = false;
    @track newlistrecs;
    @wire(getRecord, { recordId: '$recordId', fields: ['Opportunity.Order__c'] }) oppRecDetail({ error, data }) {

        if (data !== undefined) {
            // console.log(JSON.stringify(data));
            this.hasuirecs = true;
            this.newlistrecs = data;
        }
    }
}