public class ControllerAddLinesToOrderVar {

    public static final String NOMBRE_PRODUCTO = 'GIRA';
    
    @AuraEnabled
    public static ResultWrapper getLineasOrdenCompra(String recordId){
        ResultWrapper result = new ResultWrapper();
        result.listLineasOC = new List<LineasOC>();
        result.porcentajeDeCambioDeTarija = 0;
        result.textoBoton = 'Mostrar Sitio';
        result.mostrarSitio = false;
        result.total = 0.0;
        result.disabledBoton = true;
        OdenDeCompra__c OC = [Select Id, RecordType.DeveloperName, CurrencyIsoCode, IVA__c, Subtotal__c , Total__c,Proveedor__c,CampanaPublicitaria__c
                              from OdenDeCompra__c where Id =:recordId ];
        if(OC.RecordType.DeveloperName == 'ProduccionInstalacion'){
            result.textoBoton = 'Ocultar Sitio';
            result.mostrarSitio = true;
        }
        result.codigoMoneda = OC.CurrencyIsoCode;
        result.iva = OC.IVA__c;
        result.subTotal = OC.Subtotal__c;
        result.totalOC = OC.Total__c;
        result.contrato = OC.CampanaPublicitaria__c;
        for(User item: [Select PorcentajeDeCambioDeTarijaEnOC__c from user Where Id=:UserInfo.getUserId() And PorcentajeDeCambioDeTarijaEnOC__c > 0]){
            result.porcentajeDeCambioDeTarija = item.PorcentajeDeCambioDeTarijaEnOC__c;
        }
        for(LineaOrdenDeCompra__c LOC:
            [Select Id,OrdenDeCompra__c,Cadena__r.Name,Formato__r.Name,Medida__r.Name,
             Arte__c,Arte__r.Name, Cantidad__c,Tarifa__c,Medio__r.name,
             RequerimientosEspeciales__c,Total__c,Product__c,Product__r.Name, Sitio__c,Sitio__r.Name,
             Venta__c,PrecioDeCompra__c, CurrencyIsoCode,Contrato__c, Contrato__r.name 
             from LineaOrdenDeCompra__c Where OrdenDeCompra__c =:recordId]){
                 LineasOC v = new LineasOC();
                 v.id =  LOC.Id;
                 v.ordenCompraId = LOC.OrdenDeCompra__c;
                 v.ventaId = LOC.Venta__c;
                 v.cadena = LOC.Cadena__r.Name;
                 v.formato = LOC.Formato__r.Name;
                 v.productoId = LOC.Product__c;
                 v.producto = LOC.Product__r.Name;
                 v.sitioId = LOC.Sitio__c;
                 v.sitio = LOC.Sitio__r.Name;
                 v.medida = LOC.Medida__r.Name;
                 v.arteId = LOC.Arte__c;
                 v.arte = LOC.Arte__r.Name;
                 v.contratoId = LOC.Contrato__c;
                 v.contrato = LOC.Contrato__r.Name;
                 v.cantidad = LOC.Cantidad__c;
                 v.tarifa = LOC.Tarifa__c;
                 v.medioId = LOC.Medio__c;
                 v.requerimientosEspeciales = LOC.RequerimientosEspeciales__c;
                 v.total = LOC.Total__c;
                 v.precioCompraId = LOC.PrecioDeCompra__c;
                 //v.listArtes = new List<PicklistOption>();
                 //v.listMedidas = new List<PicklistOption>();
                 v.codigoMoneda = LOC.CurrencyIsoCode;
                 if(LOC.Medida__c != null){
                     //v.listMedidas.add(new PicklistOption(LOC.Medida__r.Name, LOC.Medida__c));
                 }
                 result.listLineasOC.add(v);
             }
        return result;
    }
    
