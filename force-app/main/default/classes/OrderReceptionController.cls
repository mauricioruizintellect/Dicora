public with sharing class OrderReceptionController {
    @AuraEnabled(cacheable=true)
    public static List<LineaOrdenDeCompra__c> getOrderLineDetail(String recordId) {
        return [
            SELECT Id,Arte__r.Name, Cadena__r.Name, Cantidad__c, DimensionesDeProducto__c, Formato__r.Name, Material__c,Material__r.Name,
            Medida__r.Name,Medio__r.Producto__r.Name,Medio__c,Medio__r.Sitio__r.Name,OrdenDeCompra__c,PrecioAlterado__c,
            PrecioDeCompra__c,RequerimientosEspeciales__c,Tarifa__c,Total__c,CantidadRecibida__c,PendienteRecibir__c,
            Medida__r.Producto__c,Medida__r.Producto__r.ElaboradoConMaterialPropio__c,OrdenDeCompra__r.Proveedor__c,
            OrdenDeCompra__r.recordType.developerName,Contrato__r.Name,Product__c,Product__r.Name,Product__r.ElaboradoConMaterialPropio__c
            FROM LineaOrdenDeCompra__c
            WHERE OrdenDeCompra__c =: recordId
        ];
    }

    @AuraEnabled
    public static List<EntregaDeProduccion__c> receptionItems(List<LineaOrdenDeCompra__c> items, string orderId, string recibidoPor){
        List<EntregaDeProduccion__c> deliveryProductionList = new list<EntregaDeProduccion__c>();
        for(LineaOrdenDeCompra__c item:items){
            EntregaDeProduccion__c deliveryProduction = new EntregaDeProduccion__c();
            deliveryProduction.Cantidad__c = item.UltimaCantidadRecibida__c;
            deliveryProduction.Fecha__c = System.today();
            deliveryProduction.LineaOrdenDeCompra__c = item.Id;
            deliveryProduction.OrdenDeCompra__c = orderId;
            deliveryProduction.RecibidoPorLista__c = recibidoPor;
            deliveryProductionList.add(deliveryProduction);
        }
        insert deliveryProductionList;
        update items;
        setProductCampaign(orderId,UserInfo.getUserId());
        return deliveryProductionList;
    }
    @AuraEnabled
    public static string savePdfOrder(string orderId){
        Datetime now = Datetime.now();
        Integer offset = UserInfo.getTimezone().getOffset(now);
        Datetime local = now.addSeconds(offset/1000);
        PageReference PDf =  Page.PrintVoucher;
        PDf.getParameters().put('id',orderId);
        PDf.setRedirect(false);
        Blob b = !Test.isRunningTest() ? PDf.getContent() : Blob.valueOf('Fake content');
        ContentVersion cVersion = new ContentVersion();
        cVersion.ContentLocation = 'S';
        cVersion.PathOnClient = 'Orden -'+local +'.pdf';
        cVersion.Origin = 'H';
        cVersion.Title = 'recepción de orden '+local+'.pdf';
        cVersion.VersionData = b;
        Insert cVersion;

         Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
        
         ContentDocumentLink cDocLink = new ContentDocumentLink();
         cDocLink.ContentDocumentId = conDocument;
         cDocLink.LinkedEntityId = orderId;
         cDocLink.ShareType = 'I';
         cDocLink.Visibility = 'AllUsers';
         insert cDocLink;
         return 'success';
    }

    @AuraEnabled
    public static List<MaterialDeProducto__c> getMaterialProd(String recordId) {
        return [
            SELECT Id,Cantidad__c,Material__c,Material__r.Name,Producto__r.Name
            FROM MaterialDeProducto__c
            WHERE Producto__c =: recordId
        ];
    }

    @AuraEnabled
    public static string getNameOfMaterial(string materialId){
        return [Select Name From Material__c where Id =: materialId].Name;
    }

    @AuraEnabled
    public static void reduceMaterial(List<Material__c> lstMat){
        Map<Id, Material__c> mapMatReduce = new Map<Id, Material__c>(lstMat);
        List<Material__c> matToUpdate = new list<Material__c>();
        for(Material__c mat: [Select Id,CantidadAMano__c,ActivarNotificacion__c From Material__c Where Id IN:lstMat]){
            Decimal reduceValue = mapMatReduce.get(mat.Id).CantidadAMano__c;
            mat.CantidadAMano__c = mat.CantidadAMano__c == null ? 0: mat.CantidadAMano__c - reduceValue;
            mat.ActivarNotificacion__c = false;
            matToUpdate.add(mat);
        }
        update matToUpdate;
    }


    @AuraEnabled
    public static void saveSign(String strSignElement,Id recId,list<String>idsToSave, String fileName){
        // Create Salesforce File
        //Insert ContentVersion

        Datetime now = Datetime.now();
        Integer offset = UserInfo.getTimezone().getOffset(now);
        Datetime local = now.addSeconds(offset/1000);

        ContentVersion cVersion = new ContentVersion();
        cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
        cVersion.PathOnClient = 'Signature-'+System.now() +'.png';//File name with extention
        cVersion.Origin = 'H';//C-Content Origin. H-Chatter Origin.
        //cVersion.OwnerId = attach.OwnerId;//Owner of the file
        cVersion.Title = fileName+' - '+local +'.png';//Name of the file
        cVersion.VersionData = EncodingUtil.base64Decode(strSignElement);//File content
        Insert cVersion;
        
        //After saved the Content Verison, get the ContentDocumentId
        Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
        
        //Insert ContentDocumentLink
        List<ContentDocumentLink> newVinculationSignature = new list<ContentDocumentLink>();
        ContentDocumentLink cDocLink = new ContentDocumentLink();
        cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
        cDocLink.LinkedEntityId = recId;//Add attachment parentId
        cDocLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        cDocLink.Visibility = 'AllUsers';//AllUsers, InternalUsers, SharedUsers
        newVinculationSignature.add(cDocLink);

        for(String Id:idsToSave){
            ContentDocumentLink newVin = new ContentDocumentLink();
            newVin.ContentDocumentId = conDocument;//Add ContentDocumentId
            newVin.LinkedEntityId = Id;//Add attachment parentId
            newVin.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
            newVin.Visibility = 'AllUsers';//AllUsers, InternalUsers, SharedUsers
            newVinculationSignature.add(newVin);
        }
        insert newVinculationSignature;
        String objectAPIName = recId.getSObjectType().getDescribe().getName();

        if(objectAPIName == 'OdenDeCompra__c'){
            OdenDeCompra__c ordCompra = new OdenDeCompra__c(
            Id = recId,
            IDUltimaFirmaRecibido__c = '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId='+cVersion.Id
        );
            update ordCompra;
            //savePdfOrder(recId);
        }  
    }
    

    @Future(callout=true)
    private static void setProductCampaign(String orderId, string currentUserId){
        Id recordTypeId = Schema.SObjectType.ProductoDeCampana__c.getRecordTypeInfosByDeveloperName().get('ProductoTerminado').getRecordTypeId();
        List<EntregaDeProduccion__c> deliveryList = [Select Id,LineaOrdenDeCompra__c,LineaOrdenDeCompra__r.Medio__r.Producto__c,LineaOrdenDeCompra__r.Medio__r.Producto__r.Name,
                                                    Cantidad__c,OrdenDeCompra__c,OrdenDeCompra__r.CampanaPublicitaria__c,LineaOrdenDeCompra__r.Medida__c,LineaOrdenDeCompra__r.Medida__r.Name
                                                    From EntregaDeProduccion__c where OrdenDeCompra__c=:orderId];
        List<ProductoDeCampana__c> prodCampaignList = new list<ProductoDeCampana__c>();
        for(EntregaDeProduccion__c item:deliveryList){
            ProductoDeCampana__c prodCamp = new ProductoDeCampana__c();
            prodCamp.Name = item.LineaOrdenDeCompra__r.Medio__r.Producto__r.Name +' - ' +item.LineaOrdenDeCompra__r.Medida__r.Name; 
            prodCamp.EntregaDeProduccion__c = item.Id;
            prodCamp.FechaRecibo__c = System.today();
            prodCamp.CantidadTotal__c = item.Cantidad__c;
            prodCamp.Medida__c = item.LineaOrdenDeCompra__r.Medida__c;
            prodCamp.Producto__c = item.LineaOrdenDeCompra__r.Medio__r.Producto__c;
            prodCamp.RecordTypeId = recordTypeId;
            prodCamp.CampanaPublicitaria__c = item.OrdenDeCompra__r.CampanaPublicitaria__c;
            prodCamp.Estado__c = 'Sin Entregar';
            prodCampaignList.add(prodCamp);
        }
        insert prodCampaignList;
        sendNotIfUserIsNotSupervisor(orderId,currentUserId);
    }

    public static void sendNotIfUserIsNotSupervisor(String orderId, string currentUserId){
        User userInfo = [Select UserRole.DeveloperName from User where Id =: currentUserId];
        if(userInfo.UserRole.DeveloperName != 'SupervisorProduccion'){
        CustomNotificationType notificationType = [SELECT Id, DeveloperName 
                                                   FROM CustomNotificationType 
                                                   WHERE DeveloperName='WebAndMobile'];
        OdenDeCompra__c currentOrder = [Select Id,Name from OdenDeCompra__c where Id =: orderId];

        List<User> userToNotify = [Select Id From User where UserRole.DeveloperName = 'SupervisorProduccion'];
        Set<String> recipientsIds = (new Map<String,User>(userToNotify)).keySet();
        
                                                    
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        // Set the contents for the notification
        notification.setTitle('Recepción de orden de compra');
        notification.setBody('Un usuario con una función diferente a Supervisor de Producción a realizado la recepación de la orden '+currentOrder.Name);

        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(currentOrder.Id);
            // Actually send the notification
            try {
                notification.send(recipientsIds);
            }
            catch (Exception e) {
                System.debug('Problem sending notification: ' + e.getMessage());
            }
        }
    }

    /* Entregas de productos de campaña */
    @AuraEnabled(cacheable=true)
    public static List<ProductoDeCampana__c> getCampaignProducts(String recordId) {
        Id campaignId = [Select CampanaPublicitaria__c from EntregaDeProducto__c where Id =: recordId].CampanaPublicitaria__c;
        return [
            SELECT Id,EntregaDeProduccion__r.Cantidad__c,CantidadTotal__c,CantidadRecibida__c,Producto__c,Producto__r.Name,CantidadPendiente__c
            FROM ProductoDeCampana__c
            WHERE CampanaPublicitaria__c =: campaignId
            and RecordType.DeveloperName = 'ProductoTerminado'
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductoDeEntrega__c> getProductDelivery(String recordId) {
        return [
            SELECT Id,Cantidad__c,Producto__r.Name,EntregaDeProducto__r.Entregado__c
            FROM ProductoDeEntrega__c
            WHERE EntregaDeProducto__c =: recordId
        ];
    }

    @AuraEnabled
    public static void receptionMaterials(List<LineaOrdenDeCompra__c> items, string orderId, string receivedBy,string provider){
        List<EntregaDeMaterial__c> deliveryMatList = new list<EntregaDeMaterial__c>();
        map<String,Decimal> mapMaterialMano = new map<String,Decimal>();
        for(LineaOrdenDeCompra__c item:items){
            EntregaDeMaterial__c newDeliveryMat = new EntregaDeMaterial__c();
            newDeliveryMat.Cantidad__c = item.UltimaCantidadRecibida__c;
            newDeliveryMat.Fecha__c = System.today();
            newDeliveryMat.LineaOrdenDeCompra__c = item.Id;
            newDeliveryMat.Material__c = item.Material__c;
            newDeliveryMat.OrdenDeCompra__c = orderId;
            newDeliveryMat.Proveedor__c = provider;
            newDeliveryMat.RazonDeDiferencia__c = item.RazonDiferencia__c;
            newDeliveryMat.RecibidoPor__c = receivedBy;
            deliveryMatList.add(newDeliveryMat);
            mapMaterialMano.put(item.Material__c,item.UltimaCantidadRecibida__c);
        }
        update items;
        insert deliveryMatList;
        List<Material__c> lstMaterial = [Select Id,CantidadAMano__c,ActivarNotificacion__c From Material__c where Id IN: mapMaterialMano.keySet()];
        for(Material__c mat:lstMaterial){
            mat.ActivarNotificacion__c = false;
            if(mat.CantidadAMano__c == null){
                mat.CantidadAMano__c = mapMaterialMano.get(mat.Id);
            }else{
                mat.CantidadAMano__c = mapMaterialMano.get(mat.Id) + mat.CantidadAMano__c;
            }  
        }
        update lstMaterial;
    }

    //envio correo ordenes de campaña
    @SuppressWarnings('PMD.ExcessiveParameterList')
    @AuraEnabled
    public static void sendEmail(String email,String recordId,String emailCC,String body) {	
			PageReference pdf = Page.OrderSendPdf; 
            pdf.setRedirect(False);
            pdf.getParameters().put('id',recordId);
            List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new string[] {email});
            String[] ccAddresses = new String[] {};
            String[] bccAddresses = new String[]{};
            for(User u:[Select Email From User where UserRole.DeveloperName = 'SupervisorProduccion']){
                bccAddresses.add(u.Email);
            }   
            if(emailCC != ''){
                ccAddresses.add(emailCC);
            }
            if(ccAddresses.size() > 0){
                mail.setCcAddresses(ccAddresses);
            }
            if(bccAddresses.size() > 0){
                mail.setBccAddresses(bccAddresses);
            }     
            mail.setBccSender(true);
            mail.setSubject('Orden de compra');
            mail.setHtmlBody(body.replaceAll('<p><br></p>',''));
            Blob b; 
            if(!test.isRunningTest()){
                b = pdf.getContent();
            }
            else{
                b = blob.valueOF('Test');	
            }
            OdenDeCompra__c currentOrder = [Select Id,Name,Estado__c,CampanaPublicitaria__c,CampanaPublicitaria__r.Name,
                                            CampanaPublicitaria__r.Marca__r.Name
                                            from OdenDeCompra__c where Id=:recordId];
            currentOrder.Estado__c = 'Emitida';
            string fileNameAtt;
            if(currentOrder.CampanaPublicitaria__c != null){
                fileNameAtt = 'DICORA-'+currentOrder.Name+' '+currentOrder.CampanaPublicitaria__r.Name+' '+currentOrder.CampanaPublicitaria__r?.Marca__r.Name;
            }else{
                fileNameAtt = 'DICORA-'+currentOrder.Name; 
            }
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setContentType('application/pdf');
            efa.setInline(False);
            efa.setFileName(fileNameAtt+'.pdf');
            efa.setBody(b);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
            messageList.add(mail);    	    
            Messaging.sendEmail(messageList);
            update currentOrder;
    }
}
