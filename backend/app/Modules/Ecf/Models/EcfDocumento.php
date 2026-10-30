<?php

namespace App\Modules\Ecf\Models;

use App\Models\Factura;
use App\Models\NotaCredito;
use Illuminate\Database\Eloquent\Model;

class EcfDocumento extends Model
{
    protected $table = 'ecf_documentos';

    protected $fillable = [
        'factura_id',
        'nota_credito_id',
        'encf',
        'tipo_ecf',
        'es_resumen_fc',
        'rnc_emisor',
        'rnc_comprador',
        'razon_social_comprador',
        'monto_gravado',
        'monto_exento',
        'total_itbis',
        'monto_total',
        'codigo_seguridad',
        'fecha_emision',
        'fecha_hora_firma',
        'qr_url',
        'xml_path',
        'xml_firmado',
        'xml_rfce_firmado',
        'xsd_valido',
        'xsd_errores',
        'ambiente',
        'track_id',
        'estado_dgii',
        'respuesta_dgii',
        'fecha_envio',
        'intentos_envio',
        'ultimo_error',
    ];

    protected $casts = [
        'es_resumen_fc'  => 'boolean',
        'xsd_valido'     => 'boolean',
        'xsd_errores'    => 'array',
        'respuesta_dgii' => 'array',
        'fecha_emision'  => 'date:Y-m-d',
        'fecha_envio'    => 'datetime',
        'monto_gravado'  => 'float',
        'monto_exento'   => 'float',
        'total_itbis'    => 'float',
        'monto_total'    => 'float',
    ];

    protected $hidden = [
        'xml_firmado',
        'xml_rfce_firmado',
    ];

    public function factura()
    {
        return $this->belongsTo(Factura::class, 'factura_id');
    }

    public function notaCredito()
    {
        return $this->belongsTo(NotaCredito::class, 'nota_credito_id');
    }

    public function toSummaryArray(): array
    {
        return [
            'id'               => $this->id,
            'encf'             => $this->encf,
            'tipo_ecf'         => $this->tipo_ecf,
            'es_resumen_fc'    => $this->es_resumen_fc,
            'codigo_seguridad' => $this->codigo_seguridad,
            'fecha_hora_firma' => $this->fecha_hora_firma,
            'qr_url'           => $this->qr_url,
            'xsd_valido'       => $this->xsd_valido,
            'ambiente'         => $this->ambiente,
            'track_id'         => $this->track_id,
            'estado_dgii'      => $this->estado_dgii,
        ];
    }
}

