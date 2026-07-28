<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

try {
    $producto = \App\Models\Producto::first();
    echo "Tratando de borrar producto ID: " . $producto->id . "\n";
    $producto->delete();
    echo "¡Borrado con éxito!\n";
} catch (\Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
