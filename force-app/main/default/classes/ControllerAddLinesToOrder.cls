public without sharing class ControllerAddLinesToOrder {
    
    @AuraEnabled
    public static ResultWrapper getVentas(String recordId){
        ResultWrapper result = new ResultWrapper();
        result.listVentas = new List<Venta>();
        result.listVentasAgregadas = new List<Venta>();
        result.porcentajeDeCambioDeTarija = 0;
        OdenDeCompra__c OC = [Select Id, CampanaPublicitaria__r.EstadoDeCampana__c ,CampanaPublicitaria__c,RecordType.DeveloperName
                              from OdenDeCompra__c where Id =:recordId ];
        for(User item: [Select PorcentajeDeCambioDeTarijaEnOC__c from user Where Id=:UserInfo.getUserId() And PorcentajeDeCambioDeTarijaEnOC__c > 0]){
            result.porcentajeDeCambioDeTarija = item.PorcentajeDeCambioDeTarijaEnOC__c;
        }
        result.recortype = OC.RecordType.DeveloperName;
        result.isProduccion = OC.RecordType.DeveloperName == 'Produccion';
        result.etapa = OC.CampanaPublicitaria__r.EstadoDeCampana__c;
        List<Id> listIdV = new List<Id>();
        List<Id> listMedios = new List<Id>();
        List<Id> listProductos = new List<Id>();
        Map<Id, Venta> mapVentas= new Map<Id, Venta>();
        Map<Id, Decimal> mapPrecios= new Map<Id, Decimal>();
        for(LineaOrdenDeCompra__c LOC:
            [Select Id,OrdenDeCompra__c,Cadena__r.Name,Formato__r.Name,Medida__r.Name,
             Arte__c,Arte__r.Name, Cantidad__c,Tarifa__c,Medio__r.name,
             RequerimientosEspeciales__c,Total__c
             from LineaOrdenDeCompra__c Where OrdenDeCompra__c =:recordId]){
                 Venta v = new Venta();
                 v.id =  LOC.Id;
                 v.ordenCompraId = LOC.OrdenDeCompra__c;
                 v.cadena = LOC.Cadena__r.Name;
                 v.formato = LOC.Formato__r.Name;
                 //v.productoId = LOC.Producto__c;
                 //v.sitioId = LOC.Sitio__c;
                 v.medida = LOC.Medida__r.Name;
                 v.arteId = LOC.Arte__c;
                 v.arte = LOC.Arte__r.Name;
                 v.cantidad = LOC.Cantidad__c;
                 v.tarifa = LOC.Tarifa__c;
                 v.medioId = LOC.Medio__c;
                 v.requerimientosEspeciales = LOC.RequerimientosEspeciales__c;
                 v.total = LOC.Total__c;
                 result.listVentasAgregadas.add(v);
        }
        result.OCAgregradas = result.listVentasAgregadas.size() > 0;
        
        for(Venta__c item: 
            [Select Id, Name,Cadena__c,Cadena__r.Name,MedioPublicitario__r.Sitio__r.Name ,
             Formato__c, Formato__r.Name, ProductoEtapa1__r.Name,Medida__r.Name, Tarifa__c, 
             ProductoEtapa1__c,Medida__c,MedioPublicitario__r.Sitio__c,MedioPublicitario__c,
             MedioPublicitario__r.Sitio__r.Canton__c
             from Venta__c Where Campana__c =:OC.CampanaPublicitaria__c]){
                 Venta v = new Venta();
                 listIdV.add(item.Id);
                 v.id = item.Id;
                 v.ordenCompraId = recordId;
                 v.cadena = item.Cadena__r.Name;
                 v.cadenaId = item.Cadena__c;
                 v.formato = item.Formato__r.Name;
                 v.formatoId = item.Formato__c;
                 v.producto = item.ProductoEtapa1__r.Name;
                 v.productoId = item.ProductoEtapa1__c;
                 v.medida = item.Medida__r.Name;
                 v.medidaId = item.Medida__c;
                 v.sitio = item.MedioPublicitario__r.Sitio__r.Name;
                 v.cantonId = item.MedioPublicitario__r.Sitio__r.Canton__c;
                 v.sitioId = item.MedioPublicitario__r.Sitio__c;
                 v.medioId = item.MedioPublicitario__c;
                 v.tarifa = 0.0;
                 v.tarifaOrg = 0.0;
                 v.total = 0.0;
                 v.listArtes = new List<PicklistOption>();
                 mapVentas.put(item.Id, v);
                 result.listVentas.add(v);
                 if(v.medioId != null){
                     listMedios.add(v.medioId);
                 }
                 if(v.productoId != null){
                     listProductos.add(v.productoId);
                 }
                 
             }
        for(PrecioDeCompra__c  item: [Select Precio__c, Producto__c, Medio__c from PrecioDeCompra__c  where Producto__c in :listProductos OR Medio__c in :listMedios]){
            /*if(item.Medio__c != null){
                mapPrecios.put(item.Medio__c, item.Precio__c);
            }*/
            if(item.Producto__c != null){
                mapPrecios.put(item.Producto__c, item.Precio__c);
            }
        }
        for(MedioDeArte__c item: [Select Arte__r.Name, Arte__c,Venta__c from MedioDeArte__c where Venta__c in :listIdV ]){
            for(Integer i=0; i<result.listVentas.size(); i++){
                /*if(result.listVentas[i].medioId != null){
                    result.listVentas[i].tarifa = mapPrecios.get(result.listVentas[i].medioId);
                }else*/ if(result.listVentas[i].productoId != null && mapPrecios.containsKey(result.listVentas[i].productoId)){
                    result.listVentas[i].tarifa = mapPrecios.get(result.listVentas[i].productoId);
                    result.listVentas[i].tarifaOrg = mapPrecios.get(result.listVentas[i].productoId);
                }
                if(item.Venta__c == result.listVentas[i].id){
                    result.listVentas[i].listArtes.add(new PicklistOption(item.Arte__r.Name, item.Arte__c));
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
        if(esDetallada){
            OrdenCompraDetallada(listVentas);
        }
        User usuario = [Select Name, ManagerId,Manager.Email from User where Id=:UserInfo.getUserId()];
        Integer i = 0;
        for(Venta item: listVentas){
            LineaOrdenDeCompra__c LOC = new LineaOrdenDeCompra__c();
            Notificacion notif = new Notificacion();
            LOC.OrdenDeCompra__c = item.ordenCompraId;
            LOC.Cadena__c = item.cadenaId;
            LOC.Formato__c = item.formatoId;
            //LOC.Producto__c = item.productoId;
            //LOC.Sitio__c = item.sitioId;
            LOC.Medida__c = item.medidaId;
            LOC.Arte__c = item.arteId;
            LOC.Cantidad__c = item.cantidad;
            LOC.Tarifa__c = item.tarifa;
            LOC.Medio__c = item.medioId;
            LOC.RequerimientosEspeciales__c = item.requerimientosEspeciales;
            listLineasOC.add(LOC);
            if(item.enviarNotificacion && usuario.ManagerId !=null){
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
         for(Venta item: listVentas){
             if(item.cantonId != null){
                 listCanton.add(item.cantonId);
                 listSitio.add(item.sitioId);
             }
         }
        for(Sitio__c item :[Select Id, Canton__C,Cadena__c,Formato__c from Sitio__c where Id in:listSitio and Canton__C != null]){
            mapSitio.put(item.Id, item);
        }
        for(CargoExtraDeInstalacion__c item: [Select Id, Canton__C,Canton__r.Name,Monto__c from CargoExtraDeInstalacion__c where Canton__C in:listCanton ]){
            mapCanton.put(item.Canton__c, item);
        }
        for(LineaOrdenDeCompra__c item: [Select RequerimientosEspeciales__c from LineaOrdenDeCompra__c where OrdenDeCompra__c = :listVentas[0].ordenCompraId]){
            listLineasOCAgreg.add(item.RequerimientosEspeciales__c);
        }
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
                 //LOC.Producto__c = item.productoId;
                 //LOC.Sitio__c = item.sitioId;
                 //LOC.Medida__c = item.medidaId;
                 //LOC.Arte__c = item.arteId;
                 LOC.Medio__c = item.medioId;
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
    }
    public class Venta{
        @AuraEnabled public String id{get;set;}
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
        @AuraEnabled public List<PicklistOption> listArtes{get;set;}
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