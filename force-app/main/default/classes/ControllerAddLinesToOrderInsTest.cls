@isTest
public class ControllerAddLinesToOrderInsTest {

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
        update usuario;
        
        Cadena__c cadena = new Cadena__c();
        cadena.NombreCadena2__c  = 'Test';
        cadena.Name = 'Test';
        cadena.Canal__c = 'Canal Moderno';
        cadena.Pais__c = pais.Id;
        insert cadena;
        
        Sitio__c sitio = new Sitio__c();
        sitio.Cadena__c = cadena.Id;
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
        
        
    }
    
    public TestMethod static void ControllerAddLinesToOrderIns(){
        OdenDeCompra__c OC = [Select Id from OdenDeCompra__c];
        ControllerAddLinesToOrderIns.ResultWrapper result =  ControllerAddLinesToOrderIns.getInstalaciones(OC.Id);
        result.detalle = 'Test';
        result.precio = 12;
        result.cantidad = 43;
        result.total = 32;
        ControllerAddLinesToOrderIns.inserRecord(JSON.serialize(result));
        result =  ControllerAddLinesToOrderIns.getInstalaciones(OC.Id);
        ControllerAddLinesToOrderIns.editRecord(result.listInstalacionesAgr[0].id, 12, OC.Id);
        ControllerAddLinesToOrderIns.deleteRecord(result.listInstalacionesAgr[0].id, OC.Id);
        /*result.listVentas[0].ArteId = result.listVentas[0].listArtes[0].value;
        result.listVentas[0].tarifa = 10;
        result.listVentas[0].cantidad = 10;
        result.listVentas[0].enviarNotificacion = true;
        result.listVentas[0].comentariosNotif = 'Test';
        
        ControllerAddLinesToOrder.guardarRegistros(JSON.serialize(result.listVentas), true);
        result =  ControllerAddLinesToOrder.getVentas(OC.Id);
        ControllerAddLinesToOrder.editarRegistro(JSON.serialize(result.listVentasAgregadas[0]));
        
        ControllerAddLinesToOrder.getOrderLineDetail(OC.Id);*/
    }
}