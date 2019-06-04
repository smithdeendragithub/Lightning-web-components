import { LightningElement, api, track, wire } from 'lwc';
import getOrderNumber from '@salesforce/apex/lgt_DataFactory.getOrderNumber';


export default class OrderSummary extends LightningElement {
    @api opportunity;
    @wire (getOrderNumber, {opportunityId: '$opportunity'}) 
    OrderList;

    // console.log(OrderList);
    
}