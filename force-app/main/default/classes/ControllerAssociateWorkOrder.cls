public without sharing class ControllerAssociateWorkOrder {
    
     @AuraEnabled
    public static List<ResultWrapper> getOrdenTrabajo(String recordId){
        List<ResultWrapper> listOrdenT = new List<ResultWrapper>();
        OdenDeCompra__c  OC = [Select Proveedor__c from OdenDeCompra__c  Where Id=:recordId];
        for(OrdenTrabajoDeEstructura__c item: 
            [Select Id, Tipo__c, Estado__c, Proveedor__r.Name, Instalador__r.Name,
             FechaPrevista__c, Costo__C from OrdenTrabajoDeEstructura__c
             Where Proveedor__c = :OC.Proveedor__C And OrdenCompra__c = null
            Order by Proveedor__r.Name Asc]){
                 ResultWrapper ordenT = new ResultWrapper();
                 ordenT.id = item.Id;
                 ordenT.tipo = item.Tipo__c;
                 ordenT.estado = item.Estado__c;
                 ordenT.proveedor = item.Proveedor__r.Name;
                 ordenT.instalador = item.Instalador__r.Name;
                 ordenT.fecha = item.FechaPrevista__c != null ? item.FechaPrevista__c.addDays(1) : null ;
                 ordenT.costo = item.Costo__C;
                 listOrdenT.add(ordenT);
             }
        return listOrdenT;
    }
    
    @AuraEnabled
    public static void updateRecord(String jsonString, String recordId){
        List<ResultWrapper> listOrdenT = (List<ResultWrapper>) Json.deserialize(jsonString, List<ResultWrapper>.class);
        List<OrdenTrabajoDeEstructura__c> listOrdenTrabajo = new List<OrdenTrabajoDeEstructura__c>();
        for(ResultWrapper item: listOrdenT){
            listOrdenTrabajo.add(new OrdenTrabajoDeEstructura__c(Id=item.id, OrdenCompra__c = recordId));
        }
        update listOrdenTrabajo;
    }
    
    
    public class ResultWrapper {
        @AuraEnabled public String id{get;set;}
        @AuraEnabled public String tipo{get;set;}
        @AuraEnabled public String estado{get;set;}
        @AuraEnabled public String proveedor{get;set;}
        @AuraEnabled public String instalador{get;set;}
        @AuraEnabled public Date fecha{get;set;}
        @AuraEnabled public Decimal costo{get;set;}
    }
            
            

}