import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class ReturnNavigationButton extends NavigationMixin(LightningElement) {
    @api objectrecordid;
    @api objectname;
    @api buttonlabel;
    
    handleClick(){        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                actionName: "view",
                recordId: this.objectrecordid,
                objectApiName: this.objectname,                
            },
            state: {
                nooverride: '1'
            }
        });
    }


}