import {LightningElement,api,wire} from 'lwc';
import campaignProducts from '@salesforce/apex/OrderReceptionController.getCampaignProducts';
import productDelivery from '@salesforce/apex/OrderReceptionController.getProductDelivery';
import { getRecord,getFieldValue,updateRecord,createRecord,deleteRecord } from 'lightning/uiRecordApi';
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import { refreshApex } from '@salesforce/apex';
import DELIVERY_PRODUCT_OBJECT from '@salesforce/schema/EntregaDeProducto__c';
import PRODUCT_CAMPAIGN_OBJECT from '@salesforce/schema/ProductoDeCampana__c';
import RECEIVED_BY_FIELD from '@salesforce/schema/EntregaDeProducto__c.RecibidoPor__c';
import DELIVERED_BY_FIELD from '@salesforce/schema/EntregaDeProducto__c.Entregado_Por__c';
import REASON_FIELD from '@salesforce/schema/ProductoDeCampana__c.Razon__c';
import {CloseActionScreenEvent} from 'lightning/actions';

const FIELDS = ['EntregaDeProducto__c.Tipo__c','EntregaDeProducto__c.Entregado__c'];

export default class DeliveryCampaignProducts extends LightningElement {
    @api recordId;
    isLoadingSpinner = false;
    wiredProductCampaigns;
    wiredProductDelivery;
    productItems;
    itemsToSave;
    productDeliveryItem;
    showSignature;
    valueSignatureReceived;
    valueSignatureDelivered;
    firstSignature = false;
    secondSignature = false;
    enabledPicklistDelivered = false;
    isDeliveredProd = false;
    selectedRuta;
    fileNameSignature;
    valueReason;
    itemprodCampaignLogProd = [];

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    deliveryObjectRecord;

    get typeProdLog() {
        let value = false;
        if(getFieldValue(this.deliveryObjectRecord.data, 'EntregaDeProducto__c.Tipo__c') == 'Producción a Logística'){
            value = true;
        }
        return value;
    }

    retrievedRecordId = false;

    renderedCallback() {
        if (!this.retrievedRecordId && this.recordId) {
            this.retrievedRecordId = true; // Escape case from recursion
            this.isDeliveredProd = getFieldValue(this.deliveryObjectRecord.data, 'EntregaDeProducto__c.Entregado__c');
        }
    }

    @wire(campaignProducts, {
		recordId: '$recordId'
	})
    wiredProductCampaign(value) {
        this.wiredProductCampaigns = value;
        const { data, error } = value;
        if (data) {
            this.productItems = data.map(function (record) {
                let prd = {};
				prd.Id = record.Id;
                prd.Producto = record.Producto__c != null ? record.Producto__r.Name:'';
                prd.Cantidad = record.CantidadTotal__c;
                prd.CantidadRecibida = record.CantidadRecibida__c == null ? 0:record.CantidadRecibida__c;
                prd.CantidadPendiente = record.CantidadPendiente__c;
                prd.disabled = record.CantidadPendiente__c == 0 ? true : false;
                return prd;
            });
            this.itemsToSave = data.map(function (record) {
				let obj = {};
				obj.Id = record.Id;
                obj.Producto__c = record.Producto__c;
                obj.ProductoName = record.Producto__c != null ? record.Producto__r.Name:'';
				obj.CantidadRecibida__c = record.CantidadRecibida__c == null ? record.CantidadPendiente__c:record.CantidadRecibida__c + record.CantidadPendiente__c;
				return obj;
			});
        }else if (error) {
			console.log(error);
		}
    }

    @wire(productDelivery, {
		recordId: '$recordId'
	})
    wiredProductDelivery(value) {
        this.wiredProductDelivery = value;
        const { data, error } = value;
        if (data) {
            this.productDeliveryItem = data.map(function (record) {
				let obj = {};
                obj.Id = record.Id;
                obj.ProductoName = record.Producto__r.Name;
				obj.Cantidad = record.Cantidad__c; 
                obj.DisabledDelete = record.EntregaDeProducto__r.Entregado__c;
				return obj;
			});
        }else if (error) {
			console.log(error);
		}
    }
    //Obtener picklist recibido por y entregado por
    @wire(getObjectInfo, { objectApiName: DELIVERY_PRODUCT_OBJECT })
    deliveryProdMetadata;
	@wire(getPicklistValues,
        {
        recordTypeId: '$deliveryProdMetadata.data.defaultRecordTypeId', 
        fieldApiName: RECEIVED_BY_FIELD
        }
    )
    receivedByPicklist;
    @wire(getPicklistValues,
        {
        recordTypeId: '$deliveryProdMetadata.data.defaultRecordTypeId', 
        fieldApiName: DELIVERED_BY_FIELD
        }
    )
    deliveredByPicklist;

    //Obtener picklist razon de no entrega
    @wire(getObjectInfo, { objectApiName: PRODUCT_CAMPAIGN_OBJECT })
    prodCampaignMetadata;
    @wire(getPicklistValues,
        {
        recordTypeId: '$prodCampaignMetadata.data.defaultRecordTypeId', 
        fieldApiName: REASON_FIELD
        }
    )
    reasonPicklist;

    changeInputQuantity(event){
        let currentValue = event.target.value;
        let indexParent = this.itemsToSave.findIndex(field => field.Id === event.target.name);
        const currentRecord = this.productItems.find(element => element.Id === event.target.name);
        if (currentValue <= currentRecord.CantidadPendiente) {
            this.itemsToSave[indexParent].CantidadRecibida__c = parseInt(currentValue) + currentRecord.CantidadRecibida;
        }else{
            this.itemsToSave[indexParent].CantidadRecibida__c = 0;
        }
    }

