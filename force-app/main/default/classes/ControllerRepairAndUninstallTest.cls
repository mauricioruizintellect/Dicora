@isTest
public class ControllerRepairAndUninstallTest {
    
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
        
        User usuerioGestor = [Select Id from User where Id != :UserInfo.getUserId() limit 1];
        
        
        User usuario = new User(Id= UserInfo.getUserId(), PorcentajeDeCambioDeTarijaEnOC__c = 1, ManagerId =usuerioGestor.Id );
        usuario.Country = 'Honduras';
        update usuario;
        
        Cadena__c cadena = new Cadena__c();
        cadena.NombreCadena2__c  = 'Test';
        cadena.Name = 'Test';
        cadena.Canal__c = 'Canal Moderno';
        cadena.Pais__c = pais.Id;
        insert cadena;
        
        Formato__c formato = new Formato__c ();
        formato.Cadena__c = cadena.Id;
        insert formato;
        
        Sitio__c sitio = new Sitio__c();
        sitio.Cadena__c = cadena.Id;
        sitio.Pais__c = pais.Id;
        sitio.Formato__c = formato.Id;
        insert sitio;
        
        Medida__c medida = new Medida__c();
        medida.Altura__c = 12;
        medida.Ancho__c = 2;
        medida.Base__c = '12';
        insert medida;
        
        Producto__c producto = new Producto__c();
        producto.MedidaParaProductoCompuesto__c = medida.Id;
        producto.MedidaPrincipal__c  = medida.Id;
        producto.AlturaFisica__c = 12;
        Producto.Name = 'GIRA';
        insert producto;
        
        producto = new Producto__c();
        producto.MedidaParaProductoCompuesto__c = medida.Id;
        producto.MedidaPrincipal__c  = medida.Id;
        producto.AlturaFisica__c = 12;
        producto.Name = 'Test';
        insert producto;
        
        medida.Producto__c = producto.Id;
        update medida;
        
        Medio__c medio = new Medio__c ();
        medio.Producto__c = producto.Id;
        medio.Medida__c = medida.Id;
        medio.Sitio__c = sitio.Id;
        insert medio;
        
        Venta__c venta = new Venta__c();
        venta.Cadena__c = cadena.Id;
        venta.Medio__c = medio.Id;
        venta.ProductoEtapa1__c = producto.Id;
        venta.Medida__c = medida.Id;
        venta.Campana__c = campania.Id;
        venta.FechaDeInicio__c = system.now().Date();
        venta.FechaFin__c = system.now().Date().addDays(4);
        insert venta;
        
        OdenDeCompra__c OC = new OdenDeCompra__c();
        OC.CampanaPublicitaria__c = campania.Id;
        OC.Estado__c = 'Borrador';
        insert OC;
        
        PrecioDeCompra__c precio = new PrecioDeCompra__c ();
        precio.Precio__c = 2;
        precio.Producto__c = producto.Id;
        insert precio;
        
        Arte__c arte = new Arte__c();
        arte.Campana__c = campania.Id;
        insert arte;
        
        MedioDeArte__c medioArte = new MedioDeArte__c();
        medioArte.Arte__c = arte.Id;
        medioArte.Venta__c = venta.Id;
        insert medioArte;
        
        Material__c material = new Material__c();
        insert material;
        
        Contrato__c contrato = new Contrato__c();
        contrato.FechaDeFin__c = Date.today().addDays(30);
        contrato.FechaDeInicio__c = Date.today();
        insert contrato;
        
        Estructura__c estructura = new Estructura__c();
        estructura.Producto__c = producto.Id;
        insert estructura;
        
        Account cuenta = new Account();
        cuenta.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Proveedor').getRecordTypeId();
        cuenta.Name = 'Test';
        insert cuenta;
        
        EstructuraEnSitio__c ESS = new EstructuraEnSitio__c();
        ESS.Medio__c = medio.Id;
        ESS.Estructura__c = estructura.Id;
        ESS.Estado__c = 'Activa';
        insert ESS;
        
        OrdenTrabajoDeEstructura__c OTE = new OrdenTrabajoDeEstructura__c();
        OTE.Tipo__c = 'Instalación';
        OTE.Estado__c = 'Pendiente';
        OTE.Instalador__c = UserInfo.getUserId();
        OTE.FechaPrevista__c = Date.today();
        OTE.Costo__C = 20;
        OTE.Proveedor__c = cuenta.Id;
        OTE.EstructuraEnSitio__c = ESS.Id;
        insert OTE;
        
    }
    
    public TestMethod static void ControllerRepairAndUninstall(){
        Test.startTest();
        Estructura__c estructura = [Select Id from Estructura__c];
        OrdenTrabajoDeEstructura__c ODE = [Select Id from OrdenTrabajoDeEstructura__c];
        ControllerRepairAndUninstall.getListOption(estructura.Id, null, null);
        ControllerRepairAndUninstall.insertOrdenTrabajo(ODE.Id, 'Instalación', null, 12, null);
        Test.stopTest();
    }

}