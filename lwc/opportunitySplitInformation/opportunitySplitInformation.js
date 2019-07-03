import { LightningElement, track } from 'lwc';

const activeAccordions = ['Split Information'];
export default class OpportunitySplitInformation extends LightningElement {
    @track activeSections = activeAccordions;
}