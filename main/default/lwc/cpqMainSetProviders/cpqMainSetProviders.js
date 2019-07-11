import { LightningElement, api, track } from 'lwc';
import setProviders from '@salesforce/apex/lgt_UIHandler.setProviders';

export default class CpqMainSetProviders extends LightningElement {
    @api locationid;
    @api localprovider;
    @api ldprovider;
    @api tfprovider;

    /* Modal Window Starts*/
    @track openmodel = false;
    openmodal() {
        this.openmodel = true
    }
    closeModal() {
        this.openmodel = false
    }
    saveMethod(event) {
        let childElmt = event.target.parentElement.firstChild;
        let jslocalprovider, jsldprovider, jstfprovider;
        while (childElmt) {
            if (childElmt.tagName !== 'LIGHTNING-BUTTON') {
                switch (childElmt.dataset.key) {
                    case 'localprovider':
                        jslocalprovider = childElmt.value;
                        break;
                    case 'ldprovider':
                        jsldprovider = childElmt.value;
                        break;
                    case 'tfprovider':
                        jstfprovider = childElmt.value;
                        break;
                    default:
                        console.log('no value found');
                }
            }

            childElmt = childElmt.nextSibling;
        }

        setProviders({
            oppLocID: this.locationid,
            ldProvider: jsldprovider,
            localProvider: jslocalprovider,
            tfProvider: jstfprovider
        })
            // eslint-disable-next-line no-unused-vars
            .then(result => {
                this.dispatchEvent(new CustomEvent('setprovidersuccess'));
            })
            // eslint-disable-next-line no-unused-vars
            .catch(error => {
                this.dispatchEvent(new CustomEvent('setprovidererror'));
            });

        this.closeModal();
    }
    /* Modal Window closes */
}