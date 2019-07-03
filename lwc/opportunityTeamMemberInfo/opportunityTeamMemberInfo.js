/* eslint-disable */
import { LightningElement, track, wire,api } from 'lwc';
// import getOpportunityTeamMembers from '@salesforce/apex/lgt_DataFactory.getOpportunityTeamMembers';
import getPrintOrderData from '@salesforce/apex/lgt_DataFactory.getPrintOrderData';

const columns = [
    { label: 'Team Member', fieldName: 'name' },
    { label: 'Member Role', fieldName: 'role'},
];

const activeAccordions = ['Opportunity Team'];

export default class DatatableBasic extends LightningElement {
    @api oppid;
    @track columns = columns;
    @track oppTeamMembers;
    @track activeSections = activeAccordions;

    @wire(getPrintOrderData, { opportunityId: '006n0000008jlksAAA', solutionId: 'a0fn0000001ICTsAAO'})
    solutionTableData(result) {
        if (result.data) {
            console.log('OPP TEAMS');
            var oppTeamData = result.data.opportunityTeams;
            var allMembers = [];
            // console.log(JSON.stringify(result.data.opportunityTeams));
            for (var opp in oppTeamData) {
                var oppObject = new Object();
                oppObject.role = oppTeamData[opp].TeamMemberRole;
                oppObject.name = oppTeamData[opp].User.Name;

                allMembers.push(oppObject);
            }

            this.oppTeamMembers = allMembers;
            console.log(JSON.stringify(this.oppTeamMembers));
        }
    }
    // @wire(getOpportunityTeamMembers, {opportunityId: '$oppid'})
    // teamMembers;
}