    createProductDelivery(event){
        let id = event.target.name;
        const recordToSave = this.itemsToSave.find(element => element.Id === id);
        if(recordToSave.CantidadRecibida__c > 0){
            this.updateProductCampaign(recordToSave);
            if(!this.isDeliveredProd){
                this.itemprodCampaignLogProd.push(recordToSave);
            }
        }else{
            console.log('Revisar la cantidad');
        }
    }

    updateProductCampaign(prodCampaign){
         this.isLoadingSpinner = true;
          // Create the recordInput object
          const fields = {};
          fields["Id"] = prodCampaign.Id;
          if(this.isDeliveredProd){
            fields["CantidadRecibida__c"] = prodCampaign.CantidadRecibida__c;
          }else{
            fields["Estado__c"] = 'Sin Instalar';
            fields["CantidadDevuelta__c"] = prodCampaign.CantidadRecibida__c;
          }
          const recordInput = { fields };
          updateRecord(recordInput)
            .then(() => {
                this.createProdDelivery(prodCampaign);
            })
            .catch(error => {
                console.log(error);
                this.isLoadingSpinner = false;
            });
    }

    createProdDelivery(prodCampaign){
        // Create the recordInput object
        const apiName = 'ProductoDeEntrega__c';
        const fields = {};
        fields["Cantidad__c"] = prodCampaign.CantidadRecibida__c;
        fields["EntregaDeProducto__c"] = this.recordId;
        fields["Name"] = 'Entrega de producto '+ prodCampaign.ProductoName;
        fields["ProductoDeCampana__c"] = prodCampaign.Id;
        fields["Producto__c"] = prodCampaign.Producto__c;
        const recordInput = { apiName,fields };
        createRecord(recordInput)
            .then(() => {
                this.isLoadingSpinner = false;
                refreshApex(this.wiredProductCampaigns);
                refreshApex(this.wiredProductDelivery);
            })
            .catch(error => {
                console.log(error);
                this.isLoadingSpinner = false;
            });
    }

    deleteProduct(event) {
        let id = event.target.name;
        this.isLoadingSpinner = true;
		deleteRecord(id)
			.then(() => {
                this.isLoadingSpinner = false;
                refreshApex(this.wiredProductDelivery);
			})
			.catch(error => {
                this.isLoadingSpinner = false;
				console.log(error);
			});
	}
    createSignatures(event){
        this.showSignature = true;
    }

    handleSignature(event){
        let nameSignature = event.target.name; 
        let valueSelected = event.detail.value;
        if(nameSignature == 'Recibido'){
            this.valueSignatureReceived = valueSelected;
            this.fileNameSignature = 'Recibido Por '+valueSelected;
            this.firstSignature = true;
            this.secondSignature = false;
            this.enabledPicklistDelivered = false;
        }else if(nameSignature == 'Entregado'){
            this.valueSignatureDelivered = valueSelected;
            this.fileNameSignature = 'Entregado Por '+valueSelected;
            this.firstSignature = false;
            this.secondSignature = true;
            this.enabledPicklistDelivered = true;
        }
    }

    handleSignatureReceived(event){
        this.updateSignatures('RecibidoPor__c',this.valueSignatureReceived);
    }

    handleSignatureDelivered(event){
        this.updateSignatures('Entregado_Por__c',this.valueSignatureDelivered);
    }

    updateSignatures(field,value){
        const fields = {};
        fields["Id"] = this.recordId;
        fields[field] = value;
        if(this.typeProdLog){
            fields["Ruta__c"] = this.selectedRuta;
        }
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                if(field == 'Entregado_Por__c'){
                    this.checkDelivery();
                }else{
                    this.udpateOwnerProductCampaign();
                    this.enabledPicklistDelivered = true;
                    this.firstSignature = false;
                }
            })
            .catch(error => {
                console.log(error);
                this.isLoadingSpinner = false;
            });
    }

    checkDelivery(){
        const fields = {};
        fields["Id"] = this.recordId;
        fields["Entregado__c"] = true;
        fields["Fecha__c"] = new Date().toISOString();
        const recordInput = { fields };
        updateRecord(recordInput) 
        .then(() => {
            if(this.isDeliveredProd){
                this.dispatchEvent(new CloseActionScreenEvent());
            }else{
                this.setReasonProductCampaign();
            }
        })
        .catch(error => {
            console.log(error);
            this.isLoadingSpinner = false;
        });s
    }

    handleRutaSelection(event){
        this.selectedRuta = event.target.value;
    }

    udpateOwnerProductCampaign(){
        const recordInputs =  this.productItems.slice().map(item => {
            const fields = {
                "Id" : item.Id,
                "OwnerId" : this.selectedRuta,
                "Estado__c": "Entregado"
            };
            return { fields };
        });
      const promises = recordInputs.map(recordInput => updateRecord(recordInput));
        Promise.all(promises).then(products => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Productos actualizados',
                    variant: 'success'
                })
            ); 
        }).catch(error => {
            console.log(error);
        });
    }

    handleReason(event){
        this.valueReason = event.detail.value;
    }

    setReasonProductCampaign(){
        const recordInputs =  this.itemprodCampaignLogProd.slice().map(item => {
            const fields = {
                "Id" : item.Id,
                "Razon__c" : this.valueReason
            };
            return { fields };
        });
        const promises = recordInputs.map(recordInput => updateRecord(recordInput));
        Promise.all(promises).then(products => {
            this.dispatchEvent(new CloseActionScreenEvent());
        }).catch(error => {
            console.log(error);
        });
    }

    cancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}