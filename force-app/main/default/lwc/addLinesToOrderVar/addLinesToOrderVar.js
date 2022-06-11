import { LightningElement,api,track } from 'lwc';

import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getFormato from "@salesforce/apex/ControllerAddLinesToOrderVar.getFormato";
import getSitio from "@salesforce/apex/ControllerAddLinesToOrderVar.getSitio";
import getMedida from "@salesforce/apex/ControllerAddLinesToOrderVar.getMedida";
import getArte from "@salesforce/apex/ControllerAddLinesToOrderVar.getArte";
import getPrecio from "@salesforce/apex/ControllerAddLinesToOrderVar.getPrecio";
import getLineasOC from "@salesforce/apex/ControllerAddLinesToOrderVar.getLineasOrdenCompra";
import guardarRegistro from "@salesforce/apex/ControllerAddLinesToOrderVar.guardarRegistro";
import borrarRegistro from "@salesforce/apex/ControllerAddLinesToOrder.borrarRegistro";
import editarrRegistro from "@salesforce/apex/ControllerAddLinesToOrderVar.editarRegistro";


const columnsDetalladasAgreg = [
    { label: 'Contrato', fieldName: 'contrato', type: 'text'  },
    { label: 'Cadena', fieldName: 'cadena', type: 'text' },
    { label: 'Formato', fieldName: 'formato', type: 'text' },
    { label: 'Producto', fieldName: 'producto', type: 'text' },
    { label: 'Sitio', fieldName: 'sitio', type: 'text' },
    { label: 'Medida', fieldName: 'medida', type: 'text' },
    { label: 'Arte', fieldName: 'arte', type: 'text' },
    { label: 'Cantidad', fieldName: 'cantidad', type: 'decimal',cellAttributes: { alignment: 'right' }},
    { label: 'Tarifa', fieldName: 'tarifa', type: 'currency',cellAttributes: { alignment: 'right' },typeAttributes:{currencyCode: { fieldName: 'codigoMoneda'}}},
    { label: 'Total', fieldName: 'total', type: 'currency',cellAttributes: { alignment: 'right' },typeAttributes:{currencyCode: { fieldName: 'codigoMoneda'}}},
    { label: 'Requerimientos Especiales', fieldName: 'requerimientosEspeciales', type: 'text' },
    {type: "button-icon",
        typeAttributes: {  
            label: '',
            title: '',
            iconPosition: 'right',
            iconName:'utility:edit',
            name: 'edit'
        },
        cellAttributes: { alignment: 'right' }
    },
    {type: "button-icon",
        typeAttributes: {
            label: '',
            title: '',
            iconPosition: 'right',
            iconName:'utility:delete',
            name: 'delete'
        },
        cellAttributes: { alignment: 'right' }
    } 
];


export default class AddLinesToOrderVar extends LightningElement {
    @api recordId
    @api mostrarAgreg = false;
    @track allData = {};
    @track editarLOC = {};
    showSpinner = false;
    columns = columnsDetalladasAgreg;
    popEditar = false;
    mostrarDataTabla;
    connectedCallback() {
        this.validarMostrarTabla();
        this.init();
    }
    validarMostrarTabla(){
        if(this.mostrarAgreg == true){
            this.mostrarDataTabla = true;
        }else{
            this.mostrarDataTabla = false;
        }
    }

    init() {
        getLineasOC({
            recordId: this.recordId
        }).then(response => {
            this.allData = response;
            this.showSpinner = false;
            if(!this.mostrarDataTabla){
                this.cargarArtes();
            }else{
                this.allData.contrato = null;
            }
        }).catch(error => {
            this.showSpinner = false;
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
        });
    }

    handleChangeEdit(event){
        const field = event.target.name;
        const valor = event.target.value;
        if(field == 'cantidad'){
            this.editarLOC.cantidad = valor.trim() != '' ? valor : null;
            if(this.editarLOC.cantidad != null){
                this.editarLOC.total = (this.editarLOC.cantidad * this.editarLOC.tarifa).toFixed(2);
            }else{
                this.editarLOC.total = 0;
            }
        }
    }

    handleChange(event){
        const field = event.target.name;
        const valor = event.target.value;

        console.log('valor: '+valor);
        if(field == 'contrato'){
            this.allData.contrato = valor;
            this.cargarArtes();
            this.allData.arte =null;
        }else if(field == 'cadena'){
            this.allData.cadena = valor;
            this.cargarFormatos();
            this.allData.formato = null;
        }else if(field == 'formato'){
            this.allData.formato = valor;
            this.cargarSitios();
            this.allData.sitio = null;
        }else if(field == 'producto'){
            this.allData.producto = valor;
            this.allData.listMedidas = [];
            this.allData.medida = null;
            this.allData.tarifa = 0;
            this.allData.tarifaOrg = 0; 
            this.cargarMedidas();
            this.medida = null;
        }else if(field == 'sitio'){
            this.allData.sitio = valor;
        }else if(field == 'medida'){
            this.allData.medida = valor;
            this.cargarPrecio();
        }else if(field == 'arte'){
            this.allData.arte = valor;
        }else if(field == 'requerimientosEspeciales'){
            this.allData.requerimientosEspeciales = valor.trim() != '' ? valor : null;
        }else if(field == 'tarifa'){
            this.allData.tarifa = valor.trim() != '' ? valor : null;
            this.calcularTotal();
        }else if(field == 'cantidad'){
            this.allData.cantidad = valor.trim() != '' ? valor : null;
            this.calcularTotal();
        }else if(field == 'cambioPrecio'){
            this.allData.comentariosNotif = valor.trim() != '' ? valor : null;
        }
        this.validarBoton();
    }

