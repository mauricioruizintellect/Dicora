public with sharing class ValidationMissingMaterials implements Queueable{

    private set<Id> idCampaings;

    public ValidationMissingMaterials(set<Id> idCampaings) {
        this.idCampaings = idCampaings;
    }

    public void execute(QueueableContext context) {
        List<Venta__c> listVentas = [Select Id,MedioPublicitario__c,MedioPublicitario__r.Producto__c,ProductoEtapa1__c,
                                     Campana__c,Campana__r.NombreCampana__c,Cantidad__c 
                                     From Venta__c 
                                     where Campana__c IN : idCampaings];
        map<String,Venta__c> mapCampaigProduct = new map<String,Venta__c>();
        for(Venta__c record:listVentas){
            if(record.MedioPublicitario__c == null && record.ProductoEtapa1__c != null){
                mapCampaigProduct.put(record.ProductoEtapa1__c,record);
            }
            if(record.MedioPublicitario__c != null && record.ProductoEtapa1__c == null){
                mapCampaigProduct.put(record.MedioPublicitario__r.Producto__c,record);
            }
            if(record.MedioPublicitario__c != null && record.ProductoEtapa1__c != null){
                mapCampaigProduct.put(record.MedioPublicitario__r.Producto__c,record);
            }
        }
        List<MaterialDeProducto__c> listMaterialProduct = [select Id,Cantidad__c,Material__c,Material__r.Name,Material__r.CantidadAMano__c,Producto__c,Producto__r.Name From MaterialDeProducto__c 
                                                           Where Producto__c IN: mapCampaigProduct.keySet()];
        list<Campana__c> campToUpdate = new list<Campana__c>();
        String body = null;
        for(MaterialDeProducto__c record:listMaterialProduct){
            Decimal currentQuantity = mapCampaigProduct.get(record.Producto__c).Cantidad__c;
            Decimal quantityFinal = record.Cantidad__c * currentQuantity;
            Campana__c campaingUpdate = new Campana__c();
            if(quantityFinal < record.Material__r.CantidadAMano__c){
                Decimal quantityDifference = record.Material__r.CantidadAMano__c - quantityFinal;
                body = 'Lista de Materiales por productos faltantes: <br/>';
                campaingUpdate.Id = mapCampaigProduct.get(record.Producto__c).Campana__c;
                body += '<b> Campaña: </b> '+ mapCampaigProduct.get(record.Producto__c).Campana__r.NombreCampana__c;
                body += ' <b>Material:</b> '+record.Material__r.Name + ' <b>Producto: </b>'+record.Producto__r.Name + ' <b>Cantidad: </b>'+quantityDifference;
                if(!campToUpdate.contains(campaingUpdate)){
                    campaingUpdate.MaterialFaltante__c = true;
                    campToUpdate.add(campaingUpdate);
                }
            }
        }
        update campToUpdate;
        if(body != null){
            sendEmail(body);
        }
    }

    sendEmail(String body){
        String lstEmails = System.Label.ListEmailSupProduction;
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> sendTo = new List<String>();
        sendTo = lstEmails.split(',');
        mail.setToAddresses(sendTo);
        mail.setSenderDisplayName('Notificaciones CRM');
        mail.setSubject('Materiales faltantes');
        mail.setHtmlBody(body);
        mails.add(mail);
        Messaging.sendEmail(mails);    
    }
}
