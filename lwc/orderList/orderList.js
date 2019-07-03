/* eslint-disable */
import { LightningElement, api, track, wire } from 'lwc';
import getPrintOrderData from '@salesforce/apex/lgt_DataFactory.getPrintOrderData';

const ORDERLINECOLUMNS = [
    { label: 'ID', fieldName: 'id', cellAttributes: {alignment: 'left'}, fixedWidth:175}, 
    { label: 'Secondary Location', fieldName: 'secondaryLocation', cellAttributes: {alignment: 'left'}},
    { label: 'Services', fieldName: 'services', cellAttributes: {alignment: 'left'}},
    { label: 'Qty', fieldName: 'qty', type: 'number', cellAttributes: {alignment: 'left'}, fixedWidth:75}, 
    { label: 'MRR', fieldName: 'mrr', type: 'currency', cellAttributes: {alignment: 'left'}, fixedWidth:100}, 
    { label: 'NRC', fieldName: 'nrc', type: 'currency', cellAttributes: {alignment: 'left'}, fixedWidth:100}, 
    { label: 'Approval Status', fieldName: 'approvalStatus', cellAttributes: {alignment: 'left'}, fixedWidth:175},
    { label: 'Approved', fieldName: 'approved', type: 'boolean', cellAttributes: {alignment: 'left'}, fixedWidth:125}
];

const activeAccordions = ['approval', 'approvalStatus', 'rawSolApprovalStatus', 'location', 'Opportunity Location Details', 'Order Line Items', 'OLI', 'OLI Prod', 'Tech Info', 'Tech Section', 'techLabel', 'techSection'];


export default class OrderList extends LightningElement {
    @api number;
    @track approvalData = [];
    @track columns = ORDERLINECOLUMNS;
    @track activeSections = activeAccordions;

    // reusing existing apex class with slight modifications
    // calling apex class using the wire method - retrieving and processing information to be displayed on page 
    @wire(getPrintOrderData, { opportunityId: '006n0000008jlksAAA', solutionId: 'a0fn0000001ICTsAAO'})
    solutionTableData(result) {
        if (result.data) {
            var conts = result.data.currentOrders;
            var techInfos = result.data.techInfos;
            console.log(JSON.stringify(conts));
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

                console.log(JSON.stringify(conts[order].selectedSols));
                var rawSolutions = []; // declare an array to hold solution and approval data 
                for (var selectedSolution in conts[order].selectedSols) { 
                    var serviceLocationIds = []; // declare an array to append service locations ids onto 
                    var currentApproval = new Object(); // declare an object to hold approval status and service location Ids for each solution
                    if (conts[order].selectedSols[selectedSolution].rawSolution.Name) {
                        currentApproval.approvalStatus = conts[order].selectedSols[selectedSolution].rawSolution.Name + ' - Approval Status: ';
                        currentApproval.techInfoApproval = conts[order].selectedSols[selectedSolution].rawSolution.Name + ' Technical Information' ;
                    } 
                    if (conts[order].selectedSols[selectedSolution].approvalStatus) {
                        currentApproval.approvalStatus += conts[order].selectedSols[selectedSolution].approvalStatus;
                    }
                    if (conts[order].selectedSols[selectedSolution].rawSolution.Opportunity_Location__c) {
                        currentApproval.opportunityLocationId = conts[order].selectedSols[selectedSolution].rawSolution.Opportunity_Location__c;
                    }
                    if (techInfos[currentApproval.opportunityLocationId]) {
                        currentApproval.techInfo = techInfos[currentApproval.opportunityLocationId];
                    }

                    // iterate through all service locations 
                    for (var serviceLocation in conts[order].selectedSols[selectedSolution].servLocs) {
                        var currentLocation = new Object(); // construct object to hold location information (name and id) to be displayed on page 
                        currentLocation.Name = conts[order].selectedSols[selectedSolution].servLocs[serviceLocation].Name;
                        currentLocation.Id = conts[order].selectedSols[selectedSolution].servLocs[serviceLocation].Id;
                        currentLocation.buildingId = conts[order].selectedSols[selectedSolution].servLocs[serviceLocation].Location__r.Building__c;
                        currentLocation.customerDetailId = conts[order].selectedSols[selectedSolution].servLocs[serviceLocation].Customer_Detail__r.Id;
                        serviceLocationIds.push(currentLocation);
                    }
                    
                    currentApproval.locationIds = serviceLocationIds;

                    var totalProducts = [];
                    if (conts[order].selectedSols[selectedSolution].productsMap) {
                        var productNames = Object.keys(conts[order].selectedSols[selectedSolution].productsMap);
                        var allProds = [];
                        for (var prod in productNames) {
                            var totalObject = new Object();
                            totalObject.name = productNames[prod];
                            console.log(totalObject.name)
                            var key = productNames[prod];
                            var currOLIs = [];
                            for (var currProd in (conts[order].selectedSols[selectedSolution].productsMap)[key]) {
                                var prodObject = new Object();
                                var lines = [];
                                prodObject.Name = conts[order].selectedSols[selectedSolution].productsMap[key][currProd].Name;
                                for (var line in conts[order].selectedSols[selectedSolution].productsMap[key][currProd].linesMap[key]) {
                                    var OLI = new Object(); 
                                    OLI.id = conts[order].selectedSols[selectedSolution].productsMap[key][currProd].linesMap[key][line].rawOLI.Id;
                                    OLI.services = conts[order].selectedSols[selectedSolution].productsMap[key][currProd].linesMap[key][line].rawOLI.PP_Sales_Rate_Plan_Description__c;
                                    OLI.qty = conts[order].selectedSols[selectedSolution].productsMap[key][currProd].linesMap[key][line].rawOLI.Qty__c;
                                    OLI.mrr = conts[order].selectedSols[selectedSolution].productsMap[key][currProd].linesMap[key][line].rawOLI.MRC__c;
                                    OLI.nrc = conts[order].selectedSols[selectedSolution].productsMap[key][currProd].linesMap[key][line].rawOLI.NRC__c;
                                    OLI.approvalStatus = conts[order].selectedSols[selectedSolution].productsMap[key][currProd].linesMap[key][line].rawOLI.Approval_Status__c;
                                    OLI.approved = conts[order].selectedSols[selectedSolution].productsMap[key][currProd].linesMap[key][line].rawOLI.Approved__c;

                                    if (conts[order].selectedSols[selectedSolution].productsMap[key][currProd].linesMap[key][line].rawOLI.Secondary_Location__c != null) {
                                        OLI.secondaryLocation = conts[order].selectedSols[selectedSolution].productsMap[key][currProd].linesMap[key][line].rawOLI.Secondary_Location__r.Building__r.Name;
                                    }

                                    lines.push(OLI);
                                }

                                prodObject.oliLines = lines;
                                currOLIs.push(prodObject)
                            }

                            totalObject.products = currOLIs;
                            totalProducts.push(totalObject);
                        }
                    }
                    currentApproval.orderLineItems = totalProducts;
                    rawSolutions.push(currentApproval);
                }

                dataSolution.rawSolution = rawSolutions;
                this.approvalData.push(dataSolution);
            }
        }
    }
    toggleSection(event){
        event.target.parentNode.parentElement.classList.toggle("slds-is-open");
    }
}