    validarBoton(){
        this.allData.disabledBoton = true;
        var data = this.allData;
        if(data.contrato != null && data.formato != null && data.cadena != null && 
            data.producto != null && data.medida != null && (data.sitio != null || !data.mostrarSitio) && 
            data.total > 0){// && data.arte != null){
            this.allData.disabledBoton = false;
        }
    }

    salir(){
        this.allData.popPorcentaje = false;
        this.popEditar = false;
    }

    calcularPorcentaje(){
        this.allData.enviarNotificacion = false;
        this.allData.popPorcentaje = false;
        let valorPorcen = (this.allData.tarifaOrg * this.allData.porcentajeDeCambioDeTarija) / 100;
        if(this.allData.tarifa > (valorPorcen + this.allData.tarifaOrg) || this.allData.tarifa < (this.allData.tarifaOrg - valorPorcen)){
            this.allData.enviarNotificacion = true;
            this.pushMessage('Advertencia.', 'warning', 'Está modificando el precio más de la variabilidad permitida, se notificará a supervisor.');
        }
    }
    calcularTotal(){
        if(this.allData.cantidad != null && this.allData.tarifa != null){
            this.allData.total = (this.allData.cantidad * this.allData.tarifa).toFixed(2);
        }else{
            this.allData.total = 0;
        }
    }
    cargarFormatos() {
        this.showSpinner = true;
        getFormato({
            cadenaId: this.allData.cadena
        }).then(response => {
            this.allData.listFormatos = response;
            this.showSpinner = false;
        })
    }
    cargarSitios() {
        this.showSpinner = true;
        getSitio({
            cadenaId: this.allData.cadena,
            formatoId: this.allData.formato
        }).then(response => {
            this.allData.listSitios = response;
            this.showSpinner = false;
        })
    }

    cargarMedidas() {
        this.showSpinner = true;
        getMedida({
            productoId: this.allData.producto
        }).then(response => {
            this.allData.listMedidas = response.listMedida;
            this.allData.medida = response.medidaPrincipal;
            console.log('antes')
            if(this.allData.medida != null){
                this.cargarPrecio();
            }else{
                this.showSpinner = false;
            }
        })
    }

    cargarArtes() {
        this.showSpinner = true;
        getArte({
            campaniaId: this.allData.contrato
        }).then(response => {
            this.allData.listArtes = response;
            this.showSpinner = false;
        })
    }

    cargarPrecio() {
        this.showSpinner = false;
        getPrecio({
            productoId: this.allData.producto,
            medidaId: this.allData.medida, 
            ordenCompraId: this.recordId
        }).then(response => {
            this.allData.tarifa = response;
            this.allData.tarifaOrg = response;
            this.showSpinner = false;
        })
    }

    agregarOrdenCompra(){
        if(this.allData.enviarNotificacion && !this.allData.popPorcentaje){
            this.allData.popPorcentaje = true;
        }else{
            this.showSpinner = true;
            this.allData.ordenCompraId = this.recordId;
            guardarRegistro({
                data: JSON.stringify(this.allData)
            }).then(response => {
                this.init();
                this.pushMessage('Exitoso', 'success', 'Datos guardados exitosamente.');
            }).catch(error => {
                this.showSpinner = false;
                this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
            });
        }
    }

    onclickSitio(){
        if(this.allData.mostrarSitio){
            this.allData.textoBoton = "Mostrar Sitio"
        }else{
            this.allData.textoBoton = "Ocultar Sitio"
        }
        this.allData.mostrarSitio = !this.allData.mostrarSitio;
        this.validarBoton();
    }

    pushMessage(title,variant,msj){
        const message = new ShowToastEvent({
            "title": title,
            "variant": variant,
            "message": msj
            });
            this.dispatchEvent(message);
    }

    onClickTableAgreg(event){
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if(actionName == 'edit'){
            const row = event.detail.row;
            this.editarLOC = row;
            this.popEditar = true;
        }else{
            this.deleteRecord(row.id);
        }
    }

    editarRecord(){
        this.showSpinner = true;
        this.popEditar = false;
        editarrRegistro({
            recordId: this.editarLOC.id,
            cantidad: this.editarLOC.cantidad
        }).then(response => {
            this.init();
            this.pushMessage('Exitoso', 'success', 'Datos guardados exitosamente.');
        }).catch(error => {
            this.showSpinner = false;
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
        });
    }

    deleteRecord(idRegistro){
        this.showSpinner = true;
        borrarRegistro({
            recordId: idRegistro
        }).then(response => {
            this.init();
            this.pushMessage('Exitoso', 'success', 'Datos guardados exitosamente.');
        })
    }

}