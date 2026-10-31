<?php

namespace App\Modules\Producto\Policies;

use App\Models\User;
use App\Models\Producto;
use Illuminate\Auth\Access\HandlesAuthorization;

class ProductoPolicy
{
    use HandlesAuthorization;

    public function viewAny(User $user)
    {
        return $user->hasPermissionTo('ver_productos');
    }

    public function view(User $user, Producto $producto = null)
    {
        return $user->hasPermissionTo('ver_productos');
    }

    public function create(User $user)
    {
        return $user->hasPermissionTo('crear_productos');
    }

    public function update(User $user, Producto $producto = null)
    {
        return $user->hasPermissionTo('editar_productos');
    }

    public function delete(User $user, Producto $producto = null)
    {
        return $user->hasPermissionTo('eliminar_productos');
    }
}
