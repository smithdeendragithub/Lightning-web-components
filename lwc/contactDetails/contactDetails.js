/* eslint-disable */
import { LightningElement, api, track, wire } from 'lwc';
import getPrintOrderData from '@salesforce/apex/lgt_DataFactory.getPrintOrderData';

const activeAccordions = ['Contacts'];

export default class ContactDetails extends LightningElement {

    @track data;
    @track activeSections = activeAccordions;

    @wire(getPrintOrderData, { opportunityId: '006n0000008jlksAAA', solutionId: 'a0fn0000001ICTsAAO'})
    solutionTableData(result) {
        var contactData = [];
        if (result.data) {
            var conWrapData = result.data.conWrap;
            for (var contact in conWrapData) {
                var contactObject = new Object();
                contactObject.displayName = conWrapData[contact].contact.Name + '---' + conWrapData[contact].contactRole;
                contactObject.contactId = conWrapData[contact].contact.Id;

                contactData.push(contactObject);
            }

            this.data = contactData;
            console.log(JSON.stringify(this.data));
        }
    }

    toggleSection(event){
        event.target.parentNode.parentElement.classList.toggle("slds-is-open");
    }
}