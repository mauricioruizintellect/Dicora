import { LightningElement,api } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getVentas from "@salesforce/apex/ControllerAddLinesToOrder.getVentas";
import guardarRegistros from "@salesforce/apex/ControllerAddLinesToOrder.guardarRegistros";
import borrarRegistro from "@salesforce/apex/ControllerAddLinesToOrder.borrarRegistro";
import editarrRegistro from "@salesforce/apex/ControllerAddLinesToOrder.editarRegistro";
import getPrecio from "@salesforce/apex/ControllerAddLinesToOrder.getPrecio";

const columnsAgrupadas = [
    { label: 'Cadena', fieldName: 'cadena', type: 'text', editable: true  },
    { label: 'Formato', fieldName: 'formato', type: 'text' },
    { label: 'Producto', fieldName: 'producto', type: 'text' },
    { label: 'Medida', fieldName: 'medida', type: 'text' },
    { label: 'Arte', fieldName: 'arte', type: 'text' },
    { label: 'Cantidad', fieldName: 'cantidad', type: 'decimal',cellAttributes: { alignment: 'right' }},
    { label: 'Tarifa', fieldName: 'tarifa', type: 'currency',cellAttributes: { alignment: 'right' },typeAttributes:{currencyCode: { fieldName: 'codigoMoneda'}}},
    { label: 'Total', fieldName: 'total', type: 'currency',cellAttributes: { alignment: 'right' },typeAttributes:{currencyCode: { fieldName: 'codigoMoneda'}}},
    { label: 'Requerimientos Especiales', fieldName: 'requerimientosEspeciales', type: 'text',wrapText: true},
    {type: "button-icon", typeAttributes: {
        label: '',
        title: '',
        iconPosition: 'right',
        iconName:'utility:edit',
        name: 'edit'
    },
    cellAttributes: { alignment: 'right' }
}
    
];
const columnsAgrupadasAgreg = [
    { label: 'Cadena', fieldName: 'cadena', type: 'text', editable: true  },
    { label: 'Formato', fieldName: 'formato', type: 'text' },
    { label: 'Producto', fieldName: 'producto', type: 'text' },
    { label: 'Medida', fieldName: 'medida', type: 'text' },
    { label: 'Arte', fieldName: 'arte', type: 'text' },
    { label: 'Cantidad', fieldName: 'cantidad', type: 'decimal',cellAttributes: { alignment: 'right' }},
    { label: 'Tarifa', fieldName: 'tarifa', type: 'currency',cellAttributes: { alignment: 'right' },typeAttributes:{currencyCode: { fieldName: 'codigoMoneda'}}},
    { label: 'Total', fieldName: 'total', type: 'currency',cellAttributes: { alignment: 'right' },typeAttributes:{currencyCode: { fieldName: 'codigoMoneda'}}},
    { label: 'Requerimientos Especiales', fieldName: 'requerimientosEspeciales', type: 'text',wrapText: true ,
    cellAttributes: {
        class: 'slds-cell-wrap'
    }},
    {type: "button-icon", typeAttributes: {
        label: '',
        title: '',
        iconPosition: 'right',
        iconName:'utility:edit',
        name: 'edit'
    },
     cellAttributes: { alignment: 'right' }
    },
    {type: "button-icon", typeAttributes: {
        label: '',
        title: '',
        iconPosition: 'right',
        iconName:'utility:delete',
        name: 'delete'
    },
    cellAttributes: { alignment: 'right' }
}
    
];

const columnsDetalladas = [
    { label: 'Cadena', fieldName: 'cadena', type: 'text', editable: true  },
    { label: 'Formato', fieldName: 'formato', type: 'text' },
    { label: 'Producto', fieldName: 'producto', type: 'text' },
    { label: 'Sitio', fieldName: 'sitio', type: 'text' },
    { label: 'Medida', fieldName: 'medida', type: 'text' },
    { label: 'Arte', fieldName: 'arte', type: 'text' },
    { label: 'Cantidad', fieldName: 'cantidad', type: 'decimal',cellAttributes: { alignment: 'right' }},
    { label: 'Tarifa', fieldName: 'tarifa', type: 'currency',cellAttributes: { alignment: 'right' },typeAttributes:{currencyCode: { fieldName: 'codigoMoneda'}}},
    { label: 'Total', fieldName: 'total', type: 'currency',cellAttributes: { alignment: 'right' },typeAttributes:{currencyCode: { fieldName: 'codigoMoneda'}}},
    { label: 'Requerimientos Especiales', fieldName: 'requerimientosEspeciales',type: 'text',wrapText: true},
    {type: "button-icon", typeAttributes: {
        label: '',
        title: '',
        iconPosition: 'right',
        iconName:'utility:edit',
        name: 'edit'
    },
    cellAttributes: { alignment: 'right' }
}
];
const columnsDetalladasAgreg = [
    { label: 'Cadena', fieldName: 'cadena', type: 'text', editable: true  },
    { label: 'Formato', fieldName: 'formato', type: 'text' },
    { label: 'Producto', fieldName: 'producto', type: 'text' },
    { label: 'Sitio', fieldName: 'sitio', type: 'text' },
    { label: 'Medida', fieldName: 'medida', type: 'text' },
    { label: 'Arte', fieldName: 'arte', type: 'text' },
    { label: 'Cantidad', fieldName: 'cantidad', type: 'decimal',cellAttributes: { alignment: 'right' }},
    { label: 'Tarifa', fieldName: 'tarifa', type: 'currency',cellAttributes: { alignment: 'right' },typeAttributes:{currencyCode: { fieldName: 'codigoMoneda'}}},
    { label: 'Total', fieldName: 'total', type: 'currency',cellAttributes: { alignment: 'right' },typeAttributes:{currencyCode: { fieldName: 'codigoMoneda'}}},
    { label: 'Requerimientos Especiales', fieldName: 'requerimientosEspeciales', type: 'text',wrapText: true,
    cellAttributes: {
        class: 'slds-cell-wrap'
    }},
    {type: "button-icon", typeAttributes: {
        label: '',
        title: '',
        iconPosition: 'right',
        iconName:'utility:edit',
        name: 'edit'
    },
    cellAttributes: { alignment: 'right' }
},
{type: "button-icon", typeAttributes: {
    label: '',
    title: '',
    iconPosition: 'right',
    iconName:'utility:delete',
    name: 'delete'
},
cellAttributes: { alignment: 'right' }
}
    
];

