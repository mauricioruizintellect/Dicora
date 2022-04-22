public class OrderSendPdfControllerExtension {
    private transient OdenDeCompra__c ordenDeCompra;
    private transient final String TR_INSTALACION = 'Instalacion';
    private transient final String TR_MANTENIMIENTOS_ESTRUCTURAS = 'MantenimientoEstructuras';
    private transient final String TR_PRODUCCION = 'Produccion';
    private transient final String TR_MATERIALES = 'Materiales';
    private transient final String TR_PRODUCCION_INSTALACION = 'ProduccionInstalacion';
    private transient final String TR_REPOSICION_VARIOS = 'ReposicionVarios';
    private transient Campana__c relatedCampana;
    private transient String logoCadenaId;
    public OrderSendPdfControllerExtension(ApexPages.StandardController stdController){
        System.debug('record:'+stdController.getRecord());
        load((OdenDeCompra__c)stdController.getRecord());
    }
    public void load(OdenDeCompra__c ordenDeCompra){
        this.ordenDeCompra = ordenDeCompra;
        if(ordenDeCompra.CampanaPublicitaria__c != null)
	        relatedCampana = ordenDeCompra.CampanaPublicitaria__r;
    }
    public String recordTypeName{
        get{
            return ordenDeCompra.RecordType.DeveloperName;
        }
    }
    public Boolean getHayMasDeUnaCadena(){
        Boolean toReturn = false;
        String last;
        for(LineaOrdenDeCompra__c loc : ordenDeCompra.Lineas_Ordenes_de_Compra__r){
            if(String.isBlank(last)){
                last = loc.Cadena__c;
                continue;
            }
            if(String.isNotBlank(loc.Cadena__c) && last != loc.Cadena__c)
                return true;
        }
        return toReturn;
    }
    public Boolean getHayMasDeUnContrato(){
        Boolean toReturn = false;
        String last;
        for(LineaOrdenDeCompra__c loc : ordenDeCompra.Lineas_Ordenes_de_Compra__r){
            if(String.isBlank(last)){
                last = loc.Contrato__c;
                continue;
            }
            if(String.isNotBlank(loc.Contrato__c) && last != loc.Contrato__c)
                return true;
        }
        return toReturn;
    }
    public Boolean getMostrarColCadena(){
        if(!getHaymasDeUnaCadena())
            return false;
        return
            recordTypeName == TR_PRODUCCION ||
            recordTypeName == TR_PRODUCCION_INSTALACION ||
            recordTypeName == TR_REPOSICION_VARIOS;
    }
    public Boolean getMostrarColContrato(){
        if(!getHayMasDeUnContrato())
            return false;
        return recordTypeName == TR_REPOSICION_VARIOS;
    }
    public Boolean getMostrarColFormato(){
        return
            recordTypeName == TR_PRODUCCION ||
            recordTypeName == TR_PRODUCCION_INSTALACION ||
            recordTypeName == TR_REPOSICION_VARIOS;
    }
    public Boolean getMostrarColProducto(){
        return
            recordTypeName == TR_PRODUCCION ||
            recordTypeName == TR_PRODUCCION_INSTALACION ||
            recordTypeName == TR_REPOSICION_VARIOS;
    }
    public Boolean getMostrarColSitio(){
        Boolean haySitio = false;
        for(LineaOrdenDeCompra__c loc : ordenDeCompra.Lineas_Ordenes_de_Compra__r){
            if(loc.Medio__r.Sitio__r.Name != null){
                haySitio = true;
                break;
            }
        }
        if(!haySitio)
            return false;
        return
            recordTypeName == TR_PRODUCCION_INSTALACION ||
            recordTypeName == TR_REPOSICION_VARIOS;
    }
    public Boolean getMostrarColMedida(){
        return
            recordTypeName == TR_PRODUCCION ||
            recordTypeName == TR_PRODUCCION_INSTALACION ||
            recordTypeName == TR_REPOSICION_VARIOS;
    }
    public Boolean getMostrarColArte(){
        return
            recordTypeName == TR_PRODUCCION ||
            recordTypeName == TR_PRODUCCION_INSTALACION ||
            recordTypeName == TR_REPOSICION_VARIOS;
    }
    public Boolean getMostrarColCantidad(){
        return true;
    }
    public Boolean getMostrarColTarifa(){
        return true;
    }
    public Boolean getMostrarColTotal(){
        return true;
    }
    public Boolean getMostrarColReqEspeciales(){
        for(LineaOrdenDeCompra__c loc : ordenDeCompra.Lineas_Ordenes_de_Compra__r){
            if(String.isNotBlank(loc.RequerimientosEspeciales__c))
                return true;
        }
        return false;
    }
    public Boolean getMostrarColDetalle(){
        return true;
    }
    public Boolean getMostrarColMaterial(){
        return recordTypeName == TR_MATERIALES;
    }
    public Account getPrincipal(){
        if(relatedCampana == null)
            return null;
        return relatedCampana.Principal__c == 'Agencia' ? relatedCampana.Agencia__r : relatedCampana.Cliente__r;
    }
    public String getFechaDeCreacion(){
        System.debug('ordenDeCompra:'+ordenDeCompra);
        return DateHelpers.getDateAsddMMyyyy(ordenDeCompra.CreatedDate.Date(),'/');
    }
    public String getFechaDeEntrega(){
        return DateHelpers.getDateAsddMMyyyy(ordenDeCompra.RequeridoParafecha__c,'/');
    }
    public Boolean getMostrarCliente(){
        return String.isNotBlank(ordenDeCompra.CampanaPublicitaria__c);
    }
    public Boolean getMostrarMarca(){
        return String.isNotBlank(ordenDeCompra.CampanaPublicitaria__c);
    }
    public Boolean getMostrarContrato(){
        return String.isNotBlank(ordenDeCompra.CampanaPublicitaria__c);
    }
    public String getLogoFileId(){
        if(logoCadenaId != null)
            return logoCadenaId;
        if(String.isBlank(ordenDeCompra.Cadena__c)){
            logoCadenaId = '';
            return logoCadenaId;
        }
        List<ContentDocumentLink> attachedFiles = [Select ContentDocument.LatestPublishedVersionId
                                                   From ContentDocumentLink Where LinkedEntityId = :ordenDeCompra.Cadena__c
                                                   Limit 1];
        logoCadenaId = attachedFiles.isEmpty() ? null : attachedFiles[0].ContentDocument.LatestPublishedVersionId;
        return logoCadenaId;
    }
    public Boolean getMostrarLogoCadena(){
        return String.isNotBlank(getLogoFileId());
    }
}