    public static void cargoExtraDeInstalacion(ResultWrapper data){
        Map<String, Sitio__c> mapSitio = new Map<String, Sitio__c>();
        Map<String, CargoExtraDeInstalacion__c> mapCanton = new Map<String, CargoExtraDeInstalacion__c>();
        String productoId;
        for(Sitio__c item :[Select Id, Canton__C,Cadena__c,Formato__c from Sitio__c where Id = :data.sitio  and Canton__C != null]){
            mapSitio.put(item.Id, item);
        }
        if(mapSitio.size() > 0){
            for(CargoExtraDeInstalacion__c item: [Select Id, Canton__C,Canton__r.Name,Monto__c from CargoExtraDeInstalacion__c where Canton__C = :mapSitio.get(data.sitio).Canton__C ]){
                mapCanton.put(item.Canton__c, item);
            }  
        }
        productoId = [Select Id from Producto__c where Name = :NOMBRE_PRODUCTO].Id;
       
        LineaOrdenDeCompra__c LOC = new LineaOrdenDeCompra__c();
        if(mapSitio.size() > 0 && mapCanton.containsKey(mapSitio.get(data.sitio).Canton__C)){
            Sitio__c sitio = mapSitio.get(data.sitio);
            CargoExtraDeInstalacion__c CEI = mapCanton.get(mapSitio.get(data.sitio).Canton__C);
            LOC.Cadena__c = sitio.Cadena__c;
            LOC.Formato__c = sitio.Formato__c;
            LOC.Cantidad__c = 1;
            LOC.Tarifa__c =  CEI.Monto__c;
            LOC.OrdenDeCompra__c = data.ordenCompraId;
            LOC.Product__c = productoId;
            LOC.Sitio__c = sitio.Id;
            LOC.CurrencyIsoCode = data.codigoMoneda;
            LOC.RequerimientosEspeciales__c = CEI.Canton__r.Name;
            insert LOC;
        }
    }
    
    
     @AuraEnabled
    public static void guardarRegistro(String data){
        ResultWrapper lineaOC = (ResultWrapper) Json.deserialize(data, ResultWrapper.class);
        User usuario = [Select Name, ManagerId,Manager.Email from User where Id=:UserInfo.getUserId()];
        LineaOrdenDeCompra__c LOC = new LineaOrdenDeCompra__c();
        LOC.Contrato__c = lineaOC.contrato;
        LOC.Cadena__c = lineaOC.cadena;
        LOC.Formato__c = lineaOC.formato;
        LOC.Product__c = lineaOC.producto;
        LOC.Medida__c = lineaOC.medida;
        LOC.Sitio__c = lineaOC.mostrarSitio ? lineaOC.sitio : null;
        LOC.Arte__c = lineaOC.arte;
        LOC.Tarifa__c = lineaOC.tarifa;
        LOC.Cantidad__c = lineaOC.cantidad;
        LOC.RequerimientosEspeciales__c = lineaOC.requerimientosEspeciales;
        LOC.OrdenDeCompra__c = lineaOC.ordenCompraId;
        insert LOC;
        cargoExtraDeInstalacion(lineaOC);
        if(lineaOC.enviarNotificacion != null &&lineaOC.enviarNotificacion && usuario.ManagerId !=null){
        	Notificacion notif =new Notificacion ();
            notif.correo = usuario.Manager.Email;
            notif.usuarioId = usuario.ManagerId;
            notif.comentarios = lineaOC.comentariosNotif;
            notif.precio = lineaOC.tarifa;
            notif.precioOrg = lineaOC.tarifaOrg;
            enviarNotificacion(notif);
        }
    }
    
    @AuraEnabled
    public static void editarRegistro(String recordId, Decimal cantidad){
        LineaOrdenDeCompra__c LOC = new LineaOrdenDeCompra__c(Id= recordId, Cantidad__c = cantidad);
        update LOC;
    }
    
