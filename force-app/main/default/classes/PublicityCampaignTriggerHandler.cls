public class PublicityCampaignTriggerHandler extends TriggerHandler{
    private List<Campana__c> triggerNew;
    private List<Campana__c> triggerOld;
    private Map<Id, Campana__c> triggerMapNew;
    private Map<Id, Campana__c> triggerMapOld;

    public PublicityCampaignTriggerHandler() {
        this.triggerMapNew = (Map<id, Campana__c>) Trigger.newMap;
        this.triggerMapOld  = (Map<id, Campana__c>) Trigger.oldMap;
        this.triggerNew = (List <Campana__c>) Trigger.new;
        this.triggerOld = (List <Campana__c>) Trigger.old;
        //this.setMaxLoopCount(2);
    } 

    public override void afterUpdate() {
        if(PublicityCampaignService.runOnce){
            System.debug('se ejecuta');
            PublicityCampaignService.processMaterialProducts(this.triggerNew);
        }else{
            System.debug('no se ejecuta');
        }
    }
}
