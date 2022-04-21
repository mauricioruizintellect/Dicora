import { LightningElement,api } from 'lwc';
import getOrdenTrabajo from "@salesforce/apex/ControllerAssociateWorkOrder.getOrdenTrabajo";
import updateRecord from "@salesforce/apex/ControllerAssociateWorkOrder.updateRecord";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

const columns = [
    { label: 'Tipo', fieldName: 'tipo', type: 'text' },
    { label: 'Estado', fieldName: 'estado', type: 'text' },
    { label: 'Proveedor', fieldName: 'proveedor', type: 'text' },
    { label: 'Instalador', fieldName: 'instalador', type: 'text' },
    { label: 'Fecha', fieldName: 'fecha', type: 'date' },
    { label: 'Costo', fieldName: 'costo', type: 'decimal',cellAttributes: { alignment: 'right' }}
    
];

export default class AssociateWorkOrder extends LightningElement {
    @api recordId;
    showSpinner = true;
    columns = columns;
    dataTable = [];
    dataSelected = [];
    disabledSave = true;

    connectedCallback() {
        this.init();
    }
    init() {
        this.dataSelected = [];
        this.dataTable = [];
        getOrdenTrabajo({
            recordId: this.recordId
        }).then(response => {
            this.dataTable = response;
            this.showSpinner = false;
        })
    }

    saveData(){
        this.showSpinner = true;
        updateRecord({
            jsonString: JSON.stringify(this.dataSelected), 
            recordId: this.recordId
        }).then(response => {
            this.pushMessage('Exitoso', 'success', 'Datos guardados con exito.');
            this.init();
        }).catch(error => {
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
        });
        
        this.showSpinner = false;
    }

    selectTable(event){
       console.log(JSON.stringify(event.detail.selectedRows));
       var selectedRows=event.detail.selectedRows;
       this.dataSelected = [];
       this.disabledSave = true;
       if(selectedRows.length > 0){
           this.dataSelected = selectedRows;
        this.disabledSave = false;
       }
    }
    pushMessage(title,variant,msj){
        const message = new ShowToastEvent({
            "title": title,
            "variant": variant,
            "message": msj
            });
            this.dispatchEvent(message);
    }


}