public without sharing class ControllerAddLinesToOrder {
    
    public static final String NOMBRE_PRODUCTO = 'GIRA';
    
    @AuraEnabled
    public static ResultWrapper getVentas(String recordId){
        
        ResultWrapper result = new ResultWrapper();
        result.listVentas = new List<Venta>();
        result.listVentasAgregadas = new List<Venta>();
        result.porcentajeDeCambioDeTarija = 0;
        result.porcentaje = (Decimal.valueOf(Label.PorcentajeUnidadesExtras) / 100).setsCale(4);
        result.textoBoton = 'Producir unidades extra ('+Label.PorcentajeUnidadesExtras+'%)';
        OdenDeCompra__c OC = [Select Id, CurrencyIsoCode ,CampanaPublicitaria__r.EstadoDeCampana__c ,CampanaPublicitaria__c,
                              RecordType.DeveloperName, IVA__c, Subtotal__c , Total__c,Proveedor__c
                              from OdenDeCompra__c where Id =:recordId ];
        result.codigoMoneda = OC.CurrencyIsoCode;
        for(User item: [Select PorcentajeDeCambioDeTarijaEnOC__c from user Where Id=:UserInfo.getUserId() And PorcentajeDeCambioDeTarijaEnOC__c > 0]){
            result.porcentajeDeCambioDeTarija = item.PorcentajeDeCambioDeTarijaEnOC__c;
        }
        result.iva = OC.IVA__c;
        result.subTotal = OC.Subtotal__c;
        result.totalOC = OC.Total__c;
        result.recortype = OC.RecordType.DeveloperName;
        result.isProduccion = OC.RecordType.DeveloperName == 'Produccion';
        result.etapa = OC.CampanaPublicitaria__r.EstadoDeCampana__c;
        List<Id> listIdV = new List<Id>();
        List<Id> listMedios = new List<Id>();
        List<Id> listProductos = new List<Id>();
        Map<Id, Venta> mapVentas= new Map<Id, Venta>();
        Map<String, Decimal> mapPrecios= new Map<String, Decimal>();
        Map<String, String> mapPreciosCompraId = new Map<String, String>();
        for(LineaOrdenDeCompra__c LOC:
            [Select Id,OrdenDeCompra__c,Cadena__r.Name,Formato__r.Name,Medida__r.Name,Medida__c,
             Arte__c,Arte__r.Name, Cantidad__c,Tarifa__c,Medio__r.name,
             RequerimientosEspeciales__c,Total__c,Product__c,Product__r.Name, Sitio__c,Sitio__r.Name,
             Venta__c,PrecioDeCompra__c, CurrencyIsoCode 
             from LineaOrdenDeCompra__c Where OrdenDeCompra__c =:recordId]){
                 Venta v = new Venta();
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
                 v.medidaId = LOC.Medida__c;
                 v.arteId = LOC.Arte__c;
                 v.arte = LOC.Arte__r.Name;
                 v.cantidad = LOC.Cantidad__c;
                 v.tarifa = LOC.Tarifa__c;
                 v.medioId = LOC.Medio__c;
                 v.requerimientosEspeciales = LOC.RequerimientosEspeciales__c;
                 v.total = LOC.Total__c;
                 v.precioCompraId = LOC.PrecioDeCompra__c;
                 v.listArtes = new List<PicklistOption>();
                 v.listMedidas = new List<PicklistOption>();
                 v.codigoMoneda = LOC.CurrencyIsoCode;
                 if(LOC.Medida__c != null){
                     v.listMedidas.add(new PicklistOption(LOC.Medida__r.Name, LOC.Medida__c));
                 }
                 result.listVentasAgregadas.add(v);
                 if(v.productoId != null){
                     listProductos.add(v.productoId);
                 }
        }
        result.OCAgregradas = result.listVentasAgregadas.size() > 0;
        List<String> listVentasAgrupadas = new List<String>();
        for(Venta__c item: 
            [Select Id, Name,Cadena__c,Cadena__r.Name,Medio__r.Sitio__r.Name ,
             Formato__c, Formato__r.Name, ProductoEtapa1__r.Name,Medida__r.Name, Tarifa__c, 
             ProductoEtapa1__c,Medida__c,Medio__r.Sitio__c,Medio__c,
             Medio__r.Sitio__r.Canton__c,RequerimientosEspeciales__c, Cantidad__c,
             Medio__r.Sitio__r.Distrito__r.Canton__c
             from Venta__c Where Campana__c =:OC.CampanaPublicitaria__c]){
                 Venta v = new Venta();
                 String agrupar = item.Cadena__r.Name +' - '+item.Formato__r.Name+' - '+item.ProductoEtapa1__r.Name+' - '+item.Medida__r.Name;
                 listIdV.add(item.Id);
                 v.id = item.Id;
                 v.VentaId = item.Id;
                 v.ordenCompraId = recordId;
                 v.cadena = item.Cadena__r.Name;
                 v.cadenaId = item.Cadena__c;
                 v.formato = item.Formato__r.Name;
                 v.formatoId = item.Formato__c;
                 v.producto = item.ProductoEtapa1__r.Name;
                 v.productoId = item.ProductoEtapa1__c;
                 v.medida = item.Medida__r.Name;
                 v.medidaId = item.Medida__c;
                 v.sitio = item.Medio__r.Sitio__r.Name;
                 v.cantonId = item.Medio__r.Sitio__r.Distrito__r.Canton__c;
                 v.sitioId = item.Medio__r.Sitio__c;
                 v.medioId = item.Medio__c;
                 v.tarifa = 0.0;
                 v.tarifaOrg = 0.0;
                 v.total = 0.0;
                 v.cantidad = item.Cantidad__c != null ? item.Cantidad__c : 0;
                 v.requerimientosEspeciales = item.RequerimientosEspeciales__c;
                 v.listArtes = new List<PicklistOption>();
                 v.listMedidas = new List<PicklistOption>();
                 v.agrupar = agrupar;
                 v.codigoMoneda = OC.CurrencyIsoCode;
                 if(item.Medida__c != null){
                     v.listMedidas.add(new PicklistOption(item.Medida__r.Name, item.Medida__c));
                 }
                 if(listVentasAgrupadas.contains(agrupar) && result.isProduccion){
                     for(Integer i=0; i<result.listVentas.size(); i++){
                         if(result.listVentas[i].agrupar == agrupar){
                             result.listVentas[i].cantidad += v.cantidad;
                             if(result.listVentas[i].requerimientosEspeciales != null){
                                 result.listVentas[i].requerimientosEspeciales += '\n' + v.requerimientosEspeciales;
                             }else{
                                 result.listVentas[i].requerimientosEspeciales = v.requerimientosEspeciales;
                             }
                         }
                     }
                 }else{
                     mapVentas.put(item.Id, v);
                     result.listVentas.add(v); 
                     listVentasAgrupadas.add(agrupar);
                 }
                 if(v.medioId != null){
                     listMedios.add(v.medioId);
                 }
                 if(v.productoId != null){
                     listProductos.add(v.productoId);
                 }
                 
             }
        for(PrecioDeCompra__c  item: [Select Precio__c, Producto__c, Medio__c,Proveedor__c,Medida__c,Id from PrecioDeCompra__c  where (Producto__c in :listProductos OR Medio__c in :listMedios) and Activa__c = true ]){
            if(item.Producto__c != null && item.Proveedor__c != null){
                String concatenado = item.Producto__c+' - '+item.Proveedor__c+' - '+item.Medida__c;
                mapPrecios.put(concatenado, item.Precio__c);
                mapPreciosCompraId.put(concatenado, item.Id);
            }
        }
        Map<Id, List<PicklistOption>> mapMedida = new Map<Id, List<PicklistOption>>();
        for(Medida__c item: [Select Id,Name,Producto__c from Medida__c where Producto__c in:listProductos order by Name asc]){
            List<PicklistOption> listMedida = mapMedida.containsKey(item.Producto__c) ? mapMedida.get(item.Producto__c) : new List<PicklistOption>();
            listMedida.add(new PicklistOption(item.Name, item.Id));
            mapMedida.put(item.Producto__c, listMedida);
        }
        for(Integer i=0; i<result.listVentas.size(); i++){
            String concatenado = result.listVentas[i].productoId + ' - ' +OC.Proveedor__c+' - '+result.listVentas[i].MedidaId;
            if(result.listVentas[i].productoId != null && mapPrecios.containsKey(concatenado)){
                result.listVentas[i].tarifa = mapPrecios.get(concatenado);
                result.listVentas[i].tarifaOrg = mapPrecios.get(concatenado);
                result.listVentas[i].total = (result.listVentas[i].cantidad * result.listVentas[i].tarifa).setsCale(2);
                result.listVentas[i].precioCompraId = mapPreciosCompraId.get(concatenado);
            }
        }
        for(MedioDeArte__c item: [Select Arte__r.Name, Arte__c,Venta__c from MedioDeArte__c where Venta__c in :listIdV order by Arte__r.CreatedDate Desc]){
            for(Integer i=0; i<result.listVentas.size(); i++){
                if(item.Venta__c == result.listVentas[i].id){
                    result.listVentas[i].listArtes.add(new PicklistOption(item.Arte__r.Name, item.Arte__c));
                    if(result.listVentas[i].arteId == null){
                       result.listVentas[i].arteId = item.Arte__c;
                       result.listVentas[i].arte = item.Arte__r.Name;
                    }
                }
            }
            for(Integer i=0; i<result.listVentasAgregadas.size(); i++){
               if(item.Venta__c == result.listVentasAgregadas[i].ventaId){
                    result.listVentasAgregadas[i].listArtes.add(new PicklistOption(item.Arte__r.Name, item.Arte__c));
                }
            }
        }
        for(Integer i=0; i<result.listVentas.size(); i++){
            if(mapMedida.containsKey(result.listVentas[i].productoId)){
                List<PicklistOption> medidas = mapMedida.get(result.listVentas[i].productoId);
                for(Integer j=0; j<medidas.size(); j++){
                    if(result.listVentas[i].medidaId != medidas[j].value){
                        result.listVentas[i].listMedidas.add(medidas[j]);
                    }
                }
            }
        }
        for(Integer i=0; i<result.listVentasAgregadas.size(); i++){
            if(mapMedida.containsKey(result.listVentasAgregadas[i].productoId)){
                List<PicklistOption> medidas = mapMedida.get(result.listVentasAgregadas[i].productoId);
                for(Integer j=0; j<medidas.size(); j++){
                    if(result.listVentasAgregadas[i].medidaId != medidas[j].value){
                        result.listVentasAgregadas[i].listMedidas.add(medidas[j]);
                    }
                }
            }
        }
        system.debug('Retorno: '+result);
        return result;
    }
    
    @AuraEnabled
    public static void guardarRegistros(String listRegistros, Boolean esDetallada){
        List<Venta> listVentas = (List<Venta>) Json.deserialize(listRegistros, List<Venta>.class);
        List<LineaOrdenDeCompra__c> listLineasOC = new List<LineaOrdenDeCompra__c>();
        List<Notificacion> listNotif = new List<Notificacion>();
         Integer conteo = [Select Count() from LineaOrdenDeCompra__c where OrdenDeCompra__c=: listVentas[0].ordenCompraId and Product__r.Name = :NOMBRE_PRODUCTO];
        if(esDetallada && conteo == 0){
            ordenCompraDetallada(listVentas);
        }
        User usuario = [Select Name, ManagerId,Manager.Email from User where Id=:UserInfo.getUserId()];
        Integer i = 0;
        for(Venta item: listVentas){
            LineaOrdenDeCompra__c LOC = new LineaOrdenDeCompra__c();
            Notificacion notif = new Notificacion();
            LOC.OrdenDeCompra__c = item.ordenCompraId;
            LOC.Venta__c = item.id;
            LOC.Cadena__c = item.cadenaId;
            LOC.Formato__c = item.formatoId;
            LOC.Product__c = item.productoId;
            LOC.Sitio__c = item.sitioId;
            LOC.Medida__c = item.medidaId;
            LOC.Arte__c = item.arteId;
            LOC.Cantidad__c = item.cantidad;
            LOC.Tarifa__c = item.tarifa;
            LOC.Medio__c = esDetallada ? item.medioId : null;
            lOC.RazonDiferencia__c = item.comentariosNotif;
            LOC.RequerimientosEspeciales__c = item.requerimientosEspeciales;
            LOC.PrecioDeCompra__c = item.precioCompraId;
            LOC.PrecioAlterado__c = item.comentariosNotif != null;
            LOC.CurrencyIsoCode = item.codigoMoneda;
            listLineasOC.add(LOC);
            if(item.enviarNotificacion != null &&item.enviarNotificacion && usuario.ManagerId !=null){
                notif.indice = i;
                notif.correo = usuario.Manager.Email;
                notif.usuarioId = usuario.ManagerId;
                notif.comentarios = item.comentariosNotif;
                notif.precio = item.tarifa;
                notif.precioOrg = item.tarifaOrg;
                listNotif.add(notif);
            }
            i++;
        }
        insert listLineasOC;
        map<Id, LineaOrdenDeCompra__c> mapLineasOC = new map<Id, LineaOrdenDeCompra__c>([Select id, Name From LineaOrdenDeCompra__c
                                                                        Where Id in :listLineasOC]);
        for(Notificacion notif: listNotif){
            notif.registroId = listLineasOC[notif.indice].Id;
            notif.nombre = mapLineasOC.get(notif.registroId).Name;
            listNotif[notif.indice] = notif;
        }
        enviarNotificacion(listNotif);
        
    }
    
    public static void enviarNotificacion(List<Notificacion> ListNotif){
        Id typeId = [SELECT Id FROM CUstomNotificationType LIMIT 1].Id;
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        for(Notificacion item : listNotif){
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Cambio de tarifa en Línea Orden de Compra '+item.nombre);
            notification.setBody('El ejecutivo '+UserInfo.getFirstName() + ' ha cambiado la taria de la Línea Orden de Compra. \n Precio anterior: '+item.precioOrg  + '.\n Precio nuevo: '+item.precio +'.\n Comentarios: '+item.comentarios);
            notification.setNotificationTypeId(typeId);
            notification.setTargetId(item.registroId); // target object id
            Set<String> sendUsers = (new Set<String> { item.usuarioId });
            
            //---Preparing Email---
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSaveAsActivity(false);
            mail.setToAddresses(new String[]{item.correo});
            mail.setSubject('Cambio de tarifa en Línea Orden de Compra '+item.nombre);
            mail.setPlainTextBody('El ejecutivo '+UserInfo.getFirstName() + ' ha cambiado la taria de la Línea Orden de Compra. \n Precio anterior: '+item.precioOrg  + '\n Precio nuevo: '+item.precio +'.\n Comentarios: '+ item.comentarios +' \n\nPor favor dar seguimiento. ');
            allmsg.add(mail);
            
            notification.send(sendUsers); // target user id.
        }
        Messaging.sendEmail(allmsg,false);
    }
    
    public static void ordenCompraDetallada(List<Venta> listVentas){
        List<String> listSitio = new List<String>();
        List<String> listCanton = new List<String>();
        Map<String, Sitio__c> mapSitio = new Map<String, Sitio__c>();
        Map<String, CargoExtraDeInstalacion__c> mapCanton = new Map<String, CargoExtraDeInstalacion__c>();
        List<LineaOrdenDeCompra__c> listLineasOC = new List<LineaOrdenDeCompra__c>();
        List<String> listLineasOCAgreg = new List<String>();
        String productoId;
         for(Venta item: listVentas){
             if(item.cantonId != null){
                 listCanton.add(item.cantonId);
                 listSitio.add(item.sitioId);
             }
         }
        system.debug(listSitio+ ' --- '+listCanton);
        for(Sitio__c item :[Select Id, Distrito__r.Canton__C,Cadena__c,Formato__c from Sitio__c where Id in:listSitio and Distrito__r.Canton__C != null]){
            mapSitio.put(item.Id, item);
        }
        system.debug(mapSitio+ ' --- ');
        for(CargoExtraDeInstalacion__c item: [Select Id, Canton__C,Canton__r.Name,Monto__c from CargoExtraDeInstalacion__c where Canton__C in:listCanton ]){
            mapCanton.put(item.Canton__c, item);
        }
        system.debug(mapCanton+ ' --- ');
        for(LineaOrdenDeCompra__c item: [Select RequerimientosEspeciales__c,Product__c from LineaOrdenDeCompra__c where OrdenDeCompra__c = :listVentas[0].ordenCompraId And Product__r.Name = :NOMBRE_PRODUCTO]){
            listLineasOCAgreg.add(item.RequerimientosEspeciales__c);
            productoId = item.Product__c;
        }
        system.debug(listLineasOCAgreg+ ' --- ');
        productoId = [Select Id from Producto__c where Name = :NOMBRE_PRODUCTO].Id;
         for(Venta item: listVentas){
            LineaOrdenDeCompra__c LOC = new LineaOrdenDeCompra__c();
             if(mapCanton.containsKey(item.cantonId)){
                 Sitio__c sitio = mapSitio.get(item.sitioId);
                 CargoExtraDeInstalacion__c CEI = mapCanton.get(item.cantonId);
                 LOC.Cadena__c = sitio.Cadena__c;
                 LOC.Formato__c = sitio.Formato__c;
                 LOC.Cantidad__c = 1;
                 LOC.Tarifa__c =  CEI.Monto__c;
                 
                 LOC.OrdenDeCompra__c = item.ordenCompraId;
                 LOC.Product__c = productoId;
                 LOC.Sitio__c = sitio.Id;
                 
                 LOC.Venta__c = item.id;
                 //LOC.Medida__c = item.medidaId;
                 //LOC.Arte__c = item.arteId;
                 LOC.Medio__c = item.medioId;
                 
                 LOC.CurrencyIsoCode = item.codigoMoneda;
                 LOC.RequerimientosEspeciales__c = CEI.Canton__r.Name;
                 if(!listLineasOCAgreg.contains(CEI.Canton__r.Name)){
                     listLineasOC.add(LOC);
                 } 
                 
             }
         }
        insert listLineasOC;
    }
    
    @AuraEnabled
    public static void borrarRegistro(String recordId){
        LineaOrdenDeCompra__c LOC = new LineaOrdenDeCompra__c(Id= recordId);
        delete LOC;
    }
    @AuraEnabled
    public static void editarRegistro(String dataJson){
         Venta venta = (Venta) Json.deserialize(dataJson, Venta.class);
        LineaOrdenDeCompra__c LOC = new LineaOrdenDeCompra__c(Id= venta.id, Cantidad__c = venta.cantidad, Arte__c = venta.arteId, 
                                                              RequerimientosEspeciales__c = venta.requerimientosEspeciales);
        update LOC;
    }
    
    @AuraEnabled
    public static Decimal getPrecio(String productoId, String medidaId, String ordenCompraId){
        OdenDeCompra__c OC = [Select Proveedor__c from OdenDeCompra__c where Id =:ordenCompraId ];
        for(PrecioDeCompra__c  item: [Select Precio__c from PrecioDeCompra__c  where Producto__c = :productoId And Proveedor__c = :OC.Proveedor__c And Medida__c =:medidaId And Activa__c = true]){
            return item.Precio__c;
        }
        return 0.00;
    }

    @AuraEnabled(cacheable=true)
    public static List<LineaOrdenDeCompra__c> getOrderLineDetail(String recordId) {
        return [
            SELECT Id,Arte__r.Name, Cadena__r.Name, Cantidad__c, DimensionesDeProducto__c, Formato__r.Name, Material__c,Medida__r.Name,Medida__r.Producto__r.Name,Medio__c,Medio__r.Sitio__r.Name,OrdenDeCompra__c,
            PrecioAlterado__c,PrecioDeCompra__c,RequerimientosEspeciales__c,Tarifa__c,Total__c,CantidadRecibida__c
            FROM LineaOrdenDeCompra__c
            WHERE OrdenDeCompra__c =: recordId
        ];
    }
    
    public class ResultWrapper {
        @AuraEnabled public List<Venta> listVentas {get;set;}
        @AuraEnabled public List<Venta> listVentasAgregadas {get;set;}
        @AuraEnabled public Boolean isProduccion {get;set;}
        @AuraEnabled public Boolean OCAgregradas {get;set;}
        @AuraEnabled public String etapa {get;set;}
        @AuraEnabled public String recortype {get;set;}
        @AuraEnabled public Decimal porcentajeDeCambioDeTarija {get;set;}
        
        @AuraEnabled public Decimal subTotal {get;set;}
        @AuraEnabled public Decimal iva {get;set;}
        @AuraEnabled public Decimal totalOC {get;set;}
        
        @AuraEnabled public String textoBoton {get;set;}
        @AuraEnabled public Decimal porcentaje {get;set;}
        @AuraEnabled public String codigoMoneda {get;set;}
        
    }
    public class Venta{
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
        @AuraEnabled public String requerimientosEspeciales{get;set;}
        @AuraEnabled public Decimal tarifa{get;set;}
        @AuraEnabled public Decimal tarifaOrg{get;set;}
        @AuraEnabled public Decimal total{get;set;}
        @AuraEnabled public Decimal cantidad{get;set;}
        @AuraEnabled public Boolean enviarNotificacion{get;set;}
        @AuraEnabled public String comentariosNotif{get;set;}
        @AuraEnabled public String agrupar{get;set;}
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
        public Integer indice;
    }
    
    public class PicklistOption{
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String value{get;set;}
        PicklistOption(String label, String value){
            this.label = label;
            this.value = value;
        }
    }
    
    
}