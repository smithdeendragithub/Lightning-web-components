import { LightningElement, api } from 'lwc';

export default class TechnicalFormsLocatiaonProduct extends LightningElement {
    @api opportunitylocation;
    
    get opportunitylocation(){
        // eslint-disable-next-line no-alert
        alert('opportunitylocation:'+this.opportunitylocation );
        return this.opportunitylocation;
    }
}