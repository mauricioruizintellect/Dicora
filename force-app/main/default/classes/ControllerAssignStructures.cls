public without sharing class ControllerAssignStructures {
    
    @AuraEnabled
    public static ResultWrapper getListOption(String recordId){
        try{
            ResultWrapper result = new ResultWrapper();
            result.listMedios = new List<PicklistOption>();
            result.listSitios = new List<PicklistOption>();
            result.listUsuarios = new List<PicklistOption>();
            result.listProveedores = new List<PicklistOption>();
            result.fecha = System.today();
            Map<String, String> mapSitio = new map<String, string>();
            Estructura__c estructura = [Select Id,Name, Producto__c,Producto__r.Name,CantidadBodega__c from Estructura__c Where Id = :recordId ];
            for(Medio__c item: [Select Id, Name, Sitio__r.Name,Sitio__c, UbicacionEnSitio__c ,Producto__r.Name from Medio__c Where Producto__c =:estructura.Producto__c
                                order by Name, Sitio__r.Name asc ]){
                                    //result.listMedios.add(new PicklistOption(item.Producto__r.Name+' - '+item.UbicacionEnSitio__c, item.Id));
                                    if(!mapSitio.containsKey(item.Sitio__c)){
                                        mapSitio.put(item.Sitio__c, item.Sitio__r.Name);
                                        result.listSitios.add(new PicklistOption(item.Sitio__r.Name, item.Sitio__c));
                                    }
                                }
            for(User item: [Select Id, Name from User Where Profile.Name = 'Administrador del sistema']){
                result.listUsuarios.add(new PicklistOption(item.Name, item.Id));
            }
            for(Account item: [Select Id, Name from Account Where RecordType.Name = 'Proveedor']){
                result.listProveedores.add(new PicklistOption(item.Name, item.Id));
            }
            result.id = estructura.Id;
            result.nombreEstructura = estructura.Name;
            result.nombreProducto = estructura.Producto__r.Name;
            result.asignacionesDisponibles = estructura.CantidadBodega__c;
            result.disabledBoton = estructura.CantidadBodega__c > 0 ? false : true;
            system.debug(result.listMedios.size() +' - '+result.listSitios.size() +' - '+result.listUsuarios.size() +' - '+result.listProveedores.size());
            return result;
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<PicklistOption> getMedium(String sitioId){
        List<PicklistOption> listMedios = new List<PicklistOption>();
        for(Medio__c item: 
            [Select Id, Name, Sitio__r.Name,Sitio__c, UbicacionEnSitio__c ,Producto__r.Name from Medio__c Where Sitio__c =: sitioId
             order by Name, Sitio__r.Name asc ]){
                 listMedios.add(new PicklistOption(item.Producto__r.Name+' - '+item.UbicacionEnSitio__c, item.Id));
             }
        return listMedios;
    }
    
    @AuraEnabled
    public static List<PicklistOption> getInstalador(String sitioId){
        List<PicklistOption> listInstalador = new List<PicklistOption>();
        for(Sitio__c item: 
            [Select Id, Ruta__r.Usuario__c, Ruta__r.Usuario__r.Name from Sitio__c Where Id =: sitioId ]){
                 listInstalador.add(new PicklistOption(item.Ruta__r.Usuario__r.Name, item.Ruta__r.Usuario__c));
             }
        return listInstalador;
    }
    
    @AuraEnabled
    public static void insertRecord(String data){
        try{
            ResultWrapper dataObj = (ResultWrapper)System.JSON.deserialize(data, ResultWrapper.class);
            EstructuraEnSItio__c EES = new EstructuraEnSItio__c();
            EES.Estado__c = 'En Progreso';
            EES.Name = dataObj.nombreEstructura + ' - '+dataObj.nombreProducto;
            EES.Estructura__c = dataObj.id;
            EES.Medio__c = dataObj.medioSelecionado;
            for(PicklistOption item : dataObj.listSitios){
                if(item.value == dataObj.sitioSelecionado){
                    EES.Name +=' - '+item.label;
                    break;
                }
            }
            for(Medio__c item:
                [Select UbicacionEnSitio__c from Medio__c Where Sitio__c =: dataObj.sitioSelecionado And
                 Id=: dataObj.medioSelecionado order by Name, Sitio__r.Name asc ]){
                     EES.Name += ' - '+item.UbicacionEnSitio__c;
                 }
            insert EES;
            OrdenTrabajoDeEstructura__c ODE = new OrdenTrabajoDeEstructura__c();
            ODE.Tipo__c = 'Instalación';
            ODE.Instalador__c = dataObj.usuarioSelecionado;
            ODE.FechaPrevista__c = dataObj.fecha;
            ODE.Costo__c = dataObj.costo;
            ODE.Estado__c = 'Pendiente';
            ODE.EstructuraEnSitio__c = EES.Id;
            ODE.Proveedor__c = dataObj.proveedorSelecionado;
            insert ODE;
            if(String.isNotBlank(ODE.Proveedor__c)){
                String recordTypeOC = Schema.SObjectType.OdenDeCompra__c.getRecordTypeInfosByDeveloperName().get('MantenimientoEstructuras').getRecordTypeId();
                OdenDeCompra__c orden = new OdenDeCompra__c(RecordTypeId = recordTypeOC, Estado__c = 'Borrador');
                insert orden;
            }
        }catch (Exception e) {
            system.debug(e.getMessage()+' --- '+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    
    public class ResultWrapper {
        @AuraEnabled public String id{get;set;}
        @AuraEnabled public String nombreEstructura{get;set;}
        @AuraEnabled public String nombreProducto{get;set;}
        @AuraEnabled public String medioSelecionado{get;set;}
        @AuraEnabled public String sitioSelecionado{get;set;}
        @AuraEnabled public String usuarioSelecionado{get;set;}
        @AuraEnabled public String proveedorSelecionado{get;set;}
        @AuraEnabled public Boolean disabledBoton{get;set;}
        @AuraEnabled public Decimal asignacionesDisponibles{get;set;}
        @AuraEnabled public Date fecha{get;set;}
        @AuraEnabled public Decimal costo{get;set;}
        @AuraEnabled public List<PicklistOption> listMedios{get;set;}
        @AuraEnabled public List<PicklistOption> listSitios{get;set;}
        @AuraEnabled public List<PicklistOption> listUsuarios{get;set;}
        @AuraEnabled public List<PicklistOption> listProveedores{get;set;}
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