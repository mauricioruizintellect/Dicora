import {LightningElement,api,wire} from 'lwc';
import {CloseActionScreenEvent} from 'lightning/actions';
import orderLineItems from '@salesforce/apex/OrderReceptionController.getOrderLineDetail';
import receptionItems from '@salesforce/apex/OrderReceptionController.receptionItems';
import savePdfOrder from '@salesforce/apex/OrderReceptionController.savePdfOrder';
import getMaterialProd from '@salesforce/apex/OrderReceptionController.getMaterialProd';
import getNameOfMaterial from '@salesforce/apex/OrderReceptionController.getNameOfMaterial';
import reduceMaterial from '@salesforce/apex/OrderReceptionController.reduceMaterial';
import modal from "@salesforce/resourceUrl/custommodalcss";
import {loadStyle} from "lightning/platformResourceLoader";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import ENTREGA_PROD_OBJECT from '@salesforce/schema/EntregaDeProduccion__c';
import RECIBIDO_POR_FIELD from '@salesforce/schema/EntregaDeProduccion__c.RecibidoPorLista__c';

const columnsMaterial = [{
		label: 'Material',
		fieldName: 'material',
		type: 'text'
	},
	{
		label: 'Cantidad',
		fieldName: 'CantidadAMano__c',
		type: 'number',
		editable: true
	},
	{
		type: "button",
		typeAttributes: {
			label: 'Eliminar',
			name: 'Delete',
			title: 'Eliminar',
			disabled: false,
			value: 'Delete',
			iconPosition: 'left'
		}
	}
];
export default class OrderReception extends LightningElement {
	@api recordId;
	orderLineItems;
	itemsToSave;
	isLoadingSpinner = false;
	wiredOrderLineItems;
	isModalOpen;
	columnsMaterial = columnsMaterial;
	materialProducts = [];
	draftValues = [];
	productSelected;
	showSignature;
	idsToSignature;
	recibidoPor;
	selectedMaterial;
	orderLineId;
	disabledReceptionButton = false;
	recordTypeIsRepVarios = false;
	recordTypeIsProduction = false;


	connectedCallback() {
		loadStyle(this, modal);
	}

	@wire(getObjectInfo, { objectApiName: ENTREGA_PROD_OBJECT })
    deliveryProdMetadata;
	@wire(getPicklistValues,
        {
        recordTypeId: '$deliveryProdMetadata.data.defaultRecordTypeId', 
        fieldApiName: RECIBIDO_POR_FIELD
        }
    )
    recibidoPorPicklist;

	@wire(orderLineItems, {
		recordId: '$recordId'
	})
	wiredOrder(value) {
		this.wiredOrderLineItems = value;
		const {
			data,
			error
		} = value;
		if (data) {
			console.log(data);
			this.orderLineItems = data.map(function (record) {
				let obj = {};
				obj.Id = record.Id;
				obj.contrato = record.Contrato__c != null ? record.Contrato__r.Name:'';
				obj.cadena = record.Cadena__c != null ? record.Cadena__r.Name:'';
				obj.formato = record.Formato__c != null ? record.Formato__r.Name:'';
				obj.producto = record.Product__c != null ? record.Product__r.Name:'';
				obj.sitio = record.Medio__c != null ? record.Medio__r.Sitio__r.Name:'';
				obj.medida = record.Medida__c != null ? record.Medida__r.Name: '';
				obj.arte = record.Arte__c != null ? record.Arte__r.Name : '';
				obj.cantidad = record.Cantidad__c;
				obj.tarifa = record.Tarifa__c;
				obj.total = record.Total__c;
				obj.pendienteRecibir = record.PendienteRecibir__c;
				obj.disabled = record.PendienteRecibir__c == 0 ? true : false;
				obj.productId = record.Product__c;
				obj.productMaterialProp = record.Product__c != null ? record.Product__r.ElaboradoConMaterialPropio__c:false;
				obj.cantidadRec = record.CantidadRecibida__c;
				obj.recordTypeDev = record.OrdenDeCompra__r.RecordType.DeveloperName;
				return obj;
			});
			this.itemsToSave = data.map(function (record) {
				let obj = {};
				obj.Id = record.Id;
				obj.pendiente = record.PendienteRecibir__c;
				obj.UltimaCantidadRecibida__c = record.PendienteRecibir__c;
				obj.recibido = record.CantidadRecibida__c != null ? record.CantidadRecibida__c:0;
				obj.CantidadRecibida__c = record.PendienteRecibir__c + obj.recibido;
				return obj;
			});
			console.log(this.itemsToSave);
			this.recordTypeIsRepVarios = this.orderLineItems.some(elem => elem.recordTypeDev == 'ReposicionVarios');
			this.recordTypeIsProduction = this.orderLineItems.some(elem => elem.recordTypeDev == 'Produccion');
		} else if (error) {
			console.log(error);
		}
	}

