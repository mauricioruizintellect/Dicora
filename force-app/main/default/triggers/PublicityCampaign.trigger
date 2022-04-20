trigger PublicityCampaign on Campana__c (after update) {
    new PublicityCampaignTriggerHandler().run();
}