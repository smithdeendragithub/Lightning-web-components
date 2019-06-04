import { LightningElement, track, wire,api } from 'lwc';
import getOpportunityTeamMembers from '@salesforce/apex/lgt_DataFactory.getOpportunityTeamMembers';

const columns = [
    { label: 'Team Member', fieldName: 'User.Name' },
    { label: 'Member Role', fieldName: 'TeamMemberRole'},
];

export default class DatatableBasic extends LightningElement {
    @api oppid;
    @track columns = columns;
    @track error;
    @track data;

    @wire(getOpportunityTeamMembers, {opportunityId: '$oppid'})
    teamMembers;
}