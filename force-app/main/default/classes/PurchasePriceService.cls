public with sharing class PurchasePriceService {
    public static Boolean runOnce = true;
    public static void inactiveOldPrices(List<PrecioDeCompra__c> newPrices){
        set<Id> productoIds = new set<Id>();
        set<Id> proveedorIds = new set<Id>();
        set<Id> medidaIds = new set<Id>();
        set<Id> materialIds = new set<Id>();
        set<Id> medioIds = new set<Id>();
        set<Id> priceIds = new set<Id>();
        for(PrecioDeCompra__c record : newPrices){
            //Proveedor__c,Producto__c,Medida__c
            if(record.Activa__c){
                priceIds.add(record.Id);
                if(record.Producto__c != null){
                    productoIds.add(record.Producto__c);
                }
                if(record.Proveedor__c != null){
                    proveedorIds.add(record.Proveedor__c);
                }
                if(record.Medida__c != null){
                    medidaIds.add(record.Medida__c);
                }
                if(record.Material__c != null){
                    materialIds.add(record.Material__c);
                }
                if(record.Medio__c != null){
                    medioIds.add(record.Medio__c);
                }   
            }
        } 
        System.debug('buscar por producto');
        List<PrecioDeCompra__c> productPurchase = new list<PrecioDeCompra__c>();
        for(PrecioDeCompra__c prc: [SELECT Id,Activa__c,FechaFin__c FROM PrecioDeCompra__c Where 
                                    Activa__c = true AND
                                    Proveedor__c IN:proveedorIds AND
                                    Producto__c IN:productoIds AND
                                    Medida__c IN:medidaIds AND
                                    Id Not IN:priceIds]){
                if(!productPurchase.contains(prc)){
                    productPurchase.add(prc);
                }
        } 
        System.debug('buscar por Material');
        for(PrecioDeCompra__c prc:[SELECT Id,Activa__c,FechaFin__c FROM PrecioDeCompra__c Where 
                                   Activa__c = true AND
                                   Material__c IN:materialIds AND
                                   Proveedor__c IN:proveedorIds]){
            if(!productPurchase.contains(prc)){
                productPurchase.add(prc);
            }
        }
        System.debug('buscar por Medio');
        for(PrecioDeCompra__c prc:[SELECT Id,Activa__c,FechaFin__c FROM PrecioDeCompra__c Where 
                                   Activa__c = true AND
                                   Medio__c IN:medioIds AND
                                   Proveedor__c IN:proveedorIds AND
                                   Medida__c IN:medidaIds]){
            if(!productPurchase.contains(prc)){
                productPurchase.add(prc);
            }
        }
                                                   
        if(!productPurchase.isEmpty() && runOnce)
        {
            PurchasePriceService.runOnce = false;
            for(PrecioDeCompra__c record : productPurchase){
                record.Activa__c = false;
                record.FechaFin__c = System.today();
            }
            update productPurchase;
        }                                          
    }

}