	handleChangeRecibidoPor(event) {
        this.recibidoPor = event.detail.value;
    }

	changeInputQuantity(event) {
		let currentValue = event.target.value;
		let indexParent = this.itemsToSave.findIndex(field => field.Id === event.target.name);
		const currentRecord = this.itemsToSave.find(element => element.Id === event.target.name);
		if (currentValue <= currentRecord.pendiente) {
			this.itemsToSave[indexParent].CantidadRecibida__c = parseInt(currentValue) + currentRecord.recibido;
			this.itemsToSave[indexParent].UltimaCantidadRecibida__c = parseInt(currentValue);
		}
		console.log(this.itemsToSave);
	}
	closeModal(event) {
		this.dispatchEvent(new CloseActionScreenEvent());
	}

	receptionOrderItems() {
		if(this.recibidoPor != null){
			const notExistRecordsEnabled = this.orderLineItems.some(field => field.pendienteRecibir > 0);
			if(!notExistRecordsEnabled){
				this.showToast('Recepción','Toda la orden de compra fue recibida.','warning');
				return null;
			}
			 const allValid = [
				...this.template.querySelectorAll('.inputQuantity'),
			].reduce((validSoFar, inputCmp) => {
				inputCmp.reportValidity();
				return validSoFar && inputCmp.checkValidity();
			}, true);
			if(!allValid){
				this.showToast('Recepción','Por favor revise los items que esta recibiendo, la cantidad a recibir no puede ser mayor a la cantidad','warning');
				return null;
			}
			 this.isLoadingSpinner = true;
			const resultRebajo = [];
			const contextThis = this;
			console.log(this.itemsToSave);
			this.itemsToSave.forEach(function(item) {
				contextThis.materialProducts.forEach(function(mat) {
					if(item.Id == mat.lineItemId){
						let objRebajo = {};
						objRebajo.Id = mat.Id;
						objRebajo.CantidadAMano__c = item.UltimaCantidadRecibida__c * mat.CantidadAMano__c;
						resultRebajo.push(objRebajo);
					}
				});
			});
			console.log(resultRebajo);
			 receptionItems({
				items: this.itemsToSave,
				orderId: this.recordId,
				recibidoPor: this.recibidoPor
			}).then(result => {
				this.idsToSignature = result.map(function (record) {
					return record.Id;
				});
				if(resultRebajo.length > 0){
					this.doreduceMaterial(resultRebajo);
				}else{
					this.isLoadingSpinner = false;
					this.showSignature = true;
					this.disabledReceptionButton = true;
				}
			}).catch(error => {
				this.showToast('Recepción',error,'error');
				this.isLoadingSpinner = false;
			})  
		}else{
			this.showToast('Recepción','Por favor seleccione quien recibe la orden de compra','warning');
		}
	}

