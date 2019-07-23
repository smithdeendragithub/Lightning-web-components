import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
export default class FeatureScheduledetail extends LightningElement {
    @track hasrecords = false;
    @track inputObject;
    @track luo;
    @track lto;
    @track cbo;
    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        registerListener('phoneNumberSelected', this.optionSelection, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    renderedCallback() {

    }
    displaySelectedNumberDetails() {
        alert();
    }
    optionSelection(payload) {
        // let valueToSend;
        if (undefined !== payload.recordObject.lineUseOptions) {
            this.luo = payload.recordObject.lineUseOptions;
        }
        if (undefined !== payload.recordObject.lines) {
            this.lto = payload.recordObject.lines;
        }
        if (undefined !== payload.recordObject.callBlocklines) {
            this.cbo = payload.recordObject.callBlocklines;
        }
        for (let inputvalue of payload.recordObject.TelephoneNumbers) {
            if (undefined !== inputvalue.cn && inputvalue.cn.Id === payload.dataId) {
                this.inputObject = inputvalue;
                this.hasrecords = true;
                let lineUse = undefined === inputvalue.cn.Line_Use__c ? '--Select--' : inputvalue.cn.Line_Use__c;
                let linetype = undefined === inputvalue.cn.Opportunity_Line_Item__c ? '--Select--' : inputvalue.cn.Opportunity_Line_Item__c;
                let callblockoption = undefined === inputvalue.cn.Call_Blocking__c ? '--Select--' : inputvalue.cn.Call_Blocking__c;
                this.template.querySelectorAll('c-util-select-options').forEach(element => {
                    element.generateMapToDisplay([lineUse, linetype, callblockoption]);
                });
            }
        }
        //  = valueToSend;
    }

    handleClearAll() {
        this.hasrecords = false;
        this.inputObject = undefined;
    }
    testfunction(event) {
        alert('amazing' + event.target.tagName);
    }
}