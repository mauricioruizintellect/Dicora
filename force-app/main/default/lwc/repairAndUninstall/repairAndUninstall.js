import { LightningElement,api } from 'lwc';
import getListOption from "@salesforce/apex/ControllerRepairAndUninstall.getListOption";
import insertRecord from "@salesforce/apex/ControllerRepairAndUninstall.insertOrdenTrabajo";
import filtros from "@salesforce/apex/ControllerRepairAndUninstall.getRecords";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';


const columns = [
    { label: 'Sitio', fieldName: 'sitio', type: 'text' },
    { label: 'Medio', fieldName: 'medio', type: 'text' },
    { label: 'Instalador', fieldName: 'usuario', type: 'text' },
    { label: 'Proveedor', fieldName: 'proveedor', type: 'text' },
    /*{ label: 'Fecha', fieldName: 'fecha', type: 'date' },*/
    { label: 'Costo', fieldName: 'costo', type: 'decimal' },
    { label: '',type: 'button', typeAttributes: {
        variant:'brand',
        name: 'Reparación',
        label: 'Reparar',
        disabled : {fieldName :'botonDesabilitado'}
    },
    cellAttributes: { alignment: 'right' }},
    { label: '',type: 'button', typeAttributes: {
        variant:'brand',
        name: 'Desinstalación',
        label: 'Desinstalar',
        disabled : {fieldName :'botonDesabilitado'}
    },
    cellAttributes: { alignment: 'right' }}
];


export default class RepairAndUninstall extends LightningElement {
    @api recordId;
    allData = {};
    showSpinner = true;
    columns = columns;
    dataTable = [];


    connectedCallback() {
        this.init();
    }
    init() {
        this.showSpinner = true;
        getListOption({
            recordId: this.recordId,
            medio: null,
            sitio: null
          })
          .then(response => {
            if(response != null){
                this.allData = response;
                this.dataTable = response.listRecord;
            }
        })
        .catch(error => {
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
        });
        this.showSpinner = false;
    }
    eventOnchange(event){
        let nameField = event.target.name;
        let valueFiel = event.target.value.trim() != '' ? event.target.value.trim() : null;;
        if(nameField == 'sitio'){
            this.allData.sitio = valueFiel;
        }else if(nameField == 'medio'){
            this.allData.medio = valueFiel;
        }else if(nameField == 'fecha'){
            this.allData.fecha = valueFiel;
        }else if(nameField == 'costo'){
            this.allData.costo = valueFiel;
        }else if(nameField == 'detalle'){
            this.allData.detalle = valueFiel;
        }
    }
    selectTable(event){
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if(this.allData.fecha == null || this.allData.costo == null){
            this.pushMessage('Advertencia', 'warning', 'Faltan campos obligatorios');
            return;
        }
        this.showSpinner = true;
        insertRecord({
            recordId: row.id,
            accion: actionName,
            fecha: this.allData.fecha,
            costo: this.allData.costo,
            detalle: this.allData.detalle
        })
        .then((response) => {
            this.pushMessage('Exitoso', 'success', 'Datos guardados con exito.');
            this.init();
            this.showSpinner = false;
        })
        .catch(error => {
            this.showSpinner = false;
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
        });
    }
    filtrar(){
        this.showSpinner = true;
        console.log(this.allData.sitio + '  '+this.allData.medio);
        filtros({
            recordId: this.recordId,
            medio: this.allData.medio,
            sitio: this.allData.sitio,
            botonDesabilitado: this.allData.botonDesabilitado
        })
        .then((response) => {
            if(response.length > 0){
                this.dataTable = response;
            }else{
                this.pushMessage('Advertencia', 'warning', 'No se encontraron resultados.');
            }
        })
        .catch(error => {
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
        });
        this.showSpinner = false;
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