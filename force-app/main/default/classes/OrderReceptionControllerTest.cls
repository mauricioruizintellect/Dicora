@isTest
public with sharing class OrderReceptionControllerTest {
    @TestSetup
    static void insertData(){
        String RT = Schema.SObjectType.Campana__c.getRecordTypeInfosByDeveloperName().get('Produccion').getRecordTypeId();
        Pais__c pais = new Pais__c();
        pais.CodigoPais__c = 'HN';
        pais.EsHonduras__c = true;
        pais.Iniciales__c = 'HN';
        Pais.Name = 'Honduras';
        insert pais;
        
        
        Empresa__c empresa = new Empresa__c ();
        empresa.CedulaJuridica__c = '000000000000000';
        empresa.CodigoEmpresa__c = '123123123';
        empresa.Pais__c = pais.Id;
        insert empresa;
        
        Campana__c campania = new Campana__c ();
        campania.RecordTypeId = RT;
        campania.TipoDeCambio__c = 12;
        campania.PeriodoDeFacturacion__c = 'Mensual';
        campania.CompaniaFacturadora__c = empresa.Id;
        campania.Principal__c = 'Cliente';
        insert campania;

        OdenDeCompra__c OC = new OdenDeCompra__c();
        OC.CampanaPublicitaria__c = campania.Id;
        OC.Estado__c = 'Borrador';
        insert OC;

        LineaOrdenDeCompra__c LOC = new LineaOrdenDeCompra__c();
        LOC.Detalle__c = 'detalle loc';
        LOC.OrdenDeCompra__c = OC.Id;
        LOC.Cantidad__c = 10;
        LOC.Tarifa__c = 200;
        LOC.CurrencyIsoCode = 'USD';
        LOC.UltimaCantidadRecibida__c = 1;
        insert LOC;
    }

    @isTest static void getOrderLineDetail() {
        String orderId = [Select Id From OdenDeCompra__c limit 1].Id;
        OrderReceptionController.getOrderLineDetail(orderId);
    }

    @isTest static void receptionItems() {
        String orderId = [Select Id From OdenDeCompra__c limit 1].Id;
        List<LineaOrdenDeCompra__c> lineItems = [Select UltimaCantidadRecibida__c,Detalle__c,OrdenDeCompra__c,Cantidad__c,Tarifa__c from LineaOrdenDeCompra__c];
        OrderReceptionController.receptionItems(lineItems,orderId,'test');
    }
    @isTest static void savePdfOrder() {
        String orderId = [Select Id From OdenDeCompra__c limit 1].Id;
        OrderReceptionController.savePdfOrder(orderId);
    }
    
    @isTest static void getMaterialProd() {
		Producto__c producto = new Producto__c();
        producto.AlturaFisica__c = 12;
        Producto.Name = 'GIRA';
        insert producto;
        MaterialDeProducto__c newMaterial = new MaterialDeProducto__c();
        newMaterial.Cantidad__c = 5;
        newMaterial.Producto__c = producto.Id;
        insert newMaterial;
        OrderReceptionController.getMaterialProd(producto.Id);
    }
    
    @isTest static void getNameOfMaterial() {
       Material__c  newMat = new Material__c (Name = 'material test',CantidadAMano__c = 60);
       insert newMat; 
       OrderReceptionController.getNameOfMaterial(newMat.Id);
    }
    @isTest static void reduceMaterial() {
       Material__c  newMat = new Material__c (Name = 'material test',CantidadAMano__c = 60);
       insert newMat; 
       List<Material__c> lstMat = new List<Material__c>{newMat};
       OrderReceptionController.reduceMaterial(lstMat);
    }
    
    @isTest static void saveSign() {
        String orderId = [Select Id From OdenDeCompra__c limit 1].Id;
        String lineItemOrderId = [Select Id from LineaOrdenDeCompra__c limit 1].Id;
        list<String>idsToSave = new list<String>{lineItemOrderId};
        OrderReceptionController.saveSign('firma',orderId,idsToSave,'Recibido por Test');
    }    
    
    @isTest static void getCampaignProducts(){
        Campana__c campania = [Select Id from Campana__c limit 1];
        EntregaDeProducto__c newEntregaPrd = new EntregaDeProducto__c ();
        newEntregaPrd.CampanaPublicitaria__c = campania.Id;
        insert newEntregaPrd;
        OrderReceptionController.getCampaignProducts(newEntregaPrd.Id);
        OrderReceptionController.getProductDelivery(newEntregaPrd.Id);
    }
    @isTest static void receptionMaterials(){
       String orderId = [Select Id From OdenDeCompra__c limit 1].Id;
       LineaOrdenDeCompra__c item = [Select Id,UltimaCantidadRecibida__c from LineaOrdenDeCompra__c limit 1];
       Material__c  newMat = new Material__c (Name = 'material test',CantidadAMano__c = 60);
       insert newMat; 
       item.Material__c = newMat.id;
       item.RazonDiferencia__c = 'test';
       List<LineaOrdenDeCompra__c> items = new list<LineaOrdenDeCompra__c>{item};
       OrderReceptionController.receptionMaterials(items, orderId, null,null);
    }
    
   @isTest static void sendEmail(){
       String orderId = [Select Id From OdenDeCompra__c limit 1].Id;
       OrderReceptionController.sendEmail('test@gmail.com',orderId,'','body del email');
   }
}