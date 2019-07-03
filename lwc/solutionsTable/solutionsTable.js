/* eslint-disable */
import { LightningElement, track, wire } from 'lwc';
import getPrintOrderData from '@salesforce/apex/lgt_DataFactory.getPrintOrderData';

const columns = [
    {label: 'Name', fieldName: 'name', cellAttributes: {alignment: 'left'}}, 
    {label: 'Term', fieldName: 'term', type: 'number', cellAttributes: {alignment: 'left'}}, 
    {label: 'Active', fieldName: 'isActive', type: 'boolean', cellAttributes: {alignment: 'left'}}, 
    {label: 'MRC Total', fieldName: 'mrcTotal', type: 'currency', cellAttributes: {alignment: 'left'}}, 
    {label: 'NRC Total', fieldName: 'nrcTotal', type: 'currency', cellAttributes: {alignment: 'left'}},
    {label: 'Approval Status', fieldName: 'approvalStatus', cellAttributes: {alignment: 'left'}}
];

export default class SolutionsTable extends LightningElement {
    @track solutionData = [];
    @track columns = columns;
    @track data;

    @wire(getPrintOrderData, { opportunityId: '006n0000008jlksAAA', solutionId: 'a0fn0000001ICTsAAO'})
    solutionTableData(result) {
        if (result.data) {
            var conts = result.data.currentOrders;
            for (var order in conts) {
                for (var solution in conts[order].sols) {
                    var dataSolution = new Object();

                    if (conts[order].sols[solution].rawSolution.Name) {
                        dataSolution.name = conts[order].sols[solution].rawSolution.Name;
                    } else {
                        dataSolution.name = '';
                    }

                    if (conts[order].sols[solution].rawSolution.Term__c) {
                        dataSolution.term = conts[order].sols[solution].rawSolution.Term__c;
                    } else {
                        dataSolution.term = conts[order].sols[solution].rawSolution.Term__c;
                    }

                    if (conts[order].sols[solution].rawSolution.Active__c) {
                        dataSolution.isActive = conts[order].sols[solution].rawSolution.Active__c;
                    } else {
                        dataSolution.isActive = '';
                    }

                    if (conts[order].sols[solution].rawSolution.MRC_Total__c) {
                        dataSolution.mrcTotal = conts[order].sols[solution].rawSolution.MRC_Total__c;
                    } else {
                        dataSolution.mrcTotal = '';
                    }

                    if (conts[order].sols[solution].rawSolution.NRC_Total__c) {
                        dataSolution.mrcTotal = conts[order].sols[solution].rawSolution.MRC_Total__c;
                    } else {
                        dataSolution.nrcTotal = '';
                    }

                    if (conts[order].sols[solution].approvalStatus) {
                        dataSolution.approvalStatus = conts[order].sols[solution].approvalStatus;
                    } else {
                        dataSolution.approvalStatus = '';
                    }

                    this.solutionData.push(dataSolution);
                    
                }
            }

            this.data = this.solutionData;
            console.log(JSON.stringify(this.solutionData));
        }
    }
}