import {LightningElement,api,wire} from 'lwc';
import orderLineItems from '@salesforce/apex/OrderReceptionController.getOrderLineDetail';
import receptionMaterials from '@salesforce/apex/OrderReceptionController.receptionMaterials';
import { refreshApex } from '@salesforce/apex';
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import DELIVERY_MAT_OBJECT from '@salesforce/schema/EntregaDeMaterial__c';
import RECEIVED_BY_FIELD from '@salesforce/schema/EntregaDeMaterial__c.RecibidoPor__c';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class MaterialReception extends LightningElement {
    @api recordId;
    isLoadingSpinner = false;
    wiredOrderLineItems;
    orderLineItems;
    itemsToSave;
    receivedBy;

    @wire(orderLineItems, {
		recordId: '$recordId'
	})
	wiredOrder(value) {
		this.wiredOrderLineItems = value;
		const {data,error} = value;
		if (data) {
            this.orderLineItems = data.map(function (record) {
            	let obj = {};
				obj.Id = record.Id;
                obj.Material = record.Material__r.Name;
                obj.Precio = record.Tarifa__c;
                obj.Cantidad = record.Cantidad__c;
                obj.Total = record.Total__c;
                obj.CantidadPendiente = record.PendienteRecibir__c;
                obj.disabled = record.PendienteRecibir__c == 0 ? true : false;
                obj.CantidadRecibida__c = record.CantidadRecibida__c != null ? record.CantidadRecibida__c + record.PendienteRecibir__c:0;
                obj.Proveedor = record.OrdenDeCompra__r.Proveedor__c;
                obj.recibido = record.CantidadRecibida__c != null ? record.CantidadRecibida__c:0;
                return obj;
			});
            this.itemsToSave = data.map(function (record) {
				let obj = {};
				obj.Id = record.Id;
                obj.RazonDiferencia__c = '';
                obj.UltimaCantidadRecibida__c = record.PendienteRecibir__c;
                obj.Material__c = record.Material__c;
                obj.CantidadRecibida__c = record.CantidadRecibida__c != null ? record.CantidadRecibida__c + record.PendienteRecibir__c:record.PendienteRecibir__c;
				return obj;
			});
		} else if (error) {
			console.log(error);
		}
	}

    @wire(getObjectInfo, { objectApiName: DELIVERY_MAT_OBJECT })
    deliveryMatMetadata;
	@wire(getPicklistValues,
        {
        recordTypeId: '$deliveryMatMetadata.data.defaultRecordTypeId', 
        fieldApiName: RECEIVED_BY_FIELD
        }
    )
    receivedByPicklist;

    changeInputQuantity(event) {
		let currentValue = event.target.value;
		let indexParent = this.itemsToSave.findIndex(field => field.Id === event.target.name);
		const currentRecord = this.orderLineItems.find(element => element.Id === event.target.name);
		if (currentValue <= currentRecord.CantidadPendiente) {
			this.itemsToSave[indexParent].CantidadRecibida__c = parseInt(currentValue) + currentRecord.recibido;
            this.itemsToSave[indexParent].UltimaCantidadRecibida__c = parseInt(currentValue);
		}
	}

    changeReasonDifference(event) {
		let currentValue = event.target.value;
		let indexParent = this.itemsToSave.findIndex(field => field.Id === event.target.name);
		this.itemsToSave[indexParent].RazonDiferencia__c = currentValue;
	}

    handleChangeReceivedBy(event){
        this.receivedBy = event.detail.value;
    }

    @api
	processItems(event) {
        if(this.receivedBy == null){
            this.showToast('Recepción','Debe seleccionar quien recibe la orden','warning');
            return null;
        }
       const containsInvalidQuantity = this.itemsToSave.some(field => isNaN(field.CantidadRecibida__c) || field.CantidadRecibida__c < 1);
       if(containsInvalidQuantity){
           this.showToast('Recepción','Revise las cantidades confirmadas por favor','warning');
       }else{
        const ExistRecordsEnabled = this.orderLineItems.some(field => field.CantidadPendiente > 0);
        if(ExistRecordsEnabled){
            this.isLoadingSpinner = true;
            receptionMaterials({
                items: this.itemsToSave,
                orderId: this.recordId,
                receivedBy: this.receivedBy,
                provider: this.orderLineItems[0].Proveedor
            }).then(result => {
                console.log(result);
                this.isLoadingSpinner = false;
                refreshApex(this.wiredOrderLineItems);
                this.dispatchEvent(new CustomEvent('close'));
            }).catch(error => {
                console.log(error);
                this.isLoadingSpinner = false;
            })
        }else{
            this.showToast('Recepción','No hay registros para procesar','warning');
        }   
       }
    }

    showToast(title,message,variant) {
		const event = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant,
		});
		this.dispatchEvent(event);
	}
}