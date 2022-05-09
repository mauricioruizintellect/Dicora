public class PublicityCampaignService {

    public static Boolean runOnce = true;
    
    public static void processMaterialProducts(List<Campana__c> campList,Map<id, Campana__c> oldCampanaMap){
        set<Id> idCampaings = new set<Id>();
        for(Campana__c record :campList){
            if(oldCampanaMap.get(record.id).EstadoDeCampana__c != '03 En Proceso de Artes' && record.EstadoDeCampana__c == '03 En Proceso de Artes'){
                idCampaings.add(record.Id);
            }
        }
        List<Venta__c> listVentas = [Select Id,Medio__c,Medio__r.Producto__c,ProductoEtapa1__c,
                                     Campana__c,Campana__r.NombreCampana__c,Campana__r.Name,Cantidad__c 
                                     From Venta__c 
                                     where Campana__c IN : idCampaings];
        map<String,Venta__c> mapCampaigProduct = new map<String,Venta__c>();
        for(Venta__c record:listVentas){
            if(record.Medio__c == null && record.ProductoEtapa1__c != null){
                mapCampaigProduct.put(record.ProductoEtapa1__c,record);
            }
            if(record.Medio__c != null && record.ProductoEtapa1__c == null){
                mapCampaigProduct.put(record.Medio__r.Producto__c,record);
            }
            if(record.Medio__c != null && record.ProductoEtapa1__c != null){
                mapCampaigProduct.put(record.Medio__r.Producto__c,record);
            }
        }
        List<MaterialDeProducto__c> listMaterialProduct = [select Id,Cantidad__c,Material__c,Material__r.Name,Material__r.CantidadAMano__c,Producto__c,Producto__r.Name From MaterialDeProducto__c 
                                                           Where Producto__c IN: mapCampaigProduct.keySet() and
                                                           Producto__r.ElaboradoConMaterialPropio__c = true];
        list<Campana__c> campToUpdate = new list<Campana__c>();
        Boolean sendEmailNot = false;
        String htmlBody = '';
        String message = '';
        htmlBody = '<table border="2" style="border-collapse: collapse"><tr><th>Producto</th><th>Material</th><th>Cantidad</th></tr>';
        Set<Id> idCamps = new set<Id>();
        for(MaterialDeProducto__c record:listMaterialProduct){
            Decimal quantitySales = mapCampaigProduct.get(record.Producto__c).Cantidad__c;
            Decimal quantityFinal = record.Cantidad__c * quantitySales;
            if(quantityFinal < record.Material__r.CantidadAMano__c){
                message = 'Estimado Usuario, Se le informa que para el contrato '+mapCampaigProduct.get(record.Producto__c).Campana__r.NombreCampana__c+' - '+mapCampaigProduct.get(record.Producto__c).Campana__r.Name+' que está en proceso de artes hay material faltante para los siguientes productos: <br/ >';
                sendEmailNot = true;
                Decimal quantityDifference = record.Material__r.CantidadAMano__c - quantityFinal;
                htmlBody += '<tr><td>' + record.Producto__r.Name +' x '+ quantitySales + '</td><td>' + record.Material__r.Name + '</td><td>' + quantityDifference +'</td></tr>';
                Campana__c campaingUpdate = new Campana__c();
                campaingUpdate.Id = mapCampaigProduct.get(record.Producto__c).Campana__c;
                if(!idCamps.contains(mapCampaigProduct.get(record.Producto__c).Campana__c)){
                    campaingUpdate.MaterialFaltante__c = true;
                    campToUpdate.add(campaingUpdate);
                    idCamps.add(mapCampaigProduct.get(record.Producto__c).Campana__c);
                }                     
            }
        }
        htmlBody += '</table>';
        if(sendEmailNot){
            update campToUpdate;
            sendEmail(message+htmlBody);
        }
    }
    @future
    private static void sendEmail(String body){
        String lstEmails = System.Label.ListEmailSupProduction;
        List<String> sendTo = new List<String>();
        sendTo = lstEmails.split(',');
        for(User u:[Select Email From User where UserRole.DeveloperName = 'SupervisorProduccion']){
            sendTo.add(u.Email);
        }
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(sendTo);
        mail.setSenderDisplayName('Notificaciones CRM');
        mail.setSubject('Materiales faltantes');
        mail.setHtmlBody(body);
        mails.add(mail);
        Messaging.sendEmail(mails);    
    }

}