    public static void enviarNotificacion(Notificacion notifi){
        Id typeId = [SELECT Id FROM CustomNotificationType LIMIT 1].Id;
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle('Cambio de tarifa en Línea Orden de Compra '+notifi.nombre);
        notification.setBody('El ejecutivo '+UserInfo.getFirstName() + ' ha cambiado la taria de la Línea Orden de Compra. \n Precio anterior: '+notifi.precioOrg  + '.\n Precio nuevo: '+notifi.precio +'.\n Comentarios: '+notifi.comentarios);
        notification.setNotificationTypeId(typeId);
        notification.setTargetId(notifi.registroId); 
        Set<String> sendUsers = (new Set<String> { notifi.usuarioId });
        
        //---Preparing Email---
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSaveAsActivity(false);
        mail.setToAddresses(new String[]{notifi.correo});
        mail.setSubject('Cambio de tarifa en Línea Orden de Compra '+notifi.nombre);
        mail.setPlainTextBody('El ejecutivo '+UserInfo.getFirstName() + ' ha cambiado la taria de la Línea Orden de Compra. \n Precio anterior: '+notifi.precioOrg  + '\n Precio nuevo: '+notifi.precio +'.\n Comentarios: '+ notifi.comentarios +' \n\nPor favor dar seguimiento. ');
        allmsg.add(mail);
        
        notification.send(sendUsers);
        Messaging.sendEmail(allmsg,false);
    }
    
    @AuraEnabled
    public static List<PicklistOption> getFormato(String cadenaId){
       List<PicklistOption> listFormato = new list<PicklistOption>();
        for(Formato__c item: [Select Id, name from Formato__c where Cadena__c=: cadenaId Order By Name asc]){
            listFormato.add(new PicklistOption(item.Id, item.Name));
        }
        return listFormato;
    }
    
    @AuraEnabled
    public static List<PicklistOption> getArte(String campaniaId){
       List<PicklistOption> listArtes= new list<PicklistOption>();
        for(Arte__c item: [Select Id, name from Arte__c where Campana__c=: campaniaId Order By Name asc]){
            listArtes.add(new PicklistOption(item.Id, item.Name));
        }
        return listArtes;
    }
    
    @AuraEnabled
    public static Decimal getPrecio(String productoId, String medidaId, String ordenCompraId){
        OdenDeCompra__c OC = [Select Proveedor__c from OdenDeCompra__c where Id =:ordenCompraId ];
        for(PrecioDeCompra__c  item: [Select Precio__c from PrecioDeCompra__c  where Producto__c = :productoId And Proveedor__c = :OC.Proveedor__c And Medida__c =:medidaId And Activa__c = true]){
            return item.Precio__c;
        }
        return 0.00;
    }
    
    
    @AuraEnabled
    public static producto getMedida(String productoId){
        producto product = new producto();
        
        product.listMedida = new list<PicklistOption>();
        String medidaPredet;
        for(Producto__c item: [Select MedidaPrincipal__c , MedidaPrincipal__r.Name from Producto__c where Id =: productoId]){
            product.medidaPrincipal = item.MedidaPrincipal__c;
        }
        for(Medida__c item: [Select Id, name from Medida__c where Producto__c =: productoId or Id = :product.medidaPrincipal Order By Name asc]){
            product.listMedida.add(new PicklistOption(item.Id, item.Name));
        }
        return product;
    }
    
    @AuraEnabled
    public static List<PicklistOption> getSitio(String cadenaId, String formatoId){
       List<PicklistOption> listSitios = new list<PicklistOption>();
        String pais;
        for(User item:[Select Country from User where Id =: userinfo.getUserId()]){
            pais = item.Country;
        }
        System.debug(cadenaId +' -- '+formatoId+' -- '+pais);
        for(Sitio__c item:
            [Select Id, name from Sitio__c where Cadena__c=: cadenaId and 
             Formato__c =:formatoId and Pais__r.Name =:pais Order By Name asc]){
                 listSitios.add(new PicklistOption(item.Id, item.Name));
             }
        return listSitios;
    }
    
