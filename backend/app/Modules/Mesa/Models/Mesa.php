<?php

declare(strict_types=1);

namespace App\Modules\Mesa\Models;

use App\Models\Pedido;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Mesa extends Model
{
    use HasFactory;

    protected $table = 'mesas';

    protected $fillable = [
        'nombre',
        'area',
        'capacidad',
        'estado',
        'orden_activa_id',
    ];

    protected $casts = [
        'capacidad' => 'integer',
    ];

    public function ordenActiva()
    {
        return $this->belongsTo(Pedido::class, 'orden_activa_id')->with('detalles');
    }

    public function pedidos()
    {
        return $this->hasMany(Pedido::class, 'mesa_id');
    }
}
