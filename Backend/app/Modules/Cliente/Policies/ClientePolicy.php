<?php

namespace App\Modules\Cliente\Policies;

use App\Models\User;
use App\Modules\Cliente\Models\Cliente;
use Illuminate\Auth\Access\HandlesAuthorization;

class ClientePolicy
{
    use HandlesAuthorization;

    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user)
    {
        return $user->hasPermissionTo('ver_clientes');
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User $user, Cliente $cliente)
    {
        return $user->hasPermissionTo('ver_clientes');
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user)
    {
        return $user->hasPermissionTo('crear_clientes');
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, Cliente $cliente)
    {
        return $user->hasPermissionTo('editar_clientes');
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, Cliente $cliente)
    {
        return $user->hasPermissionTo('eliminar_clientes');
    }
}