    public class producto{
        @AuraEnabled public  List<PicklistOption> listMedida{get;set;}
        @AuraEnabled public  String medidaPrincipal{get;set;}
    }
    public class ResultWrapper {
        @AuraEnabled public String ordenCompraId{get;set;}
        @AuraEnabled public String contrato {get;set;}
        @AuraEnabled public String cadena {get;set;}
        @AuraEnabled public String formato {get;set;}
        @AuraEnabled public String producto {get;set;}
        @AuraEnabled public String sitio {get;set;}
        @AuraEnabled public String medida {get;set;}
        @AuraEnabled public String arte {get;set;}
        @AuraEnabled public Decimal cantidad {get;set;}
        @AuraEnabled public Decimal tarifa {get;set;}
        @AuraEnabled public Decimal tarifaOrg {get;set;}
        @AuraEnabled public Decimal total {get;set;}
        @AuraEnabled public String requerimientosEspeciales{get;set;}
        @AuraEnabled public Boolean disabledBoton{get;set;}
        @AuraEnabled public Boolean enviarNotificacion{get;set;}
        @AuraEnabled public String comentariosNotif{get;set;}
        
        
        
        @AuraEnabled public List<LineasOC> listLineasOC {get;set;}
        //@AuraEnabled public Boolean isProduccion {get;set;}
        //@AuraEnabled public Boolean OCAgregradas {get;set;}
        //@AuraEnabled public String etapa {get;set;}
        //@AuraEnabled public String recortype {get;set;}
        @AuraEnabled public Decimal porcentajeDeCambioDeTarija {get;set;}
        
        @AuraEnabled public Decimal subTotal {get;set;}
        @AuraEnabled public Decimal iva {get;set;}
        @AuraEnabled public Decimal totalOC {get;set;}
        
        @AuraEnabled public String textoBoton {get;set;}
        @AuraEnabled public Boolean mostrarSitio {get;set;}
        @AuraEnabled public String codigoMoneda {get;set;}
        
    }
    public class LineasOC{
        @AuraEnabled public String id{get;set;}
        @AuraEnabled public String ventaid{get;set;}
        @AuraEnabled public String idLOC{get;set;}
        @AuraEnabled public String ordenCompraId{get;set;}
        @AuraEnabled public String cadena{get;set;}
        @AuraEnabled public String cadenaId{get;set;}
        @AuraEnabled public String formato{get;set;}
        @AuraEnabled public String formatoId{get;set;}
        @AuraEnabled public String producto{get;set;}
        @AuraEnabled public String productoId{get;set;}
        @AuraEnabled public String medida{get;set;}
        @AuraEnabled public String medidaId{get;set;}
        @AuraEnabled public String arte{get;set;}
        @AuraEnabled public String arteId{get;set;}
        @AuraEnabled public String sitio{get;set;}
        @AuraEnabled public String sitioId{get;set;}
        @AuraEnabled public String medioId{get;set;}
        @AuraEnabled public String cantonId{get;set;}
        @AuraEnabled public String contrato{get;set;}
        @AuraEnabled public String contratoId{get;set;}
        @AuraEnabled public String requerimientosEspeciales{get;set;}
        @AuraEnabled public Decimal tarifa{get;set;}
        @AuraEnabled public Decimal tarifaOrg{get;set;}
        @AuraEnabled public Decimal total{get;set;}
        @AuraEnabled public Decimal cantidad{get;set;}
        @AuraEnabled public Boolean enviarNotificacion{get;set;}
        @AuraEnabled public String comentariosNotif{get;set;}
        //@AuraEnabled public String agrupar{get;set;}
        @AuraEnabled public String precioCompraId{get;set;}
        @AuraEnabled public String codigoMoneda{get;set;}
        @AuraEnabled public List<PicklistOption> listArtes{get;set;}
        @AuraEnabled public List<PicklistOption> listMedidas{get;set;}
    }
    
    public class Notificacion{
        public String nombre;
        public String correo;
        public String usuarioId;
        public String comentarios;
        public String registroId;
        public Decimal precioOrg;
        public Decimal precio;
    }
    public class PicklistOption{
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String value{get;set;}
        PicklistOption(String value, String label){
            this.label = label;
            this.value = value;
        }
    }
}