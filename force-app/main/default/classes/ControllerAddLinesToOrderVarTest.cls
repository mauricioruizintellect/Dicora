@isTest
public class ControllerAddLinesToOrderVarTest {
    
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
        
    }
    
    public TestMethod static void ControllerAddLinesToOrderVar(){
        OdenDeCompra__c OC = [Select Id from OdenDeCompra__c];
        Cadena__c cadena = [Select Id from Cadena__c];
        Contrato__c contrato = [Select Id from Contrato__c];
        Producto__c producto = [Select Id from Producto__c where Name = 'Test'];
        Campana__c campania = [Select Id from Campana__c];
        ControllerAddLinesToOrderVar.ResultWrapper result =  ControllerAddLinesToOrderVar.getLineasOrdenCompra(OC.Id);
        result.contrato = contrato.Id;
        result.ordenCompraId = OC.Id;
        result.cadena = cadena.Id;
        result.formato = ControllerAddLinesToOrderVar.getFormato(cadena.Id)[0].value;
        result.producto = producto.Id;
        result.medida = ControllerAddLinesToOrderVar.getMedida(result.producto).listMedida[0].value;
        result.sitio = ControllerAddLinesToOrderVar.getSitio(result.cadena, result.formato)[0].value;
        result.arte = ControllerAddLinesToOrderVar.getArte(campania.id)[0].value;
        result.tarifa = ControllerAddLinesToOrderVar.getPrecio(result.producto, result.medida, OC.Id) + 10;
        result.tarifaOrg = result.tarifa;
        result.comentariosNotif = 'Test';
        result.enviarNotificacion = true;
        result.contrato = null;
        ControllerAddLinesToOrderVar.guardarRegistro(Json.serialize(result));
        result =  ControllerAddLinesToOrderVar.getLineasOrdenCompra(OC.Id);
        ControllerAddLinesToOrderVar.editarRegistro(result.listLineasOC[0].id, 21);
    }

}