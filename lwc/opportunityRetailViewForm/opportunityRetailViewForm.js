import { LightningElement,api,wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

export default class OpportunityRetailViewForm extends LightningElement {
    @api recordId;

}