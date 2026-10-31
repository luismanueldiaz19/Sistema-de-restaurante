<?php

declare(strict_types=1);

namespace App\Modules\Cotizacion\Policies;

use App\Models\User;
use App\Models\Cotizacion;
use Illuminate\Auth\Access\HandlesAuthorization;

class CotizacionPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user): bool
    {
        return true; // Todos los usuarios autenticados pueden ver la lista
    }

    public function view(User $user, Cotizacion $cotizacion): bool
    {
        return true; // O puedes restringir a: return $user->id === $cotizacion->user_id;
    }

    public function create(User $user): bool
    {
        return true;
    }

    public function update(User $user, Cotizacion $cotizacion): bool
    {
        return true;
    }

    public function delete(User $user, Cotizacion $cotizacion): bool
    {
        return true;
    }
}
