import { LightningElement, track, api } from 'lwc';

export default class UtilSelectOptions extends LightningElement {

    @api objectList;
    @api selectedValue;
    @api disableList;
    @track hasValue = false;
    @api elementLabel;
    @track generatedMap;
    @track isRecursion = false;
    initializationComplete = false;

    connectedCallback() {
       // let lineUse,linetype,cblock;
        this.hasValue = (undefined === this.objectList || null == this.objectList) ? false : true;
        this.elementLabel = (undefined === this.elementLabel || null == this.elementLabel) ? 'Choose Option' : this.elementLabel;
        this.generateMapToDisplay([this.selectedValue]);
    }
    @api generateMapToDisplay(inputvalue) {
        this.generatedMap = new Array();
        if (inputvalue !== undefined || inputvalue != null) {
            for (let [key, value] of Object.entries(this.objectList)) {
                let ctemp = Object();
                ctemp.key = `${key}`;
                ctemp.value = `${value}`;
                ctemp.selected = inputvalue.includes(`${key}`);
                this.generatedMap.push(ctemp);
            }
        }
    }
}