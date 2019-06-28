/*eslint no-debugger: "error"*/
import { LightningElement, track, api, wire } from 'lwc';
import getWrapperObject from '@salesforce/apex/lgt_UIHandler.retrieveWrapperData';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import TERMOPTIONS from '@salesforce/schema/Opportunity.Term__c';
import SOLUTIONRELATEDSR from '@salesforce/resourceUrl/productResources';
const accessAvailabilityColumns = [
    { label: 'Carrier NNI', fieldName: 'Carrier__c', type: 'text' },
    { label: 'Access Technology Name', fieldName: 'Access_Technology_Name__c', type: 'text' },
    { label: 'Minimum Bandwidth', fieldName: 'Minimum_Bandwidth__c', type: 'number' },
    { label: 'Maximum Bandwidth (Mbps)', fieldName: 'Maximum_Bandwidth__c', type: 'number' },
    { label: 'Minimum Required Revenue', fieldName: 'Minimum_Required_Revenue__c', type: 'currency' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' }

];

export default class CpqMainPage extends LightningElement {
    @api opptyId;
    @track wrapperRecord = [];
    @track hasrecords = false;
    @track error;
    accessAvailabilityColumns = accessAvailabilityColumns;
    @track baabybldgid = [];
    buttonClicked = false;
    @track cssClass = 'slds-hide';
    showaccess = 'Show Access Availability';
    hideaccess = 'Hide Access Availability';
    activeImg = SOLUTIONRELATEDSR + '/images/activeIcon.png';
    inactiveImg = SOLUTIONRELATEDSR + '/images/inactiveIcon.png';

    @wire(getPicklistValues, { recordTypeId: '0121A000000QeQBQA0', fieldApiName: TERMOPTIONS }) termList;
    

    @wire(getWrapperObject, { opportunityId: '$opptyId' }) wiredWrapperList({ error, data }) {
        
        if (data) {
            this.error = undefined;
            if (data !== undefined) {
                this.hasrecords = true;
                this.wrapperRecord = data;
                if (data.BaaByBldgId) {
                    // eslint-disable-next-line guard-for-in
                    for (let keyvalue in data.BaaByBldgId) {
                        //let testMap = [];
                        this.baabybldgid.push({ key: keyvalue, value: data.BaaByBldgId[keyvalue] });
                    }
                }

                console.log('this.baabybldgid' + this.baabybldgid);
               
            }
        } else if (error) {
            this.error = error;
            this.wrapperRecord = undefined;
        }
    }

    handleToggleClick(event) {

        let targetId = event.target.getAttribute("id");
        let alreadyChecked = false;
       
        // eslint-disable-next-line @lwc/lwc/no-inner-html
        event.target.innerHTML = event.target.innerHTML === this.showaccess ? this.hideaccess : this.showaccess;
        this.template.querySelectorAll('c-cpq-main-display-access-availability-table').forEach(element => {
            if(targetId.includes(element.buildingRecId) && !alreadyChecked){
                this.alreadyChecked = true;
                element.handleToggleClick();
            }
        });

    }

}