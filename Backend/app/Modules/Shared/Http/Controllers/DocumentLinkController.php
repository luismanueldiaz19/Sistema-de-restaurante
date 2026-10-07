<?php

declare(strict_types=1);

namespace App\Modules\Shared\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Cotizacion;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Barryvdh\DomPDF\Facade\Pdf;

class DocumentLinkController extends Controller
{
    public function show(Request $request, string $token)
    {
        $data = Cache::get("short_link_{$token}");

        if (!$data) {
            abort(404, 'El enlace ha expirado o no es válido.');
        }

        if ($data['type'] === 'cotizacion') {
            return $this->generarPdfCotizacion((int) $data['id'], $data['companyData']);
        }

        abort(404, 'Tipo de documento no soportado.');
    }

    private function generarPdfCotizacion(int $id, array $companyData)
    {
        $cotizacion = Cotizacion::with(['cliente', 'detalles', 'user'])->findOrFail($id);

        $company = [
            'nombre' => $companyData['company_name'] ?? 'Tu Restaurante Favorito',
            'rnc' => $companyData['company_rnc'] ?? '123456789',
            'direccion' => $companyData['company_address'] ?? 'Santo Domingo, República Dominicana',
            'telefono' => $companyData['company_phone'] ?? '(809) 555-5555',
        ];

        $pdf = Pdf::loadView('pdf.cotizacion', compact('cotizacion', 'company'));

        return $pdf->stream('cotizacion_'.$cotizacion->id.'.pdf');
    }
}
