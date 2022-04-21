public class ControllerRepairAndUninstall {
    
    @AuraEnabled
    public static ResultWrapper getListOption(String recordId, String medio, String sitio){
        ResultWrapper result = new ResultWrapper();
        
        result.listSitios = new List<PicklistOption>();
        result.listMedios = new List<PicklistOption>();
        
        result.listSitios.add(new PicklistOption('--Ninguno--', ''));
        result.listMedios.add(new PicklistOption('--Ninguno--', ''));
        
        result.sitio='';
        result.medio = '';
        result.botonDesabilitado = false;
        List<String> listaControl = new List<String>();
        for(OrdenTrabajoDeEstructura__c item: [Select Tipo__c, Estado__c,Id, Medio__c,EstructuraEnSitio__r.Medio__r.Sitio__c, EstructuraEnSitio__r.Medio__r.Sitio__r.Name from OrdenTrabajoDeEstructura__c where EstructuraEnSitio__r.Estructura__c =: recordId Order  by EstructuraEnSitio__r.Medio__r.Sitio__r.Name asc]){
            if(!listaControl.contains(item.Medio__c)){
                listaControl.add(item.Medio__c);
                result.listMedios.add(new PicklistOption(item.Medio__c, item.Medio__c)); 
            }
            if(!listaControl.contains(item.EstructuraEnSitio__r.Medio__r.Sitio__c)){
                listaControl.add(item.EstructuraEnSitio__r.Medio__r.Sitio__c);
                result.listSitios.add(new PicklistOption(item.EstructuraEnSitio__r.Medio__r.Sitio__r.Name, item.EstructuraEnSitio__r.Medio__r.Sitio__c)); 
            }
            if(item.Estado__c != 'Lista' && (item.Tipo__c == 'Reparación' || item.Tipo__c == 'Desinstalación') ){
                result.botonDesabilitado = true;
            }
        }
        result.listRecord = getRecords(recordId, medio, sitio, result.botonDesabilitado);
        return result;
    }
    
    @AuraEnabled
    public static List<OrdenTrabajoDeEstructura> getRecords(String recordId, String medio, String sitio, Boolean botonDesabilitado){
        try{
            List<String> listEstructuraSitio = new List<String>();
            for(EstructuraEnSItio__c item: [Select Id from EstructuraEnSItio__c  Where Estructura__c =:recordId and Estado__c = 'Activa']){
                listEstructuraSitio.add(item.Id);
            }
            system.debug('listEstructuraSitio: '+listEstructuraSitio.size());
            List<OrdenTrabajoDeEstructura> listRecord = new List<OrdenTrabajoDeEstructura>();
            String query = 'Select Medio__c,Name,EstructuraEnSitio__r.Medio__r.Name,Instalador__r.Name,'+
                'Tipo__c, Estado__c,EstructuraEnSitio__r.Estado__c,EstructuraEnSitio__r.Medio__r.Sitio__r.Name,EstructuraEnSitio__c,'+
                'Proveedor__r.Name,FechaPrevista__c, Costo__c from OrdenTrabajoDeEstructura__c Where EstructuraEnSitio__c in :listEstructuraSitio ';
               // '  And EstructuraEnSitio__r.Estado__c = \'Activa\'';
            //And Tipo__c = \'Instalación\'
            if(medio != null && medio != ''){
                query +=' And Medio__c = :medio';
            }
            if(sitio != null && sitio != ''){
                query +=' And EstructuraEnSitio__r.Medio__r.Sitio__c = :sitio';
            }
            query +=' Order by EstructuraEnSitio__r.Medio__r.Sitio__r.Name Asc';
            List<OrdenTrabajoDeEstructura__c> listOrdenTE = Database.query(query);
            List<String> listOrdenTERepa = new List<String>();
            for(OrdenTrabajoDeEstructura__c item: listOrdenTE){
                if(item.Estado__c != 'Lista' && (item.Tipo__c == 'Reparación' || item.Tipo__c == 'Desinstalación')){
                    listOrdenTERepa.add(item.EstructuraEnSitio__c);
                }
            }
            system.debug('Query: '+listOrdenTE.size());
            for(OrdenTrabajoDeEstructura__c item: listOrdenTE){
                system.debug('item: '+item);
                OrdenTrabajoDeEstructura record = new OrdenTrabajoDeEstructura();
                record.sitio = item.EstructuraEnSitio__r.Medio__r.Sitio__r.Name;
                record.medio = item.Medio__c;
                record.usuario = item.Instalador__r.Name;
                record.proveedor = item.Proveedor__r.Name;
                record.fecha = item.FechaPrevista__c != null ? item.FechaPrevista__c.addDays(1) : null ;
                record.costo = item.Costo__c;
                record.id = item.Id;
                record.botonDesabilitado = listOrdenTERepa.contains(item.EstructuraEnSitio__c);
                if(item.Tipo__c == 'Instalación'){
                    listRecord.add(record);
                }                
            }
            return listRecord;
        }catch (Exception e) {
            system.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void insertOrdenTrabajo(String recordId, String accion, Date fecha, Decimal costo, String detalle){
        OrdenTrabajoDeEstructura__c ODE = new OrdenTrabajoDeEstructura__c();
        System.debug('recordId: '+recordId);
        for(OrdenTrabajoDeEstructura__c item: 
            [Select Instalador__c, FechaPrevista__c, Costo__c, 
             EstructuraEnSitio__c,Proveedor__c,Estado__c 
             From OrdenTrabajoDeEstructura__c Where Id = :recordId]){
                 ODE.Tipo__c = accion;
                 ODE.Instalador__c = item.Instalador__c;
                 ODE.FechaPrevista__c = fecha;
                 ODE.Costo__c = costo;
                 ODE.Estado__c = 'Pendiente';
                 ODE.EstructuraEnSitio__c = item.EstructuraEnSitio__c;
                 ODE.Proveedor__c = item.Proveedor__c;
                 ODE.DetalleReparecion__c = detalle;
             }
        system.debug(ODE);
        insert ODE;
    }
    
    
    public class ResultWrapper {
        @AuraEnabled public List<OrdenTrabajoDeEstructura> listRecord;
        @AuraEnabled public List<PicklistOption> listMedios{get;set;}
        @AuraEnabled public List<PicklistOption> listSitios{get;set;}
        @AuraEnabled public String sitio{get;set;}
        @AuraEnabled public String medio{get;set;}
        @AuraEnabled public Boolean botonDesabilitado{get;set;}
    }
    
    public class OrdenTrabajoDeEstructura {
        @AuraEnabled public String id{get;set;}
        @AuraEnabled public String medio{get;set;}
        @AuraEnabled public String sitio{get;set;}
        @AuraEnabled public String usuario{get;set;}
        @AuraEnabled public String proveedor{get;set;}
        @AuraEnabled public Date fecha{get;set;}
        @AuraEnabled public Decimal costo{get;set;}
        @AuraEnabled public Boolean botonDesabilitado{get;set;}
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