export default class AddLinesToOrder extends LightningElement {
    @api recordId;
    columns;
    columnsAgregadas;
    allData = {};
    showSpinner = true;
    popEditar = false;
    popPorcentaje = false;
    editarVenta = {};
    listVentas = [];
    listVentasSelecc = [];
    listVentasAgregadas = [];
    total;
    precioOrig;
    disableBoton = true;
    banderaAdvert = true;
    popLineaOC = false;

    connectedCallback() {
        this.init();
    }
    init() {
        this.popLineaOC = false;
        getVentas({
            recordId: this.recordId
        }).then(response => {
            this.allData = response;
            this.listVentas = this.allData.listVentas;
            this.listVentasAgregadas = this.allData.listVentasAgregadas;
            this.disableBoton = true;
            if(response.etapa != '04 Artes Completados' && this.banderaAdvert){
                this.banderaAdvert = false;
                this.pushMessage('Advertencia.', 'warning', 'Es posible que los artes no estén completos.');
            }
            this.columns = response.isProduccion ? columnsAgrupadas : columnsDetalladas;
            this.columnsAgregadas = response.isProduccion ? columnsAgrupadasAgreg : columnsDetalladasAgreg;
            this.showSpinner = false;
        }).catch(error => {
            this.showSpinner = false;
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
        });
    }

    onclicknuevaLOC(){
        this.popLineaOC = true;
        
    }

    pushMessage(title,variant,msj){
        const message = new ShowToastEvent({
            "title": title,
            "variant": variant,
            "message": msj
            });
            this.dispatchEvent(message);
    }
    handleChange(event){
        const field = event.target.name;
        const valor = event.target.value;
        if(field == 'cantidad'){
            this.editarVenta.cantidad = valor.trim() != '' ? valor : null;
            this.calcularTotal();
        }else if(field == 'arte'){
            this.editarVenta.arteId = valor.trim() != '' ? valor : null;
        }else if(field == 'requerimientosEspeciales'){
            this.editarVenta.requerimientosEspeciales = valor.trim() != '' ? valor : null;
        }else if(field == 'tarifa'){
            this.editarVenta.tarifa = valor.trim() != '' ? valor : null;
            this.calcularTotal();
            this.calcularPorcentaje();
        }else if(field == 'cambioPrecio'){
            this.editarVenta.comentariosNotif = valor.trim() != '' ? valor : null;
        }else if(field == 'medida'){
            this.editarVenta.medidaId = valor.trim() != '' ? valor : null;
            this.cargarPrecio();
        }

        
    }
    calcularTotal(){
        if(this.editarVenta.cantidad != null && this.editarVenta.tarifa != null){
            this.editarVenta.total = (this.editarVenta.cantidad * this.editarVenta.tarifa).toFixed(2);
        }else{
            this.editarVenta.total = 0;
        }
        this.total = this.editarVenta.total;
    }
    calcularPorcentaje(){
        this.editarVenta.enviarNotificacion = false;
        for(let i=0; i<this.listVentas.length; i++){
            if(this.listVentas[i].id == this.editarVenta.id){
                let valorPorcen = (this.listVentas[i].tarifaOrg * this.allData.porcentajeDeCambioDeTarija) / 100;
                if(this.editarVenta.tarifa > (valorPorcen + this.listVentas[i].tarifaOrg) || this.editarVenta.tarifa < (this.listVentas[i].tarifaOrg - valorPorcen)){
                    this.editarVenta.enviarNotificacion = true;
                    this.pushMessage('Advertencia.', 'warning', 'Está modificando el precio más de la variabilidad permitida, se notificará a supervisor.');
                }
            }
        }
    }

