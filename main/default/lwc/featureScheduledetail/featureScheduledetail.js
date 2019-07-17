import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
export default class FeatureScheduledetail extends LightningElement {
    @track hasrecords = false;
    @track inputObject;
    @wire(CurrentPageReference) pageRef;

    connectedCallback(){
        registerListener('phoneNumberSelected',this.optionSelection,this);
    }

    disconnectedCallback(){
        unregisterAllListeners(this);
    }

    displaySelectedNumberDetails(){
        alert();
    }
    optionSelection(event){
        this.hasrecords = true;
        this.inputObject = event;
        alert(event);
    }

    handleClearAll(){
        this.hasrecords = false;
        this.inputObject = undefined;
    }
}