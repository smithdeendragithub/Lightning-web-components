import { LightningElement, api, wire, track} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Opportunity.AccountId', 
    'Opportunity.OwnerId'
];

const activeAccordions = ['Details'];

export default class AccountDetails extends LightningElement {
    @api recordId;
    @track accountId;
    @track ownerId;
    @track activeSections = activeAccordions;

    @wire(getRecord, {recordId:'006n0000008jlksAAA', fields: FIELDS})
    opportunity(result) {
        if (result.data) {
            this.accountId = result.data.fields.AccountId.value;
            this.ownerId = result.data.fields.OwnerId.value;
        }
    }
 
    // get accountId() {
    //     return this.opportunity.data.fields.AccountId.value;
    // }

}