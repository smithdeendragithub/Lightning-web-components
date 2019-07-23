import { LightningElement, track, api, wire} from 'lwc';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import getfeatureData from '@salesforce/apex/lgt_UIHandler.initiateFeaturesDataSet';

export default class FeatureSchedule extends LightningElement {
    featuresScheduleWiredData;
    @track featuresScheduleDataSet = [];
    @api fstrecid = 'a0jn0000001MXYmAAO';
    @track error;
    @track hasrecords = false;

    // eslint-disable-next-line no-undef
    @wire(CurrentPageReference) pageRef;

    disconnectedCallback(){
        unregisterAllListeners(this);
    }

    connectedCallback() {
        registerListener('selectedValue',this.handleOptionSelected,this);
        getfeatureData({ featureScheduleRecId: 'a0jn0000001MXYmAAO' })
            .then(result => {
                this.hasrecords = true;
                this.featuresScheduleDataSet = result;
            })
            .catch(error => {
                this.error = error;
            });
    }
    handleOptionSelected(){
        alert('Alert sample');
    }

    handleNumberSelected(event){
        // console.log(JSON.stringify(event.target.dataset.inputobject));
        // let valueToSend;
        // for (let inputvalue of this.featuresScheduleDataSet.TelephoneNumbers) {
           
        //     if(undefined !== inputvalue.cn && inputvalue.cn.Id === event.target.dataset.dataId){
        //         valueToSend = inputvalue;
        //     }
        //   }
         // console.log(valueToSend);
        fireEvent(this.pageRef,'phoneNumberSelected',{"recordObject":this.featuresScheduleDataSet,"dataId":event.target.dataset.dataId});
    }
    cancelButton(event){
        fireEvent(this.pageRef,'phoneNumberSelected',event)
    }
}