import { LightningElement, track, api, wire } from 'lwc';
import getOrderList from '@salesforce/apex/lgt_DataFactory.getOrderNumber';
export default class OppOrderList extends LightningElement {
@api opptyid;
@track orderList;
@track hasrecords = false;
@wire(getOrderList, { orderID: '$opptyid' }) wiredwsirolist;

}