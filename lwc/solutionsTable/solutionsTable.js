import { LightningElement, track, wire } from 'lwc';
import getSolutionTableData from '@salesforce/apex/lgt_DataFactory.getSolutionTableData';

export default class SolutionsTable extends LightningElement {
    @wire(getSolutionTableData, {opportunityId: '006n0000008jlksAAA'})
    solutionData; 
}