    cargarPrecio() {
        this.showSpinner = true;
        console.log(this.editarVenta.productoId+ ' -- '+this.editarVenta.medidaId+ ' -- '+this.recordId);
        getPrecio({
            productoId: this.editarVenta.productoId,
            medidaId: this.editarVenta.medidaId, 
            ordenCompraId: this.recordId
        }).then(response => {
            this.editarVenta.tarifa = response;
            this.editarVenta.tarifaOrg = response;
            this.showSpinner = false;
            this.calcularTotal();
            this.calcularPorcentaje();
        })
    }

    selectTable(event){
        var selectedRows = event.detail.selectedRows;
        this.listVentasSelecc = selectedRows;
        this.disableBoton = true;
        for(let i=0; i<this.listVentasSelecc.length; i++){
            if(this.listVentasSelecc[i].total == 0){
                    this.pushMessage('Advertencia.', 'warning', 'No puede seleccionar ventas con campos vacíos.');
                    return;
            }
        }
        this.disableBoton = selectedRows.length > 0 ? false : true;
    }
    onClickEdit(event){
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        this.editarVenta = row;
        this.editarVenta.seleccionado = false;
        this.total = this.editarVenta.total;
        this.precioOrig = this.editarVenta.tarifaOrg;
        this.popEditar = true;

    }
    onClickTableAgreg(event){
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if(actionName == 'edit'){
            const row = event.detail.row;
            this.editarVenta = row;
            this.editarVenta.seleccionado = true;
            this.total = this.editarVenta.total;
            this.popEditar = true;
        }else{
            this.deleteRecord(row.id);
        }
    }
    deleteRecord(idRegistro){
        this.showSpinner = true;
        borrarRegistro({
            recordId: idRegistro
        }).then(response => {
            this.listVentas = [];
            this.listVentasAgregadas = [];
            this.init();
            this.pushMessage('Exitoso', 'success', 'Datos guardados exitosamente.');
        }).catch(error => {
            this.showSpinner = false;
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
        });
    }
    editRecord(){
        this.showSpinner = true;
        this.popEditar = false;
        editarrRegistro({
            dataJson: JSON.stringify(this.editarVenta)
        }).then(response => {
            this.listVentas = [];
            this.listVentasAgregadas = [];
            this.init();
            this.pushMessage('Exitoso', 'success', 'Datos guardados exitosamente.');
        }).catch(error => {
            this.showSpinner = false;
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
        });
    }
    cancel(){
        this.popEditar = false;
        this.popPorcentaje = false;
    }
    guardarPop(){
        if(this.editarVenta.cantidad == null || this.editarVenta.tarifa == null || this.editarVenta.medidaId == null
            || (this.popPorcentaje && this.editarVenta.comentariosNotif == null)){
            this.pushMessage('Advertencia.', 'warning', 'Debe llenar todos los campos.');
        }else if(this.editarVenta.seleccionado){
            this.editRecord();
        }else if(this.editarVenta.enviarNotificacion && !this.popPorcentaje){
            this.popEditar = false;
            this.popPorcentaje = true;
        }else{
            this.cancel();
            var listTemp = [];
            for(let i=0; i<this.listVentas.length; i++){
                if(this.listVentas[i].id != this.editarVenta.id){
                    listTemp.push(this.listVentas[i]);
                }else{
                    for(let j=0; j<this.editarVenta.listArtes.length; j++){
                        if(this.editarVenta.listArtes[j].value == this.editarVenta.arteId){
                            this.editarVenta.arte = this.editarVenta.listArtes[j].label;
                        }
                    }
                    for(let j=0; j<this.editarVenta.listMedidas.length; j++){
                        if(this.editarVenta.listMedidas[j].value == this.editarVenta.medidaId){
                            this.editarVenta.medida = this.editarVenta.listMedidas[j].label;
                        }
                    }
                    listTemp.push(this.editarVenta);
                }
            }
            this.listVentas = listTemp;
        }
    }
    agregarOrdenCompra(){
        this.showSpinner = true;
        guardarRegistros({
            listRegistros: JSON.stringify(this.listVentasSelecc),
            esDetallada: !this.allData.isProduccion
        }).then(response => {
            this.listVentas = [];
            this.listVentasAgregadas = [];
            eval("$A.get('e.force:refreshView').fire();");
            this.init();
            this.pushMessage('Exitoso', 'success', 'Datos guardados exitosamente.');
        }).catch(error => {
            this.showSpinner = false;
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
        });
    }
    unidadesExtras(){
        var ventas = [];
        for(let i=0; i<this.listVentas.length; i++){
            let unidades = Math.ceil(this.listVentas[i].cantidad * this.allData.porcentaje);
            this.listVentas[i].cantidad = (this.listVentas[i].cantidad + unidades);
            this.listVentas[i].total = this.listVentas[i].cantidad * this.listVentas[i].tarifa;
            ventas.push(this.listVentas[i]);
         }
         this.listVentas = ventas;
    }

}