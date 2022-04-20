public class PurchasePriceTriggerHandler extends TriggerHandler{

    private List<PrecioDeCompra__c> triggerNew;
    private List<PrecioDeCompra__c> triggerOld;
    private Map<Id, PrecioDeCompra__c> triggerMapNew;
    private Map<Id, PrecioDeCompra__c> triggerMapOld;

    public PurchasePriceTriggerHandler() {
        this.triggerMapNew = (Map<id, PrecioDeCompra__c>) Trigger.newMap;
        this.triggerMapOld  = (Map<id, PrecioDeCompra__c>) Trigger.oldMap;
        this.triggerNew = (List <PrecioDeCompra__c>) Trigger.new;
        this.triggerOld = (List <PrecioDeCompra__c>) Trigger.old;
    } 

    public override void afterInsert() {
        System.debug('after insert trigger');
        if(PurchasePriceService.runOnce){
            PurchasePriceService.inactiveOldPrices(this.triggerNew);
        }
    }

    public override void afterUpdate() {
        System.debug('after update trigger');
        if(PurchasePriceService.runOnce){
            PurchasePriceService.inactiveOldPrices(this.triggerNew);
        }
    }
}
