import { LightningElement,api } from 'lwc';

export default class MathDisplay extends LightningElement {
    @api inputvalueone;
    @api inputvaluetwo;
    @api arithmeticOperation;
    retValue;

    get resultValue(){
        if(this.inputvalueone !== undefined && this.inputvaluetwo !== undefined)
        switch(this.arithmeticOperation){
            case 'add':
                this.retvalue = this.inputvalueone + this.inputvaluetwo;
                break;
            case 'minus':
                this.retValue = this.inputvalueone - this.inputvaluetwo;
                break;
            case 'multiply':
                this.retValue = this.inputvalueone * this.inputvaluetwo;
                break;
            case 'divide':
                this.retValue = this.inputvalueone / this.inputvaluetwo;
                break;
            default:
                this.retValue = 'Not a valid arithmetic Operation use \'add\',\'minus\',\'multiply\',\'divide\'';
        }
        return this.retValue;
    }
}