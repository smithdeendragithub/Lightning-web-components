/* eslint-disable */
import { LightningElement, track, wire } from 'lwc';
import getPrintOrderData from '@salesforce/apex/lgt_DataFactory.getPrintOrderData';

const columns = [
    {label: 'Name', fieldName: "name"}, 
    {label: 'Term', fieldName: "term"}, 
    {label: 'Active', fieldName: "isActive"}, 
    {label: 'MRC Total', fieldName: "mrcTotal"}, 
    {label: 'NRC Total', fieldName: "nrcTotal"},
    {label: 'Approval Status', fieldName: "approvalStatus"}
];

// const columns = [
//     {label: 'Opportunity name', fieldName: 'opportunityName', type: 'text'},
//     {label: 'Confidence', fieldName: 'confidence', type: 'percent', cellAttributes:
//     { iconName: { fieldName: 'trendIcon' }, iconPosition: 'right' }},
//     {label: 'Amount', fieldName: 'amount', type: 'currency', typeAttributes: { currencyCode: 'EUR'}},
//     {label: 'Contact Email', fieldName: 'contact', type: 'email'},
//     {label: 'Contact Phone', fieldName: 'phone', type: 'phone'},
// ];
export default class SolutionsTable extends LightningElement {
    solutionData = [];
    @track solutionNames = [];
    @track solutionTerms = [];
    @track solutionActive = [];
    @track solutionMRC = [];
    @track solutionNRC = [];
    @track solutionApproval = [];
    @track newSolutionData = [];
    @track columns = columns;
    hasRecords = false;


    // @wire(getPrintOrderData, { opportunityId: '006n0000008jjPHAAY', solutionId: 'a0fn0000001IC5SAAW'})
    // solutionTableData({error,data}) {
    //     if (data !== undefined) {
    //         this.solutionData = data.currentOrders;
    //         console.log('****************************');
    //         console.log(JSON.stringify(data.currentOrders));
    //     }
    // }

    // @wire(getPrintOrderData, { opportunityId: '006n0000008jjPHAAY', solutionId: 'a0fn0000001IC5SAAW'})
    // solutionTableData(result) {
    //     if (result.data) {
    //         // this.solutionData = data.currentOrders.data;
    //         var conts = result.data.currentOrders;
    //         console.log("*******");
    //         for (var order in conts) {
    //             for (var solution in conts[order].sols) {

    //                 if (conts[order].sols[solution].rawSolution.Name) {
    //                     this.solutionNames.push({value:conts[order].sols[solution].rawSolution.Name, key:order});
    //                 } else {
    //                     this.solutionNames.push({value:'', key:order});
    //                 }

    //                 if (conts[order].sols[solution].rawSolution.Term__c) {
    //                     this.solutionTerms.push({value:conts[order].sols[solution].rawSolution.Term__c, key:order});
    //                 } else {
    //                     this.solutionTerms.push({value:'', key:order});
    //                 }

    //                 if (conts[order].sols[solution].rawSolution.Active__c) {
    //                     this.solutionActive.push({value:conts[order].sols[solution].rawSolution.Active__c, key:order});
    //                 } else {
    //                     this.solutionActive.push({value:'', key:order});
    //                 }

    //                 if (conts[order].sols[solution].rawSolution.MRC_Total__c) {
    //                     this.solutionMRC.push({value:conts[order].sols[solution].rawSolution.MRC_Total__c, key:order});
    //                 } else {
    //                     this.solutionMRC.push({value:'', key:order});
    //                 }

    //                 if (conts[order].sols[solution].rawSolution.NRC_Total__c) {
    //                     this.solutionNRC.push({value:conts[order].sols[solution].rawSolution.NRC_Total__c, key:order});
    //                 } else {
    //                     this.solutionNRC.push({value:'', key:order});
    //                 }

    //                 if (conts[order].sols[solution].approvalStatus) {
    //                     this.solutionApproval.push({value:conts[order].sols[solution].approvalStatus, key:order});
    //                 } else {
    //                     this.solutionApproval.push({value:'', key:order});
    //                 }
    //             }
    //             // this.solutionData.push({value:conts[order].sols[0].rawSolution.Name, key:order});
    //         }
    //     }
    // }

        // @wire(getPrintOrderData, { opportunityId: '006n0000008jjPHAAY', solutionId: 'a0fn0000001IC5SAAW'})
    // solutionTableData({error,data}) {
    //     if (data !== undefined) {
    //         this.solutionData = data.currentOrders;
    //         console.log('****************************');
    //         console.log(JSON.stringify(data.currentOrders));
    //     }
    // }

    @wire(getPrintOrderData, { opportunityId: '006n0000008jjPHAAY', solutionId: 'a0fn0000001IC5SAAW'})
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
                    
                    // console.log('*****************');
                    // console.log(JSON.stringify(result.data.currentOrders));
                }
            }

            if (this.solutionData.length > 0) {
                this.hasRecords = true;
            } 
        }
    }
    
}