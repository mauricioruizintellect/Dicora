@isTest
public class PurchasePriceTriggerTest {
    @testSetup 
    static void setup() {
            Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Proveedor').getRecordTypeId();

            Account proveedor1 = new Account(Name = 'Proveedor test', recordTypeId = devRecordTypeId);
            insert proveedor1;

			Producto__c prd1 = new Producto__c (Name = 'Prd1', CodigoDeProducto__c = 'prd1_001', TipoDeLocalizacion__c ='Interno',
                                               Tipo__c = 'Impreso',TipoDeVenta__c = 'Alquiler');
        	insert prd1;
        
            Sitio__c sitio1 = new Sitio__c (Name = 'sitio1');
            insert sitio1;
        
        	Medio__c medio1 = new Medio__c (Name = 'medio1', Producto__c = prd1.Id, Sitio__c =sitio1.Id);
            insert medio1;
        
            Material__c material1 = new Material__c (name = 'mat1');
            insert material1;
        
     }
     @isTest static void testRunTrg() {
        Id prdId = [Select Id From Producto__c Limit 1].Id;
        Id medioId = [Select Id From Medio__c Limit 1].Id;
        Id materialId = [Select Id From Material__c Limit 1].Id;
        Id proveedorId = [Select Id From Account limit 1].Id;

		PrecioDeCompra__c pCompra1 = new PrecioDeCompra__c (Activa__c  = true, Name = 'pdc1', FechaInicio__c = System.Today() - 5,
                                                           Precio__c  = 500, Producto__c = prdId , Proveedor__c = proveedorId);
        insert pCompra1;
         
        PrecioDeCompra__c pCompra2 = new PrecioDeCompra__c (Activa__c  = true, Name = 'pdc2', FechaInicio__c = System.Today() - 5,
                                                           Precio__c  = 600, Material__c  = materialId , Proveedor__c = proveedorId);
        insert pCompra2;
         
        PrecioDeCompra__c updatePCompra2 = new PrecioDeCompra__c (Id = pCompra2.Id, Medio__c  = medioId,Material__c  = null);
        update updatePCompra2; 
     }
}