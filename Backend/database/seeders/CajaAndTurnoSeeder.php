<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Caja;
use App\Models\Turno;

class CajaAndTurnoSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        // Crear 5 cajas
        for ($i = 1; $i <= 5; $i++) {
            Caja::updateOrCreate(
                ['id' => $i],
                ['nombre' => "Caja $i", 'activa' => true]
            );
        }

        // Crear 3 turnos
        Turno::updateOrCreate(
            ['id' => 1],
            ['nombre' => 'Mañana', 'hora_inicio' => '08:00:00', 'hora_fin' => '16:00:00']
        );

        Turno::updateOrCreate(
            ['id' => 2],
            ['nombre' => 'Tarde', 'hora_inicio' => '16:00:00', 'hora_fin' => '00:00:00']
        );

        Turno::updateOrCreate(
            ['id' => 3],
            ['nombre' => 'Noche', 'hora_inicio' => '20:00:00', 'hora_fin' => '04:00:00']
        );
    }
}
