import { LightningElement,api,track } from 'lwc';
const accessAvailabilityColumns = [
    { label: 'Carrier NNI', fieldName: 'Carrier__c', type: 'text' },
    { label: 'Access Technology Name', fieldName: 'Access_Technology_Name__c', type: 'text' },
    { label: 'Minimum Bandwidth', fieldName: 'Minimum_Bandwidth__c', type: 'number' },
    { label: 'Maximum Bandwidth (Mbps)', fieldName: 'Maximum_Bandwidth__c', type: 'number' },
    { label: 'Minimum Required Revenue', fieldName: 'Minimum_Required_Revenue__c', type: 'currency' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' }
    
];

export default class CpqMainDisplayAccessAvailabilityTable extends LightningElement {
    @api buildingRecId;
    @api oppLocationBuildgId;
    @api recordsToDisplay=[];
    accessAvailabilityColumns = accessAvailabilityColumns;
    @track cssClass = 'slds-hide';
    @track cssNoRecClass = 'slds-hide slds-text-body_regular';
    @track showaccess = 'Show Access Availability';
    norecdisplay = 'No Records to Display';

    get sameBuilding(){
        let sameRecord = false;
        if(this.buildingRecId === this.oppLocationBuildgId){
            sameRecord = true;
        }
        return sameRecord;
    }

    get hasrecords(){
        
        return this.recordsToDisplay.length > 0 ? true:false;

    }

    @api handleToggleClick() {
        // console.log(event);
        this.buttonClicked = !this.buttonClicked;
        this.cssClass = this.buttonClicked ? 'slds-box slds-is-open slds-align_absolute-center' : 'slds-box slds-hide slds-align_absolute-center';
        this.cssNoRecClass = this.buttonClicked ? 'slds-box slds-is-open slds-text-color_error slds-align_absolute-center':'slds-box slds-hide slds-text-color_error slds-align_absolute-center';
        this.showaccess = this.buttonClicked ? 'Hide Access Availability' : 'Show Access Availability';
        
    }
    // @api showAlert(){
    //     alert('bow => '+this.buildingRecId);
    //     this.buttonClicked = !this.buttonClicked;
    //     this.cssClass = this.buttonClicked ? 'slds-is-open slds-align_absolute-center' : 'slds-hide slds-align_absolute-center';
    //     this.cssNoRecClass = this.buttonClicked ? 'slds-is-open slds-text-color_error slds-align_absolute-center':'slds-hide slds-text-color_error slds-align_absolute-center';
    //     this.showaccess = this.buttonClicked ? 'Hide Access Availability' : 'Show Access Availability';
    // }
}