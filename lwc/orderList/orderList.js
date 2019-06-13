/* eslint-disable */
import { LightningElement, api, track, wire } from 'lwc';
import getPrintOrderData from '@salesforce/apex/lgt_DataFactory.getPrintOrderData';


export default class OrderList extends LightningElement {
    @api number;
    @track approvalData = [];

    // reusing existing apex class with slight modifications
    // calling apex class using the wire method - retrieving and processing information to be displayed on page 
    @wire(getPrintOrderData, { opportunityId: '006n0000008jlksAAA', solutionId: 'a0fn0000001ICTsAAO'})
    solutionTableData(result) {
        if (result.data) {
            var conts = result.data.currentOrders;
            // loop through all the orders
            for (var order in conts) {
                var dataSolution = new Object(); // construct a new object to hold the data for the current solution
                // add approval and approval status keys to dataSolution object to display on page 
                // If name doesn't exist, set defaults 
                if (conts[order].rawOrder.Name) {
                    dataSolution.approval = conts[order].rawOrder.Name;
                    dataSolution.approvalStatus = conts[order].rawOrder.Name + ' - Approval Status: ' 
                } else {
                    dataSolution.approval = '';
                    dataSolution.approvalStatus = ' - Approval Status: ' ;
                }

                if (conts[order].approvalStatus) {
                    dataSolution.approvalStatus += conts[order].approvalStatus;
                }

                var rawSolutions = []; // declare an array to hold solution and approval data 
                for (var selectedSolution in conts[order].selectedSols) { 
                    var serviceLocationIds = []; // declare an array to append service locations ids onto 
                    var currentApproval = new Object(); // declare an object to hold approval status and service location Ids for each solution
                    if (conts[order].selectedSols[selectedSolution].rawSolution.Name) {
                        currentApproval.approvalStatus = conts[order].selectedSols[selectedSolution].rawSolution.Name + ' - Approval Status: ';
                    } 
                    if (conts[order].selectedSols[selectedSolution].approvalStatus) {
                        currentApproval.approvalStatus += conts[order].selectedSols[selectedSolution].approvalStatus;
                    }
                    if (conts[order].selectedSols[selectedSolution].rawSolution.Opportunity_Location__c) {
                        currentApproval.opportunityLocationId = conts[order].selectedSols[selectedSolution].rawSolution.Opportunity_Location__c;
                    }

                    // iterate through all service locations 
                    for (var serviceLocation in conts[order].selectedSols[selectedSolution].servLocs) {
                        var currentLocation = new Object(); // construct object to hold location information (name and id) to be displayed on page 
                        currentLocation.Name = conts[order].selectedSols[selectedSolution].servLocs[serviceLocation].Name;
                        currentLocation.Id = conts[order].selectedSols[selectedSolution].servLocs[serviceLocation].Id;
                        serviceLocationIds.push(currentLocation);
                    }
                    
                    currentApproval.locationIds = serviceLocationIds;

                    var products = [];
                    if (conts[order].selectedSols[selectedSolution].productsMap) {
                        var productNames = Object.keys(conts[order].selectedSols[selectedSolution].productsMap);
                        for (var prod in productNames) {
                            // var prodObject = new Object();
                            var key = productNames[prod];
                            // prodObject.Name = key;
                            for (var currProd in (conts[order].selectedSols[selectedSolution].productsMap)[key]) {
                                var prodObject = new Object();
                                prodObject.Name = conts[order].selectedSols[selectedSolution].productsMap[key][currProd].Name;
                                console.log(prodObject.Name)
                            }
                        }
                    }


                    // var orderLineItems = new Object();
                    // if (conts[order].selectedSols[selectedSolution].productsMap) {
                    //     var products = [];
                    //     var productNames = Object.keys(conts[order].selectedSols[selectedSolution].productsMap);
                    //     for (var prd in productNames) {
                    //         var key = productNames[prd];
                    //         var product = (conts[order].selectedSols[selectedSolution].productsMap)[key];
                    //         for (var prd1 in product) {
                    //             var currentProduct = new Object();
                    //             currentProduct.Name = product[prd1].Name;

                    //             products.push(currentProduct)
                    //         }
                    //     }
                    // }


                    rawSolutions.push(currentApproval);
                }

                dataSolution.rawSolution = rawSolutions;
                this.approvalData.push(dataSolution);
            }
        }
    }
}