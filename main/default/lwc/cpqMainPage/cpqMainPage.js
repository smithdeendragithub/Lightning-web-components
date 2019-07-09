/*eslint no-debugger: "error"*/
import { LightningElement, track, api, wire } from 'lwc';
import getWrapperObject from '@salesforce/apex/lgt_UIHandler.retrieveWrapperData';
import takeLocationOffHold from '@salesforce/apex/lgt_UIHandler.takeLocationOffHold';
import placeLocationOnHOld from '@salesforce/apex/lgt_UIHandler.placeLocationOnHOld';
import { refreshApex } from '@salesforce/apex';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import TERMOPTIONS from '@salesforce/schema/Opportunity.Term__c';
import SOLUTIONRELATEDSR from '@salesforce/resourceUrl/productResources';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const accessAvailabilityColumns = [
    { label: 'Carrier NNI', fieldName: 'Carrier__c', type: 'text' },
    { label: 'Access Technology Name', fieldName: 'Access_Technology_Name__c', type: 'text' },
    { label: 'Minimum Bandwidth', fieldName: 'Minimum_Bandwidth__c', type: 'number' },
    { label: 'Maximum Bandwidth (Mbps)', fieldName: 'Maximum_Bandwidth__c', type: 'number' },
    { label: 'Minimum Required Revenue', fieldName: 'Minimum_Required_Revenue__c', type: 'currency' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' }

];

export default class CpqMainPage extends LightningElement {
    retrievedValue;
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
    @track totalMRC;
    @track totalNRC;


    @wire(getPicklistValues, { recordTypeId: '0121A000000QeQBQA0', fieldApiName: TERMOPTIONS }) termList;


    @wire(getWrapperObject, { opportunityId: '$opptyId' }) wiredWrapperList(retrievedValue) {
        this.retrievedValue = retrievedValue;
        const { data, error } = retrievedValue;
        if (data) {
            this.error = undefined;
            if (data !== undefined) {
                this.hasrecords = true;
                this.wrapperRecord = data;
                this.totalMRC = data.opportunity.Amount;
                this.totalNRC = data.opportunity.NRR_Amount__c;
                if (data.BaaByBldgId) {
                    // eslint-disable-next-line guard-for-in
                    for (let keyvalue in data.BaaByBldgId) {
                        //let testMap = [];
                        this.baabybldgid.push({ key: keyvalue, value: data.BaaByBldgId[keyvalue] });
                    }
                }
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
            if (targetId.includes(element.buildingRecId) && !alreadyChecked) {
                this.alreadyChecked = true;
                element.handleToggleClick();
            }
        });

    }

    handlePlaceOnHold(event) {
        let LocationIdToHold = event.target.ariaLabel;
        placeLocationOnHOld({ inputObject: this.wrapperRecord, locationId: LocationIdToHold })
            // eslint-disable-next-line no-unused-vars
            .then(result => {
                this.refreshData(result,'Location Placed on Hold Successfully','success');
            })
            .catch(error => {
                this.refreshData(error,'Some Error Occured ! Location on Hold was not successful, Please contact your Salesforce Admin','error');
            });
    }

    handleTakeOffOnHold(event) {
        let LocationIdToHold = event.target.ariaLabel;
        takeLocationOffHold({ inputObject: this.wrapperRecord, locationId: LocationIdToHold })
            // eslint-disable-next-line no-unused-vars
            .then(result => {
                this.refreshData(result,'Location Taken Off from Hold Successfully','success');
            })
            .catch(error => {
                this.refreshData(error,'Some Error Occured ! Location Taken Off from Hold was not successful, Please contact your Salesforce Admin','error');
            });

    }

    toggleSection(event) {
        event.target.parentNode.parentElement.parentNode.parentElement.classList.toggle("slds-is-open");
    }
    
    refreshData(result,tstMsg,tstVariant) {
        if (result !== undefined) {

            this.template.querySelectorAll('c-cpq-main-display-access-availability-table').forEach(element => {
                // eslint-disable-next-line @lwc/lwc/no-inner-html
                element.parentElement.previousSibling.lastChild.lastChild.lastChild.innerHTML = this.showaccess;
                element.parentNode.removeChild(element);
                // eslint-disable-next-line no-debugger
                debugger;
            });

            this.dispatchEvent(new ShowToastEvent({
                "title": tstVariant === 'success'? 'Success!':'Error!',
                "message": tstMsg,
                "variant": tstVariant
            }));
        }

        refreshApex(this.retrievedValue);
    }

    setProviderSuccess(){
        this.refreshData(true,'Providers Info updated successfully','success');
    }

    setProviderError() {
        this.refreshData(true,'Some Error Occured ! Providers Info not updated, Please contact your Salesforce Admin','error');
    }
}