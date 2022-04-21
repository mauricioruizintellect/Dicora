trigger CampanaTrigger on Campana__c (after update) {
    new CampanaTriggerHandler().run();
}