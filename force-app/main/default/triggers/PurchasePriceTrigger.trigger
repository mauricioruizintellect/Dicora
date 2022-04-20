trigger PurchasePriceTrigger on PrecioDeCompra__c (after insert,after update) {
    new PurchasePriceTriggerHandler().run();
}