public class ControllerAddLinesToOrderMat {
    
    @AuraEnabled
    public static ResultWrapper getMateriales(String recordId){
        ResultWrapper result = new ResultWrapper();
        result.listMateriales = new List<PicklistOption>();
        result.listMaterialesAgr = new List<Material>();
        result.disabledBoton = true;
        result.idOrdenCOmpra = recordId;
        OdenDeCompra__c OC = [Select IVA__c, Subtotal__c , Total__c,CurrencyIsoCode  from OdenDeCompra__c where Id = :recordId];
        result.iva = OC.IVA__c;
        result.subTotal = OC.Subtotal__c;
        result.totalOC = OC.Total__c;
        result.codigoMoneda = OC.CurrencyIsoCode;
        for(LineaOrdenDeCompra__c item:
            [Select Id,Cantidad__c,Tarifa__c,Total__c,Material__c, Material__r.Name,CurrencyIsoCode
             from LineaOrdenDeCompra__c Where OrdenDeCompra__c =:recordId order by Material__r.Name]){
                 Material material = new Material();
                 material.precio = item.Tarifa__c;
                 material.nombre = item.Material__r.Name;
                 material.cantidad = item.Cantidad__c;
                 material.cantidadOrg = item.Cantidad__c;
                 material.total = item.Total__c;
                 material.id = item.Id;
                 material.codigoMoneda = item.CurrencyIsoCode;
                 material.disabledBoton = true;
                 result.listMaterialesAgr.add(material);
             }
             
        List<String> listMateriales = new List<String>();   
        for(PrecioDeCompra__c  item: [Select Precio__c, Material__c, Material__r.Name from PrecioDeCompra__c  where Material__c != null and Activa__c = true Order by Material__r.Name]){
            result.listMateriales.add(new PicklistOption(item.Material__r.Name, item.Material__c, item.Precio__c));
            listMateriales.add(item.Material__c);
        }
        for(Material__c item: [Select Id, Name  from Material__c where Id not in :listMateriales]){
            result.listMateriales.add(new PicklistOption(item.Name, item.Id, 0.0));
        }
        return result;
    }
    
    @AuraEnabled
    public static void inserRecord(String allData){
        ResultWrapper result = (ResultWrapper) Json.deserialize(allData, ResultWrapper.class);
        LineaOrdenDeCompra__c LOC = new LineaOrdenDeCompra__c();
        LOC.Material__c = result.material;
        LOC.OrdenDeCompra__c = result.idOrdenCOmpra;
        LOC.Cantidad__c = result.cantidad;
        LOC.Tarifa__c = result.precio;
        LOC.CurrencyIsoCode = result.codigoMoneda;
        insert LOC;
    }
    @AuraEnabled
    public static OdenDeCompra__c editRecord(String recordId, Decimal cantidad, Decimal precio, String detalle, String ordenCompraId){
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
        @AuraEnabled public List<PicklistOption> listMateriales {get;set;}
        @AuraEnabled public List<Material> listMaterialesAgr {get;set;}
        @AuraEnabled public String material {get;set;}
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
    public class PicklistOption{
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String value{get;set;}
        @AuraEnabled public Decimal precio{get;set;}
        PicklistOption(String label, String value, Decimal precio){
            this.label = label;
            this.value = value;
            this.precio = precio;
        }
    }
    
    public class Material{
        @AuraEnabled public Decimal precio{get;set;}
        @AuraEnabled public Decimal cantidadOrg{get;set;}
        @AuraEnabled public String nombre{get;set;}
        @AuraEnabled public Decimal cantidad{get;set;}
        @AuraEnabled public Decimal total{get;set;}
        @AuraEnabled public String id{get;set;}
        @AuraEnabled public Boolean disabledBoton {get;set;}
        @AuraEnabled public String codigoMoneda {get;set;}
    }

}