	openModal(event) {
		const rowOrderLine = JSON.stringify(event.target.name);
		const rowOrderLineJson = JSON.parse(rowOrderLine);
		this.productSelected = rowOrderLineJson.productId;
		this.orderLineId = rowOrderLineJson.Id;
		this.getRebajoMaterialInfo(this.productSelected);
		this.isModalOpen = true;
	}

	closeModalMaterial() {
		this.isModalOpen = false;
	}

	getRebajoMaterialInfo(productId) {
		getMaterialProd({
			recordId: productId
		}).then(result => {
			const contextThis = this;
			this.materialProducts = result.map(function (record) {
				let obj = {};
				obj.Id = record.Material__c;
				obj.material = record.Material__r.Name;
				obj.lineItemId = contextThis.orderLineId;
				obj.CantidadAMano__c = record.Cantidad__c;
				return obj;
			});
			console.log(this.materialProducts);
		}).catch(error => {
			console.log(error);
			this.showToast('Recepción',error,'error');
		})
	}
	handleSaveMaterial(event) {
		const rowEdited = event.detail.draftValues.slice().map(draft => {
			return draft;
		});
		rowEdited.forEach(element => {
			let index = this.materialProducts.findIndex(field => field.Id === element.Id);
			this.materialProducts[index].CantidadAMano__c = parseInt(element.CantidadAMano__c);
		});
		this.draftValues = [];
	}

	handleMaterialSelection(event){
		this.selectedMaterial = event.target.value;
	}

	newMaterialProduct(event) {
		event.preventDefault();		
		const fields = event.detail.fields;
		const quantity = parseInt(fields.Cantidad__c)
		if(quantity == 0){
			this.showToast('Cantidad','La cantidad debe ser mayor cero','warning');
			return null;
		}
		getNameOfMaterial({
			materialId : this.selectedMaterial
		}).then(nameOfMaterial => {
			const existMaterial = this.materialProducts.some(elem => elem.material == nameOfMaterial);
			console.log(existMaterial);
			if(existMaterial){
				this.showToast('Recepción','El material ya existe en la tabla, solo actualice la cantidad en el item','warning');
				this.handleReset();
				return null;
			}
			const newMat = {
				Id:this.selectedMaterial,
				material:nameOfMaterial,
				lineItemId: this.orderLineId,
				CantidadAMano__c:quantity
			}
			this.materialProducts = [...this.materialProducts,newMat];
			this.handleReset();
		}).catch(error => {
			console.log(error);
		})
	}

	handleReset(event) {

		const inputFields = this.template.querySelectorAll('lightning-input-field');
		if (inputFields) {
			inputFields.forEach(field => {
				field.reset();
			});
		}

	}

	rowAction(event) {
		const recId = event.detail.row.Id;
		const actionName = event.detail.action.name;
		if (actionName === 'Delete') {
			this.delete(recId);
		}
	}

	reduceMaterial(event){
		if(this.materialProducts.length == 0){
			this.showToast('Rebajo','No hay materiales para rebajo','warning');
			return null;
		}
		this.showToast('Rebajo','Rebajo de material configurado exitosamente','success');
		this.closeModalMaterial();
	}

	doreduceMaterial(material){
		 reduceMaterial({
			lstMat: material
		}).then(result => {
			console.log('rebajo exitoso');
			this.isLoadingSpinner = false;
			this.showSignature = true;
			this.disabledReceptionButton = true;
		}).catch(error => {
			console.log(error);
			this.showSignature = true;
			this.isLoadingSpinner = false;
		})
	}

	delete(recordToDelete) {
		this.materialProducts = this.materialProducts.filter((item) => item.Id !== recordToDelete);
	}

	createPDF(){
		window.open('/apex/PrintVoucher?id='+this.recordId, "_blank");
	}

	closeSignatureModal(){
		savePdfOrder({
			orderId: this.recordId
		}).then(result => {
			console.log('guardao');
			this.dispatchEvent(new CloseActionScreenEvent());
			setTimeout(function() {
				window.location.reload();
			}, 1000);
		}).catch(error => {
			console.log(error);
		})		 
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