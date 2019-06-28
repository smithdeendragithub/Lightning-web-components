import { LightningElement,api } from 'lwc';

export default class CpqMainDisplayActiveImage extends LightningElement {
    @api inputOne;
    @api inputTwo;
    @api displayValue;
    @api urlOne;
    @api urlTwo;

    get displayurlone(){
        let returnvalueone = false;
        if(this.inputOne && !this.inputTwo){
            returnvalueone = true;
        }
        return returnvalueone;
    }

    get displayurltwo(){
        let returnvalue = false;
        if(!this.inputOne || this.inputTwo){
            returnvalue = true;
        }
        return returnvalue;
    }
}