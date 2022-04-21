public class ControllerAddLinesToOrderIns {
    
     @AuraEnabled
    public static ResultWrapper getInstalaciones(String recordId){
        ResultWrapper result = new ResultWrapper();
        result.listInstalacionesAgr = new List<Instalacion>();
        result.disabledBoton = true;
        result.idOrdenCOmpra = recordId;
        OdenDeCompra__c OC = [Select IVA__c, Subtotal__c , Total__c,CurrencyIsoCode  from OdenDeCompra__c where Id = :recordId];
        result.iva = OC.IVA__c;
        result.subTotal = OC.Subtotal__c;
        result.totalOC = OC.Total__c;
        result.codigoMoneda = OC.CurrencyIsoCode;
        for(LineaOrdenDeCompra__c item:
            [Select Id,Cantidad__c,Tarifa__c,Total__c,Detalle__c,CurrencyIsoCode
             from LineaOrdenDeCompra__c Where OrdenDeCompra__c =:recordId order by CreatedDate Desc]){
                 Instalacion instalacion = new Instalacion();
                 instalacion.precio = item.Tarifa__c;
                 instalacion.cantidad = item.Cantidad__c;
                 instalacion.cantidadOrg = item.Cantidad__c;
                 instalacion.total = item.Total__c;
                 instalacion.detalle = item.Detalle__c;
                 instalacion.id = item.Id;
                 instalacion.disabledBoton = true;
                 instalacion.codigoMoneda = item.CurrencyIsoCode;
                 result.listInstalacionesAgr.add(instalacion);
             }
        return result;
    }
    
    @AuraEnabled
    public static void inserRecord(String allData){
        ResultWrapper result = (ResultWrapper) Json.deserialize(allData, ResultWrapper.class);
        LineaOrdenDeCompra__c LOC = new LineaOrdenDeCompra__c();
        LOC.Detalle__c = result.detalle;
        LOC.OrdenDeCompra__c = result.idOrdenCOmpra;
        LOC.Cantidad__c = result.cantidad;
        LOC.Tarifa__c = result.precio;
        LOC.CurrencyIsoCode = result.codigoMoneda;
        insert LOC;
    }
    
    @AuraEnabled
    public static OdenDeCompra__c editRecord(String recordId, Decimal cantidad, String ordenCompraId){
        LineaOrdenDeCompra__c LineaOC = new LineaOrdenDeCompra__c(Id = recordId, Cantidad__c = cantidad);
        update LineaOC;
        return [Select IVA__c, Subtotal__c , Total__c  from OdenDeCompra__c where Id = :ordenCompraId];
    }
    @AuraEnabled
    public static OdenDeCompra__c deleteRecord(String recordId, String ordenCompraId){
        LineaOrdenDeCompra__c LineaOC = new LineaOrdenDeCompra__c(Id = recordId);
        delete LineaOC;
        return [Select IVA__c, Subtotal__c , Total__c  from OdenDeCompra__c where Id = :ordenCompraId];
    }
    
    public class ResultWrapper {
        @AuraEnabled public List<Instalacion> listInstalacionesAgr {get;set;}
        @AuraEnabled public String detalle {get;set;}
        @AuraEnabled public Decimal precio {get;set;}
        @AuraEnabled public Decimal cantidad {get;set;}
        @AuraEnabled public Decimal total {get;set;}
        @AuraEnabled public String idOrdenCOmpra {get;set;}
        @AuraEnabled public Boolean disabledBoton {get;set;}
        
        
        @AuraEnabled public Decimal subTotal {get;set;}
        @AuraEnabled public Decimal iva {get;set;}
        @AuraEnabled public Decimal totalOC {get;set;}
        
        @AuraEnabled public String codigoMoneda {get;set;}
    }
    
    public class Instalacion{
        @AuraEnabled public Decimal precio{get;set;}
        @AuraEnabled public Decimal cantidadOrg{get;set;}
        @AuraEnabled public String detalle{get;set;}
        @AuraEnabled public Decimal cantidad{get;set;}
        @AuraEnabled public Decimal total{get;set;}
        @AuraEnabled public String id{get;set;}
        @AuraEnabled public Boolean disabledBoton {get;set;}
        @AuraEnabled public String codigoMoneda {get;set;}
    }

}