public class CampanaTriggerHandler  extends TriggerHandler {
     private Map<id,Campana__c> newCampanaMap; 
     private Map<id, Campana__c> oldCampanaMap; 
     private List <Campana__c> newCampanaList;
     private list <Campana__c> oldCampanaList;
    
	public CampanaTriggerHandler() {
         this.newCampanaMap = (Map<id, Campana__c>) Trigger.newMap;
         this.oldCampanaMap  = (Map<id, Campana__c>) Trigger.oldMap;
         this.newCampanaList = (List <Campana__c>) Trigger.new;
         this.oldCampanaList = (List <Campana__c>) Trigger.old; 
     } 
    
    public override void  afterUpdate (){
        Set<Id> calcularDiferidos = new Set<ID>();
        for(Campana__c c: newCampanaList){
            if( oldCampanaMap.get(c.id).CantidadDeVentas__c != newCampanaMap.get(c.id).CantidadDeVentas__c ){
                calcularDiferidos.add(c.id);
  			}
       	}
        delete [Select id from DiferidoCampana__c where Campana__c in :calcularDiferidos];
        calcularDiferidos([Select FechaFirma__c, MonedaLocal__c, FechaDeInicio__c, (Select TipoDeVenta__c, DiasDeVenta__c, PrecioTotalMonedaLocal__c, FechaDeInicio__c, FechaFin__c from 
                                                                 Ventas__r) from Campana__c where id in :calcularDiferidos]);
        
        
        if(PublicityCampaignService.runOnce){
            PublicityCampaignService.processMaterialProducts(this.newCampanaList,oldCampanaMap);
        }
        
    }
    
    public void calcularDiferidos(List<Campana__c> campanas){
        List<DiferidoCampana__c> diferidos = new List<DiferidoCampana__c>();
        For (Campana__c cam : campanas){
            For(Venta__c v: cam.ventas__R){
                    if (label.Tipo_Ventas_diferidas_en_mismo_mes.split(';').contains(v.TipoDeVenta__c)){
                        Integer numberOfDays = Date.daysInMonth(v.FechaDeInicio__c.year(), v.FechaDeInicio__c.month());
                        Date ultimaFechaDelMes = Date.newInstance(v.FechaDeInicio__c.year(), v.FechaDeInicio__c.month(), numberOfDays);
                        Date inicioMes = Date.newInstance(v.FechaDeInicio__c.year(), v.FechaDeInicio__c.month(),1);
                        DiferidoCampana__c dif = new DiferidoCampana__c(Venta__c = v.id,CurrencyIsoCode = cam.MonedaLocal__c,Campana__c = cam.id,FechaInicioDiferido__c = inicioMes,FechaFinDiferido__c = ultimaFechaDelMes);                
                        dif.MontoDiferido__c = v.PrecioTotalMonedaLocal__c;
                        diferidos.add(dif);
                    }
                    else{
                        Integer mesesEntreFechas = v.FechaDeInicio__c.monthsBetween(v.FechaFin__c);
                        Date fechaInicio = v.FechaDeInicio__c; 
                        Date fechaFin = v.FechaFin__c;
                    While (fechaInicio <= fechaFin){                    
                             //Se saca la última fecha del mes
                            Integer numberOfDays = Date.daysInMonth(fechaInicio.year(), fechaInicio.month());
                            Date lastDayOfMonth = Date.newInstance(fechaInicio.year(), fechaInicio.month(), numberOfDays);
                            DiferidoCampana__c dif =  new DiferidoCampana__c(Venta__c = v.id,CurrencyISOCode = cam.MonedaLocal__c,	Campana__c = cam.id,FechaInicioDiferido__c = fechaInicio,FechaFinDiferido__c = lastDayOfMonth);
                            if(lastDayOfMonth > fechaFin){ //Si el último día del mes es más grande que la fecha fin, entonces se agarra la fecha fin
                                    lastdayOfMonth = fechaFin;
                                    dif.FechaFinDiferido__c = fechaFin;
                                	////Si la diferencia es mayor a 1, se le suma un dia a la diferencia para tomar en cuenta el primer dia del mes
                                	//Si la diferencia es = 0, se le suma un día para que el calculo no de 0. (esto es en los casos que solo se necesita diferir 1 día de la campaña EJ: un día de sept. 01-09-2021/01-09-2021)
                        			//Igualmente si la fecha de inicio del mes es la misma de la fecha de inicio de la campaña, se excluye del primer if para que ejecute el cálculo solo con daysbetween, lo cual será congruente con el campo "dias de pauta"
                                	If((fechaInicio.daysBetween(lastDayOfMonth)>=1 || fechaInicio.daysBetween(lastDayOfMonth) == 0)  && (cam.fechaDeInicio__c != null && cam.FechaDeInicio__c != fechaInicio))
                                    	dif.MontoDiferido__c = (fechaInicio.daysBetween(lastDayOfMonth)+1) * (v.PrecioTotalMonedaLocal__c / v.DiasDeVenta__c);
                                	else//si la diferencia es = 1, no se suma el día extra
                                        dif.MontoDiferido__c = (fechaInicio.daysBetween(lastDayOfMonth)) * (v.PrecioTotalMonedaLocal__c / v.DiasDeVenta__c);
                                    dif.diasDiferidos__c = fechaInicio.daysBetween(lastDayOfMonth+1);
                            }
                            else If( fechaInicio == v.FechaDeInicio__c){ //Si es la primera resta del calculo
                                    dif.MontoDiferido__c = (fechaInicio.daysBetween(lastDayOfMonth)) * (v.PrecioTotalMonedaLocal__c / v.DiasDeVenta__c);
                                    dif.diasDiferidos__c = fechaInicio.daysBetween(lastDayOfMonth);
                            }
                            else{ //Si es todo el mes, se utilizan los dias del mes para crear el monto diferido
                                    dif.MontoDiferido__c = (Date.daysInMonth(fechaInicio.year(), fechaInicio.month())) * (v.PrecioTotalMonedaLocal__c / v.DiasDeVenta__c);
                                    dif.diasDiferidos__c = Date.daysInMonth(fechaInicio.year(), fechaInicio.month());
                            }
                            fechaInicio = lastDayOfMonth + 1;
                            diferidos.add(dif);
                        }
                    }
            }//For(Venta__c v: cam.ventas__R){
        }//For (Campana__c cam : campanas)
        insert diferidos;

    }
    
}