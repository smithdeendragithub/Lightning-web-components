import { LightningElement, api } from 'lwc';

export default class CpqMainDispayApprovalRequestDate extends LightningElement {
    @api solutionActive;
    @api cmptCount;
    @api mgrCount;
    @api icbCount;
    @api approvalRequested;
    @api approvalRequestDate;

    get canDisplay() {
        let returnValue = false;
        if (this.solutionActive && this.cmptCount > 0 && this.mgrCount > 0 && this.icbCount === 0 && this.approvalRequested) {
            returnValue = true;
        }
        return returnValue;
    }
}