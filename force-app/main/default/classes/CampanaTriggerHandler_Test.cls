@isTest
private class CampanaTriggerHandler_Test {
   
    @testSetup static void testSetUp() {
        Id accountRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Agencia Publicitaria').getRecordTypeId();
        Pais__c p = New Pais__c (Name = 'Costa Rica');
        insert p;
        Empresa__c empresa = new Empresa__c(CodigoEmpresa__c = 'DICR',Name = 'DICORA Costa Rica', Pais__c = p.id);
        insert empresa;
       
        Account accCadena = new Account (Name = 'Test AccCad',RazonSocial__c = 'Test RZC', Phone= '88351222', Correo__c = 'mail@mail.com',Estado__c = label.estadoactivo, recordtypeid = accountRecordType, Pais__c =  'Costa Rica');
        insert accCadena;
 		Cadena__c cadena = new Cadena__c(Name = 'TestCadena',Comercio__c = accCadena.id);
        insert cadena; 	
        Formato__c formato = new Formato__c(Name = 'Supercentro', Cadena__c= cadena.id);
        Producto__c producto = new Producto__c(Name='Botaderos',CodigoDeProducto__c = 'BOT', Tipo__c = 'Impreso', TipoDeVenta__c = label.CampanaAlquiler, MaterialProducto__c = 'En Adhesivo');
         Producto__c producto2 = new Producto__c(Name='Botaderos Prod',CodigoDeProducto__c = 'BOT-PRD', Tipo__c = 'Impreso', TipoDeVenta__c = label.CampanaProduccion, MaterialProducto__c = 'En Adhesivo');
        insert formato; insert producto; insert producto2;
        Categoria__c cat = new Categoria__c (Name='CatTest');
        Marca__c marca = new Marca__c(Name = 'MarcaTest', Categoria__c = cat.id);
        insert cat; insert marca;
	}

    static testMethod void insertarActualizarCampanas(){
        Id campanaRecordType = Schema.SObjectType.Campana__c.getRecordTypeInfosByName().get(label.CampanaAlquiler).getRecordTypeId();
        Id campanaRecordTypeProd = Schema.SObjectType.Campana__c.getRecordTypeInfosByName().get(label.CampanaProduccion).getRecordTypeId();
        Id accountRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Agencia Publicitaria').getRecordTypeId();
        Cadena__c cadena = [Select id from Cadena__c limit 1];
        Formato__c formato = [Select id from Formato__c limit 1];
        Producto__c producto = [Select id from Producto__c limit 1];
        Producto__c producto2 = [Select id from Producto__c where TipoDeVenta__c = :label.CampanaProduccion limit 1];
        Marca__c marca = [Select id from Marca__c limit 1];
        Empresa__c empresa = [Select id from Empresa__c limit 1];
        Account acc = new Account (Name = 'Test Acc',RazonSocial__c = 'Test RZ', Phone= '88351222', Correo__c = 'mail@mail.com',Estado__c = label.estadoactivo, recordtypeid = accountRecordType, Pais__c =  'Costa Rica');
        insert acc;
        
        //Insercion de campañas
        Campana__c c = new Campana__c(NombreCampana__c = 'Test', FechaDeInicio__c = date.today(),FechaDeFinalizacion__c = date.today()+30, Principal__c = 'Cliente', OficinaDeVenta__c='Costa Rica',
                                      Cliente__c =  acc.id,CompaniaFacturadora__c = empresa.id, TipoDeCambio__c = 615, EstadoDeCampana__c = '01 Sin Firmar', PeriodoDeFacturacion__c = 'Mensual', FacturarANombreDe__c = 'Cliente');
        insert c;
        
       	Venta__c v = new Venta__c (Campana__c = c.id,Cadena__c = cadena.id, Formato__c = formato.id,ProductoEtapa1__c = producto.id, marca__c = marca.id, Cantidad__c = 10, PrecioTotal__C = 1000, FechaDeInicio__c = date.today(), FechaFin__c = date.today()+30);
        insert v;
            
        Campana__c c2 = new Campana__c(recordtypeid = campanaRecordTypeProd, NombreCampana__c = 'Test', FechaDeInicio__c = date.today(),FechaDeFinalizacion__c = date.today()+30, Principal__c = 'Cliente', OficinaDeVenta__c='Costa Rica',
                                      Cliente__c =  acc.id,CompaniaFacturadora__c = empresa.id, TipoDeCambio__c = 615, EstadoDeCampana__c = '01 Sin Firmar', PeriodoDeFacturacion__c = 'Mensual', FacturarANombreDe__c = 'Cliente');
        insert c2;
        
       	Venta__c v2 = new Venta__c (Campana__c = c2.id,Cadena__c = cadena.id, Formato__c = formato.id,ProductoEtapa1__c = producto2.id, marca__c = marca.id, Cantidad__c = 10, PrecioTotal__C = 1000, FechaDeInicio__c = date.today(), FechaFin__c = date.today()+30);
        insert v2;
        ///Actualización a firmada para calcular diferidos
        c.EstadoDeCampana__c = '02 Firmada';
        c.FechaFirma__c = date.today();
        update c;
        
        c2.EstadoDeCampana__c = '02 Firmada';
        c2.FechaFirma__c = date.today();
        update c2;
        
    }
    static testMethod void materialsMissing(){
        Id accountRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Agencia Publicitaria').getRecordTypeId();
        Empresa__c empresa = [Select id from Empresa__c limit 1];
        Account acc = new Account (Name = 'Test Acc',RazonSocial__c = 'Test RZ', Phone= '88351222', Correo__c = 'mail@mail.com',Estado__c = label.estadoactivo, recordtypeid = accountRecordType, Pais__c =  'Costa Rica');
        insert acc;
        //Insercion de campañas
        Campana__c c = new Campana__c(NombreCampana__c = 'Test', FechaDeInicio__c = date.today(),FechaDeFinalizacion__c = date.today()+30, Principal__c = 'Cliente', OficinaDeVenta__c='Costa Rica',
                                      Cliente__c =  acc.id,CompaniaFacturadora__c = empresa.id, TipoDeCambio__c = 615, EstadoDeCampana__c = '01 Sin Firmar', PeriodoDeFacturacion__c = 'Mensual', FacturarANombreDe__c = 'Cliente');
        insert c;

        Cadena__c cadena = [Select id from Cadena__c limit 1];
        Formato__c formato = [Select id from Formato__c limit 1];
        Producto__c producto = [Select id,ElaboradoConMaterialPropio__c from Producto__c limit 1];
        producto.ElaboradoConMaterialPropio__c = true;
        update producto;
        Marca__c marca = [Select id from Marca__c limit 1];
        Venta__c v = new Venta__c (Campana__c = c.id,Cadena__c = cadena.id, Formato__c = formato.id,ProductoEtapa1__c = producto.id, marca__c = marca.id, Cantidad__c = 10, PrecioTotal__C = 1000, FechaDeInicio__c = date.today(), FechaFin__c = date.today()+30);
        insert v;
        
        Material__c  newMat = new Material__c (Name = 'material test',CantidadAMano__c = 60);
        insert newMat;
        
        MaterialDeProducto__c newMatProd = new MaterialDeProducto__c(Material__c = newMat.Id,Producto__c = producto.Id,
                                                                    Cantidad__c = 5);
        insert newMatProd;
         
        Campana__c updateCamp = new Campana__c(Id = c.id, EstadoDeCampana__c = '03 En Proceso de Artes');
        update updateCamp;
    }
}