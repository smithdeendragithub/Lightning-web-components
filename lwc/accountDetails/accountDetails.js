import { LightningElement, api, wire} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Opportunity.AccountId'
];

export default class AccountDetails extends LightningElement {
    @api recordId;

    @wire(getRecord, {recordId:'006n0000008jjPHAAY', fields: FIELDS})
    opportunity;

    get accountId() {
        return this.opportunity.data.fields.AccountId.value;
    }

}