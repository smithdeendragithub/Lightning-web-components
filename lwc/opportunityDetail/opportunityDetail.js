import { LightningElement, track } from 'lwc';

const activeAccordions = ['Detail'];
export default class OpportunityDetail extends LightningElement {
    @track activeSections = activeAccordions;
}