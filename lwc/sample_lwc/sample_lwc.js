import { LightningElement, wire } from 'lwc';
import getContactList from '@salesforce/apex/TestLwC.getContactList';

export default class ApexWireMethodToProperty extends LightningElement {
    @wire(getContactList) contacts;
}