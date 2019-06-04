/* eslint-disable no-console */
import { LightningElement, api, wire, track } from 'lwc';
//import {getRecord} from 'lightning/uiRecordApi';
import getLocationList from '@salesforce/apex/lgt_ManageLocationConfigController.init';
//const FIELDS = ['Opportunity.Name'];
export default class TechnicalForms extends LightningElement {
    @api oppid;
    @api progWrap;
    @track error;
    @track oppname;
    
    @wire(getLocationList, {opportunityId:'$oppid'})
    wireTheList ({error, data}) {
        if (data) {
            // eslint-disable-next-line no-alert
            //alert('progWrap :'+this.progWrap);
            // eslint-disable-next-line no-alert
            //alert('data :'+data);

            this.progWrap = data;
            // eslint-disable-next-line no-alert
            //alert('progWrap :'+this.progWrap);
            // eslint-disable-next-line no-alert
            //alert('progWrap.opportunityLocations :'+this.progWrap.opportunityLocations);
            // eslint-disable-next-line no-alert
            //alert('titleLabel :'+this.progWrap.opportunity.Name);
            this.oppname = this.progWrap.opportunity.Name;
            //console.log('test value =>'+JSON.stringify(this.progWrap));
           
            this.error = undefined;
            // eslint-disable-next-line no-alert
            //alert('data length :'+data.length);
            // eslint-disable-next-line no-alert
            //alert('data length :'+this.progWrap.opportunityLocationss);


        } else if (error) {
            // eslint-disable-next-line no-alert
            //alert('check eror'+error);
            this.error = error;
            this.progWrap = undefined;
        }
    }
    get titleLabel() {
            // eslint-disable-next-line no-alert
        // eslint-disable-next-line no-undef 
        //alert('titleLabel :'+this.progWrap.opportunity.Name);
        
        return 'Manage Location Information for '+ this.oppname;
    }
}